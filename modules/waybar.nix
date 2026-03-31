{ pkgs, config, ... }:

let
  nixosIcon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
in
{
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        exclusive = true;
        passthrough = false;
        gtk-layer-shell = true;

        height = 40;
        margin-top = 8;
        margin-left = 6;
        margin-right = 6;
        spacing = 0;

        modules-left = [ "hyprland/workspaces" "custom/separator" "custom/playerctl" ];
        modules-center = [];
        modules-right = [ "tray" "group/network" "group/status" "group/system" "battery" "clock" ];

        "group/network" = {
          orientation = "horizontal";
          modules = [ "network" ];
        };

        "group/status" = {
          orientation = "horizontal";
          modules = [ "pulseaudio" "bluetooth" ];
        };

        "group/system" = {
          orientation = "horizontal";
          modules = [ "cpu" "memory" "temperature" ];
        };

        # Workspaces module from migration
        "hyprland/workspaces" = {
          active-only = false;
          all-outputs = true;
          format = "{icon}";
          show-special = false;
          on-click = "activate";
          on-scroll-up = "hyprctl dispatch workspace e+1";
          on-scroll-down = "hyprctl dispatch workspace e-1";
          persistent-workspaces = {
            "1" = [];
            "2" = [];
            "3" = [];
            "4" = [];
            "5" = [];
            "6" = [];
          };
          format-icons = {
            "1" = "I";
            "2" = "II";
            "3" = "III";
            "4" = "IV";
            "5" = "V";
            "6" = "VI";
            "7" = "VII";
            "8" = "VIII";
            "9" = "IX";
            "10" = "X";
          };
        };

        # Custom separator
        "custom/separator" = {
          format = "|";
          tooltip = false;
        };

        # Player control from migration
        "custom/playerctl" = {
          format = "<span>{}</span>";
          return-type = "json";
          max-length = 35;
          exec = "playerctl -a metadata --format '{\"text\": \"{{artist}} ~ {{markup_escape(title)}}\", \"tooltip\": \"{{playerName}} : {{markup_escape(title)}}\", \"alt\": \"{{status}}\", \"class\": \"{{status}}\"}' -F";
          on-click-middle = "playerctl play-pause";
          on-click = "playerctl previous";
          on-click-right = "playerctl next";
        };

        # Battery from migration
        "battery" = {
          interval = 3;
          align = 0;
          rotate = 0;
          bat = "BAT0";
          adapter = "AC0";
          full-at = 100;
          design-capacity = false;
          states = {
            good = 85;
            warning = 30;
            critical = 15;
          };
          format = "{icon} {capacity}%";
          format-charging = " {capacity}%";
          format-plugged = " {capacity}%";
          format-alt-click = "click";
          format-full = "{icon} Full";
          format-alt = "{icon} {hour}h {M}min";
          format-icons = [
            "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"
          ];
          format-time = "{H}h {M}min";
          tooltip = true;
          tooltip-format = "{timeTo} {power}w";
        };

        # Clock from migration
        "clock" = {
          interval = 1;
          format = " {:%H:%M:%S}";
          format-alt = " {:%H:%M   %Y, %d %B, %A}";
          tooltip-format = "<tt><small>{calendar}</small></tt>";
          calendar = {
            mode = "year";
            mode-mon-col = 3;
            weeks-pos = "right";
            on-scroll = 1;
            format = {
              months = "<span color='#ffead3'><b>{}</b></span>";
              days = "<span color='#ecc6d9'><b>{}</b></span>";
              weeks = "<span color='#99ffdd'><b>W{}</b></span>";
              weekdays = "<span color='#ffcc66'><b>{}</b></span>";
              today = "<span color='#ff6699'><b><u>{}</u></b></span>";
            };
          };
        };

        # CPU monitoring
        "cpu" = {
          format = "󰻠 {usage}%";
          interval = 3;
          tooltip = true;
        };

        # Memory monitoring
        "memory" = {
          format = "󰍛 {percentage}%";
          interval = 5;
          tooltip = true;
          tooltip-format = "{used:0.1f}G / {total:0.1f}G";
        };

        # Temperature monitoring
        "temperature" = {
          thermal-zone = 0;
          format = " {temperatureC}°C";
          interval = 5;
          tooltip = true;
        };

        "mpris" = {
          format = "{player_icon} {thumbnail} {artist} — {title}";
          format-paused = "{player_icon} {thumbnail} {artist} — {title}  󰏤";
          player-icons = {
            default = "󰎆";
            zen-browser = "󰈹";
            spotify = "";
          };
          thumbnail-size = 24;
          max-length = 60;
        };

        "pulseaudio" = {
          format = "{icon} {volume}%";
          format-muted = "󰝟 mute";
          format-icons.default = ["󰕿" "󰖀" "󰕾"];
          on-click = "pavucontrol";
          tooltip = true;
          tooltip-format = "{volume}% • {desc}";
        };

        "bluetooth" = {
          format = " {status}";
          format-disabled = " off";
          format-connected = " {device_alias} {device_battery_percentage}%";
          tooltip-format = "{controller_alias}\t{controller_address}";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          on-click = "bluetoothctl power on";
        };

        "network" = {
          format-wifi = "  {essid}";
          format-ethernet = "󰈀 {ifname}";
          format-disconnected = "󰖪 Disconnected";
          tooltip-format = "{ifname} via {gwaddr} 󰊗";
          tooltip-format-wifi = "{essid} ({signalStrength}%) ";
          on-click = "nm-applet";
          on-click-right = "nm-connection-editor";
        };

        "tray" = {
          icon-size = 18;
          spacing = 8;
        };
      };
    };

    style = ''
      @import url("${config.xdg.configHome}/waybar-matugen.css");

      * {
          font-family: "FiraCode Nerd Font", "JetBrains Mono", sans-serif;
          font-size: 13px;
          font-weight: 500;
          border: none;
          margin: 0;
          padding: 0;
      }

      window#waybar {
          background: transparent;
          color: var(--waybar-text, #cdd6f4);
      }

      /* === ISLAND STYLING === */
      /* All islands are completely rounded with semicircle ends */

      #workspaces {
          background-color: var(--waybar-bg-island, rgba(30, 30, 46, 0.9));
          color: var(--waybar-text, #cdd6f4);
          padding: 0 20px;
          margin: 8px 4px;
          border-radius: 25px;
          transition: background-color 0.3s ease, color 0.3s ease;
      }

      #workspaces > button {
          padding: 0 12px;
          color: inherit;
          border: none;
          background: none;
          transition: background-color 0.3s, color 0.3s;
      }

      #workspaces > button:first-child {
          border-radius: 25px 0 0 25px;
          padding-left: 20px;
          margin-right: -2px;
      }

      #workspaces > button:last-child {
          border-radius: 0 25px 25px 0;
          padding-right: 20px;
          margin-left: -2px;
      }

      #workspaces > button:not(:first-child):not(:last-child) {
          border-radius: 0;
          margin: 0 -2px;
      }

      #workspaces > button.active {
          background-color: var(--waybar-active, #cba6f7);
          color: var(--waybar-active-text, #1e1e2e);
          font-weight: bold;
      }

      #workspaces > button.empty {
          color: var(--waybar-empty, #6c7086);
      }

      #workspaces > button.visible {
          color: var(--waybar-visible, #a6adc8);
      }

      #workspaces > button:hover {
          background-color: var(--waybar-hover, rgba(203, 166, 247, 0.2));
          color: var(--waybar-hover-text, #cba6f7);
      }

      /* Separator island */
      #custom-separator {
          background-color: transparent;
          color: var(--waybar-separator, #6c7086);
          padding: 0 8px;
          margin: 8px 2px;
          border-radius: 25px;
          font-weight: bold;
      }

      /* Player island */
      #custom-playerctl {
          background-color: var(--waybar-player-bg, rgba(30, 30, 46, 0.9));
          color: var(--waybar-player-text, #f0a0d0);
          padding: 0 12px;
          margin: 8px 4px;
          border-radius: 25px;
          transition: background-color 0.3s ease, color 0.3s ease;
      }

      /* Group containers - islands with proper semicircle ends */
      #tray,
      group-box {
          background: transparent;
          margin: 0;
          padding: 0;
      }

      group-box {
          background-color: var(--waybar-bg-island, rgba(30, 30, 46, 0.9));
          margin: 8px 4px;
          border-radius: 25px;
          transition: background-color 0.3s ease;
      }

      group-box > * {
          margin: 0;
          padding: 0 12px;
          border: none;
          background: transparent !important;
          border-radius: 0;
      }

      group-box > *:first-child {
          border-radius: 25px 0 0 25px;
          padding-left: 20px;
          margin-right: -2px;
      }

      group-box > *:last-child {
          border-radius: 0 25px 25px 0;
          padding-right: 20px;
          margin-left: -2px;
      }

      group-box > *:not(:first-child):not(:last-child) {
          border-radius: 0;
          margin: 0 -2px;
          padding: 0 12px;
      }

      /* Individual island modules */
      #battery {
          background-color: var(--waybar-battery-bg, rgba(30, 30, 46, 0.9));
          color: var(--waybar-battery-text, #a6e3a1);
          padding: 0 12px;
          margin: 8px 4px;
          border-radius: 25px;
          transition: background-color 0.3s ease, color 0.3s ease;
      }

      #battery.charging,
      #battery.plugged {
          color: var(--waybar-battery-charging, #06D001);
      }

      #battery.critical:not(.charging) {
          background-color: #c80036;
          color: #161320;
          animation: blink 0.5s linear infinite alternate;
      }

      #clock {
          background-color: var(--waybar-clock-bg, rgba(30, 30, 46, 0.9));
          color: var(--waybar-clock-text, #f0a0d0);
          padding: 0 12px;
          margin: 8px 4px;
          border-radius: 25px;
          font-weight: bold;
          transition: background-color 0.3s ease, color 0.3s ease;
      }

      #tray {
          background-color: var(--waybar-tray-bg, rgba(30, 30, 46, 0.9));
          padding: 0 12px;
          margin: 8px 4px;
          border-radius: 25px;
          transition: background-color 0.3s ease;
      }

      /* Ensure group boxes appear as single islands */
      group-box#group-network,
      group-box#group-status,
      group-box#group-system {
          background-color: var(--waybar-bg-island, rgba(30, 30, 46, 0.9));
      }

      /* CPU, Memory, Temperature in system group */
      #cpu,
      #memory,
      #temperature {
          color: inherit;
      }

      #cpu::after,
      #memory::after {
          content: " •";
          margin-right: 4px;
      }

      /* Pulseaudio and Bluetooth in status group */
      #pulseaudio,
      #bluetooth {
          color: inherit;
      }

      #pulseaudio::after {
          content: " •";
          margin-right: 4px;
      }

      /* Network in network group */
      #network {
          color: inherit;
      }

      /* Animations */
      @keyframes blink {
          to {
              background-color: #bf616a;
              color: #b5e8e0;
          }
      }

      /* Tooltip styling */
      tooltip {
          background-color: var(--waybar-tooltip-bg, #1e1e2e);
          color: var(--waybar-tooltip-text, #cdd6f4);
          border: 1px solid var(--waybar-tooltip-border, #45475a);
          border-radius: 12px;
          padding: 10px 15px;
          font-size: 12px;
          font-family: "JetBrains Mono", monospace;
      }

      tooltip label {
          color: var(--waybar-tooltip-text, #cdd6f4);
      }
    '';
  };
}

