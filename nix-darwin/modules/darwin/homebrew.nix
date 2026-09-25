{ config, lib, pkgs, ... }:
let
  user = config.system.primaryUser;
  trustJson = builtins.toJSON {
    trustedtaps = [ "ryan-stoffel/taps" ];
    trustedcasks = [
      "ryan-stoffel/taps/caffeine"
      "ryan-stoffel/taps/tidy"
      "ryan-stoffel/taps/auto-peer-evals"
    ];
  };
in
{
  homebrew = {
    enable = true;
    onActivation.autoUpdate = false;
    onActivation.upgrade = false;
    onActivation.cleanup = "uninstall";
    onActivation.extraEnv = {
      HOMEBREW_NO_ENV_HINTS = "1";
    };

    taps = [
      {
        name = "ryan-stoffel/taps";
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
      "figma"

      # microsoft office
      "microsoft-word"
      "microsoft-excel"
      "microsoft-powerpoint"

      # browsers
      "zen"
      "helium-browser"
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
      "ryan-stoffel/taps/caffeine"
      "ryan-stoffel/taps/tidy"
      "ryan-stoffel/taps/auto-peer-evals"
      "shottr"

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

  system.activationScripts.preActivation.text = lib.mkAfter ''
    user="${user}"
    user_home=$(/usr/bin/dscl . -read "/Users/$user" NFSHomeDirectory 2>/dev/null | /usr/bin/awk 'NF==2 {print $2}')
    user_home="''${user_home:-/Users/$user}"
    trust_json='${trustJson}'

    for home in "$user_home" /var/root; do
      /bin/mkdir -p "$home/.homebrew"
      printf '%s\n' "$trust_json" > "$home/.homebrew/trust.json"
    done
    /usr/sbin/chown -R "$user":staff "$user_home/.homebrew"
  '';
}
