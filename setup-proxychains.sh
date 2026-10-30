#!/bin/bash
# The base image ships only legacy proxychains v3; v4 coexists with it.
set -e

if [ "$EUID" -eq 0 ]; then
    echo "Run as your normal user, not root."
    exit 1
fi

sudo apt-get install -y proxychains4
sudo update-alternatives --set proxychains /usr/bin/proxychains4

echo
echo "Done. 'proxychains' -> proxychains4 (config: /etc/proxychains4.conf)"
