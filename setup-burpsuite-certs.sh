#!/bin/bash
set -e

if [ "$EUID" -eq 0 ]; then
    echo "Run as your normal user, not root."
    exit 1
fi

if [ -z "$DISPLAY" ]; then
    echo "No X display detected -- Burp is GUI-only and needs one, even briefly, to serve its CA cert."
    exit 1
fi

sudo apt-get install -y burpsuite libnss3-tools

echo "Launching Burp Suite to fetch its CA certificate."
echo "If it shows a startup/project dialog, click through it (New project -> In-memory, then Use Burp defaults) -- waiting up to 5 minutes for its proxy to come up..."
burpsuite >/tmp/burpsuite-cert-fetch.log 2>&1 &
burp_pid=$!

cert="$(mktemp --suffix=.der)"
got_cert=0
for _ in $(seq 1 300); do
    if curl -fsS -x http://127.0.0.1:8080 -o "$cert" http://burp/cert && [ -s "$cert" ] && \
       { openssl x509 -inform DER -in "$cert" -noout 2>/dev/null || \
         openssl x509 -inform PEM -in "$cert" -noout 2>/dev/null; }; then
        got_cert=1
        break
    fi
    sleep 1
done

kill "$burp_pid" 2>/dev/null || true
wait "$burp_pid" 2>/dev/null || true

if [ "$got_cert" -ne 1 ]; then
    echo "Couldn't fetch the CA cert from Burp's proxy listener (127.0.0.1:8080) within 5 minutes."
    echo "Open Burp once manually, click through to the main window, then re-run this script."
    rm -f "$cert"
    exit 1
fi

pem="$(mktemp --suffix=.pem)"
if openssl x509 -inform DER -in "$cert" -out "$pem" 2>/dev/null; then
    :
else
    openssl x509 -inform PEM -in "$cert" -out "$pem"
fi

mkdir -p ~/.config
cp "$pem" ~/.config/burpsuite-ca.pem

if [ -f ~/.mozilla/firefox/profiles.ini ]; then
    awk -F= '/^Path=/ {print $2}' ~/.mozilla/firefox/profiles.ini | while read -r profile; do
        dir=~/.mozilla/firefox/"$profile"
        [ -d "$dir" ] || continue
        certutil -A -n "PortSwigger CA" -t "C,," -i "$pem" -d sql:"$dir"
        echo "Installed Burp CA into Firefox profile: $profile"
    done
else
    echo "No Firefox profile found -- run Firefox once, then re-run this script to import the cert."
fi

rm -f "$cert" "$pem"

echo
echo "Burp CA cert also saved to ~/.config/burpsuite-ca.pem (import into other browsers manually if needed)."
echo "Point Firefox's proxy at 127.0.0.1:8080 (manual proxy or FoxyProxy) to actually route traffic through Burp."
