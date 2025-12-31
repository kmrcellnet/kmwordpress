#!/bin/bash

set -e

echo "=== INSTALL GENIACS + DATABASE ==="

# ===============================
# Update system
# ===============================
apt update && apt upgrade -y
apt install -y curl gnupg unzip git sudo

# ===============================
# Install MongoDB (WAJIB)
# ===============================
echo "=== Install MongoDB ==="
apt install -y mongodb
systemctl enable mongodb
systemctl start mongodb

# ===============================
# Install MariaDB (Opsional)
# ===============================
echo "=== Install MariaDB ==="
apt install -y mariadb-server mariadb-client
systemctl enable mariadb
systemctl start mariadb

# ===============================
# Setup MariaDB database
# ===============================
DB_NAME="geniacs"
DB_USER="geniacs"
DB_PASS="geniacs123"

mysql <<EOF
CREATE DATABASE IF NOT EXISTS ${DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

# ===============================
# Install Node.js LTS
# ===============================
echo "=== Install Node.js ==="
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt install -y nodejs

# ===============================
# Install GeniACS
# ===============================
echo "=== Install GeniACS ==="
npm install -g genieacs@latest

# ===============================
# Create genieacs user
# ===============================
useradd --system --no-create-home --shell /bin/false genieacs || true

mkdir -p /opt/genieacs
chown genieacs:genieacs /opt/genieacs

# ===============================
# Create config file
# ===============================
cat <<EOF >/opt/genieacs/genieacs.env
GENIEACS_CWMP_INTERFACE=0.0.0.0
GENIEACS_NBI_INTERFACE=0.0.0.0
GENIEACS_FS_INTERFACE=0.0.0.0
GENIEACS_UI_INTERFACE=0.0.0.0

GENIEACS_MONGODB_CONNECTION_URL=mongodb://localhost:27017/genieacs
EOF

chown genieacs:genieacs /opt/genieacs/genieacs.env

# ===============================
# Create systemd services
# ===============================
for svc in cwmp nbi fs ui; do
cat <<EOF >/etc/systemd/system/genieacs-$svc.service
[Unit]
Description=GenieACS $svc
After=network.target mongodb.service

[Service]
User=genieacs
Group=genieacs
EnvironmentFile=/opt/genieacs/genieacs.env
ExecStart=/usr/bin/genieacs-$svc
Restart=always
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
done

# ===============================
# Enable services
# ===============================
systemctl daemon-reexec
systemctl daemon-reload

systemctl enable genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui
systemctl start genieacs-cwmp genieacs-nbi genieacs-fs genieacs-ui

echo "================================="
echo " INSTALL SELESAI "
echo "================================="
echo "Web UI : http://IP-SERVER:3000"
echo "Login  : admin / admin"
echo ""
echo "MariaDB:"
echo " DB     : $DB_NAME"
echo " User   : $DB_USER"
echo " Pass   : $DB_PASS"
