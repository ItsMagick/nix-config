{
  pkgs,
  config,
  ...
}:
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

  # home.nix or eww.nix
  xdg.configFile = {
    # Root eww files
    "eww/eww.yuck".source = ./new-eww/eww.yuck;
    "eww/eww.scss".source = ./new-eww/eww.scss;

    # Sub-popup files
    "eww/popups/brightness/eww.yuck".source = ./new-eww/popups/brightness/eww.yuck;
    "eww/popups/brightness/eww.scss".source = ./new-eww/popups/brightness/eww.scss;

    "eww/popups/volume/eww.yuck".source = ./new-eww/popups/volume/eww.yuck;
    "eww/popups/volume/eww.scss".source = ./new-eww/popups/volume/eww.scss;

    "eww/popups/usb/eww.yuck".source = ./new-eww/popups/usb/eww.yuck;
    "eww/popups/usb/eww.scss".source = ./new-eww/popups/usb/eww.scss;

    "eww/popups/bluetooth/eww.yuck".source = ./new-eww/popups/bluetooth/eww.yuck;
    "eww/popups/bluetooth/eww.scss".source = ./new-eww/popups/bluetooth/eww.scss;
  };
}
