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

    socat
    bc
    pulseaudio
    ladspaPlugins
    ladspa-sdk
    imagemagick
  ];

  xdg.configFile."eww".source = config.lib.file.mkOutOfStoreSymlink (toString ../..);
}
