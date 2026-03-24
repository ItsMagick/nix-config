{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
    ];

  system.stateVersion = "25.11"; 

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };



  networking = {
    hostName = "TPS"; 
    networkmanager.enable = true;
  };

  time.timeZone = "Europe/Berlin";

  i18n = {

    defaultLocale = "en_US.UTF-8";

    extraLocaleSettings = {
      LC_ADDRESS = "de_DE.UTF-8";
      LC_IDENTIFICATION = "de_DE.UTF-8";
      LC_MEASUREMENT = "de_DE.UTF-8";
      LC_MONETARY = "de_DE.UTF-8";
      LC_NAME = "de_DE.UTF-8";
      LC_NUMERIC = "de_DE.UTF-8";
      LC_PAPER = "de_DE.UTF-8";
      LC_TELEPHONE = "de_DE.UTF-8";
      LC_TIME = "de_DE.UTF-8";
    };
  };
  services = {
    upower.enable = true;
    dbus.enable = true;
    blueman.enable = true;
 
    xserver.xkb = {
      layout = "de";
      variant = "";
    };
     
    displayManager = {
      defaultSession = "hyprland";

      sddm = {
        enable = true;
        wayland.enable = true;
      };
    
      autoLogin = {
        enable = true;
        user = "charon";
      };
    };
     
    pipewire = {
      enable = true;
      alsa = {
        enable = true;
        support32Bit = true;
      };
      pulse.enable = true;
      wireplumber.enable = true;
    };
  };


  programs = {
    hyprland = {
      enable = true; 
    };
    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc
        zlib
        fuse3
        icu
        nss
        openssl
        curl
        expat
      ];
    };

    zsh.enable = true;
  };
  console.keyMap = "de";
 
   users.users.charon = {
    isNormalUser = true;
    description = "Charon";
    extraGroups = [ "networkmanager" "wheel" "video" "lp" "docker"];
    packages = with pkgs; [];
    shell = pkgs.zsh;
  };
 
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    neovim
    wget
    git
    firefox
    zathura
    rofi
    hyprpaper
    cryptsetup
    bluez
  ];

  nix.settings.experimental-features = ["nix-command" "flakes"];

  
 
  fonts = {
    packages = with pkgs; [
      nerd-fonts.fira-code

    ];
  };

  virtualisation.docker.enable = true;
  security.pam.services.swaylock = {};

}
