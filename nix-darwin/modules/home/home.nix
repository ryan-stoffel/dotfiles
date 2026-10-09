{ lib, username, ... }:
{
  imports = [
    ./shell.nix
    ./git.nix
    ./finder.nix
    ./vscode.nix
    ./ghostty.nix
    ./btop.nix
    ./bat.nix
    ./vesktop.nix
    ./projects.nix
    ./ssh.nix
    ./layout.nix
    ./syncthing.nix
  ];

  home.username = username;
  home.homeDirectory = "/Users/${username}";
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
