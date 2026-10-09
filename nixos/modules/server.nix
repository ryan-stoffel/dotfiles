# Headless access: SSH, Tailscale, and a laptop that ignores its lid.
{ ... }:
{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  services.tailscale.enable = true;
  networking.firewall = {
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPortRanges = [{ from = 60000; to = 61000; }]; # mosh
  };

  networking.networkmanager.enable = true;

  # Keep running with the lid closed, on battery or AC, and never auto-suspend.
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
    IdleAction = "ignore";
  };
}
