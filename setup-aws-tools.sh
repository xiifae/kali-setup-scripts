#!/bin/bash
set -e

if [ "$EUID" -eq 0 ]; then
    echo "Run as your normal user, not root. It calls sudo itself where it needs root."
    exit 1
fi

install_dir="$HOME/tools/cloud/aws"
mkdir -p "$install_dir"

curl -fsSL https://awscli.amazonaws.com/v2/install.sh | sudo bash

sudo apt-get install -y unzip curl pipx podman build-essential libssl-dev zlib1g-dev \
    libbz2-dev libreadline-dev libsqlite3-dev wget llvm libncurses-dev \
    xz-utils tk-dev libffi-dev liblzma-dev python3-openssl git

go_ver=1.24.3
arch=$(uname -m)
case "$arch" in
    x86_64)  go_arch=amd64 ;;
    aarch64) go_arch=arm64 ;;
    *)       echo "Unsupported architecture: $arch"; exit 1 ;;
esac

if ! command -v /usr/local/go/bin/go &>/dev/null; then
    curl -fsSL "https://go.dev/dl/go${go_ver}.linux-${go_arch}.tar.gz" -o /tmp/go.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    rm /tmp/go.tar.gz
fi

go_install() {
    sudo GOBIN=/usr/local/bin /usr/local/go/bin/go install -v "$1"
    ln -sf "/usr/local/bin/$(basename "$2")" "$install_dir/$2"
}

go_install github.com/WhiteOakSecurity/GoAWSConsoleSpray@latest GoAWSConsoleSpray
go_install github.com/shabarkin/aws-enumerator@latest aws-enumerator

pipx_install() {
    pipx install "$1" --force
    ln -sf "$(which "$2" 2>/dev/null || echo "$HOME/.local/bin/$2")" "$install_dir/$2"
}

pipx_install "git+https://github.com/WithSecureLabs/IAMGraph.git" iamgraph
pipx_install "git+https://github.com/RhinoSecurityLabs/pacu.git" pacu
pipx_install "git+https://github.com/WeAreCloudar/s3-account-search.git" s3-account-search

if ! command -v git-secrets &>/dev/null; then
    tmpdir=$(mktemp -d)
    git clone --depth 1 https://github.com/awslabs/git-secrets.git "$tmpdir/git-secrets"
    sudo make -C "$tmpdir/git-secrets" install
    rm -rf "$tmpdir"
fi
ln -sf /usr/local/bin/git-secrets "$install_dir/git-secrets"

# ~/.pyenv/bin isn't on a script's PATH, so test the file
if [ ! -x "$HOME/.pyenv/bin/pyenv" ]; then
    curl -fsSL https://pyenv.run | bash
fi
export PATH="$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
pyenv install -s 3.10.20
pipx install --python "$(pyenv prefix 3.10.20)/bin/python" principalmapper --force
ln -sf "$(which pmapper 2>/dev/null || echo "$HOME/.local/bin/pmapper")" "$install_dir/pmapper"

grep -qxF 'export PATH="$PATH:$HOME/tools/cloud/aws"' "$HOME/.zprofile" 2>/dev/null || \
    echo 'export PATH="$PATH:$HOME/tools/cloud/aws"' >> "$HOME/.zprofile"

echo
echo "Done. Run: source ~/.zprofile"
