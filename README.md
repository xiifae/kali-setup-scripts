# kali-setup-scripts

Standalone, re-runnable installers for Kali. Run only what you need, as your
normal user, not root. Each script calls `sudo` where it needs root.

```
git clone https://github.com/xiifae/kali-setup-scripts
cd kali-setup-scripts
./install.sh
```

Run `install.sh` first. It installs the base packages system wide (git, zsh,
tmux, pipx, cargo, Go, pyenv build deps, VMware tools when in a VMware
guest), installs pyenv and adds `~/.local/bin`, `~/.cargo/bin`, `~/go/bin` and
pyenv to `PATH` in `~/.zprofile`.

## Scripts

| Script | Does |
| --- | --- |
| `setup-bloodhound-ce.sh` | Docker + BloodHound CE |
| `setup-bloodhound-legacy.sh` | BloodHound 4.3.1 + Neo4j, `bloodhound-legacy start\|stop\|status` |
| `setup-ad-tools.sh` | AD and pivoting: RustHound-CE, bloodyAD, Certipy, krbrelayx, ligolo-ng, chisel, kerbrute, SharpCollection |
| `setup-azure-tools.sh` | Azure / Entra ID / M365 tooling in `~/tools/cloud/azure` |
| `setup-aws-tools.sh`, `setup-cloud-tools.sh` | AWS and multi-cloud tooling |
| `setup-burpsuite-certs.sh` | installs Burp and imports its CA into every Firefox profile |
| `setup-linpeas.sh` | latest linpeas / winPEAS into `~/tools/PEASS-ng` |
| `setup-shells.sh` | reverse-shell generators (xct resh, egre55 PowerShell) into `~/tools/shells` |
| `setup-pwntools.sh` | pwntools from the Kali repo, plus pwndbg |
| `setup-sublime-text.sh` | Sublime Text from its apt repo |
| `setup-editors.sh` | full vim and neovim, makes vim the default editor |
| `setup-proxychains.sh` | proxychains4, made the default `proxychains` |
| `fix-vmware-dns.sh` | if VMware's NAT hands out a broken resolver, sets up stubby (DNS-over-TLS) and points `/etc/resolv.conf` at it |
| `pimpmykali.sh` | trimmed fork of [Dewalt-arch/pimpmykali](https://github.com/Dewalt-arch/pimpmykali) |

## Attribution

`pimpmykali.sh` is based on [pimpmykali](https://github.com/Dewalt-arch/pimpmykali) by **Dewalt-arch**, modified to remove functionality that overlaps with the other scripts in this repo.
