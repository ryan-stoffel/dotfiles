{
  description = "nixos config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, disko, ... }:
    let
      # One configuration per machine. Shared modules come first; hosts/<host>
      # adds that machine's hardware, disk layout, and settings.
      mkHost = { host, username }: nixpkgs.lib.nixosSystem {
        specialArgs = { inherit host username; };
        modules = [
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager
          ./modules/base.nix
          ./modules/packages.nix
          ./modules/server.nix
          ./hosts/${host}
          {
            networking.hostName = host;
            home-manager.backupFileExtension = "hm-backup";
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit host username; laptop = true; };
            home-manager.users.${username} = import ./home/home.nix;
          }
        ];
      };
    in
    {
      nixosConfigurations = {
        thinkpad = mkHost { host = "thinkpad"; username = "ryan-stoffel"; };
      };
    };
}
