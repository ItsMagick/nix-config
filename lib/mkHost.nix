{ inputs, nixpkgs, home-manager, system }:

# mkHost assembles one nixosConfiguration from:
#   - hosts/<hostname>/configuration.nix   (machine-specific facts/overrides)
#   - hosts/<hostname>/hardware-configuration.nix
#   - modules/nixos/*.nix                  (shared, reusable system behavior)
#   - Home Manager, wired per-user from users/<user>.nix
#
# A host does NOT need to hand-import every shared module below -
# common.nix and hyprland.nix are applied to every host by default.

{ hostname
, extraModules ? [ ]
, users ? { }
}:

let
  sharedModules = [
    ../modules/nixos/common.nix
    ../modules/nixos/hyprland.nix
  ];

  homeManagerUsers = builtins.mapAttrs (_: path: import path) users;
in
nixpkgs.lib.nixosSystem {
  inherit system;
  specialArgs = { inherit inputs; };

  modules = sharedModules ++ extraModules ++ [
    ../hosts/${hostname}/configuration.nix
    ../hosts/${hostname}/hardware-configuration.nix

    home-manager.nixosModules.home-manager
    {
      home-manager.useGlobalPkgs = true;
      home-manager.useUserPackages = true;
      home-manager.extraSpecialArgs = { inherit inputs; };
      home-manager.users = homeManagerUsers;
      home-manager.backupFileExtension = "hm-backup";
    }

    { networking.hostName = hostname; }
  ];
}
