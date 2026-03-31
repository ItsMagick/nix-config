#!/usr/bin/env zsh

ROFI_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/rofi/config.rasi"

if pgrep -x "rofi" > /dev/null; then
    pkill rofi
else
    cliphist list | rofi -dmenu \
    -p "Clipboard" \
    -config "$ROFI_CONFIG" \
    -theme-str 'listview { columns: 1; spacing: 0px; }' \
    -theme-str 'element { orientation: horizontal; children: [ element-text ]; padding: 10px; }' \
    -theme-str 'element-text { enabled: true; vertical-align: 0.5; horizontal-align: 0.0; margin: 0; text-color: inherit; }' \
    -theme-str 'element-icon { enabled: false; }' \
    | cliphist decode | wl-copy
fi
