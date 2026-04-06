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

        modules-left = [ "hyprland/workspaces" "custom/separator" ];
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
      @import url("${config.xdg.configHome}/waybar/matugen.css");

      * {
          font-family: "FiraCode Nerd Font Mono";
          font-size: 13px;
          font-weight: 500;
          border: none;
          margin: 0;
          padding: 0;
      }

      window#waybar {
          background: transparent;
          color: @waybar_text;
      }

      /* === ISLAND STYLING === */
      /* All islands are completely rounded with semicircle ends */

      #workspaces {
          background-color: @waybar_bg_island;
          color: @waybar_text;
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
          background-color: @waybar_active;
          color: @waybar_active_text;
          font-weight: bold;
      }

      #workspaces > button.empty {
          color: @waybar_empty;
      }

      #workspaces > button.visible {
          color: @waybar_visible;
      }

      #workspaces > button:hover {
          background-color: @waybar_hover;
          color: @waybar_hover_text;
      }

      /* Separator island */
      #custom-separator {
          background-color: transparent;
          color: @waybar_separator;
          padding: 0 8px;
          margin: 8px 2px;
          border-radius: 25px;
          font-weight: bold;
      }

      /* Group containers - islands with proper semicircle ends */
      #tray,
      group-box {
          background: transparent;
          margin: 0;
          padding: 0;
      }

      group-box {
          background-color: @waybar_bg_island;
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
          background-color: @waybar_battery_bg;
          color: @waybar_battery_text;
          padding: 0 12px;
          margin: 8px 4px;
          border-radius: 25px;
          transition: background-color 0.3s ease, color 0.3s ease;
      }

      #battery.charging,
      #battery.plugged {
          color: @waybar_battery_charging;
      }

      #battery.critical:not(.charging) {
          background-color: #c80036;
          color: #161320;
          animation: blink 0.5s linear infinite alternate;
      }

      #clock {
          background-color: @waybar_clock_bg;
          color: @waybar_clock_text;
          padding: 0 12px;
          margin: 8px 4px;
          border-radius: 25px;
          font-weight: bold;
          transition: background-color 0.3s ease, color 0.3s ease;
      }

      #tray {
          background-color: @waybar_tray_bg;
          padding: 0 12px;
          margin: 8px 4px;
          border-radius: 25px;
          transition: background-color 0.3s ease;
      }

      /* Ensure group boxes appear as single islands */
      group-box#group-network,
      group-box#group-status,
      group-box#group-system {
          background-color: @waybar_bg_island;
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
          background-color: @waybar_tooltip_bg;
          color: @waybar_tooltip_text;
          border: 1px solid @waybar_tooltip_border;
          border-radius: 12px;
          padding: 10px 15px;
          font-size: 12px;
          font-family: "FiraCode Nerd Font Mono";
      }

      tooltip label {
          color: @waybar_tooltip_text;
      }
    '';
  };
}

