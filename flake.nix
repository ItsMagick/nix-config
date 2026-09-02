{
  description = "Hyprland on Nix";
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
    };
    clipvault-src = {
      url = "github:rolv-apneseth/clipvault";
      flake = false;
    };

    frontend-sdl-rust-src = {
      url = "github:projectM-visualizer/frontend-sdl-rust";
      flake = false;
    };
    projectm-cream-of-the-crop = {
      url = "github:projectM-visualizer/presets-cream-of-the-crop";
      flake = false;
    };
    projectm-milkdrop-texture-pack = {
      url = "github:projectM-visualizer/presets-milkdrop-texture-pack";
      flake = false;
    };

    catppuccin.url = "github:catppuccin/nix";

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";

    hyprfm.url = "github:soyeb-jim285/hyprfm";

  };
  outputs =
    {
      nixpkgs,
      home-manager,
      zen-browser,
      catppuccin,
      matugen,
      spicetify-nix,
      clipvault-src,
      hyprfm,
      frontend-sdl-rust-src,
      projectm-cream-of-the-crop,
      projectm-milkdrop-texture-pack,
      ...
    }@inputs:
    {
      nixosConfigurations.TPS = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = {
          inherit inputs;
        };
        modules = [
          ({ pkgs, ... }: {
            nixpkgs.overlays = [
              (final: prev: {
                clipvault = final.callPackage ./custom/clipvault.nix {
                  inherit clipvault-src;
                };
                projectm-sdl-rust = final.callPackage ./custom/projectm-rust.nix {
                  inherit frontend-sdl-rust-src;
                };
              })
            ];
          })
          ./configuration.nix
          catppuccin.nixosModules.catppuccin
          home-manager.nixosModules.home-manager
          matugen.nixosModules.default
          {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "backup";

              extraSpecialArgs = {
                inherit inputs;
              };
              users.charon = {
                imports = [
                  ./home.nix
                  catppuccin.homeModules.catppuccin
                  spicetify-nix.homeManagerModules.default
                ];
              };
            };
          }
        ];
      };
    };
}
