{ pkgs }:
pkgs.writeShellScriptBin "theme-menu" ''
  options="󰸉 Pick Wallpaper\n󱠗 Toggle Mode (Pywal/Cat)\n󰅖 Exit"
  chosen=$(echo -e "$options" | ${pkgs.rofi}/bin/rofi -dmenu -p "Theme Manager")

  case $chosen in
      *"Pick Wallpaper"*) wall-picker ;;
      *"Toggle Mode"*) theme-toggle ;;
      *) exit 0 ;;
  esac
''
