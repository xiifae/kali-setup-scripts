#!/bin/bash
set -e

if [ "$EUID" -eq 0 ]; then
    echo "Run as your normal user, not root."
    exit 1
fi

sudo apt-get install -y python3-pwntools cmake build-essential

# cmake/build-essential above cover pwndbg's unicorn dependency.
curl -qsL 'https://install.pwndbg.re' | sh -s -- -t pwndbg-gdb

echo
echo "Done. pwntools installed from the Kali repo (pwn CLI + python3 module)."
echo "pwndbg installed -- it hooks into ~/.gdbinit, just run gdb as normal."
