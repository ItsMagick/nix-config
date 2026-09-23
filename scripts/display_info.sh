#!/usr/bin/env zsh

set -uo pipefail

CACHE="${XDG_RUNTIME_DIR:-/tmp}/qs_displays.json"

emit() {
  hyprctl monitors -j | jq -c '
    [ .[] | {
        name, description, make, model, serial,
        width, height,
        refreshRate: (.refreshRate | (. * 100 | round) / 100),
        x, y, scale, transform, focused, disabled, dpmsStatus, vrr,
        # Parse "1920x1080@144.00Hz" style strings hyprctl reports for each
        # mode the connected EDID actually advertises, group by resolution,
        # and collapse to { w, h, rates: [ ... ] }, largest resolution first.
        resolutions: (
          [ .availableModes[]?
            | capture("(?<w>[0-9]+)x(?<h>[0-9]+)@(?<r>[0-9.]+)Hz")
            | { w: (.w | tonumber), h: (.h | tonumber), r: (.r | tonumber) }
          ]
          | group_by([.w, .h])
          | map({ w: .[0].w, h: .[0].h, rates: (map(.r) | unique | sort | reverse) })
          | sort_by(-(.w * .h))
        )
      }
    ]'
}

case "${1:-}" in
  --watch)
    if ! command -v socat > /dev/null 2>&1; then
      echo "display_info.sh --watch: socat is required but not found" >&2
      exit 1
    fi
    SOCK="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
    mkdir -p "$(dirname "$CACHE")"
    emit > "$CACHE"

    socat -u UNIX-CONNECT:"$SOCK" - | while read -r line; do
      case "$line" in
        monitoradded* | monitorremoved* | monitoraddedv2* | monitorremovedv2*)
          # Small debounce: give Hyprland a beat to finish (re)negotiating the
          # newly (dis)connected monitor's modes before we re-query them.
          sleep 0.25
          emit > "${CACHE}.tmp" && mv "${CACHE}.tmp" "$CACHE"
          ;;
      esac
    done
    ;;
  *)
    emit
    ;;
esac

