#!/bin/bash
# Installs the patched appledrm.ko for the running kernel, turns early flip on from
# boot, holds the kernel package so an update can't drop the patch, and rebuilds the
# boot image. Run as root after build.sh. Reboot to use it.
#
# Usage: sudo install.sh [WORKDIR]   (default ~ryan-stoffel/.cache/display-120hz-j514s)
set -euo pipefail

work=${1:-$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)/.cache/display-120hz-j514s}
kv=$(uname -r)
ko=$work/appledrm.ko
uki=/boot/efi/EFI/Linux/omarchy_linux-aurora.efi

[[ $(modinfo -F vermagic "$ko" | cut -d' ' -f1) == "$kv" ]] || { echo "$ko is not built for $kv" >&2; exit 1; }
grep -qx 'apple,j514s' < <(tr '\0' '\n' </proc/device-tree/compatible) || { echo "not a J514s" >&2; exit 1; }

install -Dm644 "$ko" "/usr/lib/modules/$kv/updates/appledrm.ko"
cat >/etc/modprobe.d/appledrm-120hz.conf <<EOF
# Local 120 Hz fix for the M3 Pro built-in panel (patched appledrm in /usr/lib/modules/$kv/updates).
# Early flip from omacom/linux-aurora#31. Remove with uninstall.sh from the dotfiles.
options appledrm t6030_early_flip=1
EOF
if ! grep -q '^IgnorePkg = linux-aurora linux-aurora-headers$' /etc/pacman.conf; then
  sed -i '/^HoldPkg/a # Hold the kernel: the 120 Hz appledrm patch only exists for '"$kv"'. Remove once omacom/linux-aurora#358 ships.\nIgnorePkg = linux-aurora linux-aurora-headers' /etc/pacman.conf
fi
depmod -a "$kv"
limine-mkinitcpio linux-aurora

# The boot image must carry this module, or the stock one loads first.
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
objcopy -O binary --only-section=.initrd "$uki" "$tmp/initrd.img"
(cd "$tmp" && lsinitcpio -x initrd.img "usr/lib/modules/$kv/updates/appledrm.ko")
cmp -s "$tmp/usr/lib/modules/$kv/updates/appledrm.ko" "$ko" && echo "Installed for $kv. Reboot to use 120 Hz."
