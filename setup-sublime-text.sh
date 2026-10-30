#!/bin/bash
set -e

if [ "$EUID" -eq 0 ]; then
    echo "Run as your normal user, not root."
    exit 1
fi

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.sublimetext.com/sublimehq-pub.gpg \
    | sudo tee /etc/apt/keyrings/sublimehq-pub.asc > /dev/null

sudo tee /etc/apt/sources.list.d/sublime-text.sources > /dev/null <<'EOF'
Types: deb
URIs: https://download.sublimetext.com/
Suites: apt/stable/
Signed-By: /etc/apt/keyrings/sublimehq-pub.asc
EOF

sudo apt-get update
sudo apt-get install -y sublime-text

echo
echo "Done. Launch with: subl"
