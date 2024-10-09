#!/bin/bash

# Variables
MASTER_DB="db_name"
BACKUP_FILE="/root/backup.sql"
SLAVE_USER="root"
SLAVE_IP="10.0.0.3"
SLAVE_DEST_PATH="/root/backup.sql"
MYSQL_ROOT_PASSWORD="XXXXXXXXXX"
SSH_PORT=22  # Change if using a custom SSH port

# Backup the database using mysqldump
echo "Backing up the database..."
# mysqldump -u root -p --databases $MASTER_DB --master-data=2 > $BACKUP_FILE
# mysqldump -u root -p$MYSQL_ROOT_PASSWORD $MASTER_DB | gzip > $BACKUP_FILE
# --hex-blob
mysqldump -uroot -p$MYSQL_ROOT_PASSWORD $MASTER_DB --default-character-set=utf8 > $BACKUP_FILE


# Transfer the backup to the slave server via SCP
echo "Transferring the backup to the slave server via SCP..."
scp -P $SSH_PORT $BACKUP_FILE $SLAVE_USER@$SLAVE_IP:$SLAVE_DEST_PATH

# Clean up the backup file on the master server (optional)
echo "Cleaning up the backup file on the master server..."
rm $BACKUP_FILE

echo "Backup and transfer complete."


# mysql -u root -p sbzgr_api < /root/backup.sql.gz

