#!/usr/bin/env zsh
set -eu

CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
WALLPAPER=""

# Ensure wallpaper backend is available before applying wallpaper/colors.
if ! pgrep -x awww-daemon >/dev/null 2>&1; then
  awww-daemon >/dev/null 2>&1 &
  sleep 0.4
fi

if [[ -s "$CACHE_HOME/wal/wal" ]]; then
  WALLPAPER="$(<"$CACHE_HOME/wal/wal")"
fi

if [[ -z "$WALLPAPER" ]] && command -v awww >/dev/null 2>&1; then
  WALLPAPER=$(awww query 2>/dev/null | grep -o "$HOME/[^ ]*" | head -n1 || true)
fi

if [[ -n "$WALLPAPER" && -f "$WALLPAPER" ]]; then
  awww img "$WALLPAPER" >/dev/null 2>&1 || true
  matugen image "$WALLPAPER" >/dev/null 2>&1 || true
fi

if [[ -x "$CONFIG_HOME/hypr/scripts/qs_manager.sh" ]]; then
  zsh "$CONFIG_HOME/hypr/scripts/qs_manager.sh" || true
fi

if pgrep -x waybar >/dev/null 2>&1; then
  pkill -x waybar
fi
waybar >/dev/null 2>&1 &

