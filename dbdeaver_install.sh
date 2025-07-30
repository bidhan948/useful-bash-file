#!/bin/bash

echo "📦 DBeaver Installer for Ubuntu/Pop!_OS"
echo "--------------------------------------"

read -p "Do you want to install DBeaver CE (Community Edition)? (y/n): " choice

if [[ "$choice" != "y" && "$choice" != "Y" ]]; then
    echo "❌ Installation cancelled."
    exit 1
fi

echo "🔍 Checking if wget is installed..."
if ! command -v wget &> /dev/null; then
    echo "📥 Installing wget..."
    sudo apt update && sudo apt install -y wget
fi

echo "🌐 Downloading latest DBeaver .deb package..."
wget -O dbeaver.deb https://dbeaver.io/files/dbeaver-ce_latest_amd64.deb

echo "📦 Installing DBeaver..."
sudo apt install -y ./dbeaver.deb

echo "🧹 Cleaning up..."
rm dbeaver.deb

echo "✅ DBeaver CE installed successfully!"
echo "🚀 You can launch it by running: dbeaver"

read -p "Do you want to launch DBeaver now? (y/n): " launch
if [[ "$launch" == "y" || "$launch" == "Y" ]]; then
    dbeaver &
fi
