{ pkgs, ... }:
{
  environment.systemPath = [
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
  ];

  environment.systemPackages = with pkgs; [
    # navigation and search
    ripgrep
    fd
    fzf
    zoxide
    broot

    # file viewing
    # bat is owned by home-manager (modules/home/shell.nix) for its theme.
    eza
    jless

    # git
    lazygit
    delta
    gh
    git-absorb
    difftastic

    # system monitoring
    # btop is owned by home-manager (modules/home/btop.nix) for its theme.
    htop
    procs
    dust
    duf
    bandwhich

    # data manipulation
    jq
    yq
    xh
    hyperfine

    # docs
    tealdeer

    # misc
    tokei
    sd
    watchexec
    python3
    uv

    # dotfiles workflow
    nixpkgs-fmt
    nil

    # Node runtime with npm and npx
    nodejs_22

    # Previously installed in an unmanaged personal Nix profile.
    jdk21
    maven
    postgresql_16

    # secrets management
    gitleaks

    # editors
    vim
    neovim
  ];
}
