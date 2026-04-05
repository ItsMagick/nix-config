#!/usr/bin/env zsh
set -ex
MODE=${1:-drun}
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
ROFI_THEME="$CONFIG_HOME/rofi/matugen.rasi"

if [[ ! -f "$ROFI_THEME" ]] && command -v matugen >/dev/null 2>&1; then
    WALLPAPER=""

    if command -v awww >/dev/null 2>&1; then
        WALLPAPER=$(awww query 2>/dev/null | grep -o "$HOME/[^ ]*\(jpg\|jpeg\|png\|webp\|gif\|mp4\|mkv\|mov\|webm\)" | head -n1)
    fi

    if [[ -z "$WALLPAPER" ]] && command -v pgrep >/dev/null 2>&1; then
        WALLPAPER=$(pgrep -a mpvpaper 2>/dev/null | sed -n "s/.* '\([^']*\)'.*/\1/p" | head -n1)
    fi

    if [[ -n "$WALLPAPER" && -f "$WALLPAPER" ]]; then
        matugen image "$WALLPAPER" >/dev/null 2>&1
    fi
fi

if pgrep -x "rofi" > /dev/null; then
    pkill rofi
else
    rofi -show "$MODE" -theme "$ROFI_THEME"
fi
