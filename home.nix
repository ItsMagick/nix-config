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


  imports = [
    ./modules
    ./scripts
  ];
}
