{ pkgs, lib, ... }:
let
  dotfiles = "$HOME/.dotfiles";
  flake = "${dotfiles}/nix-darwin#macbook";
in
{
  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;

    syntaxHighlighting.enable = true;
    history.size = 50000;
    shellAliases = {
      ls = "eza --icons";
      ll = "eza -la --icons";
      cat = "bat";
      lg = "lazygit";
      cd = "z";
      dots = "cd ~/.dotfiles";
      sshvm = "TERM=xterm-256color ssh vm";
      zj = "zellij";
      zdev = "zellij -s dev -n dev";
      p = "$HOME/.local/bin/project";

      rebuild = "${dotfiles}/scripts/rebuild.sh";
      dbuild = "darwin-rebuild build --flake ${flake}";
      dup = "nix flake update --flake ${dotfiles}/nix-darwin";
      dgc = "sudo nix-collect-garbage --delete-older-than 14d && nix-collect-garbage --delete-older-than 14d";
      ddoctor = "python3 ${dotfiles}/scripts/doctor.py";
      dtui = "python3 ${dotfiles}/scripts/tui.py";
      dcheck = "python3 -B -m unittest discover -s ${dotfiles}/tests -v && git -C ${dotfiles} diff --check";
      dbrew = "brew update && brew upgrade";
      dext = "python3 ${dotfiles}/scripts/vscode-extensions.py --prune";
      dscan = "gitleaks git ${dotfiles} --redact --gitleaks-ignore-path ${dotfiles}/.gitleaksignore && gitleaks dir ${dotfiles} --redact";
      dbootstrap = "${dotfiles}/scripts/bootstrap.sh";

    } // lib.mapAttrs (_: target: "project open " + lib.escapeShellArg target)
      (builtins.fromTOML (builtins.readFile ../../../projects/config.toml)).aliases;
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$character";
      character.success_symbol = "[>](bold green)";
      character.error_symbol = "[>](bold red)";
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f";
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };
}
