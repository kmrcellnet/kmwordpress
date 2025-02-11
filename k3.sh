#!/bin/bash

# Define color for yellow
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Update and install required packages
echo -e "${YELLOW}Updating system and installing required packages...${NC}"
apt update -y
apt install -y openssh-sftp-server apache2 php mariadb-server phpmyadmin wget unzip expect

# Configure phpMyAdmin with Apache
echo -e "${YELLOW}Configuring phpMyAdmin for Apache...${NC}"
ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
systemctl restart apache2

# Download WordPress
echo -e "${YELLOW}Downloading WordPress...${NC}"
wget http://172.16.90.2/unduh/wordpress.zip -P /var/www/html/

# Navigate to the web directory
cd /var/www/html/

# Unzip the WordPress file
echo -e "${YELLOW}Unzipping WordPress...${NC}"
unzip wordpress.zip

# Set permissions for the WordPress directory
echo -e "${YELLOW}Setting permissions for the WordPress directory...${NC}"
chmod -R 755 wordpress

# Prompt user for MySQL database and user details
echo -e "${YELLOW}Enter the database name for WordPress:${NC}"
read DB_NAME

echo -e "${YELLOW}Enter the MySQL root password:${NC}"
read -s ROOT_PASS

echo -e "${YELLOW}Enter the database username for WordPress:${NC}"
read DB_USER

echo -e "${YELLOW}Enter the database password for the WordPress user:${NC}"
read -s DB_PASS

# Secure MySQL installation using expect
echo -e "${YELLOW}Securing MySQL installation...${NC}"

expect <<EOF
spawn mysql_secure_installation

# Automate responses to secure installation prompts
expect "Enter current password for root (enter for none):"
send "$ROOT_PASS\r"

expect "Set root password? [Y/n]"
send "Y\r"

expect "New password:"
send "$ROOT_PASS\r"

expect "Re-enter new password:"
send "$ROOT_PASS\r"

expect "Remove anonymous users? [Y/n]"
send "Y\r"

expect "Disallow root login remotely? [Y/n]"
send "Y\r"

expect "Remove test database and access to it? [Y/n]"
send "Y\r"

expect "Reload privilege tables now? [Y/n]"
send "Y\r"

expect eof
EOF

# Log in to MySQL and create the database and user
echo -e "${YELLOW}Creating MySQL database and user...${NC}"

mysql -u root -p"$ROOT_PASS" <<MYSQL_SCRIPT
CREATE DATABASE $DB_NAME;
CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';
GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# Create wp-config.php file with dynamic database details
echo -e "${YELLOW}Creating wp-config.php file...${NC}"

cat <<EOL > /var/www/html/wordpress/wp-config.php
<?php
/**
 * The base configuration for WordPress
 *
 * The wp-config.php creation script uses this file during the installation.
 * You don't have to use the web site, you can copy this file to "wp-config.php" and fill in the values.
 *
 * @link https://codex.wordpress.org/Editing_wp-config.php
 *
 * @package WordPress
 */

// ** MySQL settings - You can get these from your web host ** //
define( 'DB_NAME', '$DB_NAME' );
define( 'DB_USER', '$DB_USER' );
define( 'DB_PASSWORD', '$DB_PASS' );
define( 'DB_HOST', 'localhost' );

// ** Authentication Unique Keys and Salts.** You can generate these using the WordPress secret key service.
define( 'AUTH_KEY',         '$(openssl rand -base64 32)' );
define( 'SECURE_AUTH_KEY',  '$(openssl rand -base64 32)' );
define( 'LOGGED_IN_KEY',    '$(openssl rand -base64 32)' );
define( 'NONCE_KEY',        '$(openssl rand -base64 32)' );
define( 'AUTH_SALT',        '$(openssl rand -base64 32)' );
define( 'SECURE_AUTH_SALT', '$(openssl rand -base64 32)' );
define( 'LOGGED_IN_SALT',   '$(openssl rand -base64 32)' );
define( 'NONCE_SALT',       '$(openssl rand -base64 32)' );

// ** Database Table prefix. You can change this if you want to run multiple WordPress installations in a single database.**
$table_prefix = 'wp_';

// ** For developers: WordPress debugging mode.**
define( 'WP_DEBUG', false );

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( !defined('ABSPATH') )
	define('ABSPATH', __DIR__ . '/');

/** Sets up WordPress vars and included files. */
require_once(ABSPATH . 'wp-settings.php');
EOL

# Start Apache and MariaDB services
echo -e "${YELLOW}Starting Apache and MariaDB services...${NC}"
systemctl start apache2
systemctl start mariadb

# Enable services to start on boot
echo -e "${YELLOW}Enabling Apache and MariaDB services on boot...${NC}"
systemctl enable apache2
systemctl enable mariadb

# Output the status of services
echo -e "${YELLOW}Checking status of Apache and MariaDB...${NC}"
systemctl status apache2
systemctl status mariadb

echo -e "${YELLOW}Installation complete. You can now access:${NC}"
echo -e "${YELLOW}1. WordPress: http://<your-server-ip>/wordpress${NC}"
echo -e "${YELLOW}2. phpMyAdmin: http://<your-server-ip>/phpmyadmin${NC}"
echo -e "${YELLOW}Remember to log in to phpMyAdmin with MySQL root or WordPress user credentials.${NC}"

echo -e "${YELLOW}Script execution completed!${NC}"
echo -e "${YELLOW}Script by @nkmrx_18${NC}"
