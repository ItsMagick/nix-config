{ pkgs }:
pkgs.writeShellScriptBin "wall-picker" ''
  WALLP_DIR="$HOME/Pictures/wallpapers"
  [ ! -d "$WALLP_DIR" ] && mkdir -p "$WALLP_DIR"

  selection=$(ls "$WALLP_DIR" | ${pkgs.rofi}/bin/rofi -dmenu -p "Select Wallpaper")

  if [ ! -z "$selection" ]; then
      ${pkgs.pywal}/bin/wal -i "$WALLP_DIR/$selection"
      ${pkgs.swww}/bin/swww img "$WALLP_DIR/$selection" --transition-type outer
      ${pkgs.libnotify}/bin/notify-send "Theme Updated" "Colors generated from $selection"
  fi
''
