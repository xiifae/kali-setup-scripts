#!/bin/bash
set -e

if [ "$EUID" -eq 0 ]; then
    echo "Run as your normal user, not root. It calls sudo itself where it needs root."
    exit 1
fi

install_dir="$HOME/tools/cloud/azure"
mkdir -p "$install_dir" "$HOME/tools/username-anarchy"

clone_or_pull() {
    if [ -d "$1/.git" ]; then
        git -C "$1" pull --ff-only
    else
        git clone --depth 1 "$2" "$1"
    fi
}

clone_or_pull "$install_dir/AADInternals" https://github.com/Gerenios/AADInternals
clone_or_pull "$install_dir/GraphRunner" https://github.com/dafthack/GraphRunner
clone_or_pull "$install_dir/TokenTacticsV2" https://github.com/f-bader/TokenTacticsV2
clone_or_pull "$install_dir/MFASweep" https://github.com/dafthack/MFASweep
clone_or_pull "$HOME/tools/username-anarchy" https://github.com/urbanadventurer/username-anarchy

clone_or_pull "$install_dir/AzSubEnum" https://github.com/yuyudhn/AzSubEnum
clone_or_pull "$install_dir/basicblobfinder" https://github.com/joswr1ght/basicblobfinder
clone_or_pull "$install_dir/o365enum" https://github.com/gremwell/o365enum
clone_or_pull "$install_dir/o365spray" https://github.com/0xZDH/o365spray
clone_or_pull "$install_dir/Omnispray" https://github.com/0xZDH/Omnispray
clone_or_pull "$install_dir/Oh365UserFinder" https://github.com/dievus/Oh365UserFinder

mkdir -p "$install_dir/exfil_exchange_mail"
curl -fsSL https://raw.githubusercontent.com/rootsecdev/Azure-Red-Team/master/Tokens/exfil_exchange_mail.py \
    -o "$install_dir/exfil_exchange_mail/exfil_exchange_mail.py"

pipx install azure-cli
pipx install graphspy
sudo pip3 install impacket --break-system-packages
pipx install seamlesspass
pipx install "git+https://github.com/dirkjanm/ROADtools" --include-deps
pipx install "git+https://github.com/absolomb/FindMeAccess" --include-deps
pip install --user --break-system-packages requests colorama tabulate termcolor lxml

echo
echo "Done."
