#!/bin/bash

# Function to generate a random alphanumeric password (12 characters)
generate_password() {
    tr -dc 'A-Za-z0-9' </dev/urandom | head -c 12
}

# Variables
REPLICATION_USER="replicator"
REPLICATION_PASSWORD=$(generate_password)  # Generate a random 12-character alphanumeric password
MYSQL_ROOT_PASSWORD="L6hxyfzO2QN"
CREDENTIALS_FILE="replication_credentials.txt"  # File to store credentials and master status
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

# 1. Enable binary logging in MariaDB
echo "Enabling binary logging on the master..."

# Configure necessary parameters in my.cnf under [mysqld]
add_config_under_mysqld "bind-address" "0.0.0.0"
add_config_under_mysqld "log-bin" "mysql-bin"
add_config_under_mysqld "server-id" "1"
# add_config_under_mysqld "binlog-format" "ROW"

# Restart MariaDB to apply changes
echo "Restarting MariaDB service..."
sudo systemctl restart mysqld

# 2. Create a replication user with the generated password
echo "Creating replication user '$REPLICATION_USER' with a random password..."
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "DROP USER IF EXISTS '$REPLICATION_USER'@'%';"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "CREATE USER '$REPLICATION_USER'@'%' IDENTIFIED BY '$REPLICATION_PASSWORD';"
mysql -u root -p$MYSQL_ROOT_PASSWORD -e "GRANT REPLICATION SLAVE ON *.* TO '$REPLICATION_USER'@'%'; FLUSH PRIVILEGES;"

# 3. Get master status and save binary log file and position
MASTER_STATUS=$(mysql -u root -p$MYSQL_ROOT_PASSWORD -e "SHOW MASTER STATUS\G")
BINLOG_FILE=$(echo "$MASTER_STATUS" | grep File: | awk '{print $2}')
BINLOG_POS=$(echo "$MASTER_STATUS" | grep Position: | awk '{print $2}')

# Display the binary log file and position for reference
echo "Binary Log File: $BINLOG_FILE"
echo "Binary Log Position: $BINLOG_POS"

# 4. Store credentials and master status in a text file
echo "Saving replication credentials and master status to '$CREDENTIALS_FILE'..."
echo "REPLICATION_USER=$REPLICATION_USER" > $CREDENTIALS_FILE
echo "REPLICATION_PASSWORD=$REPLICATION_PASSWORD" >> $CREDENTIALS_FILE
echo "BINLOG_FILE=$BINLOG_FILE" >> $CREDENTIALS_FILE
echo "BINLOG_POS=$BINLOG_POS" >> $CREDENTIALS_FILE

echo "Master setup complete. Use the '$CREDENTIALS_FILE' file in the slave setup."
