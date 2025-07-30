#!/usr/bin/env bash
set -euo pipefail

echo "▶ Detecting CPU architecture ..."
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  ARCH="linux-amd64" ;;
  aarch64) ARCH="linux-arm64" ;;
  armv6l|armv7l) ARCH="linux-armv6l" ;;
  i386|i686) ARCH="linux-386" ;;
  *) echo "❌ Unsupported arch $(uname -m)"; exit 1 ;;
esac
echo "✔ Architecture set to: $ARCH"

echo "▶ Fetching latest Go version ..."
LATEST=$(curl -sS https://go.dev/VERSION?m=text | head -n1)   # <- fixed
echo "✔ Latest version is: $LATEST"

echo "▶ Removing existing Go installations (if any) ..."
sudo apt -y remove golang-go >/dev/null 2>&1 || true
sudo rm -rf /usr/local/go

echo "▶ Downloading $LATEST for $ARCH ..."
TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"
curl -LO "https://go.dev/dl/${LATEST}.${ARCH}.tar.gz"

echo "▶ Installing to /usr/local/go ..."
sudo tar -C /usr/local -xzf "${LATEST}.${ARCH}.tar.gz"

echo "▶ Updating PATH ..."
PROFILE_LINE='export PATH=$PATH:/usr/local/go/bin'
if ! grep -qxF "$PROFILE_LINE" "$HOME/.profile"; then
  echo "$PROFILE_LINE" >> "$HOME/.profile"
  echo "→ Added PATH entry to ~/.profile"
fi

echo "▶ Cleaning up ..."
cd ~
rm -rf "$TMP_DIR"

echo "✅ Go installation complete:"
/usr/local/go/bin/go version
echo "👉 Open a new terminal or run:  source ~/.profile"
