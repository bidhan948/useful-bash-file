#!/bin/bash

echo "🌐 Installing WebSocket server dependencies for Laravel..."

# Update packages
sudo apt update && sudo apt upgrade -y

# Install PHP and required extensions
echo "📦 Installing PHP and extensions..."
sudo apt install -y php php-cli php-curl php-mbstring php-xml php-bcmath php-zip php-sqlite3 php-pdo php-tokenizer php-intl unzip curl git

# Check PHP version
php -v

# Install Composer globally
if ! command -v composer &> /dev/null
then
    echo "🎼 Installing Composer..."
    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer
else
    echo "✅ Composer is already installed"
fi

# Move to Laravel project folder
read -p "📂 Enter Laravel project folder path (e.g., /home/youruser/code/laravel-app): " project_path
cd "$project_path" || { echo "❌ Project folder not found. Exiting."; exit 1; }

# Install Ratchet
echo "🔌 Installing Ratchet WebSocket package..."
composer require cboden/ratchet

# Done!
echo "✅ All set! Your WebSocket server is ready to use 🚀"
echo "👉 Run the server using: php artisan websocket:serve"
