#!/usr/bin/env bash
# Install NixOS on the ThinkPad. WIPES the target disk.
#
# 1. Boot the NixOS minimal ISO and get online (`nmtui` for wifi).
# 2. nix-shell -p git
# 3. git clone https://github.com/RyanStoffel/dotfiles.git ~/.dotfiles
# 4. ~/.dotfiles/nixos/install.sh /dev/nvme0n1    (see `lsblk` for the disk)
set -euo pipefail

disk="${1:?Usage: install.sh <disk>, e.g. /dev/nvme0n1 (see lsblk)}"
host=thinkpad
user=ryan-stoffel
github_user=RyanStoffel

nixos="$(cd "$(dirname "$0")" && pwd)"
repo="$(dirname "$nixos")"
hostdir="$nixos/hosts/$host"
nix=(nix --extra-experimental-features "nix-command flakes")

[ -b "$disk" ] || { echo "$disk is not a block device." >&2; exit 1; }
[ "$(id -u)" -eq 0 ] || { echo "Run as root: sudo $0 $disk" >&2; exit 1; }
[ -d /sys/firmware/efi ] || { echo "Not booted in UEFI mode." >&2; exit 1; }

lsblk "$disk"
read -rp "Erase $disk and install NixOS as $host? Type 'yes': " answer
[ "$answer" = yes ] || exit 1

# SSH keys, so the headless machine is reachable after the first boot.
if [ ! -s "$hostdir/authorized_keys" ]; then
  curl -fsSL "https://github.com/$github_user.keys" > "$hostdir/authorized_keys"
fi
[ -s "$hostdir/authorized_keys" ] || { echo "No SSH keys found. Add some to $hostdir/authorized_keys." >&2; exit 1; }

sed -i "s|device = \".*\";|device = \"$disk\";|" "$hostdir/disko.nix"

# Partition, format, and mount at /mnt.
"${nix[@]}" run github:nix-community/disko -- --mode destroy,format,mount --flake "$nixos#$host"

# Hardware config from this machine. Filesystems come from disko.
nixos-generate-config --root /mnt --no-filesystems --show-hardware-config > "$hostdir/hardware-configuration.nix"

# Flakes only see files Git knows about.
git -C "$repo" add -A "$nixos"

nixos-install --no-root-passwd --flake "$nixos#$host"

# Wifi profiles from the installer, so the first boot can get online.
if [ -d /etc/NetworkManager/system-connections ]; then
  mkdir -p /mnt/etc/NetworkManager/system-connections
  cp -a /etc/NetworkManager/system-connections/. /mnt/etc/NetworkManager/system-connections/
fi

# Put the repo (with the generated hardware config) in the user's home.
mkdir -p "/mnt/home/$user"
cp -a "$repo" "/mnt/home/$user/.dotfiles"
nixos-enter --root /mnt -c "chown -R $user:users /home/$user"

echo "Set a password for $user (used for sudo; SSH is key-only):"
nixos-enter --root /mnt -c "passwd $user"

echo "Done. Remove the USB and reboot. Then: ssh $user@$host"
echo "Run 'sudo tailscale up' once, and commit hardware-configuration.nix and authorized_keys."
