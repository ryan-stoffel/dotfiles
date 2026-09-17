{ config, ... }:
let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  link = file: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/zed/${file}";
in
{
  # Live symlinks to the real files in the repo — edits apply without a rebuild.
  home.file.".config/zed/settings.json".source = link "settings.json";
  home.file.".config/zed/keymap.json".source = link "keymap.json";
}
