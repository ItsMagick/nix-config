{ pkgs }:
pkgs.writeShellScriptBin "theme-toggle" ''
  STATE_FILE="$HOME/.theme_state"
  [ ! -f "$STATE_FILE" ] && echo "catppuccin" > "$STATE_FILE"
  CURRENT=$(cat "$STATE_FILE")

  if [ "$CURRENT" == "catppuccin" ]; then
      wall-picker
      echo "pywal" > "$STATE_FILE"
  else
      ${pkgs.pywal}/bin/wal --theme catppuccin-macchiato
      echo "catppuccin" > "$STATE_FILE"
      ${pkgs.libnotify}/bin/notify-send "Theme Switched" "Mode: Static Catppuccin"
  fi
''
