#!/bin/bash

UPSTREAM_NAME="Google-rdibble219"

# Backup Cristi's Samba folder
rclone copy --update --verbose --transfers 30 --checkers 8 --contimeout 60s --timeout 300s --retries 3 --low-level-retries 10 --stats 1s /mnt/samba/cristi/ "${UPSTREAM_NAME}:CristiNetworkBackup"
# Backup the KeePass folder
rclone copy --update --verbose --transfers 30 --checkers 8 --contimeout 5s --timeout 5s --retries 3 --low-level-retries 10 --stats 1s /mnt/samba/keepass/ "${UPSTREAM_NAME}:KeePass"

# Alert for success / failure
if [[ $? -ne 0 ]]; then
	/usr/local/bin/send-text "$(date) WARNING: googlebackup.sh backup failed!"
	echo "[ERROR] Backup to Google Drive (googlebackup.sh) failed"
	exit 1
else
	/usr/local/bin/send-text "$(date) googlebackup.sh successful"
	echo "Backup successfully completed"
fi
	
