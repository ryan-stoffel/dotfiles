# ThinkPad: headless dev server.
{ lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];

  nixpkgs.hostPlatform = "x86_64-linux";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  zramSwap.enable = true;

  # Set to the NixOS release this machine was first installed with. Never bump it.
  system.stateVersion = "26.05";
}
