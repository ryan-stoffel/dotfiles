#!/usr/bin/env bash
# Copies this Mac's Omarchy setup between the live machine and omarchy/config/.
#
#   omarchy/sync.sh capture   live machine -> repo. Run before committing.
#   omarchy/sync.sh restore   repo -> ~/.config. Backs up each file it replaces.
#
# Files are copied, not symlinked: Omarchy and editors replace config files
# with new ones (rename, sed -i), which silently breaks symlinks.
# System files are captured but never restored by this script. The PAM files
# need fprintd and the Touch ID kernel patch, so a blind copy can lock out sudo.
# See omarchy/README.md for restoring them.
set -euo pipefail

repo="$(cd "$(dirname "$0")" && pwd)/config"

# Paths relative to $HOME.
home_paths=(
  .config/hypr/autostart.lua
  .config/hypr/bindings.lua
  .config/hypr/hyprland.lua
  .config/hypr/input.lua
  .config/hypr/looknfeel.lua
  .config/hypr/monitors.lua
  .config/hypr/hyprsunset.conf
  .config/hypr/xdph.conf
  .config/omarchy/shell.json
  .config/omarchy/extensions/omarchy-menu.jsonc
  .config/omarchy/themes/everforest/colors.toml
  .config/omarchy/themes/everforest/shell.toml
  .config/omarchy/hooks/theme-set.d/10-owe-sync
  .config/omarchy/branding/about.txt
  .config/omarchy/branding/screensaver.txt
  .config/omarchy/plugins/ryan-stoffel-apple-menu
  .config/omarchy/plugins/ryan-stoffel.full-gaps
  .config/omarchy/plugins/ryan-stoffel.lock
  .config/omarchy/plugins/ryan-stoffel.menu
  .config/omarchy/plugins/ryan-stoffel.sudo-touchid
)

# Absolute paths, captured for reference and manual restore.
system_paths=(
  /etc/pam.d/sudo
  /etc/pam.d/polkit-1
  /etc/pam.d/omarchy-lock-fingerprint
  /etc/pam.d/omarchy-lock-password
  /etc/modprobe.d/appledrm-120hz.conf
  /etc/modprobe.d/omarchy-mac-touchid.conf
  /etc/modprobe.d/j514s-xart-guard.conf
  /etc/systemd/system/omarchy-wifi-resume-fix.service.d/awdl0.conf
  /usr/local/bin/sudo-touchid
)

# Third-party plugins with local edits: stored as patches on top of upstream.
plugins="$HOME/.config/omarchy/plugins"

# copy SRC DEST: replace DEST with SRC (file or directory), dropping backups.
copy() {
  rm -rf "$2"
  mkdir -p "$(dirname "$2")"
  cp -a "$1" "$2"
  [[ -d $2 ]] && find "$2" \( -name '*.bak*' -o -name '*.orig' -o -name '*.rej' \) -exec rm -rf {} +
  return 0
}

capture() {
  for p in "${home_paths[@]}"; do copy "$HOME/$p" "$repo/home/$p"; done
  for p in "${system_paths[@]}"; do copy "$p" "$repo/system$p"; done

  local out="$repo/plugin-patches"
  mkdir -p "$out"
  local g="$plugins/io.github.workingtitle.gestures"
  { echo "base: $(git -C "$g" remote get-url origin) $(git -C "$g" rev-parse HEAD)"
    git -C "$g" diff; } >"$out/io.github.workingtitle.gestures.patch"
  local d="$plugins/netmojo.omdrop"
  { echo "base: $(git -C "$d" remote get-url origin) $(git -C "$d" merge-base main local/airdrop-ui)"
    git -C "$d" diff main...local/airdrop-ui; } >"$out/netmojo.omdrop.patch"
  echo "Captured into $repo. Review with: git status omarchy/"
}

restore() {
  local stamp; stamp=$(date +%s)
  for p in "${home_paths[@]}"; do
    # Hidden backup name, so the shell doesn't load a backed-up plugin twice.
    [[ -e $HOME/$p ]] && mv "$HOME/$p" "$(dirname "$HOME/$p")/.$(basename "$p").bak.$stamp"
    copy "$repo/home/$p" "$HOME/$p"
  done
  echo "Restored user config (old copies saved as .<name>.bak.$stamp)."
  echo "System files and plugin patches are manual: see omarchy/README.md."
}

case "${1:-}" in
  capture) capture ;;
  restore) restore ;;
  *) echo "usage: $0 capture|restore" >&2; exit 2 ;;
esac
