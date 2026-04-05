{config, pkgs, inputs, ...}:

{
  home.username = "charon";
  home.homeDirectory = "/home/charon";
  home.stateVersion = "26.05";
  home.sessionVariables = {
    GTK_THEME = "catppuccin-macchiato-lavender-standard";
    COLORTERM = "truecolor";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };
  home.pointerCursor = {
    x11.enable = true;
    package = pkgs.catppuccin-cursors.macchiatoLavender;
    name = "catppuccin-macchiato-lavender-cursors";
    size = 24;
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
    awww
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
    matugen
  ];

    gtk = {
      enable = true;
      iconTheme = {
        name = "Papirus-Dark";
      };
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
        style.name = "kvantum";
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
