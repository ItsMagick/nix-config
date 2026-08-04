{
  description = "NixOS with clean home-home manager and multi user/host setup";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    matugen = {
      url = "github:/InioX/Matugen";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin = {
      url = "github:catppuccin/nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... } @ inputs:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      mkHost = import ./lib/mkHost.nix { inherit inputs nixpkgs home-manager system; };
    in {
      nixosConfigurations = {
        TPS = mkHost {
          hostname = "TPS";
          extraModules = [
            ./hosts/laptop/power-management.nix
          ];
          users = {
            charon = ./users/charon.nix;
          };
        };
        desktop = mkHost {
          hostname = "desktop";
          extraModules = [];
          users = {
            charon = ./users/charon.nix;
          };
        };
      };
      home.Configurations = {
        "charon@TPS" = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          extraSpecialArgs = { inherit inputs; };
          modules = [ ./users/charon.nix ];
        };
      };
    };
}
