{ config, lib, ... }:
let
  user = config.system.primaryUser;
in
{
  # Homebrew 4.x requires explicit cask trust for third-party taps during cleanup.
  system.activationScripts.homebrew.text = lib.mkBefore ''
    if [ -x /opt/homebrew/bin/brew ]; then
      echo "Trusting ryanstoffel/tap casks..."
      trust_tap() {
        for tap in ryanstoffel/tap ryanstoffel/taps; do
          "$1" /opt/homebrew/bin/brew trust "$tap" 2>/dev/null || true
        done
        for cask in ryanstoffel/tap/caffeine ryanstoffel/tap/tidy ryanstoffel/taps/caffeine ryanstoffel/taps/tidy; do
          "$1" /opt/homebrew/bin/brew trust --cask "$cask" 2>/dev/null || true
        done
      }
      trust_tap /opt/homebrew/bin/env
      trust_tap "/usr/bin/sudo -u ${user} -H /usr/bin/env"
    fi
  '';
}
