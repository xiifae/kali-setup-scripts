#!/bin/bash
set -e

if [ "$EUID" -eq 0 ]; then
    echo "Run as your normal user, not root."
    exit 1
fi

dest=~/tools/shells
mkdir -p "$dest"

declare -A gists=(
    [resh.py]="https://gist.githubusercontent.com/xct/ab71d58a29e9017eb38565e32aeb95b0/raw/resh.py"
    [powershell_reverse_shell.ps1]="https://gist.githubusercontent.com/egre55/c058744a4240af6515eb32b2d33fbed3/raw/powershell_reverse_shell.ps1"
)

for name in "${!gists[@]}"; do
    curl -fsSL "${gists[$name]}" -o "$dest/$name"
done
chmod +x "$dest/resh.py"

echo
echo "Done. Reverse-shell generators in $dest"
