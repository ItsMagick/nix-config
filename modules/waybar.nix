{ pkgs, ... }:

let
 nixosIcon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";

in {
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 40;
        margin-top = 8;
        margin-left = 12;
        margin-right = 12;
        spacing = 0;

        modules-left = [ "custom/nixos" "group/hardware" "custom/window" "hyprland/workspaces" ];
        modules-center = [ "custom/player-prev" "mpris" "custom/player-next" ];
        modules-right = [ "tray" "network" "group/status" "clock" ];

        "group/hardware" = { orientation = "inherit"; modules = [ "cpu" "battery" ]; };
        "group/status" = { orientation = "inherit"; modules = [ "pulseaudio" "bluetooth" ]; };

        "custom/nixos" = {
          format = " ";
          on-click = "kitty";
          tooltip = false;
        };

        "custom/window" = {
          exec = "window-title";
          return-type = "json";
          interval = 2;
          tooltip = false;
        };

        "custom/player-prev" = { format = "󰒮"; on-click = "playerctl -p spotify previous"; tooltip = false; };
        "custom/player-next" = { format = "󰒭"; on-click = "playerctl -p spotify next"; tooltip = false; };

        "hyprland/workspaces" = {
          format = "{id}";
          on-click = "activate";
          sort-by-number = true;
          all-outputs = true;
        };

        "cpu" = { format = "󰻠 {usage}%"; interval = 3; };

        "battery" = {
          format = "{icon} {capacity}%";
          format-charging = "󰂄 {capacity}%";
          format-full = "󰁹 {capacity}%";
          format-icons = ["󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
        };

        "mpris" = {
          format = "{player_icon} {thumbnail} {artist} — {title}";
          format-paused = "{player_icon} {thumbnail} {artist} — {title}  󰏤";
          player-icons = { default = "󰎆"; zen-browser = "󰈹"; spotify = "";};
	  thumbnail-size = 24;
          max-length = 60;
        };

        "pulseaudio" = {
          format = "{icon} {volume}%";
          format-muted = "󰝟 mute";
          format-icons.default = ["󰕿" "󰖀" "󰕾"];
          on-click = "pavucontrol";
        };

        "clock" = {
          format = "  {:%H:%M}";
          format-alt = "  {:%a %d %b  %H:%M}";
        };
	"bluetooth" = {
          format = " {status}";
          format-disabled = " off";
          format-connected = " {device_alias} {device_battery_percentage}%";
          tooltip-format = "{controller_alias}\t{controller_address}";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          on-click = "bluetooth-manager"; # This triggers your new script
        };
	"network" = {
          format-wifi = "  {essid}";
          format-ethernet = "󰈀 {ifname}";
          format-disconnected = "󰖪 Disconnected";
          tooltip-format = "{ifname} via {gwaddr} 󰊗";
          tooltip-format-wifi = "{essid} ({signalStrength}%) ";
          on-click = "nm-applet"; # Link to your new script
          on-click-right = "nm-connection-editor"; # Right click for advanced settings
        };
      };
    };

    style = ''
      * {
          font-family: "FiraCode Nerd Font", "JetBrains Mono", sans-serif;
          font-size: 13px;
          font-weight: 500;
          color: #e1dee9;
          border: none;
      }

      window#waybar { background: transparent; }

      #custom-nixos {
          background-color: rgba(0, 0, 0, 0.72);
          background-image: url("${nixosIcon}");
          background-repeat: no-repeat;
          background-position: center;
          background-size: 18px 18px;
          border-radius: 16px;
          padding: 0 18px;
          margin: 4px 4px 4px 0;
          min-width: 36px;
      }

      #custom-window {
          background: rgba(0, 0, 0, 0.72);
          border-radius: 16px;
          padding: 0 14px;
          margin: 4px 4px;
          color: #ce93d8;
      }

      #cpu, #pulseaudio #network{ border-radius: 16px 0 0 16px; color: #b9f6ca; border-right: 1px solid rgba(255,255,255,0.06); }
      #battery, #bluetooth { border-radius: 0 16px 16px 0; color: #ffe082; }
      
      #cpu, #battery, #pulseaudio, #bluetooth, #mpris, #custom-player-prev, #custom-player-next, #tray, #clock, #workspaces {
          background: rgba(0, 0, 0, 0.72);
          margin: 4px 4px;
          padding: 0 12px;
          border-radius: 16px;
      }

      #workspaces button.active {
          color: #1a0d2b;
          background: linear-gradient(135deg, #ce93d8, #b388ff);
      }

    #mpris {
      color: #f0a0d0;
      padding: 0 10px;
    }

    #mpris image {
      border-radius: 4px;
      margin-right: 8px;
    }  

    #custom-player-prev, #custom-player-next{
      background: rgba(0, 0, 0, 0.72);
      color: #ce93d8;
      padding: 0 8px;
    }

      #clock { color: #f0a0d0; font-weight: bold; }
    '';
  };
}
