{ host, ... }:
let
  dotfiles = "$HOME/.dotfiles";
  flake = "${dotfiles}/nixos#${host}";
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

      rebuild = "sudo nixos-rebuild switch --flake ${flake}";
      dbuild = "nixos-rebuild build --flake ${flake}";
      dup = "nix flake update --flake ${dotfiles}/nixos";
      dgc = "sudo nix-collect-garbage --delete-older-than 14d";
    };
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
