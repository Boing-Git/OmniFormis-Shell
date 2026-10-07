local bind = require("modules.keybind_engine").bind



hl.config({
    general = {
        layout = "dwindle",
    },
    dwindle = {
        preserve_split = true, -- You probably want this
    },
})

--------------------------------------------------------------------------------
-- ## Dwindle Layout Exclusive Keybinds (Grid Navigation & Manual Resizing)
--------------------------------------------------------------------------------

-- 1. Bracket Focus Navigation
bind("DwindleFocusBracketLeftBind", hl.dsp.focus({ direction = "l" }))
bind("DwindleFocusBracketRightBind", hl.dsp.focus({ direction = "r" }))

-- 2. Directional Focus Navigation (Vim Keys + Down Arrow)
bind("DwindleFocusLeftBind", hl.dsp.focus({ direction = "l" }))
bind("DwindleFocusRightBind", hl.dsp.focus({ direction = "r" }))
bind("DwindleFocusUpBind", hl.dsp.focus({ direction = "u" }))
bind("DwindleFocusDownBind", hl.dsp.focus({ direction = "d" }))

-- 3. Directional Window Moving (Vim Keys)
bind("DwindleMoveLeftBind", hl.dsp.window.move({ direction = "l" }))
bind("DwindleMoveRightBind", hl.dsp.window.move({ direction = "r" }))
bind("DwindleMoveUpBind", hl.dsp.window.move({ direction = "u" }))
bind("DwindleMoveDownBind", hl.dsp.window.move({ direction = "d" }))

-------------------------------------------------------------------------
-- Move workspace only the view with arrow keys or vim keys relatively --
-------------------------------------------------------------------------

bind("DwindleViewLeftBind", hl.dsp.focus({ workspace ="r-1" }))
bind("DwindleViewRightBind", hl.dsp.focus({ workspace ="r+1" }))

-- 4. Split Ratio Window Resizing
-- Shrink window width (Minus)
bind("DwindleShrinkBind", hl.dsp.window.resize({ x = -50, y = 0, relative = true }), { repeating = true })

-- Grow window width (MM + TM + h)
bind("DwindleGrowBind", hl.dsp.window.resize({ x = 50, y = 0, relative = true }), { repeating = true })
