
-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------
local vars = require("modules.variables")
local hw = require("modules.hardware")

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", vars.env_xcursor_size)
hl.env("HYPRCURSOR_SIZE", vars.env_hyprcursor_size)
hl.env("XCURSOR_THEME", vars.cursor_theme)
hl.env("HYPRCURSOR_THEME", vars.cursor_theme)
hl.env("QT_SCALE_FACTOR", vars.env_qt_scale_factor)

hl.env("XDG_SESSION_TYPE", "wayland")

-- Nvidia + Wayland, only with the NVIDIA driver loaded. On Intel or AMD these break hardware
-- video decoding (VA-API) and XWayland OpenGL.
if hw.nvidia then
    hl.env("LIBVA_DRIVER_NAME", "nvidia")
    hl.env("GBM_BACKEND", "nvidia-drm")
    hl.env("__GLX_VENDOR_LIBRARY_NAME", "nvidia")

    -- Fix for Qt Quick/Wayland inconsistent physics and flickering on NVIDIA
    hl.env("QSG_RENDER_LOOP", "basic")
end
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORM", "wayland")
