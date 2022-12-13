#!/bin/bash
serverDirectory="/etc/openvpn/server/"
randomServer="${serverDirectory}$(ls $serverDirectory | sort -R | tail -1)"
current_script=$(realpath ${BASH_SOURCE[0]})

# Run script as root if it's run by another user
if [[ $EUID -ne 0 ]]; then
	echo "$(basename ${current_script}) must be run as root. Attempting to sudo..."
	sudo ${current_script}
	exit
fi

# Verify that this script can be sudoed by all users regardless of normal permissions
#	(without password)
nopasswd_sudo_enabled () {
	regex="^all[[:space:]]+all[[:space:]]*=\(root\)[[:space:]]+(.*:)*nopasswd:(.*:)*[[:space:]]+(.*)"
	# ALL	ALL=(root) 	NOPASSWD:{accept but ignore any add'l paramters} {script name}
	while read line; do
		
		[[ ${line,,} =~ $regex ]]
		if [[ ${#BASH_REMATCH[@]} > 0 ]]; then
			# Bash regex doesn't allow us to create ignored capture groups, so we need to always check
			#	the last regex group in the array
			capture=${BASH_REMATCH[-1]}
			echo $capture
			# If the captured regex matches our script source,
			#	that means this script can sudo as intended
			if [[ ${capture} == ${current_script} ]]; then
				return 1
			fi
		fi
	done < <(sudo cat /etc/sudoers)
	
	return 0
}

add_nopasswd_sudoers_entry () {
	echo "$(basename ${current_script}) is not currently set to allow all users to sudo"
	echo "Adding /etc/sudoers entry now..."
	
	config_entry="ALL	ALL=(root)	NOPASSWD:	${current_script}"
	echo $config_entry | sudo EDITOR='tee -a' visudo
	if [[ $? != 0 ]]; then
		echo "... [$(tput setaf 1)ERROR$(tput setaf 7)] Failed to update /etc/sudoers"
	else
		echo "... [$(tput setaf 2)SUCCESS$(tput setaf 7)] Updated /etc/sudoers"
		echo "... ${config_entry}"
	fi
}

# If the sudo entry isn't set up, then add it
nopasswd_sudo_enabled && add_nopasswd_sudoers_entry

echo "Connecting to random AirVPN Server [$(basename ${randomServer})]"
/usr/sbin/openvpn ${randomServer} &> /dev/null
