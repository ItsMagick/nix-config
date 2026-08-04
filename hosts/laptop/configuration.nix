{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  system.stateVersion = "25.11";

  networking = {
    hostName = "TPS"; 
    networkmanager.enable = true;
  };

  services = {
    upower.enable = true;
    blueman.enable = true;

  };

  hardware = {
    bluetooth = {
      enable = true;
      powerOnBoot = true;
      settings = {
        General = {
          Enable = "Source,Sink,Media,Socket";
          Experimental = true;
          AutoConnect = true;
          FastConnectable = true;
        };
      };
    };
  };
}
