#!/bin/bash
set -e

if [ "$EUID" -eq 0 ]; then
    echo "Run as your normal user, not root."
    exit 1
fi

dest=~/tools/PEASS-ng
mkdir -p "$dest"

base=https://github.com/carlospolop/PEASS-ng/releases/latest/download

assets=(
    linpeas.sh
    winPEASany.exe
)

# Download everything first so a failed run leaves the existing copies intact.
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

for a in "${assets[@]}"; do
    curl -fsSL "$base/$a" -o "$tmp/$a"
done

chmod +x "$tmp"/*.sh
for a in "${assets[@]}"; do
    mv -f "$tmp/$a" "$dest/$a"
done

echo
echo "Done. linPEAS: $dest/linpeas.sh   winPEAS: $dest/winPEASany.exe"
