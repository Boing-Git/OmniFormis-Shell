----------------
----  MISC  ----
----------------
local vars = require("modules.variables")
local hw = require("modules.hardware")

hl.config({
  misc = {
    force_default_wallpaper = vars.force_default_wallpaper,
    disable_hyprland_logo = vars.disable_hyprland_logo,
    allow_session_lock_restore = vars.allow_session_lock_restore,
    vrr = vars.vrr
  },

  xwayland = {
    force_zero_scaling = vars.xwayland_force_zero_scaling,
    use_nearest_neighbor = vars.xwayland_use_nearest_neighbor
  },

  experimental = {
    wp_cm_1_2 = true
  },

  -- Colour management, auto HDR and the SDR copy kept for screensharing each cost an extra pass
  -- per frame, which low-spec GPUs (and their 6-bit laptop panels) get nothing back for
  render = {
    cm_enabled = not hw.low_spec,
    cm_auto_hdr = not hw.low_spec,
    use_shader_blur_blend = true,
    keep_unmodified_copy = not hw.low_spec
  }
})
