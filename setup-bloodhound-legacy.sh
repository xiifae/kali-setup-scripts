#!/bin/bash
set -e

if [ "$EUID" -eq 0 ]; then
    echo "Run as your normal user, not root."
    exit 1
fi

sudo apt-get install -y curl unzip ca-certificates neo4j pipx

# BloodHound.py ingestor for legacy (installs bloodhound-python).
pipx install bloodhound --force

# Pinned: 4.3.1 is the last legacy release.
bh_dir=~/tools/active-directory/BloodHound-legacy
mkdir -p "$bh_dir" ~/.local/bin

if [ ! -x "$bh_dir/BloodHound-linux-x64/BloodHound" ]; then
    tmp="$(mktemp -d)"
    curl -fsSL https://github.com/BloodHoundAD/BloodHound/releases/download/v4.3.1/BloodHound-linux-x64.zip \
        -o "$tmp/BloodHound-legacy.zip"
    unzip -qo "$tmp/BloodHound-legacy.zip" -d "$bh_dir"
    rm -rf "$tmp"
    chmod +x "$bh_dir/BloodHound-linux-x64/BloodHound"
fi

# Keep Chromium's sandbox on: the setuid helper must be root-owned, mode 4755.
sudo chown root:root "$bh_dir/BloodHound-linux-x64/chrome-sandbox"
sudo chmod 4755 "$bh_dir/BloodHound-linux-x64/chrome-sandbox"

cat > ~/.local/bin/bloodhound-legacy <<'EOF_BH'
#!/bin/bash
bh="$HOME/tools/active-directory/BloodHound-legacy/BloodHound-linux-x64/BloodHound"

case "${1:-}" in
    start)
        shift
        sudo neo4j status >/dev/null 2>&1 || sudo neo4j start || exit 1
        echo -n "Waiting for Neo4j (bolt :7687)"
        for _ in $(seq 1 60); do
            if (exec 3<>/dev/tcp/127.0.0.1/7687) 2>/dev/null; then
                echo " up."
                setsid "$bh" --disable-gpu "$@" >/dev/null 2>&1 &
                exit 0
            fi
            echo -n "."
            sleep 1
        done
        echo
        echo "Neo4j did not come up in 60s. Check: sudo tail -n 50 /etc/neo4j/logs/neo4j.log" >&2
        exit 1
        ;;
    stop)
        pkill -f "BloodHound-legacy/BloodHound-linux-x64/BloodHound" || true
        sudo neo4j stop
        echo "BloodHound legacy and Neo4j stopped."
        ;;
    status)
        sudo neo4j status || true
        pgrep -f "BloodHound-legacy/BloodHound-linux-x64/BloodHound" >/dev/null \
            && echo "GUI: running" || echo "GUI: not running"
        ;;
    *)
        echo "Usage: bloodhound-legacy start|stop|status" >&2
        exit 1
        ;;
esac
EOF_BH
chmod 0755 ~/.local/bin/bloodhound-legacy
rm -f ~/.local/bin/bloodhound-legacy-start ~/.local/bin/bloodhound-legacy-stop

echo
echo "Installed."
echo "  bloodhound-legacy start   (starts Neo4j, then the GUI)"
echo "  bloodhound-legacy stop"
echo "  bloodhound-legacy status"
echo "First time: set the Neo4j password at http://localhost:7474 (neo4j / neo4j), then log in to bolt://localhost:7687"
