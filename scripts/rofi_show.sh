#!/usr/bin/env zsh

MODE=${1:-drun}
ROFI_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/config.rasi"

if pgrep -x "rofi" > /dev/null; then
    pkill rofi
else
    rofi -show "$MODE" -config "$ROFI_CONFIG"
fi
