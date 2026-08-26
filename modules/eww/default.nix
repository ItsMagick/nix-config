{ pkgs, config, ... }:

{
  home.packages = with pkgs; [ 
    jq
    socat 
    pamixer 
    brightnessctl
    acpi
    iw
    bluez
    libnotify
    networkmanager
    lm_sensors
    bc
    pulseaudio
    ladspaPlugins
    ladspa-sdk
    imagemagick
  ];

  xdg.configFile."awww".source = config.lib.file.mkOutOfStoreSymlink (toString ./.);
}
