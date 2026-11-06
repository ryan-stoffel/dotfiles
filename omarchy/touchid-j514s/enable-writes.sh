#!/bin/bash
# Lets apple-sep write the Secure Enclave's shared xART store from the next
# boot, the step Omarchy's own enable script does on supported Macs (its board
# check rejects J514s). xart_guard=1 refuses changes to records this Linux
# install did not create. Run as root, reboot, then omarchy-setup-security-fingerprint.
set -euo pipefail
note="# The owner turned on Touch ID; omarchy-mac's disable-fingerprint removes this."
rm -f /etc/modprobe.d/aurora-sep.conf
mkdir -p -m 0755 /etc/omarchy-mac
printf '%s\n' "$note" >/etc/omarchy-mac/touchid-on
printf '%s\n' "$note" "options apple_sep xart_writes=1 provision_keybag=1" >/etc/modprobe.d/omarchy-mac-touchid.conf
printf '%s\n' "# J514s: refuse writes to xART records this Linux install did not create." \
  "options apple_sep xart_guard=1" >/etc/modprobe.d/j514s-xart-guard.conf
pacman -S --needed --noconfirm --ask 4 -- libfprint-git fprintd usbutils
echo "Reboot. Then check diag (keybag present, xart_guard_refusals 0) and run omarchy-setup-security-fingerprint."
