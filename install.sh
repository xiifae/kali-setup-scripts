#!/bin/bash
set -e

if [ "$EUID" -eq 0 ]; then
    echo "Run as your normal user, not root."
    exit 1
fi

sudo apt-get update && sudo apt-get upgrade -y

sudo apt-get install -y wget curl git zsh jq unzip xz-utils tmux xclip \
    shellcheck wireguard pocl-opencl-icd pipx cargo golang-go

# pyenv build dependencies
sudo apt-get install -y build-essential libssl-dev zlib1g-dev libbz2-dev \
    libreadline-dev libsqlite3-dev libncurses-dev tk-dev libxml2-dev \
    libxmlsec1-dev libffi-dev liblzma-dev

if [ "$(systemd-detect-virt)" = vmware ]; then
    sudo apt-get install -y open-vm-tools open-vm-tools-desktop
fi

if [ ! -x ~/.pyenv/bin/pyenv ]; then
    curl -fsSL https://pyenv.run | bash
fi

touch ~/.zprofile
for p in '$HOME/.local/bin' '$HOME/.cargo/bin' '$HOME/go/bin'; do
    line="export PATH=\"\$PATH:$p\""
    grep -qxF "$line" ~/.zprofile || echo "$line" >> ~/.zprofile
done

if ! grep -q 'PYENV_ROOT' ~/.zprofile; then
    cat >> ~/.zprofile <<'EOF'
export PYENV_ROOT="$HOME/.pyenv"
if [ -x "$PYENV_ROOT/bin/pyenv" ]; then
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
fi
EOF
fi

[ "$SHELL" = "$(command -v zsh)" ] || chsh -s "$(command -v zsh)"

echo
echo "Done. Run: source ~/.zprofile"
