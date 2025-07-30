#!/bin/bash


# Clean up any old/bad copies
rm -f websocat
sudo rm -f /usr/local/bin/websocat

# Download correct binary (verified link)
curl -L -o websocat https://github.com/vi/websocat/releases/download/v1.11.0/websocat_amd64-linux-static

# Make it executable
chmod +x websocat

# Move to system path
sudo mv websocat /usr/local/bin/websocat

# Confirm it works
websocat --version
