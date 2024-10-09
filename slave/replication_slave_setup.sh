#!/bin/bash

# Variables - Set these values accordingly
MASTER_HOST="10.0.0.2"                    # Replace with the IP of the master
MYSQL_ROOT_PASSWORD="zv5v8Ds4q8oN"
REPLICATION_USER="replicator"    # Replication user
REPLICATION_PASSWORD="X8Zn5tkDlNi6"    # Replication user's password
BINLOG_FILE="mysql-bin.000001"           # Master Binary Log File
BINLOG_POS=923                               # Master Log Position
REPLICATION_DB="sbzgr_api"    # Replication DB
MY_CNF="/etc/my.cnf"

# Function to add a configuration entry under the [mysqld] section if it doesn't already exist
add_config_under_mysqld() {
    local parameter="$1"
    local value="$2"

    # Check if the [mysqld] section exists
    if ! grep -q "^\[mysqld\]" $MY_CNF; then
        echo "Adding [mysqld] section to $MY_CNF"
        sudo bash -c 'echo "[mysqld]" >> /etc/my.cnf'
    fi

    # Check if the parameter already exists under [mysqld]
    if ! grep -A 10 "^\[mysqld\]" $MY_CNF | grep -q "^$parameter"; then
        echo "Adding $parameter=$value under [mysqld] section in $MY_CNF"
        sudo sed -i "/^\[mysqld\]/a $parameter=$value" $MY_CNF
    else
        echo "$parameter already exists under [mysqld] in $MY_CNF. Skipping."
    fi
}

# 1. Configure the slave's unique server ID and other settings in my.cnf
echo "Configuring server-id and replication settings for the slave..."
add_config_under_mysqld "server-id" "2"
add_config_under_mysqld "log_bin" "mysql-bin"
add_config_under_mysqld "binlog_do_db" "$REPLICATION_DB"
add_config_under_mysqld "bind-address" "0.0.0.0"

# Restart MariaDB to apply changes
echo "Restarting MariaDB service..."
sudo systemctl restart mariadb

# 2. Set up replication on the slave
echo "Configuring slave to connect to master ($MASTER_HOST)..."
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "CHANGE MASTER TO MASTER_HOST='$MASTER_HOST', MASTER_USER='$REPLICATION_USER', MASTER_PASSWORD='$REPLICATION_PASSWORD', MASTER_LOG_FILE='$BINLOG_FILE', MASTER_LOG_POS=$BINLOG_POS;"


# 3. Start slave replication
echo "Starting replication on the slave..."
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "START SLAVE;"

# 4. Check the status of the slave
echo "Checking the replication status..."
mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SHOW SLAVE STATUS\G"

echo "Slave setup complete."
