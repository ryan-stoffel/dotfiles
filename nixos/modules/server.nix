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

  # GitHub's published ed25519 host key, so git over SSH never prompts.
  programs.ssh.knownHosts."github.com".publicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

  # Keep running with the lid closed, on battery or AC, and never auto-suspend.
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
    IdleAction = "ignore";
  };
}
