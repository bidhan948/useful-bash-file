#!/usr/bin/env bash
# --------------------------------------------------------------------
# docker_installer.sh  – Docker Engine + Compose plugin for Pop!_OS /
#                        Ubuntu 22.04 (Jammy)   © 2025
#
# Usage:   sudo ./docker_installer.sh
# --------------------------------------------------------------------
set -euo pipefail

# 0. Require root
if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo:  sudo $0" >&2
  exit 1
fi

echo "🛑  Stopping PackageKit (prevents APT lock conflicts)…"
systemctl stop packagekit || true

echo "🔄  Removing any old Docker packages (if present)…"
apt-get remove -y docker docker-engine docker.io containerd runc || true

echo "📦  Installing prerequisites…"
apt-get update -qq
apt-get install -y \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

echo "🔑  Adding Docker’s GPG key…"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

echo "➕  Adding Docker repository…"
CODENAME="$(lsb_release -cs)"      # should be 'jammy'
echo \
"deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $CODENAME stable" \
> /etc/apt/sources.list.d/docker.list

echo "🔄  Updating package lists…"
apt-get update -qq

echo "⬇️  Installing Docker Engine, CLI, containerd & Compose plugin…"
apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

echo "🔧  Enabling & starting docker service…"
systemctl enable --now docker

# Add invoking user to docker group for root-less usage
if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
  echo "👤  Adding ${SUDO_USER} to docker group…"
  usermod -aG docker "${SUDO_USER}"
  NEED_RELOGIN=true
fi

echo "🔄  Restarting PackageKit…"
systemctl start packagekit || true

echo
echo "✅  Docker installation complete!"
docker --version
docker compose version

if [[ "${NEED_RELOGIN:-false}" == true ]]; then
  echo "ℹ️  Log out & back in (or run 'newgrp docker') for group changes to take effect."
fi
echo "🚀  Test it:  docker run --rm hello-world"
