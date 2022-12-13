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
echo "Connecting to random AirVPN Server [$(basename ${randomServer})]"
/usr/sbin/openvpn ${randomServer} &> /dev/null
