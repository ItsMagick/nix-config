{ pkgs, ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Keep the store tidy automatically instead of remembering to gc by hand
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  networking.networkmanager.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
  ];

  virtualisation.docker = {
    enable = true;
  };

  # Adjust to your actual login user(s); kept here so both hosts agree
  users.users.charon = {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" "docker" ];
  };

  system.stateVersion = "25.11";
}
