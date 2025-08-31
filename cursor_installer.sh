#!/bin/bash
#
# 🎨 Cursor Theme Installer for Pop!_OS
# 👨‍💻 Author: Bidhan
# 🔗 GitHub: https://github.com/bidhan948
# 📌 Description:
#   Automatically downloads, installs, and sets the Bibata Modern Ice
#   cursor theme system-wide on Pop!_OS (GNOME).
#

set -euo pipefail

THEME_NAME="Bibata-Modern-Ice"
# Official mirror (v2.0.5) – .tar.xz archive
THEME_URL="https://sourceforge.net/projects/bibata-cursor.mirror/files/v2.0.5/Bibata-Modern-Ice.tar.xz/download"

echo "🎯 Installing cursor theme: $THEME_NAME"

# --- prerequisites ---
need() { command -v "$1" >/dev/null 2>&1 || { echo "❌ Required tool '$1' not found."; exit 1; }; }
need curl
need tar
# xz support (usually built into tar on Ubuntu/Pop!_OS, but check anyway)
if ! tar --help 2>/dev/null | grep -qi "xz"; then
  echo "🔧 Adding xz support (xz-utils)..."
  sudo apt-get update -y
  sudo apt-get install -y xz-utils
fi

# --- download ---
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
archive="$tmpdir/${THEME_NAME}.tar.xz"

echo "⬇️  Downloading $THEME_NAME..."
# Use -L for redirects and --fail for proper error on 4xx/5xx
if ! curl -L --fail "$THEME_URL" -o "$archive"; then
  echo "❌ Download failed."
  exit 1
fi

# sanity check (>100KB)
size=$(wc -c < "$archive")
if [ "$size" -lt 102400 ]; then
  echo "❌ Downloaded file looks too small ($size bytes) – aborting."
  exit 1
fi

# --- install to /usr/share/icons ---
echo "📦 Extracting to /usr/share/icons ..."
sudo mkdir -p /usr/share/icons
sudo tar -xJf "$archive" -C /usr/share/icons/

if [ ! -d "/usr/share/icons/$THEME_NAME" ]; then
  echo "ℹ️  Extracted folder not found as /usr/share/icons/$THEME_NAME."
  echo "    Checking for possible folder names..."
  found="$(sudo find /usr/share/icons -maxdepth 1 -type d -name 'Bibata*Ice*' | head -n1 || true)"
  if [ -n "$found" ]; then
    echo "✅ Using detected folder: $found"
    THEME_NAME="$(basename "$found")"
  else
    echo "❌ Could not detect installed theme folder."
    exit 1
  fi
fi

echo "✅ Installed to /usr/share/icons/$THEME_NAME"

# --- set system default via update-alternatives ---
echo "⚙️  Setting system default cursor ..."
sudo update-alternatives --install /usr/share/icons/default/index.theme x-cursor-theme "/usr/share/icons/$THEME_NAME/index.theme" 50
sudo update-alternatives --set x-cursor-theme "/usr/share/icons/$THEME_NAME/index.theme"

# --- apply in GNOME for the current user ---
echo "🖥️  Applying theme in GNOME ..."
gsettings set org.gnome.desktop.interface cursor-theme "$THEME_NAME" || true

# --- ensure Qt/XWayland apps follow it ---
mkdir -p "$HOME/.local/share/icons"
ln -sfn /usr/share/icons/default "$HOME/.local/share/icons/default"
echo "🔗 Linked $HOME/.local/share/icons/default → /usr/share/icons/default"

# --- optional: ensure a size (uncomment to force 24/32/48/96 etc.) ---
# gsettings set org.gnome.desktop.interface cursor-size 32 || true

echo "🎉 Done! Installed by 👨‍💻 Bidhan (🌐 https://github.com/bidhan948)"
echo "🔄 Log out and back in (or reboot) if you don’t see the new cursor everywhere."
