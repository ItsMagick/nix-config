{ pkgs, ... }:

{
  home.packages = [
    (import ./window-title.nix { inherit pkgs; })
    (import ./lock.nix {inherit pkgs; })
  ];
}
