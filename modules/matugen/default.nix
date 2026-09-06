{
  config,
  pkgs,
  lib,
  ...
}:
{
  xdg.configFile."matugen".source = config.lib.file.mkOutOfStoreSymlink (toString ./.);

  home.activation.ensureMatugenRuntimeFiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        cfg_home="''${XDG_CONFIG_HOME:-$HOME/.config}"

        mkdir -p "$cfg_home/hypr" "$cfg_home/waybar" "$cfg_home/rofi" "$cfg_home/zen"

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

  '';
  home.activation.ensureHyprfmTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        cfg_home="''${XDG_CONFIG_HOME:-$HOME/.config}"

        mkdir -p "$cfg_home/hyprfm" "$cfg_home/hyprfm/themes"

        if [ ! -f "$cfg_home/hyprfm/config.toml" ]; then
          cat > "$cfg_home/hyprfm/config.toml" <<'EOF'
    [general]
    theme = "matugen"
    icon_theme = "Adwaita"
    default_view = "grid"
    show_hidden = false
    sort_by = "name"
    sort_ascending = true

    [sidebar]
    position = "left"
    width = 200
    visible = true

    [appearance]
    radius_small = 4
    radius_medium = 8
    radius_large = 12
    EOF
        else
          sed -i 's/^theme[[:space:]]*=.*/theme = "matugen"/' "$cfg_home/hyprfm/config.toml"
        fi
  '';
}
