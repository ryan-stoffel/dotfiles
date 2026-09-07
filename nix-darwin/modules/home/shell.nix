{ pkgs, lib, ... }:
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
      rebuild = "just --justfile ~/.dotfiles/Justfile rebuild";
      lg = "lazygit";
      cd = "z";
      dots = "cd ~/.dotfiles";
      sshvm = "TERM=xterm-256color ssh vm";
      ai = "omp";
      tdev = "$HOME/.local/bin/tmux-dev";
      tp = "$HOME/.local/bin/tmux-project";
      t = "$HOME/.local/bin/tmux-project";
      zj = "zellij";
      zdev = "zellij -s dev -n dev";
      h = "herdr";
      hp = "$HOME/.local/bin/herdr-project";
      p = "$HOME/.local/bin/project";

    } // lib.mapAttrs (_: target: "project open " + lib.escapeShellArg target)
      (builtins.fromTOML (builtins.readFile ../../../projects/config.toml)).aliases;
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      # Layout and glyphs only. Module colors are starship's defaults.
      format = "$directory$git_branch$git_status$cmd_duration$character";
      # Stock caret is a heavy angle quote; ">" is a plain ASCII caret. Green
      # and red are starship's own success/error colors.
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
