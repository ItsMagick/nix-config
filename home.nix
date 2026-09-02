{
  config,
  pkgs,
  inputs,
  ...
}:

{
  home.username = "charon";
  home.homeDirectory = "/home/charon";
  home.stateVersion = "25.11";
  home.sessionVariables = {
    GTK_THEME = "catppuccin-macchiato-lavender-standard";
    COLORTERM = "truecolor";
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    MOZ_ENABLE_WAYLAND = "1";
    NIXOS_OZONE_WL = "1";
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
    #    vesktop
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
    libreoffice-qt
    zathura
    openvpn
    openfortivpn
    devenv
    clipvault
    mpv
    mpvpaper
    ffmpeg
    inputs.hyprfm.packages.${pkgs.stdenv.hostPlatform.system}.default
    projectm-sdl-rust

  ];

  gtk = {
    enable = true;
    iconTheme = {
      name = "Papirus-Dark";
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-theme-name = "adw-gtk3-dark";
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  qt = {
    enable = true;
    platformTheme.name = "qt6ct";
    style.name = "kvantum";
  };


  imports = [
    ./modules
    ./scripts
  ];
}
