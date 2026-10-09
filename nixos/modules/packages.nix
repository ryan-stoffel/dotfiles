# Command-line tools for development over SSH.
{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
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

    # languages
    python3
    uv
    nodejs_22

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
