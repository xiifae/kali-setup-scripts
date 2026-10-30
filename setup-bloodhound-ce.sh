#!/bin/bash
set -e

BH_PORT="${BH_PORT:-8081}"

if [ "$EUID" -eq 0 ]; then
    echo "Run as your normal user, not root."
    exit 1
fi

sudo apt-get install -y docker.io curl ca-certificates pipx
sudo systemctl enable --now docker

getent group docker >/dev/null || sudo groupadd docker
sudo usermod -aG docker "$USER"

# BloodHound.py ingestor for CE.
pipx install bloodhound-ce --force

mkdir -p ~/.docker/cli-plugins
curl -fsSL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
    -o ~/.docker/cli-plugins/docker-compose
chmod +x ~/.docker/cli-plugins/docker-compose

mkdir -p ~/.local/bin
tmp="$(mktemp -d)"
curl -fsSL https://github.com/SpecterOps/bloodhound-cli/releases/latest/download/bloodhound-cli-linux-amd64.tar.gz \
    -o "$tmp/bloodhound-cli.tar.gz"
tar -xzf "$tmp/bloodhound-cli.tar.gz" -C "$tmp"
install -m 0755 "$tmp/bloodhound-cli" ~/.local/bin/bloodhound-cli
rm -rf "$tmp"

sg docker -c "$HOME/.local/bin/bloodhound-cli install"

conf="$HOME/.config/bloodhound"
if [ -d "$conf" ]; then
    echo "BLOODHOUND_PORT=$BH_PORT" > "$conf/.env"
    sg docker -c "$HOME/.local/bin/bloodhound-cli config set ROOT_URL http://127.0.0.1:$BH_PORT"
    sg docker -c "$HOME/.local/bin/bloodhound-cli down && $HOME/.local/bin/bloodhound-cli up"
else
    echo "WARNING: $conf not found -- couldn't set port to $BH_PORT. Is bloodhound-cli install complete?" >&2
fi

echo
echo "BloodHound CE: http://127.0.0.1:$BH_PORT/ui/login  (user: admin)"
echo -n "Admin password: "
sg docker -c "$HOME/.local/bin/bloodhound-cli config get default_password"
echo "Log out/in once so 'docker' works without sg. Update later with: bloodhound-cli update"
