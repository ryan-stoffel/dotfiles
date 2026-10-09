{ lib, pkgs, ... }:
let
  ignore = pkgs.writeText "stignore" ''
    (?d).DS_Store
    (?d)._*
    (?d).localized
    (?d)Icon?
    *.crdownload
    *.download
    *.part
    *.partial
    *.icloud
    .obsidian/workspace*.json
  '';
in
{
  # Syncthing reads .stignore from each folder root. It is copied, not
  # symlinked into the store, so Syncthing.app can always read it.
  home.activation.syncthingIgnores =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      for dir in "$HOME/Downloads" "$HOME/Documents"; do
        run install -m 644 ${ignore} "$dir/.stignore"
      done
    '';
}
