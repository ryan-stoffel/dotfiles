{ config, lib, ... }:
let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
  link = file: config.lib.file.mkOutOfStoreSymlink "${dotfiles}/${file}";
in
{
  home.file.".local/bin/project".source = link "scripts/project.py";
  home.file.".local/bin/dotfiles-doctor".source = link "scripts/doctor.py";
  home.file.".config/raycast/scripts".source = link "raycast";
  home.file.".config/just/justfile".source = link "projects/Justfile";

  # Private app runtimes must not take over unrelated development commands.
  # Only remove the known Hermes links; leave its private installation intact.
  home.activation.scopeHermesNode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for name in node npm npx; do
      file="$HOME/.local/bin/$name"
      if [ -L "$file" ] && [ "$(readlink "$file")" = "$HOME/.hermes/node/bin/$name" ]; then
        run rm "$file"
      fi
    done
  '';
}
