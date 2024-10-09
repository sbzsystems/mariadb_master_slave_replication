To allow access to MariaDB from another server over the network, you'll need to configure both the MariaDB server and the firewall settings to permit remote connections.

Modify a User with Remote Access Privileges.    
RENAME USER 'user_247402981cb1'@'localhost' TO 'user_247402981cb1'@'10.0.0.2';

If you want to delete an unused user:
DROP USER 'user_247402981cb1'@'10.0.0.3';
