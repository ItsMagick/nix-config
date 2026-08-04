{ pkgs, ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Keep the store tidy automatically instead of remembering to gc by hand
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  networking.networkmanager.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
  ];
  console.keyMap = "de";

  virtualisation.docker = {
    enable = true;
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
    kernelPackages = pkgs.linuxPackages_latest;
  };

  # Adjust to your actual login user(s); kept here so both hosts agree
  users.users.charon = {
    isNormalUser = true;
    description = "Charon";
    extraGroups = [ "networkmanager" "wheel" "video" "lp" "docker" "bluetooth"];
    packages = with pkgs; [];
    shell = pkgs.zsh;

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
  flatpak.enable = true;

  hardware = {
    enableAllFirmware = true;
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    wget
    git
    firefox
    rofi
    hyprpaper
    cryptsetup
    bluez
  ];

  security.pam.services.swaylock = {};

  services = {
    dbus.enable = true;

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
        libappindicator-gtk2
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

}
