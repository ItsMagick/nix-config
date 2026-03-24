{ pkgs, ... }:

{
  home.packages = [
    (import ./wall-picker.nix { inherit pkgs; })
    (import ./theme-toggle.nix { inherit pkgs; })
    (import ./theme-menu.nix { inherit pkgs; })
    (import ./window-title.nix { inherit pkgs; })
    (import ./lock.nix {inherit pkgs; })
    (import ./rofi-nm.nix {inherit pkgs; })
  ];
}
