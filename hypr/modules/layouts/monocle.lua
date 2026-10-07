local bind = require("modules.keybind_engine").bind


hl.config({
    general = {
        layout = "monocle",
    }
})

--------------------------------------------------------------------------------
-- ## Focus & Navigation (Monocle Style)
--------------------------------------------------------------------------------
-- Cycle to the next window
bind("MonocleNextTabBind", hl.dsp.layout("cyclenext"))
bind("MonocleNextBind", hl.dsp.layout("cyclenext"))

-- Cycle to the previous window
bind("MonoclePrevTabBind", hl.dsp.layout("cycleprev"))
bind("MonoclePrevBind", hl.dsp.layout("cycleprev"))
