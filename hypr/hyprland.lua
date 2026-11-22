require("modules.misc")
require("modules.autostart")
require("modules.animations")
require("modules.deco")
require("modules.winrules")
require("modules.input")
require("modules.env")
require("modules.binds")
require("modules.general")
require("modules.plugins")
local variables = require("modules.variables")

if variables.Layout == "Scrolling" or variables.Layout == "scrolling" then
    require("modules.layouts.scrolling")
elseif variables.Layout == "Dwindle" or variables.Layout == "dwindle" then
    require("modules.layouts.dwindle")
elseif variables.Layout == "Master" or variables.Layout == "master" then
    require("modules.layouts.master")
elseif variables.Layout == "Monocle" or variables.Layout == "monocle" then
    require("modules.layouts.monocle")
end

------------------
---- MONITORS ----
------------------

-- 10-bit output only where it's worth it, low-spec machines (usually 6-bit laptop panels) stay 8-bit
local bitdepth = 8

-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
hl.monitor({
    output   = "HEADLESS-1",
    mode     = "2388x1668@60",
    position = "auto",
    scale    = "1",
    bitdepth = bitdepth,
    cm       = "auto",
})

hl.monitor({
    output   = "FALLBACK",
    mode     = "1920x1080@60",
    position = "auto",
    scale    = "1",
    bitdepth = bitdepth,
    cm       = "auto",
})

hl.monitor({
    output   = "DP-1",
    mode     = "preferred@60",
    position = "auto",
    scale    = "1",
    bitdepth = bitdepth,
    cm       = "auto",
    icc      = "/home/boing/.local/share/icc/SxxBG40x.icm",
})

hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "1",
    bitdepth = bitdepth,
    cm       = "auto",
})
