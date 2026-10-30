#!/bin/bash
set -e

if [ "$EUID" -eq 0 ]; then
    echo "Run as your normal user, not root."
    exit 1
fi

sudo apt-get install -y stubby

# Replace default upstream (getdnsapi.net demo server) with production resolvers
sudo tee /etc/stubby/stubby.yml > /dev/null <<'STUBBY'
resolution_type: GETDNS_RESOLUTION_STUB
dns_transport_list:
  - GETDNS_TRANSPORT_TLS
tls_authentication: GETDNS_AUTHENTICATION_REQUIRED
tls_query_padding_blocksize: 128
edns_client_subnet_private: 1
round_robin_upstreams: 1
idle_timeout: 10000
listen_addresses:
  - 127.0.0.1
  - 0::1
upstream_recursive_servers:
  - address_data: 1.1.1.1
    tls_auth_name: "cloudflare-dns.com"
  - address_data: 1.0.0.1
    tls_auth_name: "cloudflare-dns.com"
  - address_data: 9.9.9.9
    tls_auth_name: "dns.quad9.net"
STUBBY

# Prevent NetworkManager from overwriting resolv.conf
printf '[main]\ndns=none\n' | sudo tee /etc/NetworkManager/conf.d/no-dns.conf
echo "nameserver 127.0.0.1" | sudo tee /etc/resolv.conf
sudo systemctl restart NetworkManager

sudo systemctl enable --now stubby
sudo systemctl restart stubby

echo "--- Verifying DNS resolution ---"
dig +short google.com @127.0.0.1 && echo "DNS over TLS is working." || echo "DNS resolution failed."
