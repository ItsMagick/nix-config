{ config, pkgs, lib, ... }:

{
  xdg.configFile."matugen".source = config.lib.file.mkOutOfStoreSymlink (toString ./.);

  home.activation.ensureMatugenRuntimeFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cfg_home="''${XDG_CONFIG_HOME:-$HOME/.config}"

    mkdir -p "$cfg_home/hypr" "$cfg_home/waybar" "$cfg_home/rofi"

    if [ ! -f "$cfg_home/hypr/matugen-colors.conf" ]; then
      cat > "$cfg_home/hypr/matugen-colors.conf" <<'EOF'
general {
  col.active_border = rgba(cba6f7ff) rgba(89b4faff) 45deg
  col.inactive_border = rgba(6c7086cc)
}
EOF
    fi

    if [ ! -f "$cfg_home/waybar/matugen.css" ]; then
      cat > "$cfg_home/waybar/matugen.css" <<'EOF'
@define-color waybar_text #cdd6f4;
@define-color waybar_bg_island rgba(30, 30, 46, 0.9);
@define-color waybar_active #cba6f7;
@define-color waybar_active_text #1e1e2e;
@define-color waybar_empty #6c7086;
@define-color waybar_visible #a6adc8;
@define-color waybar_hover rgba(203, 166, 247, 0.2);
@define-color waybar_hover_text #cba6f7;
@define-color waybar_separator #6c7086;
@define-color waybar_battery_bg rgba(30, 30, 46, 0.9);
@define-color waybar_battery_text #a6e3a1;
@define-color waybar_battery_charging #a6e3a1;
@define-color waybar_clock_bg rgba(30, 30, 46, 0.9);
@define-color waybar_clock_text #f0a0d0;
@define-color waybar_tray_bg rgba(30, 30, 46, 0.9);
@define-color waybar_tooltip_bg #1e1e2e;
@define-color waybar_tooltip_text #cdd6f4;
@define-color waybar_tooltip_border #45475a;
EOF
    fi

    if [ ! -f "$cfg_home/rofi/matugen.rasi" ]; then
      cat > "$cfg_home/rofi/matugen.rasi" <<'EOF'
* {
  bg: rgba(30, 30, 46, 0.92);
  bg-alt: rgba(49, 50, 68, 0.86);
  fg: #cdd6f4;
  fg-dim: #a6adc8;
  accent: #cba6f7;
  urgent: #f38ba8;
  border: #45475a;
  separator: #6c7086;
}
EOF
    fi
  '';
}
