{ config, lib, ... }:
let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  link = file: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${file}";
in
{
  home.file.".local/bin/project".source = link "scripts/project.py";
  home.file.".local/bin/dotfiles-doctor".source = link "scripts/doctor.py";
  home.file.".local/bin/dotfiles-health".source = link "scripts/tui.py";
  home.file.".config/raycast/scripts".source = link "raycast";

  home.activation.linkAgents = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run /bin/bash "${dotfiles}/scripts/link-agents.sh"
  '';

  # One-time cleanup of symlinks from removed Home Manager modules.
  home.activation.removeRetiredLinks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for path in \
      "$HOME/.config/just/justfile" \
      "$HOME/.config/herdr/config.toml" \
      "$HOME/.config/tmux/tmux.conf" \
      "$HOME/.config/cmux/cmux.json" \
      "$HOME/.tmux.conf" \
      "$HOME/.local/bin/herdr-project" \
      "$HOME/.local/bin/tmux-project" \
      "$HOME/.local/bin/tmux-dev" \
      "$HOME/.omp/agent/keybindings.json" \
      "$HOME/.omp/agent/config.yml" \
      "$HOME/.omp/agent/skills" \
      "$HOME/.omp/agent/AGENTS.md" \
      "$HOME/.config/zed/settings.json" \
      "$HOME/.config/zed/keymap.json" \
      "$HOME/.config/zed/tasks.json" \
      "$HOME/.config/zellij/config.kdl" \
      "$HOME/.config/zellij/layouts/dev.kdl"; do
      if [ -L "$path" ] || [ -e "$path" ]; then
        run rm -rf "$path"
      fi
    done
  '';

  # Custom tap casks are ad-hoc signed; Gatekeeper blocks them after reboot until
  # quarantine is cleared and the bundle is locally signed again.
  home.activation.trustedTapApps = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for app in Caffeine Tidy; do
      bundle="/Applications/$app.app"
      if [ -d "$bundle" ]; then
        /usr/bin/xattr -dr com.apple.quarantine "$bundle" 2>/dev/null || true
        /usr/bin/codesign --force --deep --sign - "$bundle" 2>/dev/null || true
      fi
    done
  '';
}
