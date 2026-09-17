{ pkgs, ... }:
{
  homebrew = {
    enable = true;
    onActivation.autoUpdate = false;
    onActivation.upgrade = false;
    onActivation.cleanup = "uninstall";
    # Custom tap casks during `--force-cleanup`; taps are declared trusted in Nix.
    onActivation.extraEnv = {
      HOMEBREW_NO_REQUIRE_TAP_TRUST = "1";
    };

    taps = [
      {
        name = "ryanstoffel/tap";
        trusted = true;
      }
    ];

    casks = [
      # launcher and productivity
      "raycast"

      # terminal
      "ghostty"

      # dev
      "tailscale-app"
      "visual-studio-code"
      "docker-desktop"
      "claude"
      "claude-code"
      "github"
      "codex"
      "antigravity-cli"
      "cursor"
      "grok-bot"
      "chatgpt"
      "figma"

      # browsers
      "zen"
      "photon"

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
      "mysides"
      "ryanstoffel/tap/caffeine"
      "ryanstoffel/tap/tidy"

      # media
      "spotify"
    ];

    brews = [
      "mas"
      "xcodes"
      "glab"
    ];

    # `mas list` can hang on the App Store service. Already installed bundles
    # should not block unrelated rebuilds; absent apps still install via mas.
    extraConfig = ''
      mas "Windows App", id: 1295203466 unless File.directory?("/Applications/Windows App.app")
      mas "Xcode", id: 497799835 unless File.directory?("/Applications/Xcode.app")
    '';
  };
}
