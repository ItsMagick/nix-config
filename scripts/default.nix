{ pkgs, ... }: {
  home.packages = [
    (import ./window-title.nix { inherit pkgs; })
    (import ./lock.nix { inherit pkgs; })
  ];
  xdg.configFile = {
    "hypr/scripts/usb.sh".source = ./usb.sh;
    "hypr/scripts/volume.sh".source = ./volume.sh;
    "hypr/scripts/brightness.sh".source = ./brightness.sh;
    "hypr/scripts/bluetooth_mgr.sh".source = ./bluetooth_mgr.sh;
    "hypr/scripts/audio_devices.sh".source = ./audio_devices.sh;
    "hypr/scripts/display_info.sh".source = ./display_info.sh;
  };
}
