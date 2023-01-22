#!/bin/bash
# watch-for-torrents.sh
# Watches a specified directory for new .torrent files and passes them to transmission when they arrive
INCOMING_DIR="/mnt/samba/start-torrent/"
OUTPUT_DIR="/mnt/samba/torrent-processed/"

inotifywait -m -e create -e moved_to --format "%w%f" $INCOMING_DIR \
	| while read FILENAME; do
		echo "New torrent file received [$(tput setaf 3)${FILENAME}$(tput setaf 7)]"
		start-torrent "${FILENAME}"
		mv "${FILENAME}" "${OUTPUT_DIR}"
	done
	
