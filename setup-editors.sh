#!/bin/bash
# The base image ships only vim-tiny, which runs in vi-compatible mode.
set -e

if [ "$EUID" -eq 0 ]; then
    echo "Run as your normal user, not root."
    exit 1
fi

sudo apt-get install -y vim neovim

sudo update-alternatives --set editor /usr/bin/vim.basic

echo
echo "Done. vim (vim.basic) + neovim (nvim) installed; default editor -> vim"
