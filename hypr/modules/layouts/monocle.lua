local vars = require("modules.keybinds_variables")

local MM = vars.MM
local SM = vars.SM
local TM = vars.TM
local left = vars.left 
local right = vars.right
local up = vars.up
local down = vars.down

hl.config({
    general = {
        layout = "monocle",
    }
})

--------------------------------------------------------------------------------
-- ## Focus & Navigation (Monocle Style)
--------------------------------------------------------------------------------
-- Cycle to the next window
hl.bind(SM .. " + Tab",hl.dsp.layout("cyclenext"))
hl.bind(MM .. " + " .. right,hl.dsp.layout("cyclenext"))

-- Cycle to the previous window
hl.bind(SM .. " + " .. TM .. " + Tab",hl.dsp.layout("cycleprev"))
hl.bind(MM .. " + " .. left,hl.dsp.layout("cycleprev"))
