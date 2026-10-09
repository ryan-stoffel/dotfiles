# Command-line tools for development over SSH.
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # terminfo for SSH from Ghostty
    ghostty.terminfo

    # sessions that survive disconnects
    tmux
    mosh

    # navigation and search
    ripgrep
    fd
    fzf
    zoxide

    # file viewing
    eza
    jless

    # git
    lazygit
    delta
    gh
    git-absorb

    # system monitoring
    htop
    procs
    dust
    duf

    # data manipulation
    jq
    yq
    xh

    # misc
    tealdeer
    tokei
    sd
    watchexec

    # coding agents
    claude-code
    codex

    # agent sandboxing
    bubblewrap
    socat

    # languages
    python3
    uv
    nodejs_22
    jdk21
    maven
    postgresql_16

    # dotfiles workflow
    nixpkgs-fmt
    nil
    gitleaks

    # editors
    vim
    neovim
  ];

  virtualisation.docker.enable = true;
}
