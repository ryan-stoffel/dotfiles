# Nix settings, locale, and the user account.
{ pkgs, username, ... }:
{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" username ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  time.timeZone = "America/Los_Angeles";
  i18n.defaultLocale = "en_US.UTF-8";

  users.users.${username} = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
    shell = pkgs.zsh;
    # Public keys only. install.sh fills this from github.com/ryan-stoffel.keys.
    openssh.authorizedKeys.keyFiles = [ ../hosts/thinkpad/authorized_keys ];
  };

  programs.zsh.enable = true;
}
