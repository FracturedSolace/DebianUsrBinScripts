#!/bin/bash
# Quickly change the address to which transmission is bound

if [[ $1 == "" ]]; then
	echo "Usage: $(basename ${BASH_SOURCE[0]}) <address>"
	exit
fi

if [[ $EUID != 0 ]]; then
	echo "This script should be run as root..."
	sudo ${BASH_SOURCE[0]} $1
	exit
fi


new_ip=$1


# Shutdown transmission if it's running and remember to turn it back on
shutdown_daemon=false
if systemctl status transmission-daemon &> /dev/null; then
	shutdown_daemon=true
	echo "Stopping transmission-daemon.service before updating config..."
	systemctl stop transmission-daemon
fi

# Config entry takes this format:
# 	"bind-address-ipv4": "x.x.x.x"
sed -i -e "/\"bind-address-ipv4\": / s/: .*/: \"${new_ip}\",/" /var/lib/transmission-daemon/.config/transmission-daemon/settings.json

# Restart transmission if we turned it off
if [[ $shutdown_daemon == true ]]; then
	echo "Restarting transmission-daemon.service..."
	systemctl restart transmission-daemon
fi
