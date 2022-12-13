#!/bin/bash
serverDirectory="/etc/openvpn/server/"
randomServer="${serverDirectory}$(ls $serverDirectory | sort -R | tail -1)"
current_script=${BASH_SOURCE[0]}

# Run script as root if it's run by another user
if [[ $EUID -ne 0 ]]; then
	echo "$(basename {current_script}) must be run as root. Attempting to sudo..."
	sudo ${current_script}
	exit
fi

# Verify that this script can be sudoed by all users regardless of normal permissions
#	(without password)
nopasswd_sudo_enabled () {
	regex="^all[[:space:]]+all[[:space:]]*=\(root\)[[:space:]]+(.*:)*nopasswd:(.*:)*[[:space:]]+(.*)"
	# ALL	ALL=(root) 	NOPASSWD:{accept but ignore any add'l paramters} {script name}
	while read line; do
		if $nopasswd_sudo_enabled; then break; fi
		
		[[ ${line,,} =~ $regex ]]
		if [[ ${#BASH_REMATCH[@]} > 0 ]]; then
			# Bash regex doesn't allow us to create ignored capture groups, so we need to always check
			#	the last regex group in the array
			length=$(( ${#BASH_REMATCH[@]} - 1))
			capture=${BASH_REMATCH[$length]}
			# If the captured regex matches our script source,
			#	that means this script can sudo as intended
			if [[ ${capture} == ${current_script} ]]; then
				return 1
			fi
		fi
	done < <(sudo cat /etc/sudoers)
	
	return 0
}

[[ nopasswd_sudo_enabled ]] && echo 'No Passwd Sudo is Enabled' || echo 'No Passwd Sudo is Disabled'

echo "Connecting to random AirVPN Server [$(basename ${randomServer})]"
/usr/sbin/openvpn ${randomServer} &> /dev/null
