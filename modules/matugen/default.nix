{ config, pkgs, lib, ... }:

{ 
  xdg.configFile."matugen".source = config.lib.file.mkOutOfStoreSymlink (toString ./.);
}
