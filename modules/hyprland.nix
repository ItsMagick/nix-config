{pkgs, config, ...}:
{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    settings = {
      monitor = [
        # monitor = name, resolution@hz, position, scale
        "eDP-1, 1920x1080@59.98, 0x0, 1"
        "HDMI-A-1, preferred, auto, 1" 
      ];
      input = {
        kb_layout = "de";
        follow_mouse = 1;
        touchpad.natural_scroll = true;
      };

      general = {
        gaps_in = 5;
        gaps_out = 20;
        border_size = 3;
        "col.active_border" = "rgba(cba6f7ff) rgba(89b4faff) 45deg";
        "col.inactive_border" = "rgba(6c7086cc)";
        resize_on_border = false;
        allow_tearing = false;
        layout = "dwindle";
      };

      decoration = {
        rounding = 10;
        active_opacity = 1.0;
        inactive_opacity = 1.0;
        shadow = {
          enabled = true;
          range = 4;
          render_power = 3;
          color = "rgba(1a1a1aee)";
        };
        blur = {
          enabled = true;
          size = 3;
          passes = 1;
          vibrancy = 0.1696;
        };
      };

      animations = {
        enabled = "yes";
        bezier = [
          "easeOutQuint, 0.23, 1, 0.32, 1"
          "easeInOutCubic, 0.65, 0.05, 0.36, 1"
          "linear, 0, 0, 1, 1"
          "almostLinear, 0.5, 0.5, 0.75, 1"
          "quick, 0.15, 0, 0.1, 1"
        ];
        animation = [
          "global, 1, 10, default"
          "border, 1, 5.39, easeOutQuint"
          "windows, 1, 4.79, easeOutQuint"
          "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
          "windowsOut, 1, 1.49, linear, popin 87%"
          "fadeIn, 1, 1.73, almostLinear"
          "fadeOut, 1, 1.46, almostLinear"
          "fade, 1, 3.03, quick"
          "layers, 1, 3.81, easeOutQuint"
          "layersIn, 1, 4, easeOutQuint, fade"
          "layersOut, 1, 1.5, linear, fade"
          "workspaces, 1, 1.94, almostLinear, fade"
        ];
      };

      gesture = [
        "3, horizontal, workspace"
      ];

      "$mainMod" = "SUPER";
      
      bind = [
        "$mainMod, Q, exec, kitty"
        "$mainMod, C, killactive,"
        "$mainMod, M, exit,"
        "$mainMod, V, togglefloating,"
	    "$mainMod, UP, fullscreen"
	    "$mainMod SHIFT, LEFT, movewindow, l"
        "$mainMod SHIFT, RIGHT, movewindow, r"
        "$mainMod SHIFT, UP, movewindow, u"
        "$mainMod SHIFT, DOWN, movewindow, d"

        "$mainMod, R, exec, ~/.config/hypr/scripts/rofi_show.sh drun"
        "$mainMod, W, exec, zsh ~/.config/hypr/scripts/qs_manager.sh toggle wallpaper"
        "$mainMod, N, exec, zsh ~/.config/hypr/scripts/qs_manager.sh toggle network wifi"
        "$mainMod SHIFT, N, exec, zsh ~/.config/hypr/scripts/qs_manager.sh toggle network bt"
        "$mainMod SHIFT, B, exec, zsh ~/.config/hypr/scripts/quickshell/network/bluetooth_panel_logic.sh --toggle"
        "$mainMod, D, exec, zsh ~/.config/hypr/scripts/qs_manager.sh toggle calendar"
        "$mainMod, Y, exec, zsh ~/.config/hypr/scripts/qs_manager.sh toggle music"
        "$mainMod, P, exec, zsh ~/.config/hypr/scripts/qs_manager.sh toggle battery"
        "$mainMod, Escape, exec, zsh ~/.config/hypr/scripts/qs_manager.sh close"
        ", Print, exec, grim -g \"$(slurp)\" - | wl-copy"
        
        "$mainMod, 1, workspace, 1"
        "$mainMod, 2, workspace, 2"
        "$mainMod, 3, workspace, 3"
        "$mainMod, 4, workspace, 4"
        "$mainMod, 5, workspace, 5"

        "$mainMod SHIFT, 1, movetoworkspace, 1"
        "$mainMod SHIFT, 2, movetoworkspace, 2"
        "$mainMod SHIFT, 3, movetoworkspace, 3"
        "$mainMod SHIFT, 4, movetoworkspace, 4"
        "$mainMod SHIFT, 5, movetoworkspace, 5"
        "$mainMod SHIFT, 6, movetoworkspace, 6"
        "$mainMod SHIFT, 7, movetoworkspace, 7"
        "$mainMod SHIFT, 8, movetoworkspace, 8"
        "$mainMod SHIFT, 9, movetoworkspace, 9"
        "$mainMod SHIFT, 0, movetoworkspace, 10"
        "ALT, TAB, exec, zsh ~/.config/hypr/scripts/rofi_show.sh window"
	    "$mainMod, L, exec, lock-screen"
      ];


      bindle = [
        ", XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        ", XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        ", XF86MonBrightnessUp, exec, brightnessctl set 5%+"
        ", XF86MonBrightnessDown, exec, brightnessctl set 5%-"
      ];

      bindl = [
        ", XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        ", XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        ", XF86Bluetooth, exec, rfkill toggle bluetooth"
      ];

      bindm = [
        "$mainMod, mouse:272, movewindow"
      ];
      exec-once = [
      "zsh ~/.config/hypr/scripts/session_start.sh"
	    "nm-applet --indicator"
      ];
      misc =  {
        disable_hyprland_logo = true;
        disable_splash_rendering = true;
      };
    };

    # Keep Matugen border overrides without conflicting with Catppuccin's settings.source.
    extraConfig = ''
      source = ${config.xdg.configHome}/hypr/matugen-colors.conf
    '';
  };
}
