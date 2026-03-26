{ pkgs }:

pkgs.writeShellScriptBin "lock-screen" ''
  ${pkgs.swaylock-effects}/bin/swaylock \
    --image "$HOME/Pictures/wallpapers/lockscreen.jpg" \
    --clock \
    --indicator \
    --indicator-radius 100 \
    --indicator-thickness 7 \
    --ring-color bb4444 \
    --key-hl-color 880033 \
    --text-color ffffff \
    --inside-color 00000088 \
    --fade-in 0.2 \
    --datestr "%A, %d %B" \
    --timestr "%H:%M"
''
