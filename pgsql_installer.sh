#!/usr/bin/env bash
# pgsql_installer.sh – PostgreSQL 16 for Pop!_OS 22.04 / Ubuntu 22.04
# Usage:
#   sudo ./pgsql_installer.sh          # install server + client
#   sudo ./pgsql_installer.sh --client # client-only
set -euo pipefail

# 0. Require sudo
[[ $EUID -eq 0 ]] || { echo "Run with sudo: sudo $0 [--client]"; exit 1; }

CLIENT_ONLY=false
[[ ${1:-} == "--client" ]] && CLIENT_ONLY=true

echo "🛑  Stopping PackageKit to free the APT lock..."
systemctl stop packagekit || true

echo "📦  Installing prerequisites..."
apt-get update -qq
apt-get install -y wget gnupg lsb-release >/dev/null

echo "🔑  Adding PostgreSQL GPG key..."
wget -qO- https://www.postgresql.org/media/keys/ACCC4CF8.asc \
  | gpg --dearmor -o /usr/share/keyrings/postgresql.gpg

# Determine codename (should be jammy)
CODENAME="$(lsb_release -cs)"

echo "➕  Adding PGDG repository for PostgreSQL 16..."
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/postgresql.gpg] \
http://apt.postgresql.org/pub/repos/apt ${CODENAME}-pgdg main" \
  > /etc/apt/sources.list.d/pgdg.list

echo "🔄  Updating package lists..."
apt-get update -qq

if $CLIENT_ONLY; then
  echo "⬇️  Installing client (psql)..."
  apt-get install -y postgresql-client-16
  echo "✅  PostgreSQL client installed – version: $(psql --version)"
else
  echo "⬇️  Installing PostgreSQL 16 server + client..."
  apt-get install -y postgresql-16

  echo "🔧  Enabling & starting postgres service..."
  systemctl enable --now postgresql

  # Initial superuser password prompt
  echo "👤  Setting password for postgres superuser..."
  sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'postgres';"

  echo -e "\n🎉  PostgreSQL server is running."
  echo "   ➜ Host:  localhost"
  echo "   ➜ Port:  5432"
  echo "   ➜ User:  postgres"
  echo "   ➜ Password:  postgres  (change in DBeaver after first login)"
  echo -e "\nOpen DBeaver → New Connection → PostgreSQL → fill the above details."
fi

echo "🔄  Restarting PackageKit..."
systemctl start packagekit || true
