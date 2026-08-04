hl.config({
  general = {
    gaps_in = 5,
    gaps_out = 20,
    border_size = 3,
    ["col.active_border"] = "rgba(cba6f7ff) rgba(89b4faff) 45deg",
    ["col.inactive_border"] = "rgba(6c7086cc)",
    resize_on_border = false,
    allow_tearing = false,
    layout = "dwindle"
  },
  decoration = {
    rounding = 10,
    active_opacity = 1.0,
    inactive_opacity = 1.0,
    shadow = {
      enabled = true,
      range = 4,
      render_power = 3,
      color = "rgba(1a1a1aee)"
    },
    blur = {
      enabled = true,
      size = 3,
      passes = 1,
      vibrancy = 0.1696
    }
  },
  animations = {
    enabled = true
  }
})

-- Bezier curves definition
hl.bezier("easeOutQuint", 0.23, 1, 0.32, 1)
hl.bezier("easeInOutCubic", 0.65, 0.05, 0.36, 1)
hl.bezier("linear", 0, 0, 1, 1)
hl.bezier("almostLinear", 0.5, 0.5, 0.75, 1)
hl.bezier("quick", 0.15, 0, 0.1, 1)

-- Core element animations
hl.animation("global", 1, 10, "default")
hl.animation("border", 1, 5.39, "easeOutQuint")
hl.animation("windows", 1, 4.79, "easeOutQuint")
hl.animation("windowsIn", 1, 4.1, "easeOutQuint", "popin 87%")
hl.animation("windowsOut", 1, 1.49, "linear", "popin 87%")
hl.animation("fadeIn", 1, 1.73, "almostLinear")
hl.animation("fadeOut", 1, 1.46, "almostLinear")
hl.animation("fade", 1, 3.03, "quick")
hl.animation("layers", 1, 3.81, "easeOutQuint")
hl.animation("layersIn", 1, 4, "easeOutQuint", "fade")
hl.animation("layersOut", 1, 1.5, "linear", "fade")
hl.animation("workspaces", 1, 1.94, "almostLinear", "fade")