#!/bin/bash

echo "🔐 FortiClient VPN 7.4 Installer (via Official Repo) for Ubuntu 22.04"
echo "---------------------------------------------------------------------"

read -p "Proceed with installation? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "❌ Installation cancelled."
    exit 1
fi

# Step 1: Add Fortinet GPG key
echo "🔑 Adding GPG key..."
wget -O - https://repo.fortinet.com/repo/forticlient/7.4/ubuntu22/DEB-GPG-KEY | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/repo.fortinet.com.gpg > /dev/null

# Step 2: Create APT source list
echo "📝 Creating sources.list.d entry..."
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/repo.fortinet.com.gpg] https://repo.fortinet.com/repo/forticlient/7.4/ubuntu22/ stable non-free" | \
    sudo tee /etc/apt/sources.list.d/repo.fortinet.com.list > /dev/null

# Step 3: Update APT and install
echo "🔄 Updating package list..."
sudo apt update

echo "📦 Installing FortiClient..."
sudo apt install -y forticlient

# Final message
echo "✅ FortiClient VPN installed successfully!"
echo "🚀 Launch from the app menu or run: forticlient"
