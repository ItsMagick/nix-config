{ pkgs, config, lib, ... }:
let
  lua = lib.generators.mkLuaInline;
  dsp = {
    exec = cmd: lua "hl.dsp.exec_cmd('${cmd}')";
    close = lua "hl.dsp.window.close()";
    exit = lua "hl.dsp.exit()";
    float = lua "hl.dsp.window.float({ action = 'toggle' })";
    fullscreen = lua "hl.dsp.window.fullscreen()";
    pseudo = lua "hl.dsp.window.pseudo()";
    layout = msg: lua "hl.dsp.window.layout('${msg}')";
    focus = dir: lua "hl.dsp.focus({ direction = '${dir}'})";
    movewindow = dir: lua "hl.dsp.window.swap({ direction = '${dir}'})";
    moveToWorkspace = ws: lua "hl.dsp.window.move({ workspace = '${toString ws}'})";
    focusWorkspace = ws: lua "hl.dsp.focus({ workspace = '${toString ws}'})";
    drag = lua "hl.dsp.window.drag()";
    resize = lua "hl.dsp.window.resize()";
  };
  bind = keys: dispatcher: {_args=[keys dispatcher];};
  bindOpts = keys: dispatcher: opts: {_args=[keys dispatcher opts];};
  workspaceBinds = lib.concatMap (i:
    let key = toString (lib.mod i 10);
    in [
      (bind "SUPER + ${key}" (dsp.focusWorkspace i))
      (bind "SUPER + SHIFT + ${key}" (dsp.moveToWorkspace i))
    ]
  ) (lib.range 1 10);
in 
{
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    configType = "lua";

    settings = {
      monitor = [{
        output = "eDP-1";
        mode = "1920x1080@59.98";
        position = "0x0";
        scale = "1";
      #  "HDMI-A-1, preferred, auto, 1";
      }];

#      input = {
 #       kb_layout = "de";
  #      follow_mouse = 1;
   #     touchpad = {
    #      natural_scroll = true;
     #   };
     # };
      config = {
        general = {
          gaps_in = 5;
          gaps_out = 20;
          border_size = 3;
#          col = {
#	    active_border = "rgba(cba6f7ff) rgba(89b4faff) 45deg";
 #           inactive_border = "rgba(6c7086cc)";
  #        };
          resize_on_border = false;
          allow_tearing = false;
          layout = "dwindle";
        };
        input = {
          kb_layout = "de";
          follow_mouse = 1;
          touchpad.natural_scroll = true;
        };

        decoration = {
          rounding = 10;
          active_opacity = 1.0;
          inactive_opacity = 1.0;
          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
   #         color = "rgba(1a1a1aee)";
          };
          blur = {
            enabled = true;
            size = 3;
            passes = 1;
            vibrancy = 0.1696;
          };
        };
        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
        };

#        animations = {
 #         enabled = true;
  #      }
#        bezier = [
 #         "easeOutQuint, 0.23, 1, 0.32, 1"
  #        "easeInOutCubic, 0.65, 0.05, 0.36, 1"
   #       "linear, 0, 0, 1, 1"
    #      "almostLinear, 0.5, 0.5, 0.75, 1"
     #     "quick, 0.15, 0, 0.1, 1"
      #  ];
#        animation = [
 #         "global, 1, 10, default"
  #        "border, 1, 5.39, easeOutQuint"
   #       "windows, 1, 4.79, easeOutQuint"
    #      "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
     #     "windowsOut, 1, 1.49, linear, popin 87%"
      #    "fadeIn, 1, 1.73, almostLinear"
       #   "fadeOut, 1, 1.46, almostLinear"
        #  "fade, 1, 3.03, quick"
         # "layers, 1, 3.81, easeOutQuint"
#          "layersIn, 1, 4, easeOutQuint, fade"
 #         "layersOut, 1, 1.5, linear, fade"
  #        "workspaces, 1, 1.94, almostLinear, fade"
   #     ];
      };

#      gesture = [
#        "3, horizontal, workspace"
#      ];

      # Declare your modifier as a local variable in Lua

      # Mapping binds into structured arguments so Lua interprets variables properly
      bind = [
        (bind "SUPER + Q" (dsp.exec "kitty"))
        (bind "SUPER + C" dsp.close)
        (bind "SUPER + M" dsp.exit)
        (bind "SUPER + V" dsp.float)
        (bind "SUPER + UP" dsp.fullscreen)
        (bind "SUPER + SHIFT + LEFT" (dsp.movewindow "l"))
        (bind "SUPER + SHIFT + RIGHT" (dsp.movewindow "r"))
        (bind "SUPER + SHIFT + UP" (dsp.movewindow "u"))
        (bind "SUPER + SHIFT + DOWN" (dsp.movewindow "d"))
        (bind "SUPER + Page_Up" (dsp.moveToWorkspace "+1"))
        (bind "SUPER + Page_Down" (dsp.moveToWorkspace "-1"))

        (bind "SUPER + R" (dsp.exec "rofi -show drun"))
        (bind "SUPER + W" (dsp.exec "zsh /home/charon/.config/hypr/scripts/qs_manager.sh toggle wallpaper"))
        (bind "SUPER + N" (dsp.exec "zsh /home/charon/.config/hypr/scripts/qs_manager.sh toggle network wifi"))
        (bind "SUPER + B" (dsp.exec  "zsh /home/charon/.config/hypr/scripts/quickshell/network/bluetooth_panel_logic.sh --toggle"))
        (bind "SUPER + D" (dsp.exec "zsh /home/charon/.config/hypr/scripts/qs_manager.sh toggle calendar" ))
        (bind "SUPER + L" (dsp.exec "lock-screen"))
        (bindOpts "SUPER + mouse:272" (dsp.drag) { mouse = true;})
 	(bindOpts "XF86AudioRaiseVolume" (dsp.exec "wpctl set-volume @ 5%+") {locked = true; repeatig = true;})
        (bindOpts "XF86AudioLowerVolume" (dsp.exec "wpctl set-volume @ 5%-") {locked = true; repeating = true;})
        (bindOpts "XF86AudioMute" (dsp.exec "wpctl set-mute @ toggle") {toggle = true;})
        (bindOpts "XF86AudioMicMute" (dsp.exec "wpctl set-mute u/DEFAULT_AUDIO_SOURCE @ toggle") {locked = true;})
      ];

      # Modern event-based Lua startup format replacing 'exec-once'
      on = {
        _args = [
          "hyprland.start"
          (lua ''
            function()
              hl.exec_cmd("zsh /home/charon/.config/hypr/scripts/session_start.sh")
              hl.exec_cmd("zsh jetbrains-toolbox")
              hl.exec_cmd("lock-screen")
            end
          '')
        ];
      };

      
    };

    # Translated legacy multi-line extraConfig to target a Lua setup block
  };
}
