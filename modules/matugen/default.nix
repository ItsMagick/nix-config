{ config, pkgs, lib, ... }:

{ 
  xdg.configFile."matugen".source = config.lib.file.mkOutOfStoreSymlink "/home/Documents/nix-config/modules/matugen";
}
