{ pkgs, ... }:
{
  homebrew = {
    enable = true;
    onActivation.autoUpdate = false;
    onActivation.upgrade = false;
    onActivation.cleanup = "uninstall";

    taps = [
      {
        name = "FelixKratz/formulae";
        trusted = true;
      }
      {
        name = "can1357/tap";
        trusted = true;
      }
      {
        name = "ryanstoffel/tap";
        trusted = true;
      }
    ];

    casks = [
      # launcher and productivity
      "raycast"

      # terminal
      "cmux"

      # dev
      "tailscale-app"
      "visual-studio-code"
      "docker-desktop"
      "claude"
      "claude-code"
      "github"
      "codex"
      "antigravity-cli"
      "hermes-desktop"

      # latex
      "mactex-no-gui"

      # browsers
      "zen"

      # communication
      "zoom"
      "microsoft-teams"
      "slack"
      "vesktop"

      # notes
      "obsidian"
      "notion"
      "granola"

      # utilities
      "1password"
      "1password-cli"
      "alt-tab"
      "atoll"
      "ryanstoffel/tap/caffeine"
      "ryanstoffel/tap/tidy"

      # media
      "spotify"
      "gamehub"
    ];

    brews = [
      "mas"
      { name = "ollama"; start_service = true; }
      "xcodes"
      "glab"
      "omp"
      "tmux"
      "herdr"
      "hermes-agent"
    ];

    # `mas list` can hang on the App Store service. Already installed bundles
    # should not block unrelated rebuilds; absent apps still install via mas.
    extraConfig = ''
      mas "Windows App", id: 1295203466 unless File.directory?("/Applications/Windows App.app")
      mas "Xcode", id: 497799835 unless File.directory?("/Applications/Xcode.app")
    '';
  };
}
