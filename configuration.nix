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
    kernelParams = [
      "resume_offset=72464384"
      "mem_sleep_default=deep"
    ];
    resumeDevice = "/dev/disk/by-uuid/e8491619-1594-4fd3-9ae6-6e81ab1bb6c2";
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

    flatpak.enable = true;
    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 20;

        # Optional helps save long term battery health
        START_CHARGE_THRESH_BAT0 = 40; # 40 and below it starts to charge
        STOP_CHARGE_THRESH_BAT0 = 80;  # 80 and above it stops charging
      };
    };
    logind = {
      settings = {
        Login = {
          LidSwitch = "suspend-then-hibernate";
          PowerKey = "hibernate";
          PowerKeyLongPress = "poweroff";
        };
      };
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
    extraGroups = [ "networkmanager" "wheel" "video" "lp" "docker" "bluetooth"];
    packages = with pkgs; [];
    shell = pkgs.zsh;
  };
 
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
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

### Remove all builds older than 14 days on a daily basis
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 14d";
  };
  hardware = {
    enableAllFirmware = true;
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
  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 32*1024; 
  }];
  powerManagement.enable = true;
}
