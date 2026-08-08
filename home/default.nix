{ pkgs, ... }:

{
  imports = [
    ./spicetify.nix
    ./hyprland.nix
    ./kitty.nix
    ./zsh.nix
    ./waybar.nix
    ./rofi.nix
    ./swayidle.nix
    ./network-manager.nix
    ./nvim.nix
    ./eww/default.nix
    ./matugen/default.nix
    ./quickshell-symlinks.nix
    ./direnv.nix
  ];
}
