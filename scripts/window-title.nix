{ pkgs }:

pkgs.writeShellScriptBin "window-title" ''
  active_json=$(${pkgs.hyprland}/bin/hyprctl activewindow -j 2>/dev/null)
  
  if [ -z "$active_json" ] || [ "$active_json" = "{}" ]; then
      echo '{"text": "", "class": "empty"}'
      exit 0
  fi

  class=$(echo "$active_json" | ${pkgs.jq}/bin/jq -r '.class')
  title=$(echo "$active_json" | ${pkgs.jq}/bin/jq -r '.title')

  case "$class" in
      "vesktop")       echo '{"text": "󰙯 Discord", "class": "social"}' ;;
      "spotify")       echo '{"text": "󰓇 Spotify", "class": "music"}' ;;
      "zen")           echo '{"text": "󰈹 Zen Browser", "class": "browser"}' ;;
      "kitty")         echo '{"text": "󰄛 Kitty", "class": "terminal"}' ;;
      "Zotero")        echo '{"text": "󱉟 Zotero", "class": "academic"}' ;;
      "org.keepassxc.KeePassXC")     echo '{"text": "󰢁 KeePassXC", "class": "security"}' ;;
      "rofi")          echo '{"text": "󰮯 Launcher", "class": "rofi"}' ;;
      "")              echo '{"text": "", "class": "empty"}' ;;
      *)               echo "{\"text\": \"$title\", \"class\": \"default\"}" ;;
  esac
''
