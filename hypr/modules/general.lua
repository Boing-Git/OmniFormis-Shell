package.path = package.path .. ";../scheme/?.lua"
local Utils = require("utils")
local vars = require("modules.variables")
local hw = require("modules.hardware")

hl.config({
    general = {
        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = vars.resize_on_border,

        -- Please see https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ before you turn this on
        allow_tearing = vars.allow_tearing,
    },
    cursor = {
        -- Software cursors work around NVIDIA; everywhere else a hardware cursor saves
        -- repainting the screen on every mouse move
        no_hardware_cursors = hw.nvidia,
    }
})