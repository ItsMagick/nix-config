{ pkgs }:

pkgs.writeShellScriptBin "lock-screen" ''
  # If you have a specific wallpaper, blur it once and save it
  # Or just use a solid color/simple image to save CPU
  ${pkgs.swaylock-effects}/bin/swaylock \
    --image ~/Pictures/Wallpapers/blurred_lock.png \
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
