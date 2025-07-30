#!/usr/bin/env bash
# VS Code installer for Pop!_OS 22.04 / Ubuntu 22.04
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo:  sudo $0" >&2; exit 1; fi

echo "🛑  Stopping PackageKit…";  systemctl stop packagekit || true

echo "📦  Installing wget & gpg…"; apt-get update -qq
apt-get install -y wget gpg >/dev/null

echo "🔑  Adding Microsoft GPG key…"
wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
 | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg

echo "➕  Adding VS Code repo…"
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
 > /etc/apt/sources.list.d/vscode.list

echo "🔄  Updating package lists…"; apt-get update -qq
echo "⬇️  Installing code…";      apt-get install -y code

echo "🔄  Restarting PackageKit…"; systemctl start packagekit || true
echo "✅  Visual Studio Code installed!  Type 'code' to launch."
