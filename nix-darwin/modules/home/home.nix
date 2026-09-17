{ lib, ... }:
{
  imports = [
    ./shell.nix
    ./git.nix
    ./finder.nix
    ./zed.nix
    ./vscode.nix
    ./ghostty.nix
    ./zellij.nix
    ./btop.nix
    ./bat.nix
    ./vesktop.nix
    ./projects.nix
    ./ssh.nix
  ];

  home.username = "ryanstoffel";
  home.homeDirectory = "/Users/ryanstoffel";
  home.stateVersion = "24.05";
  home.sessionPath = [
    "$HOME/.npm-global/bin"
    "$HOME/.local/bin"
  ];
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Single home for all code projects. No code lives outside ~/Developer.
  home.activation.createDevFolders =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run mkdir -p \
        "$HOME/Developer/personal" \
        "$HOME/Developer/work" \
        "$HOME/Developer/school"
    '';
}
