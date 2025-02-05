#!/bin/bash

# Pastikan skrip dijalankan sebagai root
if [ "$EUID" -ne 0 ]; then
  echo "Silakan jalankan sebagai root (sudo bash install_webserver_wordpress.sh)"
  exit 1
fi

# Update dan upgrade sistem
echo "Updating system..."
apt update && apt upgrade -y

# Install OpenSSH Server
echo "Installing OpenSSH Server..."
apt install -y openssh-server
systemctl enable --now ssh

# Install Apache2
echo "Installing Apache2..."
apt install -y apache2
systemctl enable --now apache2

# Install MariaDB Server
echo "Installing MariaDB..."
apt install -y mariadb-server
systemctl enable --now mariadb

# Mengamankan MariaDB
echo "Securing MariaDB..."
mysql_secure_installation <<EOF

y
n
y
y
y
y
EOF

# Membuat database WordPress
echo "Creating WordPress database..."
DB_NAME="wordpress"
DB_USER="wp_user"
DB_PASS="WpPass123!"

mysql -uroot -e "CREATE DATABASE $DB_NAME;"
mysql -uroot -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mysql -uroot -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
mysql -uroot -e "FLUSH PRIVILEGES;"

# Install PHP dan ekstensi yang diperlukan
echo "Installing PHP and required extensions..."
apt install -y php libapache2-mod-php php-mysql php-mbstring php-zip php-gd php-json php-curl php-xml php-bcmath

# Install PHPMyAdmin
echo "Installing PHPMyAdmin..."
apt install -y phpmyadmin

# Konfigurasi Apache untuk PHPMyAdmin
echo "Configuring Apache for PHPMyAdmin..."
ln -s /usr/share/phpmyadmin /var/www/html/phpmyadmin
systemctl restart apache2

# Install WordPress
echo "Downloading WordPress..."
cd /var/www/html
wget https://wordpress.org/latest.tar.gz
tar -xvzf latest.tar.gz
rm latest.tar.gz

# Mengatur izin direktori WordPress ke 777
echo "Setting permissions for WordPress..."
chown -R www-data:www-data wordpress
chmod -R 777 wordpress

# Konfigurasi Apache untuk WordPress
echo "Configuring Apache for WordPress..."
cat > /etc/apache2/sites-available/wordpress.conf <<EOF
<VirtualHost *:80>
    ServerAdmin admin@yourdomain.com
    DocumentRoot /var/www/html/wordpress
    ServerName yourdomain.com
    ServerAlias www.yourdomain.com

    <Directory /var/www/html/wordpress>
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
EOF

# Mengaktifkan konfigurasi dan modul Apache yang diperlukan
a2ensite wordpress
a2enmod rewrite
systemctl restart apache2

# Menampilkan informasi akhir
echo "Installation completed successfully!"
echo "------------------------------------------------------"
echo "✅ Apache2 is running on: http://$(hostname -I | awk '{print $1}')/"
echo "✅ PHPMyAdmin is available at: http://$(hostname -I | awk '{print $1}')/phpmyadmin"
echo "✅ WordPress is available at: http://$(hostname -I | awk '{print $1}')/wordpress"
echo "------------------------------------------------------"
echo "📌 Database WordPress:"
echo " - Database: $DB_NAME"
echo " - User: $DB_USER"
echo " - Password: $DB_PASS"
echo "------------------------------------------------------"
echo "✅ Script by @nkmrx_18"
