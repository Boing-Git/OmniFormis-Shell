local bind = require("modules.keybind_engine").bind



hl.config({
    general = {
        layout = "scrolling"
    },
    scrolling = {
        fullscreen_on_one_column = true,
        column_width = 0.5,
        direction = "right",
        focus_fit_method = 1,
        follow_focus = true,
        follow_min_visible = 0.4,
        explicit_column_widths = "0.333, 0.5, 0.667, 1.0",
        wrap_focus = true,
        wrap_swapcol = true,
    }
})

--------------------------------------------------------------------------------
-- 1. MOVE (Navigate or scroll the layout canvas horizontally)
--------------------------------------------------------------------------------
-- Shift focus or layout view by columns
bind("ScrollMoveLeftBind", hl.dsp.layout("move -col"))
bind("ScrollMoveRightBind", hl.dsp.layout("move +col"))


--------------------------------------------------------------------------------
-- 2. COLRESIZE (Adjust column widths)
--------------------------------------------------------------------------------
-- Resize explicitly by relative factor
bind("ScrollResizeLeftBind", hl.dsp.layout("colresize -0.1"))
bind("ScrollResizeRightBind", hl.dsp.layout("colresize +0.1"))

-- Cycle through your preconfigured widths (defined in explicit_column_widths)
bind("ScrollResizeConfLeftBind", hl.dsp.layout("colresize -conf"))
bind("ScrollResizeConfRightBind", hl.dsp.layout("colresize +conf"))

-- Resize all columns to a uniform width (e.g., 500 pixels)
bind("ScrollResizeAllBind", hl.dsp.layout("colresize all 500"))


--------------------------------------------------------------------------------
-- 3. FIT (Adjust windows to fit screen boundaries)
--------------------------------------------------------------------------------
-- Fit active window, visible layout, or expand to use remaining free space
bind("ScrollFitActiveBind", hl.dsp.layout("fit active"))
bind("ScrollFitExpandBind", hl.dsp.layout("fit expand"))
bind("ScrollFitVisibleBind", hl.dsp.layout("fit visible"))


--------------------------------------------------------------------------------
-- 4. FIT_INTO_VIEW (Force active column into view bounds)
--------------------------------------------------------------------------------
bind("ScrollFitIntoViewBind", hl.dsp.layout("fit_into_view"))


--------------------------------------------------------------------------------
-- 6. PROMOTE (Eject a nested window into its own full column)
--------------------------------------------------------------------------------
bind("ScrollPromoteBind", hl.dsp.layout("promote"))


--------------------------------------------------------------------------------
-- 7. SWAPCOL (Rearrange column ordering)
--------------------------------------------------------------------------------
-- Swap current column placement left or right
bind("ScrollSwapLeftBind", hl.dsp.layout("swapcol l"))
bind("ScrollSwapRightBind", hl.dsp.layout("swapcol r"))


--------------------------------------------------------------------------------
-- 8. INHIBIT_SCROLL (Toggle canvas scrolling lock)
--------------------------------------------------------------------------------
-- Leaving the parameters blank toggles the scroll lock state
bind("ScrollInhibitBind", hl.dsp.layout("inhibit_scroll"))


--------------------------------------------------------------------------------
-- 9. EXPEL (Move window out of current column block into a dedicated column)
--------------------------------------------------------------------------------
bind("ScrollExpelBind", hl.dsp.layout("expel"))


--------------------------------------------------------------------------------
-- 10. CONSUME (Pull adjacent window into the current focused column block)
--------------------------------------------------------------------------------
bind("ScrollConsumeBind", hl.dsp.layout("consume"))


--------------------------------------------------------------------------------
-- 11. CONSUME_OR_EXPEL (Smart contextual layout consolidation)
--------------------------------------------------------------------------------
-- Expels window if grouped; consumes if isolated in a column
bind("ScrollConsumeExpelNextBind", hl.dsp.layout("consume_or_expel next"))
bind("ScrollConsumeExpelPrevBind", hl.dsp.layout("consume_or_expel prev"))
