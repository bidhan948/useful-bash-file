#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# This script will prompt for MySQL root credentials and new database/user info,
# then create a database and a matching user with the specified privileges.
#
# Usage:
#   chmod +x create_db_user.sh
#   ./create_db_user.sh
# ------------------------------------------------------------------------------

# 1. Prompt for MySQL “root” (or admin) login info
read -rp "MySQL root username [root]: " ROOT_USER
ROOT_USER=${ROOT_USER:-root}

read -rsp "MySQL root password (leave blank if none): " ROOT_PASS
echo

read -rp "MySQL host [localhost]: " DB_HOST
DB_HOST=${DB_HOST:-localhost}

read -rp "MySQL port [3306]: " DB_PORT
DB_PORT=${DB_PORT:-3306}

# 2. Prompt for the new database and user you want to create
read -rp "New database name: " DB_NAME
read -rp "New MySQL username: " DB_USER

read -rsp "New MySQL user password: " DB_PASS
echo

read -rp "Allow new user to connect from host [%]: " DB_USER_HOST
DB_USER_HOST=${DB_USER_HOST:-%}

# 3. Build the mysql client command (include -p only if ROOT_PASS is nonempty)
if [[ -z "$ROOT_PASS" ]]; then
  MYSQL_CMD="mysql -u${ROOT_USER} -h${DB_HOST} -P${DB_PORT}"
else
  MYSQL_CMD="mysql -u${ROOT_USER} -p${ROOT_PASS} -h${DB_HOST} -P${DB_PORT}"
fi

# 4. Run the SQL statements to create the database, user, and grant privileges
$MYSQL_CMD <<-EOSQL
  CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\`
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

  CREATE USER IF NOT EXISTS '${DB_USER}'@'${DB_USER_HOST}'
    IDENTIFIED BY '${DB_PASS}';

  GRANT ALL PRIVILEGES
    ON \`${DB_NAME}\`.* 
    TO '${DB_USER}'@'${DB_USER_HOST}';

  FLUSH PRIVILEGES;
EOSQL

echo "✅ Database '${DB_NAME}' and user '${DB_USER}'@'${DB_USER_HOST}' created successfully."
