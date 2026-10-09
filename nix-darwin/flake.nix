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

      # One configuration per machine. Scripts read /etc/dotfiles-host to pick theirs.
      # Shared modules come first; hosts/<host> adds that machine's own settings
      # and Homebrew apps. The ThinkPad (NixOS) has its own flake in ../nixos.
      mkHost = { host, username, laptop }: nix-darwin.lib.darwinSystem {
        inherit system;
        specialArgs = { inherit host username laptop; };
        modules = [
          ./modules/darwin/packages.nix
          ./modules/darwin/homebrew.nix
          ./modules/darwin/system-defaults.nix
          ./modules/darwin/security.nix
          ./modules/darwin/limits.nix
          ./modules/darwin/fonts.nix
          ./modules/darwin/nix-daemon.nix
          ./modules/darwin/desktop.nix
          ./hosts/${host}
          home-manager.darwinModules.home-manager
          {
            environment.etc."dotfiles-host".text = host;
            system.primaryUser = username;
            home-manager.backupFileExtension = "hm-backup";
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { inherit host username laptop; };
            home-manager.users.${username} = import ./modules/home/home.nix;
          }
        ];
      };
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

      darwinConfigurations = {
        macbook = mkHost { host = "macbook"; username = "ryanstoffel"; laptop = true; };
        macmini = mkHost { host = "macmini"; username = "ryan-stoffel"; laptop = false; };
      };
    };
}
