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
  };
}
