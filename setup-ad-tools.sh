#!/bin/bash
set -e

if [ "$EUID" -eq 0 ]; then
    echo "Run as your normal user, not root."
    exit 1
fi

case "$(uname -m)" in
    x86_64) goarch=amd64 ;;
    aarch64) goarch=arm64 ;;
    *) echo "Unsupported architecture: $(uname -m)"; exit 1 ;;
esac

sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    jq unzip pipx python3-ldap3 python3-dnspython krb5-user ntpsec-ntpdate \
    gcc python3-dev libkrb5-dev krb5-pkinit \
    cargo golang-go clang libclang-dev libgssapi-krb5-2 libsasl2-modules-gssapi-mit

# Disable automatic time sync so the host clock can be set manually to match
# the target DC -- Kerberos rejects tickets when the skew is too large.
if systemctl list-unit-files systemd-timesyncd.service >/dev/null 2>&1; then
    sudo systemctl stop systemd-timesyncd 2>/dev/null || true
    sudo systemctl disable systemd-timesyncd 2>/dev/null || true
fi

sudo pip3 install --break-system-packages --ignore-installed --no-deps impacket
sudo pip3 install --break-system-packages impacket
sudo pipx install git+https://github.com/Pennyw0rth/NetExec.git --global
sudo pipx install git+https://github.com/Mister-Joe/PositiveIntent --global

# sudo's secure_path omits /usr/local/bin, so `sudo nxc` can't find the
# pipx --global symlink there.
sp_dropin="$(mktemp)"
printf 'Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"\n' > "$sp_dropin"
if sudo visudo -cf "$sp_dropin" >/dev/null; then
    sudo install -m 0440 -o root -g root "$sp_dropin" /etc/sudoers.d/local-path
fi
rm -f "$sp_dropin"
pipx install coercer
pipx install lsassy
pipx install mitm6
pipx install pypykatz
pipx install adidnsdump
pipx install git+https://github.com/S3cur3Th1sSh1t/SnafflePy.git

mkdir -p ~/.local/bin
mkdir -p ~/tools/active-directory/krbrelayx ~/tools/active-directory/ntlm_theft ~/tools/pivoting/ligolo-ng-agents ~/tools/active-directory/SharpCollection

cargo install rusthound-ce
pipx install bloodyAD
pipx install certipy-ad
pipx install "evil-winrm-py[kerberos]"
pipx install bloodhound-ce
go install github.com/lkarlslund/ldapnomnom@latest
pipx install git+https://github.com/login-securite/DonPAPI.git

if [ -d ~/tools/active-directory/krbrelayx/.git ]; then
    git -C ~/tools/active-directory/krbrelayx pull --ff-only
else
    git clone --depth 1 https://github.com/dirkjanm/krbrelayx ~/tools/active-directory/krbrelayx
fi

if [ -d ~/tools/active-directory/ntlm_theft/.git ]; then
    git -C ~/tools/active-directory/ntlm_theft pull --ff-only
else
    git clone --depth 1 https://github.com/Greenwolf/ntlm_theft ~/tools/active-directory/ntlm_theft
fi

if [ -d ~/tools/active-directory/SharpCollection/.git ]; then
    git -C ~/tools/active-directory/SharpCollection pull --ff-only --depth 1
else
    git clone --depth 1 https://github.com/Flangvik/SharpCollection.git ~/tools/active-directory/SharpCollection
fi

tmp="$(mktemp -d)"
lg_json="$(curl -fsSL https://api.github.com/repos/nicocha30/ligolo-ng/releases/latest)"
lg_ver="$(echo "$lg_json" | jq -r '.tag_name' | sed 's/^v//')"

lg_asset_url() { echo "$lg_json" | jq -r --arg n "$1" '.assets[] | select(.name == $n) | .browser_download_url'; }

proxy_url="$(lg_asset_url "ligolo-ng_proxy_${lg_ver}_linux_${goarch}.tar.gz")"
curl -fsSL "$proxy_url" -o "$tmp/proxy.tar.gz"
tar -xzf "$tmp/proxy.tar.gz" -C "$tmp" proxy
# Install into /usr/local/bin (root-owned, on sudo's secure_path) so the proxy
# runs via `sudo ligolo-ng-proxy` -- it needs root to create the TUN interface.
sudo install -m 0755 "$tmp/proxy" /usr/local/bin/ligolo-ng-proxy

agent_linux_url="$(lg_asset_url "ligolo-ng_agent_${lg_ver}_linux_${goarch}.tar.gz")"
agent_win_url="$(lg_asset_url "ligolo-ng_agent_${lg_ver}_windows_amd64.zip")"
curl -fsSL "$agent_linux_url" -o "$tmp/agent-linux.tar.gz"
curl -fsSL "$agent_win_url" -o "$tmp/agent-windows.zip"
tar -xzf "$tmp/agent-linux.tar.gz" -C "$tmp" agent
unzip -p "$tmp/agent-windows.zip" agent.exe > "$tmp/agent.exe"
install -m 0755 "$tmp/agent" ~/tools/pivoting/ligolo-ng-agents/agent-linux-"${goarch}"
install -m 0644 "$tmp/agent.exe" ~/tools/pivoting/ligolo-ng-agents/agent-windows-amd64.exe

chisel_dir=~/tools/pivoting/chisel
mkdir -p "$chisel_dir"
chisel_json="$(curl -fsSL https://api.github.com/repos/jpillora/chisel/releases/latest)"
chisel_ver="$(echo "$chisel_json" | jq -r '.tag_name' | sed 's/^v//')"
chisel_asset_url() { echo "$chisel_json" | jq -r --arg n "$1" '.assets[] | select(.name == $n) | .browser_download_url'; }

curl -fsSL "$(chisel_asset_url "chisel_${chisel_ver}_linux_${goarch}.gz")" | gunzip > "$tmp/chisel"
curl -fsSL "$(chisel_asset_url "chisel_${chisel_ver}_windows_amd64.zip")" -o "$tmp/chisel-windows.zip"
unzip -p "$tmp/chisel-windows.zip" chisel.exe > "$tmp/chisel.exe"
install -m 0755 "$tmp/chisel" "$chisel_dir/chisel"
install -m 0644 "$tmp/chisel.exe" "$chisel_dir/chisel-windows-amd64.exe"
echo "$chisel_ver" > "$chisel_dir/VERSION"

rm -rf "$tmp"

kb_json="$(curl -fsSL https://api.github.com/repos/ropnop/kerbrute/releases/latest)"
if [ "$goarch" = amd64 ]; then
    kb_url="$(echo "$kb_json" | jq -r '.assets[] | select(.name == "kerbrute_linux_amd64") | .browser_download_url')"
    curl -fsSL "$kb_url" -o ~/.local/bin/kerbrute
    chmod 0755 ~/.local/bin/kerbrute
elif command -v go >/dev/null 2>&1; then
    go install github.com/ropnop/kerbrute@latest
    install -m 0755 "$(go env GOPATH)/bin/kerbrute" ~/.local/bin/kerbrute
else
    echo "No prebuilt kerbrute for $goarch and no Go toolchain found -- install golang-go and re-run to build it."
fi

for p in '$HOME/.local/bin' '$HOME/.cargo/bin' '$HOME/go/bin'; do
    line="export PATH=\"\$PATH:$p\""
    grep -qxF "$line" ~/.zprofile 2>/dev/null || echo "$line" >> ~/.zprofile
done

echo
echo "Done. Run: source ~/.zprofile"
