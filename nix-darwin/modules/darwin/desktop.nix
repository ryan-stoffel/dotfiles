{ lib, laptop, ... }:
{
  # Desktop Macs stay reachable (SSH, Tailscale, Docker) and come back on their own
  # after an outage. Laptops keep macOS's battery-aware defaults.
  config = lib.mkIf (!laptop) {
    power.sleep.computer = "never";
    power.sleep.display = 15;
    power.restartAfterPowerFailure = true;
    power.restartAfterFreeze = true;
  };
}
