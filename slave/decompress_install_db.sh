#!/bin/bash

# Variables (update these with your details)
MYSQL_ROOT_PASS="your_mysql_root_password"  # Set your MySQL root password here
DB_USER="user_$(openssl rand -hex 6)"
DB_PASS="$(openssl rand -base64 12)"
DB_NAME="db_name"
IM_SQL_FILE="db_name.sql"
FILE_NAME="user.admin.db.tar.zst"
CREDENTIALS_FILE="db_credentials.txt"

# Check if zstd and mysql are installed
if ! command -v zstd &> /dev/null
then
    echo "zstd could not be found. Install it using 'sudo apt install zstd' and try again."
    exit 1
fi

if ! command -v mysql &> /dev/null
then
    echo "mysql could not be found. Please install MySQL and try again."
    exit 1
fi

# Decompress the .zst file
echo "Decompressing $FILE_NAME..."
zstd -d $FILE_NAME

# Extract the .tar file
TAR_FILE="${FILE_NAME%.zst}"
echo "Extracting $TAR_FILE..."
tar -xvf $TAR_FILE

# Find the $IM_SQL_FILE file
SQL_FILE=$(find . -type f -name "$IM_SQL_FILE")
if [ -z "$SQL_FILE" ]; then
    echo "$IM_SQL_FILE file not found in the extracted archive."
    exit 1
fi

# Create the MySQL database
echo "Creating database $DB_NAME..."
mysql -u root -p"$MYSQL_ROOT_PASS" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"

# Create MySQL user and grant privileges
echo "Creating MySQL user $DB_USER..."
mysql -u root -p"$MYSQL_ROOT_PASS" -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -u root -p"$MYSQL_ROOT_PASS" -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
mysql -u root -p"$MYSQL_ROOT_PASS" -e "FLUSH PRIVILEGES;"

# Import the $IM_SQL_FILE file as root
echo "Importing $SQL_FILE into $DB_NAME using root privileges..."
mysql -u root -p"$MYSQL_ROOT_PASS" $DB_NAME < $SQL_FILE

# Check if the import was successful
if [ $? -eq 0 ]; then
    echo "Database import completed successfully."

    # Store the credentials in the file
    echo "Storing credentials in $CREDENTIALS_FILE..."
    echo "Database Name: $DB_NAME" > $CREDENTIALS_FILE
    echo "Username: $DB_USER" >> $CREDENTIALS_FILE
    echo "Password: $DB_PASS" >> $CREDENTIALS_FILE
else
    echo "Database import failed."
    exit 1
fi
