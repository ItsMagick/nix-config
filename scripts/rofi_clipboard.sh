#!/usr/bin/env zsh
set -ex
ROFI_THEME="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/matugen.rasi"

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
    cliphist list | rofi -dmenu \
    -p "Clipboard" \
    -theme "$ROFI_THEME" \
    -theme-str 'listview { columns: 1; spacing: 0px; }' \
    -theme-str 'element { orientation: horizontal; children: [ element-text ]; padding: 10px; }' \
    -theme-str 'element-text { enabled: true; vertical-align: 0.5; horizontal-align: 0.0; margin: 0; text-color: inherit; }' \
    -theme-str 'element-icon { enabled: false; }' \
    | cliphist decode | wl-copy
fi
