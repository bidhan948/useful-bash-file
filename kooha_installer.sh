#!/bin/bash

LOGFILE="install_kooha.log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "📦 Starting Kooha installation..."
echo "Timestamp: $(date)"

# Step 1: Check if flatpak is installed
if ! command -v flatpak &> /dev/null; then
    echo "⚠️ Flatpak is not installed. Installing flatpak first..."
    sudo apt update
    sudo apt install -y flatpak
else
    echo "✅ Flatpak is already installed."
fi

# Step 2: Add Flathub remote if not added
if ! flatpak remotes | grep -q flathub; then
    echo "🔗 Adding Flathub repository..."
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
else
    echo "✅ Flathub remote already exists."
fi

# Step 3: Install Kooha
echo "⬇️ Installing Kooha..."
flatpak install -y flathub io.github.seadve.Kooha

echo "✅ Kooha installation complete!"
echo "🚀 You can launch it from app menu or by running: flatpak run io.github.seadve.Kooha"
