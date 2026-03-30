{config, pkgs, inputs, ...}:

{
  home.username = "charon";
  home.homeDirectory = "/home/charon";
  home.stateVersion = "25.11";
  home.sessionVariables = {
    GTK_THEME = "catppuccin-macchiato-lavender-standard";
    COLORTERM = "truecolor";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };
  home.pointerCursor =
  let
    getFrom = url: hash: name: {
      gtk.enable = true;
      x11.enable = true;
      name = name;
      size = 24;
      package =
        pkgs.runCommand "moveUp" {} ''
          mkdir -p $out/share/icons
          ln -s ${pkgs.fetchzip {
            url = url;
            hash = hash;
          }}/dist $out/share/icons/${name}
        '';
      };
  in
    getFrom
      "https://github.com/yeyushengfan258/ArcMidnight-Cursors/archive/refs/heads/main.zip"
      "sha256-VgOpt0rukW0+rSkLFoF9O0xO/qgwieAchAev1vjaqPE="
      "ArcMidnight-Cursors";

    dconf.settings = {
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        gtk-theme = "adw-gtk3-dark";
      };
    };

  services.easyeffects.enable = true;

  home.packages = with pkgs; [
    glib
    kitty
    maestral
    maestral-gui
    vesktop
    spotify
    spicetify-cli
    zotero
    keepassxc
    inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
    grim
    slurp
    wl-clipboard
    brightnessctl
    jetbrains-toolbox
    pywal
    swww
    imagemagick
    swaynotificationcenter
    playerctl
    jq
    swaylock-effects
    swayidle
    btop
    networkmanager_dmenu
    networkmanagerapplet
    quickshell
    tree
  ];
    
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    settings = {
      monitor = [
        "eDP-1, 1920x1080@59.98, 0x0, 1"
        "HDMI-A-1, preferred, auto, 1" 
      ];
      input = {
        kb_layout = "de";
      };
    };
  };

    gtk = {
      enable = true;
      # Global `theme` block has been entirely removed to protect GTK4 apps.
      # Target GTK3 specifically
      gtk3.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
        gtk-theme-name = "adw-gtk3-dark";
      };
      # Keep GTK4 native but ensure it requests the dark preference
      gtk4.extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
    };

    qt = {
        enable = true;
        platformTheme.name = "qt6ct";
      };
      xdg.portal = {
        enable = true;
        extraPortals = with pkgs; [
          xdg-desktop-portal-gtk
        ];
        config.common.default = "*";
      };

  imports = [
    ./modules
    ./scripts
  ];
}
