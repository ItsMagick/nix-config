local mainMod = "SUPER"

-- System Window Hooks
hl.bind(mainMod, "Q", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod, "C", hl.dsp.window.close())
hl.bind(mainMod, "M", hl.dsp.exit())
hl.bind(mainMod, "V", hl.dsp.window.toggle_floating())
hl.bind(mainMod, "UP", hl.dsp.window.fullscreen(0))
hl.bind(mainMod, "L", hl.dsp.exec_cmd("lock-screen"))

-- Layout Position Shifting
hl.bind(mainMod .. " SHIFT", "LEFT", hl.dsp.window.move("l"))
hl.bind(mainMod .. " SHIFT", "RIGHT", hl.dsp.window.move("r"))
hl.bind(mainMod .. " SHIFT", "UP", hl.dsp.window.move("u"))
hl.bind(mainMod .. " SHIFT", "DOWN", hl.dsp.window.move("d"))

-- Relative Workspace Navigation
hl.bind(mainMod, "Page_Up", hl.dsp.workspace.move_relative(1))
hl.bind(mainMod, "Page_Down", hl.dsp.workspace.move_relative(-1))

-- App Launches and Desktop Controls
hl.bind(mainMod, "R", hl.dsp.exec_cmd("rofi -show drun"))
hl.bind("ALT", "TAB", hl.dsp.exec_cmd("rofi -show window"))
hl.bind(mainMod, "W", hl.dsp.exec_cmd("zsh ~/.config/hypr/scripts/qs_manager.sh toggle wallpaper"))
hl.bind(mainMod, "N", hl.dsp.exec_cmd("zsh ~/.config/hypr/scripts/qs_manager.sh toggle network wifi"))
hl.bind(mainMod .. " SHIFT", "N", hl.dsp.exec_cmd("zsh ~/.config/hypr/scripts/qs_manager.sh toggle network bt"))
hl.bind(
	mainMod .. " SHIFT",
	"B",
	hl.dsp.exec_cmd("zsh ~/.config/hypr/scripts/quickshell/network/bluetooth_panel_logic.sh --toggle")
)
hl.bind(mainMod, "D", hl.dsp.exec_cmd("zsh ~/.config/hypr/scripts/qs_manager.sh toggle calendar"))
hl.bind(mainMod, "Y", hl.dsp.exec_cmd("zsh ~/.config/hypr/scripts/qs_manager.sh toggle music"))
hl.bind(mainMod, "P", hl.dsp.exec_cmd("zsh ~/.config/hypr/scripts/qs_manager.sh toggle battery"))
hl.bind(mainMod, "Escape", hl.dsp.exec_cmd("zsh ~/.config/hypr/scripts/qs_manager.sh close"))
hl.bind("", "Print", hl.dsp.exec_cmd('grim -g "$(slurp)" - | wl-copy'))

-- Loops for absolute switching & shifting workspaces
for i = 1, 5 do
	hl.bind(mainMod, tostring(i), hl.dsp.workspace.switch_to(i))
end

for i = 1, 10 do
	local key = i == 10 and "0" or tostring(i)
	hl.bind(mainMod .. " SHIFT", key, hl.dsp.window.move_to_workspace(i))
end

-- Media Control Flags (bindle)
hl.bindle("", "XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"))
hl.bindle("", "XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))
hl.bindle("", "XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set 5%+"))
hl.bindle("", "XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"))

-- Core Mute & Radios (bindl)
hl.bindl("", "XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
hl.bindl("", "XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
hl.bindl("", "XF86Bluetooth", hl.dsp.exec_cmd("rfkill toggle bluetooth"))

-- Window Grab Interactions (bindm)
hl.bindm(mainMod, "mouse:272", hl.dsp.window.drag_move())
