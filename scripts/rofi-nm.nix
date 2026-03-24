{ pkgs }:

pkgs.writeShellScriptBin "rofi-network" ''
  # Use networkmanager_dmenu with your existing Rofi theme
  # We use the -theme-str to make it look like a dropdown
  ${pkgs.networkmanager_dmenu}/bin/networkmanager_dmenu \
    -conf /dev/null \
    -theme-str 'window { width: 20%; } listview { lines: 10; }'
''
