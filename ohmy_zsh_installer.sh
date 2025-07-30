#!/usr/bin/env bash
# install_oh_my_zsh.sh
# A small helper to download and install Oh My Zsh safely.

set -euo pipefail

# ────────────────────────────────────────────────────────────────────
# 1. Sanity-check the environment
# ────────────────────────────────────────────────────────────────────
need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "❌  Missing dependency: $1"
    return 1
  }
}

echo "↪ Checking required tools…"
need git
if ! need zsh; then
  echo "ℹ  Installing zsh (requires sudo)…"
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y zsh
  else
    echo "Please install zsh with your package manager, then re-run this script."
    exit 1
  fi
fi

DL_TOOL=""
if command -v curl >/dev/null 2>&1; then
  DL_TOOL="curl -fsSL"
elif command -v wget >/dev/null 2>&1; then
  DL_TOOL="wget -qO-"
else
  echo "❌  Neither curl nor wget is available."
  exit 1
fi
echo "✓ All prerequisites satisfied."

# ────────────────────────────────────────────────────────────────────
# 2. Back up any existing ~/.zshrc
# ────────────────────────────────────────────────────────────────────
if [[ -f "$HOME/.zshrc" ]]; then
  ts=$(date +%Y%m%d_%H%M%S)
  cp "$HOME/.zshrc" "$HOME/.zshrc.backup.$ts"
  echo "↪ Backed up existing .zshrc ➜ ~/.zshrc.backup.$ts"
fi

# ────────────────────────────────────────────────────────────────────
# 3. Download and run the official installer
# ────────────────────────────────────────────────────────────────────
echo "↪ Downloading Oh My Zsh installer…"
OHMY_URL="https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh"  # official URL :contentReference[oaicite:0]{index=0}

# Run the installer in unattended mode (no prompt) and keep the script file
$DL_TOOL "$OHMY_URL" > /tmp/oh_my_install.sh
chmod +x /tmp/oh_my_install.sh
RUNZSH="no" KEEP_ZSHRC="yes" sh /tmp/oh_my_install.sh
rm -f /tmp/oh_my_install.sh
echo "✓ Oh My Zsh installed."

# ────────────────────────────────────────────────────────────────────
# 4. Make zsh your default shell (optional)
# ────────────────────────────────────────────────────────────────────
if [[ "$SHELL" != */zsh ]]; then
  echo "↪ Changing default shell to zsh (requires password)…"
  chsh -s "$(command -v zsh)" "${USER}"
  echo "✓ Default shell changed. Log out & back in to start using zsh."
else
  echo "ℹ  zsh is already your default shell."
fi

echo "🎉 All done! Open a new terminal or run \`exec zsh\` to start."
