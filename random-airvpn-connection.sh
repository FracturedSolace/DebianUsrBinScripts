#!/bin/bash
serverDirectory="/etc/openvpn/server/"
randomServer="${serverDirectory}$(ls $serverDirectory | sort -R | tail -1)"

# Run script as root if it's run by another user
if [[ $EUID -ne 0 ]]; then
	echo "${BASH_SOURCE[0]} must be run as root. Attempting to sudo..."
	sudo ${BASH_SOURCE[0]}
	exit
fi

echo "Connecting to random AirVPN Server [${randomServer}]"
/usr/sbin/openvpn ${randomServer}
