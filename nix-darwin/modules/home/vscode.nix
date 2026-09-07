{ config, lib, pkgs, ... }:
let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  userDir = "Library/Application Support/Code/User";
  link = file: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/vscode/${file}";
in
{
  # Live symlinks to the real files in the repo — edits apply without a rebuild.
  home.file."${userDir}/settings.json".source = link "settings.json";
  home.file."${userDir}/keybindings.json".source = link "keybindings.json";

  # Workspace files use absolute paths, so the symlink location does not matter.
  home.file."Developer/school/FA26.code-workspace".source = link "FA26.code-workspace";
  home.file."Developer/school/capstone.code-workspace".source = link "capstone.code-workspace";

  # Versions are recorded explicitly; updates are a separate user action.
  home.activation.vscodeExtensions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -x /opt/homebrew/bin/code ]; then
      run ${pkgs.python3}/bin/python3 "${dotfiles}/scripts/vscode-extensions.py"
    fi
  '';
}
