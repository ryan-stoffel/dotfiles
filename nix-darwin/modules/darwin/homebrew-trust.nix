{ config, lib, ... }:
let
  user = config.system.primaryUser;
  trustJson = builtins.toJSON {
    trustedtaps = [ "ryanstoffel/tap" "ryanstoffel/taps" ];
    trustedcasks = [
      "ryanstoffel/tap/caffeine"
      "ryanstoffel/tap/tidy"
      "ryanstoffel/taps/caffeine"
      "ryanstoffel/taps/tidy"
    ];
  };
in
{
  # Runs before the Homebrew activation script (see nix-darwin activation order).
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
