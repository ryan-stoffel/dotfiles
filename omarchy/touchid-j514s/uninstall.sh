#!/bin/bash
# Restores the stock DTB and driver for the running kernel and removes the
# Touch ID options. Enrolled fingerprints: run omarchy-remove-security-fingerprint
# first. Run as root.
set -euo pipefail
work=${1:-$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)/.cache/touchid-j514s}
kv=$(uname -r)
install -m644 "$work/backup/$kv/t6030-j514s.dtb" "/usr/lib/modules/$kv/dtbs/t6030-j514s.dtb"
rm -f "/usr/lib/modules/$kv/updates/apple-sep.ko" /etc/modprobe.d/aurora-sep.conf \
  /etc/omarchy-mac/touchid-on /etc/modprobe.d/omarchy-mac-touchid.conf /etc/modprobe.d/j514s-xart-guard.conf
depmod -a "$kv"
update-m1n1
