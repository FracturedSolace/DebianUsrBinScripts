#!/bin/bash
# Returns the local interface of the tun0 interface

regex="inet ([[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3}\.[[:digit:]]{1,3})"
[[ $(ip addr | grep tun0) =~ $regex ]]
vpn_interface_address=${BASH_REMATCH[1]}

if [[ $vpn_interface_address == "" ]]; then
	echo "[$(tput setaf 1)ERROR$(tput setaf 7)] VPN is not connected"
	exit 1
else
	echo $vpn_interface_address
fi
