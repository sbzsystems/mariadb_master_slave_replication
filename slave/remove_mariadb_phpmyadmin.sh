#!/bin/bash

# Define file paths and credentials file
CREDENTIALS_FILE="/root/credentials.txt"

# Stop services
echo "Stopping MariaDB and Apache services..."
sudo systemctl stop mariadb
sudo systemctl stop httpd

# Remove MariaDB and its related packages
echo "Removing MariaDB and related packages..."
sudo dnf remove -y mariadb-server mariadb
sudo rm -rf /var/lib/mysql /etc/my.cnf /var/log/mysql /etc/my.cnf.d /etc/my.cnf.backup

# Remove Apache and PHP
echo "Removing Apache and PHP..."
sudo dnf remove -y httpd php php-mysqli
sudo rm -rf /var/www/html /etc/httpd

# Remove phpMyAdmin
echo "Removing phpMyAdmin..."
sudo dnf remove -y phpmyadmin
sudo rm -rf /etc/phpMyAdmin /usr/share/phpmyadmin

# Remove generated databases and users
if [ -f "$CREDENTIALS_FILE" ]; then
    # Extract database and user information from the credentials file
    DB_NAME=$(grep "Database Name" "$CREDENTIALS_FILE" | awk '{print $3}')
    DB_USER=$(grep "Database User" "$CREDENTIALS_FILE" | awk '{print $3}')
    MARIADB_ROOT_PASSWORD=$(grep "MariaDB Root Password" "$CREDENTIALS_FILE" | awk '{print $4}')
    
    echo "Removing database and user..."

    # Remove the database and user from MariaDB
    if [ -n "$MARIADB_ROOT_PASSWORD" ]; then
        mysql -uroot -p"$MARIADB_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS $DB_NAME;"
        mysql -uroot -p"$MARIADB_ROOT_PASSWORD" -e "DROP USER IF EXISTS '$DB_USER'@'localhost';"
        mysql -uroot -p"$MARIADB_ROOT_PASSWORD" -e "DROP USER IF EXISTS 'phpmyadmin'@'localhost';"
    else
        echo "Root password not found in $CREDENTIALS_FILE."
    fi
else
    echo "Credentials file not found. Skipping user and database removal."
fi

# Remove credentials file
echo "Removing credentials file..."
sudo rm -f "$CREDENTIALS_FILE"

# Disable and remove services
echo "Disabling MariaDB and Apache services..."
sudo systemctl disable mariadb
sudo systemctl disable httpd

# Clean any remaining configurations and dependencies
echo "Cleaning up remaining configurations and dependencies..."
sudo dnf autoremove -y

echo "All components removed successfully."
