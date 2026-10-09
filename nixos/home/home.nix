{ lib, pkgs, username, ... }:
{
  imports = [
    ./shell.nix
    # Portable modules shared with the Macs.
    ../../nix-darwin/modules/home/git.nix
    ../../nix-darwin/modules/home/bat.nix
    ../../nix-darwin/modules/home/btop.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "26.05";
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Link shared agent instructions and skills (Mac-only settings are skipped).
  home.activation.linkAgents = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.bash}/bin/bash "$HOME/.dotfiles/scripts/link-agents.sh"
  '';
}
