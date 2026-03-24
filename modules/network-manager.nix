# /etc/nixos/modules/network-manager.nix
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    networkmanager_dmenu
    networkmanagerapplet 
  ];

  # This creates ~/.config/networkmanager-dmenu/config.ini automatically
  xdg.configFile."networkmanager-dmenu/config.ini".text = ''
    [dmenu]
    # Use Rofi in dmenu mode
    dmenu_command = ${pkgs.rofi}/bin/rofi -dmenu -i
    active_chars = ==
    compact = True
    # Position it like a dropdown
    pinentry = ${pkgs.pinentry-gnome3}/bin/pinentry-gnome3

    [editor]
    terminal = ${pkgs.kitty}/bin/kitty
    gui_if_available = True

    [nmdm]
    # Ensures it uses the correct network manager path
    rescan_delay = 5
  '';
}
