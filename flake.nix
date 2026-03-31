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
    catppuccin.url = "github:catppuccin/nix";

 
  };
  outputs = { nixpkgs, home-manager, zen-browser, catppuccin, ... } @ inputs: {
    nixosConfigurations.TPS = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit inputs;
      };
      modules = [
        ./configuration.nix
        catppuccin.nixosModules.catppuccin
	    home-manager.nixosModules.home-manager
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
	          ];
            };
	      };
	    }
      ];
    };
  };
}
