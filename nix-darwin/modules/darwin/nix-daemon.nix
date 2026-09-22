{ lib, ... }:
{
  # nix-darwin's own activation sometimes bootouts nix-daemon to swap in a new
  # store path and then fails to bootstrap it back (seen 2026-09-20, 2026-09-22:
  # rebuild fails with "could not connect to any lix socket"). Verify it's
  # actually loaded after every activation and re-bootstrap if not.
  system.activationScripts.postActivation.text = lib.mkAfter ''
    if ! /bin/launchctl print system/org.nixos.nix-daemon >/dev/null 2>&1; then
      echo "nix-daemon not loaded after activation; bootstrapping..."
      /bin/launchctl bootstrap system /Library/LaunchDaemons/org.nixos.nix-daemon.plist || true
    fi
  '';
}
