#!/bin/bash
# Installs the patched DTB, apple-sep.ko and this Mac's sensor calibration for
# the running kernel, then rebuilds m1n1's boot.bin. Run as root after build.sh.
#
# Usage: sudo install.sh [WORKDIR]   (default ~ryan-stoffel/.cache/touchid-j514s)
#
# On a Mac where Touch ID is not turned on yet, the driver is forced read-only
# (enable-writes.sh lifts that). A kernel update overwrites both files and so
# reverts this; build and install again for the new kernel.
set -euo pipefail

work=${1:-$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)/.cache/touchid-j514s}
kv=$(uname -r)
out=$(ls -d "$work"/linux-aurora/src/linux-aurora-*/build/base)
[[ $(cat "$out/version") == "$kv" ]] || { echo "build is $(cat "$out/version"), running $kv" >&2; exit 1; }
grep -qx 'apple,j514s' < <(tr '\0' '\n' </proc/device-tree/compatible) || { echo "not a J514s" >&2; exit 1; }

backup=$work/backup/$kv
mkdir -p "$backup"
[[ -e $backup/t6030-j514s.dtb ]] || cp -a "/usr/lib/modules/$kv/dtbs/t6030-j514s.dtb" "$backup/"
install -m644 "$out/arch/arm64/boot/dts/apple/t6030-j514s.dtb" "/usr/lib/modules/$kv/dtbs/t6030-j514s.dtb"

# The module's BTF is relative to this build's vmlinux, not the running one,
# and the kernel refuses mismatched BTF (-ELOOP). The driver doesn't use it.
install -Dm644 "$out/drivers/soc/apple/apple-sep.ko" "/usr/lib/modules/$kv/updates/apple-sep.ko"
/usr/lib/llvm18/bin/llvm-objcopy --remove-section=.BTF "/usr/lib/modules/$kv/updates/apple-sep.ko"
depmod -a "$kv"

if [[ ! -e /etc/omarchy-mac/touchid-on ]]; then
  printf 'options apple_sep xart_writes=0 provision_keybag=0\n' >/etc/modprobe.d/aurora-sep.conf
fi

cal=/usr/lib/firmware/updates/apple/mesacal-j514s.bin
if [[ ! -s $cal ]]; then
  mkdir -p "${cal%/*}"
  python3 -I /usr/lib/linux-aurora/extract-mesa-calibration -o "$cal.new"
  chmod 644 "$cal.new" && mv -f "$cal.new" "$cal"
fi

update-m1n1
grep -qa mesacal-j514s /boot/efi/m1n1/boot.bin && echo "Installed for $kv. Reboot to use the new device tree."
