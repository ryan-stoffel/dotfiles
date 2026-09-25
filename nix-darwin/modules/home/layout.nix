{ config, lib, ... }:
let
  home = config.home.homeDirectory;
in
{
  home.activation.createScratchFolders = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "$HOME/Developer/scratch/claude" "$HOME/Developer/scratch/codex"
  '';

  # launchd fires on any entry change in ~; ~/Documents is left to dotfiles-doctor
  # because a background agent would need its own Documents privacy grant.
  launchd.agents.home-guard = {
    enable = true;
    config = {
      ProgramArguments = [ "/bin/bash" "${home}/.dotfiles/scripts/home-guard.sh" ];
      WatchPaths = [ home ];
      RunAtLoad = true;
    };
  };
}
