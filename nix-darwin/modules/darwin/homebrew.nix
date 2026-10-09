# Homebrew settings and apps shared by every Mac. Per-machine apps live in
# hosts/<host>/homebrew.nix and are appended to these lists.
{ config, lib, pkgs, ... }:
let
  user = config.system.primaryUser;
  trustJson = builtins.toJSON {
    trustedtaps = [ "ryan-stoffel/taps" "youssofal/mtplx" ];
    trustedcasks = [
      "ryan-stoffel/taps/caffeine"
      "ryan-stoffel/taps/tidy"
      "ryan-stoffel/taps/auto-peer-evals"
      "ryan-stoffel/taps/hush"
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
      {
        name = "youssofal/mtplx";
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
      "claude-code@latest"
      "github"
      "codex"
      "t3-code@nightly"
      "antigravity-cli"
      "cursor"
      "grok-bot"
      "chatgpt"
      "figma"

      # browsers
      "zen"
      "helium-browser"
      "photon"

      # communication
      "zoom"
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
      "ryan-stoffel/taps/hush"
      "shottr"
      "syncthing-app"

      # media
      "spotify"
    ];

    brews = [
      "mas"
      "xcodes"
      "glab"
      "youssofal/mtplx/mtplx"
    ];

    # `mas list` can hang on the App Store service. Already installed bundles
    # should not block unrelated rebuilds; absent apps still install via mas.
    extraConfig = ''
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
