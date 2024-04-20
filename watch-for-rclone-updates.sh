#!/bin/bash
# watch-for-torrents.sh
# Watches a specified directory for new rclone config and pushes it to the correct directory when it comes in 
INCOMING_DIR="/mnt/samba/update-rclone/"
OUTPUT_DIR="/home/fracturedsolace/.config/rclone/rclone.conf"
OUTPUT_DIR_2="/root/.config/rclone/rclone.conf"

# rm "${INCOMING_DIR}/*"

inotifywait -m -e create -e moved_to --format "%w%f" $INCOMING_DIR \
	| while read FILENAME; do
		echo "$(date): New rclone config file received"
		cp "${FILENAME}" "${OUTPUT_DIR}"
		if [[ $? -ne 0 ]]; then
			echo "[ERROR] Could not copy new rclone config to user"
		else
			echo "Successfully copied rclone config to user"
		fi
		cp "${FILENAME}" "${OUTPUT_DIR_2}"
		if [[ $? -ne 0 ]]; then
			echo "[ERROR] Could not copy new rclone config to root"
		else
			echo "Successfully copied rclone config to root"
		fi
		rm "${FILENAME}"
	done
	
