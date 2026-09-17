{ ... }:
{
  system.defaults.CustomUserPreferences = {
    "com.apple.screensaver" = {
      askForPassword = 1;
      askForPasswordDelay = 0;
    };
  };

  security.pam.services.sudo_local.touchIdAuth = true;

  system.defaults.loginwindow = {
    GuestEnabled = false;
    # Username + password field instead of clicking a user tile.
    SHOWFULLNAME = false;
  };

  networking.applicationFirewall = {
    enable = true;
    blockAllIncoming = false;
    allowSignedApp = true;
    enableStealthMode = true;
  };
}
