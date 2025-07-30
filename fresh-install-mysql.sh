#!/usr/bin/env bash
set -euo pipefail

# This script completely removes any existing MySQL installation
# and performs a fresh install on Ubuntu/Pop!_OS.

# 1. Stop MySQL service if running
echo "Stopping MySQL service..."
sudo systemctl stop mysql.service || true

# 2. Purge MySQL packages and related dependencies
echo "Purging MySQL packages..."
sudo apt-get remove --purge -y \
    mysql-server mysql-client mysql-common mysql-server-core-* mysql-client-core-*
sudo apt-get autoremove -y
sudo apt-get autoclean

# 3. Remove MySQL directories and AppArmor profile
echo "Removing MySQL data and config directories..."
sudo rm -rf /etc/mysql /var/lib/mysql /var/log/mysql
sudo rm -f /etc/apparmor.d/usr.sbin.mysqld
sudo systemctl reload apparmor || true

# 4. Update package lists
echo "Updating package lists..."
sudo apt update

# 5. Install MySQL server
echo "Installing MySQL server..."
DEBIAN_FRONTEND=noninteractive sudo apt install -y mysql-server

# 6. Secure installation and optionally set root password
# You can set the root password by exporting MYSQL_ROOT_PASSWORD before running this script.
if [ -n "${MYSQL_ROOT_PASSWORD-}" ]; then
  echo "Configuring root user password..."
  sudo mysql <<-SQL
    ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${MYSQL_ROOT_PASSWORD}';
    DELETE FROM mysql.user WHERE User='';
    DROP DATABASE IF EXISTS test;
    DELETE FROM mysql.db WHERE Db='test' OR Db LIKE 'test\_%';
    FLUSH PRIVILEGES;
  SQL
else
  echo "No MYSQL_ROOT_PASSWORD provided; default socket authentication remains."
fi

# 7. Final status
echo "MySQL fresh install complete."
systemctl status mysql.service --no-pager
