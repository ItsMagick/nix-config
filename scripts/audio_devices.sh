#!/usr/bin/env zsh
# audio_devices.sh — lists PipeWire output (sink) and input (source) devices
# and lets you switch the system default between them, for AudioPopup.qml.
#
# Deliberately lazy, same philosophy as monitors/display_info.sh: no
# persistent daemon by default. `wpctl status` is cheap (<10ms) and is only
# ever called when the popup is opened or you switch a device — nothing runs
# in the background unless you explicitly start --watch.
#
# Usage:
#   audio_devices.sh                  One-shot: print {"sinks": [...], "sources": [...]}.
#   audio_devices.sh --set-sink ID    wpctl set-default ID, then print the refreshed list.
#   audio_devices.sh --set-source ID  Same, for an input device.
#   audio_devices.sh --watch          Optional. Blocks on `pactl subscribe` (event-driven,
#                                     ~0% idle CPU) and re-emits the list to $CACHE on any
#                                     sink/source add/remove/change. Not required by the
#                                     popup itself — only start this if you want a live
#                                     indicator somewhere outside the popup, e.g.:
#                                       Process {
#                                           command: ["zsh", "-c", "~/.config/hypr/scripts/quickshell/audio/audio_devices.sh --watch"]
#                                           running: true
#                                       }

set -uo pipefail

CACHE="${XDG_RUNTIME_DIR:-/tmp}/qs_audio_devices.json"

# Parses `wpctl status`'s Sinks:/Sources: blocks into
# "kind<TAB>id<TAB>name<TAB>default<TAB>volume<TAB>muted" rows, then lets jq
# turn that into properly-escaped JSON (device names can contain almost
# anything, so we don't hand-build JSON strings ourselves).
list_devices() {
  wpctl status 2>/dev/null | awk '
    BEGIN { mode="" }
    {
      line = $0
      gsub(/[│├└─]/, "", line)
      if (line ~ /Sinks:/)   { mode="sink";   next }
      if (line ~ /Sources:/) { mode="source"; next }
      if (line ~ /(Filters:|Streams:|Devices:|Clients:|Modules:)/) { mode=""; next }
      if (mode == "") next
      gsub(/^[ \t]+|[ \t]+$/, "", line)
      if (line == "") next

      is_default = (line ~ /^\*/) ? "true" : "false"
      gsub(/^\*[ \t]*/, "", line)

      if (match(line, /^[0-9]+\./)) {
        id = substr(line, RSTART, RLENGTH-1)
        rest = substr(line, RSTART+RLENGTH)
        gsub(/^[ \t]+/, "", rest)

        if (match(rest, /\[vol:[^]]*\][ \t]*$/)) {
          volpart = substr(rest, RSTART, RLENGTH)
          name = substr(rest, 1, RSTART-1)
          gsub(/[ \t]+$/, "", name)

          is_muted = (volpart ~ /MUTED/) ? "true" : "false"
          vnum = volpart
          gsub(/\[vol:[ \t]*/, "", vnum)
          gsub(/[ \t]*(MUTED)?\][ \t]*$/, "", vnum)
          volpct = int(vnum*100 + 0.5)

          printf "%s\t%s\t%s\t%s\t%s\t%s\n", mode, id, name, is_default, volpct, is_muted
        }
      }
    }
  ' | jq -R -s '
    split("\n") | map(select(length > 0) | split("\t")) |
    map({
      kind: .[0],
      id: (.[1] | tonumber),
      name: .[2],
      default: (.[3] == "true"),
      volume: (.[4] | tonumber),
      muted: (.[5] == "true")
    }) as $rows |
    {
      sinks:   [$rows[] | select(.kind == "sink")   | del(.kind)],
      sources: [$rows[] | select(.kind == "source") | del(.kind)]
    }
  '
}

set_default() {
  wpctl set-default "$1" > /dev/null 2>&1
  # Give PipeWire a beat to actually flip the default before re-querying.
  sleep 0.15
}

case "${1:-}" in
  --set-sink | --set-source)
    if [[ -z "${2:-}" ]]; then
      echo "usage: audio_devices.sh $1 <id>" >&2
      exit 1
    fi
    set_default "$2"
    list_devices
    ;;
  --watch)
    if ! command -v pactl > /dev/null 2>&1; then
      echo "audio_devices.sh --watch: pactl not found" >&2
      exit 1
    fi
    mkdir -p "$(dirname "$CACHE")"
    list_devices > "$CACHE"

    pactl subscribe | while read -r line; do
      case "$line" in
        *"on sink"* | *"on source"* | *"on server"*)
          sleep 0.2
          list_devices > "${CACHE}.tmp" && mv "${CACHE}.tmp" "$CACHE"
          ;;
      esac
    done
    ;;
  *)
    list_devices
    ;;
esac
