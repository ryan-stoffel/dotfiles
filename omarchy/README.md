# Omarchy

Omarchy (Arch Linux with Hyprland) on the MacBook Pro 14" M3 Pro (Mac15,6, board
J514s, SoC T6030), on Omarchy's Apple Silicon kernel `linux-aurora`.

- `touchid-j514s/`: Touch ID for this Mac. Upstream `linux-aurora` has no M3 Pro
  Secure Enclave profile, so this adds one with a local kernel patch.
