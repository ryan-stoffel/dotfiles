{
  description = "darwin config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nix-darwin, home-manager, ... }@inputs:
    let
      system = "aarch64-darwin";
      username = "ryanstoffel";
    in
    {
      devShells.${system} =
        let
          pkgs = import nixpkgs { inherit system; };
          shell = packages: pkgs.mkShellNoCC { inherit packages; };
        in
        {
          node = shell [ pkgs.nodejs_22 ];
          python = shell [ pkgs.python312 pkgs.uv pkgs.ruff ];
          rust = shell [ pkgs.cargo pkgs.rustc pkgs.rustfmt pkgs.clippy pkgs.pkg-config ];
          java = shell [ pkgs.jdk21 pkgs.maven ];
          # Apple SDKs and Swift remain owned by the selected Xcode installation.
          swift = shell [ ];
        };

      darwinConfigurations."macbook" = nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          ./modules/darwin/packages.nix
          ./modules/darwin/homebrew.nix
          ./modules/darwin/system-defaults.nix
          ./modules/darwin/security.nix
          ./modules/darwin/limits.nix
          ./modules/darwin/fonts.nix
          home-manager.darwinModules.home-manager
          {
            system.primaryUser = username;
            home-manager.backupFileExtension = "hm-backup";
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${username} = import ./modules/home/home.nix;
          }
        ];
      };
    };
}
