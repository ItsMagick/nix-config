{ ... }:
{
  imports = [
    ./audio.nix
    ./bluetooth.nix
    ./boot.nix
    ./firmware.nix
    ./flatpak.nix
    ./fonts.nix
    ./locale.nix
    ./networking.nix
    ./nix-ld.nix
    ./nix-settings.nix
    ./system-packages.nix
    ./upower.nix
    ./virtualisation.nix
  ];
}