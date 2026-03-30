{ pkgs, ... }:

{
  imports = [
    ./hyprland.nix
    ./kitty.nix
    ./zsh.nix
    ./waybar.nix
    ./rofi.nix
    ./swayidle.nix
    ./network-manager.nix
    ./catppuccin.nix
    ./nvim.nix
    ./eww/default.nix
    ./matugen/default.nix

  ];
}
