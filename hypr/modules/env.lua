
-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
local vars = require("modules.variables")

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", vars.env_xcursor_size)
hl.env("HYPRCURSOR_SIZE", vars.env_hyprcursor_size)
hl.env("XCURSOR_THEME", vars.cursor_theme)
hl.env("HYPRCURSOR_THEME", vars.cursor_theme)
hl.env("QT_SCALE_FACTOR", vars.env_qt_scale_factor)

-- Nvidia + Wayland
hl.env("LIBVA_DRIVER_NAME", "nvidia")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("GBM_BACKEND", "nvidia-drm")
hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

-- Fix for Qt Quick/Wayland inconsistent physics and flickering on NVIDIA
hl.env("QSG_RENDER_LOOP", "basic")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
