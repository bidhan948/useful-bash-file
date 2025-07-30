#!/usr/bin/env bash
# ----------------------------------------------------------------------
# git_installer.sh – Install Git on Pop!_OS 22.04 / Ubuntu 22.04
# Usage:
#   sudo ./git_installer.sh        # distro version (stable + security-patched)
#   sudo ./git_installer.sh --latest   # latest stable from ppa:git-core/ppa
# ----------------------------------------------------------------------
set -euo pipefail

### 0. Root check ----------------------------------------------------------
if [[ $EUID -ne 0 ]]; then
  echo "Please run with sudo:" >&2
  echo "  sudo $0 [--latest]" >&2
  exit 1
fi

### 1. Parse flag ----------------------------------------------------------
INSTALL_LATEST=false
if [[ $# -gt 0 && $1 == "--latest" ]]; then
  INSTALL_LATEST=true
fi

### 2. Ensure PackageKit isn’t holding the APT lock ------------------------
echo "🛑  Stopping PackageKit to avoid APT lock conflicts…"
systemctl stop packagekit || true

### 3. Update package lists ------------------------------------------------
echo "🔄  Updating package lists…"
apt-get update -qq

### 4. Optional: add the git-core PPA -------------------------------------
if $INSTALL_LATEST; then
  echo "➕  Adding git-core PPA for the latest Git…"
  apt-get install -y software-properties-common >/dev/null
  add-apt-repository -y ppa:git-core/ppa
  apt-get update -qq
fi

### 5. Install or upgrade Git ---------------------------------------------
echo "⬇️  Installing Git…"
apt-get install -y git

### 6. Restart PackageKit (optional) ---------------------------------------
echo "🔄  Restarting PackageKit…"
systemctl start packagekit || true

echo "✅  Git installation complete – version: $(git --version)"
echo "👉  Don’t forget to configure your identity:"
echo "    git config --global user.name  \"Bidhan Baniya\""
echo "    git config --global user.email \"bidhanbaniya789@gmail.com\""
