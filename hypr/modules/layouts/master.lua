local bind = require("modules.keybind_engine").bind



hl.config({
    general = {
        layout = "master",
    },
    master = {
        allow_small_split = false,
        special_scale_factor = 1.0,
        mfact = 0.55,
        new_status = "slave",
        new_on_top = false,
        new_on_active = "none",
        orientation = "left",
        slave_count_for_center_master = 2,
        center_master_fallback = "left",
        smart_resizing = true,
        drop_at_cursor = true,
        always_keep_position = false,
    }
})
--------------------------------------------------------------------------------
-- ## Focus & Navigation (Vim: j/k)
--------------------------------------------------------------------------------
-- Cycle focus down/up the stack
bind("MasterFocusPrevBind", hl.dsp.layout("cycleprev loop"))
bind("MasterFocusNextBind", hl.dsp.layout("cyclenext loop"))

-- Focus the master window directly
bind("MasterFocusMasterBind", hl.dsp.layout("focusmaster auto"))


--------------------------------------------------------------------------------
-- ## Window Swapping (Vim: TM + j/k)
--------------------------------------------------------------------------------
-- Swap the focused window down/up the stack
bind("MasterSwapPrevBind", hl.dsp.layout("swapprev loop"))
bind("MasterSwapNextBind", hl.dsp.layout("swapnext loop"))

-- Swap current active window with the master window
bind("MasterSwapWithMasterBind", hl.dsp.layout("swapwithmaster master"))


--------------------------------------------------------------------------------
-- ## Layout Resizing (Vim: h/l)
--------------------------------------------------------------------------------
-- Decrease / Increase the master split ratio (mfact)
bind("MasterShrinkBind", hl.dsp.layout("mfact -0.05"))
bind("MasterGrowBind", hl.dsp.layout("mfact +0.05"))
-- Alternatively, set to an exact value (e.g., reset to exactly 50%)
bind("MasterResetSizeBind", hl.dsp.layout("mfact exact 0.50"))


--------------------------------------------------------------------------------
-- ## Stack Rotation (Rolling)
--------------------------------------------------------------------------------
-- Rotate windows through the master position while keeping focus on master
bind("MasterRollNextBind", hl.dsp.layout("rollnext"))
bind("MasterRollPrevBind", hl.dsp.layout("rollprev"))


--------------------------------------------------------------------------------
-- ## Master Capacity Limits
--------------------------------------------------------------------------------
-- Increase or decrease the number of allowed master windows
bind("MasterAddBind", hl.dsp.layout("addmaster"))       -- 'i' for insert
bind("MasterRemoveBind", hl.dsp.layout("removemaster"))    -- 'd' for delete


--------------------------------------------------------------------------------
-- ## Orientation Cycling
--------------------------------------------------------------------------------
-- Cycle the master area orientation (Left -> Top -> Right -> Bottom -> Center)
bind("MasterOrientationNextBind", hl.dsp.layout("orientationnext"))
bind("MasterOrientationPrevBind", hl.dsp.layout("orientationprev"))

-- Snap directly to specific orientations
bind("MasterOrientationCenterBind", hl.dsp.layout("orientationcenter"))
bind("MasterOrientationLeftBind", hl.dsp.layout("orientationleft"))
bind("MasterOrientationTopBind", hl.dsp.layout("orientationtop"))
