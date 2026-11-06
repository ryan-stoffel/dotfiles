# Omarchy

Omarchy (Arch Linux with Hyprland) on the MacBook Pro 14" M3 Pro (Mac15,6, board
J514s, SoC T6030), on Omarchy's Apple Silicon kernel `linux-aurora`.

- `touchid-j514s/`: Touch ID for this Mac. Upstream `linux-aurora` has no M3 Pro
  Secure Enclave profile, so this adds one with a local kernel patch.
- `display-120hz-j514s/`: 120 Hz on the built-in display. Stock `linux-aurora`
  shows 60 fps on this panel, so this rebuilds the display driver with two
  upstream fixes.
- `config/`: this Mac's desktop setup, copied from the live machine by `sync.sh`.

## Desktop config

`config/home/` mirrors `~` (Hyprland, the Omarchy shell layout, Everforest
theme overrides, and the custom plugins: Apple menu, menu, lock screen, Touch ID
sudo card, full gaps, and a clock whose calendar shows Canvas due dates). `config/system/` mirrors `/` (PAM, modprobe, the AWDL
resume drop-in, `sudo-touchid`). `config/plugin-patches/` holds local edits to
two third-party plugins; the first line of each names the upstream repo and
commit it applies to.

```sh
omarchy/sync.sh capture   # machine -> repo, then review and commit
omarchy/sync.sh restore   # repo -> ~/.config, backing up what it replaces
```

Files are copied, not symlinked, because Omarchy and editors replace config
files on save and would break the links. Run `capture` after changing the desktop.

Restore by hand, in this order, on a fresh install:

1. Kernel work: `touchid-j514s/` then `display-120hz-j514s/`.
2. AirDrop: install `brcmfmac-awdl-dkms` 0.10.4 or newer, enable `awdl0.service`,
   and allow TCP 8771 on `awdl0` from `fe80::/10` in ufw.
3. Plugins: clone the upstream repo at the named commit into
   `~/.config/omarchy/plugins/<id>`, then `git apply` the patch.
4. System files: `sudo install -m 644` each file under `config/system/etc/` to
   the same path, and `sudo install -m 755 config/system/usr/local/bin/sudo-touchid
   /usr/local/bin/`. Do the PAM files only after Touch ID works
   (`fprintd-verify`); keep a root shell open while testing sudo.
5. `omarchy/sync.sh restore`, then `omarchy restart shell`.
6. Canvas: put the calendar feed URL (Canvas > Calendar > Calendar Feed) in
   `~/.config/canvas-calendar/feed-url` with mode 600, then
   `systemctl --user daemon-reload && systemctl --user enable --now canvas-sync.timer`.

Not stored: the live wallpaper video (58 MB, `~/.config/omarchy/backgrounds/`),
fingerprint templates, the Secure Enclave state, the sensor calibration blob,
`~/.config/omdrop/settings`, and the Canvas feed URL (it grants read access
to your Canvas calendar).

## Stability notes

- `/etc/pacman.conf` holds `linux-aurora`. The 120 Hz and Touch ID modules are
  built for one kernel version; a kernel update drops both. Rebuild them before
  lifting the hold.
- Third-party plugin updates (`omarchy plugin update`) conflict with the local
  patches. Reapply the patch after updating.
