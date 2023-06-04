#!/bin/bash

# Backup Cristi's Samba folder
rclone copy --update --verbose --transfers 30 --checkers 8 --contimeout 60s --timeout 300s --retries 3 --low-level-retries 10 --stats 1s /mnt/samba/cristi/ "Rob Backup:CristiNetworkBackup"
# Backup the KeePass folder
rclone copy --update --verbose --transfers 30 --checkers 8 --contimeout 60s --timeout 300s --retries 3 --low-level-retries 10 --stats 1s /mnt/samba/keepass/ "Rob Backup:KeePass"

# Alert for success / failure
if [[ $? -ne 0 ]]; then
	/usr/local/bin/send-text "$(date) WARNING: CristiBackup.sh backup failed!"
	echo "[ERROR] Backup to Google Drive (CristiBackup.sh) failed"
else
	/usr/local/bin/send-text "$(date) Successfully backed up Cristis files"
	echo "Backup successfully completed"
fi
	
