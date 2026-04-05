{ config, pkgs, lib, ... }:

{
  xdg.configFile."matugen".source = config.lib.file.mkOutOfStoreSymlink (toString ./.);

  # Hyprland parses `source` early; make sure the file exists before Matugen writes to it.
  home.activation.ensureMatugenHyprlandColors = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cfg_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/hypr"
    target="$cfg_dir/matugen-colors.conf"

    mkdir -p "$cfg_dir"

    if [ ! -f "$target" ]; then
      cat > "$target" <<'EOF'
general {
  col.active_border = rgba(cba6f7ff) rgba(89b4faff) 45deg
  col.inactive_border = rgba(6c7086cc)
}
EOF
    fi
  '';
}
