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

# Mitigate any kind of code injection attempted by modifying $BASH_SOURCE against a known regex
verify_bashsource_integrity () {
	
	# Matches {any number of parent directories}/{filename}[.sh]
	regex="^\/([a-z0-9\-]+\/)*[a-z0-9\-]+(\.sh)?$"
	
	# If regex fails, then we simply cut the variable completely
	[[ $current_script =~ $regex ]] || $current_script=''
}
verify_bashsource_integrity

# Ensure that file has correct read/write permissions to be executed as sudo without password
#	(file should not be modifiable by anyone other than root to avoid escalation)
verify_self_permissions () {
	self_permissions=$(stat -c %a ${current_script})
	[[ $self_permissions == 755 ]] && return 0 || return 1
}
self_permissions_invalid () {
# Executed if a problem is found with the script's permissions
	echo "[$(tput setaf 1)WARNING$(tput setaf 7)] Script permissions should be [$(tput setaf 3)755$(tput setaf 7)] actually [$(tput setaf 3)${self_permissions}$(tput setaf 7)]"
	echo "...attempting to set permissions to [$(tput setaf 3)755$(tput setaf 7)]"
	chmod 755 ${current_script} || (
		echo [$(tput setaf 1)Failed$(tput setaf 7)] chown could not be set on $(tput setaf 3)$current_script$(tput setaf 7)
		echo "...exiting ${current_script}"
		exit 1
	) && echo "...success"
}
verify_self_permissions || self_permissions_invalid

# Verify that this script can be sudoed by all users regardless of normal permissions
#	(without password)

nopasswd_sudo_enabled () {
	regex="^all[[:space:]]+all[[:space:]]*=\(root\)[[:space:]]+(.*:)*nopasswd:(.*:)*[[:space:]]+(.*)"
	# ALL	ALL=(root) 	NOPASSWD:{accept but ignore any add'l paramters} {script name}
	while read line; do
		
		if [[ ${line,,} =~ $regex ]]; then
			# If the final captured regex region matches our script source,
			#	that means this script can sudo as intended
			if [[ ${BASH_REMATCH[-1]} == ${current_script} ]]; then
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

nopasswd_sudo_enabled && add_nopasswd_sudoers_entry

# Finally, initiate a simple openvpn connection
echo "Connecting to random AirVPN Server [$(tput setaf 3)$(basename ${randomServer})$(tput setaf 7)]"
/usr/sbin/openvpn --script-security 2 --up /etc/openvpn/up.sh ${randomServer}
