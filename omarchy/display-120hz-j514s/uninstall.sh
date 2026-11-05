#!/bin/bash
# Removes the patched appledrm, its early-flip config and the kernel hold, then
# rebuilds the boot image. Run as root; the stock driver is back after a reboot.
set -euo pipefail

kv=$(uname -r)
rm -f "/usr/lib/modules/$kv/updates/appledrm.ko" /etc/modprobe.d/appledrm-120hz.conf
sed -i '/^# Hold the kernel: the 120 Hz appledrm patch/d; /^IgnorePkg = linux-aurora linux-aurora-headers$/d' /etc/pacman.conf
depmod -a "$kv"
limine-mkinitcpio linux-aurora
echo "appledrm now resolves to $(modinfo -n appledrm). Reboot to load it."
