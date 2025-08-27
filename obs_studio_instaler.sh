#!/bin/bash
# =========================================================
# 🎥 OBS Studio Installer
# 👨‍💻 Author: Bidhan Baniya
# =========================================================

echo "========================================================="
echo "🎬 Installing OBS Studio (Open Broadcaster Software)..."
echo "👨‍💻 Author: Bidhan Baniya"
echo "========================================================="

# Update system
sudo apt update && sudo apt upgrade -y

# Install OBS Studio via official PPA
sudo add-apt-repository ppa:obsproject/obs-studio -y
sudo apt update
sudo apt install -y obs-studio

# Confirm installation
if command -v obs &> /dev/null; then
    echo "✅ OBS Studio installed successfully!"
    echo "🚀 Launch with: obs"
else
    echo "❌ Installation failed. Please check logs."
fi

echo "========================================================="
echo "🎥 OBS Studio setup complete!"
echo "========================================================="
