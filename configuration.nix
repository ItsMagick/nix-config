{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./security
  ];

  system.stateVersion = "25.11";
  boot.kernelPackages = import ./security/linux-hardened.nix { inherit pkgs lib; };

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
#    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "uvcvideo" "amdgpu" ];
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
    fwupd.enable = true;
    upower.enable = true;
    dbus.enable = true;
    blueman.enable = true;

    gvfs.enable = true;

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
        STOP_CHARGE_THRESH_BAT0 = 80; # 80 and above it stops charging
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
        SDL
        SDL2
        SDL2_image
        SDL2_mixer
        SDL2_ttf
        SDL_image
        SDL_mixer
        SDL_ttf
        alsa-lib
        at-spi2-atk
        at-spi2-core
        atk
        bzip2
        cairo
        cups
        curlWithGnuTls
        dbus
        dbus-glib
        desktop-file-utils
        e2fsprogs
        expat
        flac
        fontconfig
        freeglut
        freetype
        fribidi
        fuse
        fuse3
        gdk-pixbuf
        glew_1_10
        glib
        gmp
        gst_all_1.gst-plugins-base
        gst_all_1.gst-plugins-ugly
        gst_all_1.gstreamer
        gtk2
        harfbuzz
        icu
        keyutils.lib
        libGL
        libGLU
        libappindicator-gtk3
        libcaca
        libcanberra
        libcap
        libclang.lib
        libdbusmenu
        libdrm
        libgcrypt
        libgpg-error
        libidn
        libjack2
        libjpeg
        libmikmod
        libogg
        libpng12
        libpulseaudio
        librsvg
        libsamplerate
        libthai
        libtheora
        libtiff
        libudev0-shim
        libusb1
        libuuid
        libvdpau
        libvorbis
        libvpx
        libxcrypt-legacy
        libxkbcommon
        libxml2
        mesa
        nspr
        nss
        openssl
        p11-kit
        pango
        pixman
        python3
        speex
        stdenv.cc.cc
        tbb
        udev
        vulkan-loader
        wayland
        libice
        libsm
        libx11
        libxscrnsaver
        libxcomposite
        libxcursor
        libxdamage
        libxext
        libxfixes
        libxft
        libxi
        libxinerama
        libxmu
        libxrandr
        libxrender
        libxt
        libxtst
        libxxf86vm
        libpciaccess
        libxcb
        xcbutil
        xcbutilimage
        xcbutilkeysyms
        xcbutilrenderutil
        xcbutilwm
        xkeyboardconfig
        xz
        zlib
      ];
    };

    zsh.enable = true;
  };
  console.keyMap = "de";
  users.users.charon = {
    isNormalUser = true;
    description = "Charon";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "camera"
      "lp"
      "docker"
      "bluetooth"
    ];
    packages = with pkgs; [ ];
    shell = pkgs.zsh;
  };

  nixpkgs.config.allowUnfree = true;

  environment = {
    systemPackages = with pkgs; [
      wget
      git
      firefox
      rofi
      hyprpaper
      cryptsetup
      bluez
    ];
    sessionVariables = {
      AMD_DEBUG = "nodcc";
    };
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  fonts = {
    packages = with pkgs; [
      nerd-fonts.fira-code
    ];
  };

  virtualisation.docker.enable = true;
  security.pam.services.swaylock = { };

  ### Remove all builds older than 14 days on a daily basis
  nix.gc = {
    automatic = true;
    dates = "daily";
    options = "--delete-older-than 14d";
  };
  hardware = {
    enableAllFirmware = true;
    enableAllHardware = true;
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
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        mesa
        libva
      ];
    };
  };
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 32 * 1024;
    }
  ];
  powerManagement.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = [
          "hyprland"
          "gtk"
        ];
      };
      hyprland = {
        default = [
          "hyprland"
          "gtk"
        ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };
    };
  };
}
