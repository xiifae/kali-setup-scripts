#!/bin/bash
set -e

if [ "$EUID" -eq 0 ]; then
    echo "Run as your normal user, not root. It calls sudo itself where it needs root."
    exit 1
fi

install_dir="$HOME/tools/cloud"
mkdir -p "$install_dir"

clone_or_pull() {
    if [ -d "$1/.git" ]; then
        git -C "$1" pull --ff-only
    else
        git clone --depth 1 "$2" "$1"
    fi
}

curl -LsSf https://astral.sh/uv/install.sh | sh
uv tool install git+https://github.com/initstring/cloud_enum

arch=$(uname -m)
case "$arch" in
    x86_64)  cf_arch=amd64 ;;
    aarch64) cf_arch=arm64 ;;
    i?86)    cf_arch=386 ;;
    *)       echo "Unsupported architecture: $arch"; exit 1 ;;
esac
cf_url=$(curl -s https://api.github.com/repos/BishopFox/cloudfox/releases/latest \
    | grep -o "https://.*cloudfox-linux-${cf_arch}\.zip")
tmpdir=$(mktemp -d)
curl -fsSL "$cf_url" -o "$tmpdir/cloudfox.zip"
unzip -o "$tmpdir/cloudfox.zip" -d "$tmpdir"
chmod +x "$tmpdir/cloudfox"
sudo mv "$tmpdir/cloudfox" /usr/local/bin/cloudfox
rm -rf "$tmpdir"

clone_or_pull "$install_dir/CloudPEASS" https://github.com/peass-ng/CloudPEASS

pipx install "git+https://github.com/prowler-cloud/prowler.git" --force
pipx install trufflehog --force

echo
echo "Done."
