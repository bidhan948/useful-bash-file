#!/bin/bash

DB_NAME="perfect"
DB_USER="gotest"
DB_PASS="gotest"

# Create the database
sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"

# Create the user (if not exists)
sudo -u postgres psql -tc "SELECT 1 FROM pg_roles WHERE rolname='$DB_USER'" | grep -q 1 || \
  sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"

# Grant privileges
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"

echo "✅ Database '$DB_NAME' and user '$DB_USER' created and ready."
