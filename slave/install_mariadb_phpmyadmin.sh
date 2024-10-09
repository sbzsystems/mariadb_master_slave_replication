#!/bin/bash

# Function to generate a 12-character alphanumeric password
generate_password() {
    echo $(head /dev/urandom | tr -dc A-Za-z0-9 | head -c12)
}

# Generate database and user names with prefixes
# DB_NAME="db_$(generate_password)"
# DB_USER="user_$(generate_password)"
# DB_PASSWORD=$(generate_password)
PHPMYADMIN_PASSWORD=$(generate_password)
PHPMYADMIN_USER="phpmyadmin"

MARIADB_ROOT_PASSWORD=$(generate_password) # Root password

# Store credentials in a text file
CREDENTIALS_FILE="/root/credentials.txt"
# echo "Database Name: $DB_NAME" > $CREDENTIALS_FILE
# echo "Database User: $DB_USER" >> $CREDENTIALS_FILE
# echo "Database Password: $DB_PASSWORD" >> $CREDENTIALS_FILE
echo "phpMyAdmin User: $PHPMYADMIN_USER" >> $CREDENTIALS_FILE
echo "phpMyAdmin Password: $PHPMYADMIN_PASSWORD" >> $CREDENTIALS_FILE
echo "MariaDB Root Password: $MARIADB_ROOT_PASSWORD" >> $CREDENTIALS_FILE

# Install and configure MariaDB, Apache, and phpMyAdmin
echo "Updating system..."
sudo dnf -y update

echo "Installing MariaDB server..."
sudo dnf install -y mariadb-server

echo "Enabling and starting MariaDB service..."
sudo systemctl enable mariadb
sudo systemctl start mariadb

# Secure MariaDB installation
echo "Securing MariaDB..."
sudo mysql_secure_installation <<EOF

Y
$MARIADB_ROOT_PASSWORD
$MARIADB_ROOT_PASSWORD
Y
Y
Y
Y
EOF

# Install Apache and PHP
echo "Installing Apache and PHP..."
sudo dnf install -y httpd php php-mysqli

echo "Enabling and starting Apache service..."
sudo systemctl enable httpd
sudo systemctl start httpd

# Install phpMyAdmin
echo "Installing phpMyAdmin..."
sudo dnf install -y epel-release
sudo dnf install -y phpmyadmin

# Configure phpMyAdmin
echo "Configuring phpMyAdmin..."
sudo sed -i "s/Require local/Require all granted/g" /etc/httpd/conf.d/phpMyAdmin.conf

# Restart Apache service
sudo systemctl restart httpd

# Create phpMyAdmin user in MariaDB
mysql -uroot -p"$MARIADB_ROOT_PASSWORD" -e "CREATE USER '$PHPMYADMIN_USER'@'localhost' IDENTIFIED BY '$PHPMYADMIN_PASSWORD';"
mysql -uroot -p"$MARIADB_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON *.* TO '$PHPMYADMIN_USER'@'localhost' WITH GRANT OPTION;"

# Create dynamically generated MyISAM database and user
# echo "Creating MyISAM database and user..."
# mysql -uroot -p"$MARIADB_ROOT_PASSWORD" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"
# mysql -uroot -p"$MARIADB_ROOT_PASSWORD" -e "CREATE USER IF NOT EXISTS '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
# mysql -uroot -p"$MARIADB_ROOT_PASSWORD" -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
# mysql -uroot -p"$MARIADB_ROOT_PASSWORD" -e "ALTER DATABASE $DB_NAME DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;"
# mysql -uroot -p"$MARIADB_ROOT_PASSWORD" -e "USE $DB_NAME; CREATE TABLE test_table (id INT AUTO_INCREMENT PRIMARY KEY) ENGINE=MyISAM;"



# Set timezone
sudo timedatectl set-timezone Europe/Athens


# Restart services
echo "Restarting services..."
sudo systemctl restart mariadb
sudo systemctl restart httpd





# Get server's IP address
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "Installation complete. You can now access phpMyAdmin at http://$SERVER_IP/phpmyadmin"
echo "Database credentials are saved in $CREDENTIALS_FILE"
