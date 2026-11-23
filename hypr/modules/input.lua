
---------------
---- INPUT ----
---------------
local vars = require("modules.variables")

-- KeyboardLayout ("us(colemak_dh)", or several: "us(colemak_dh),de") as XKB's two lists:
-- layouts "us,de" and variants "colemak_dh," (the Dotfiles flake's nixosModules.keyboard reads
-- the same setting for the login screen and the consoles)
local function xkb(s)
    local layouts, variants = {}, {}
    for item in s:gmatch("[^,]+") do
        local l, v = item:match("^%s*([%w_%-]+)%s*%(([%w_%-]*)%)%s*$")
        if not l then l, v = item:match("^%s*([%w_%-]+)%s*$"), "" end
        table.insert(layouts, l or "")
        table.insert(variants, v or "")
    end
    return table.concat(layouts, ","), table.concat(variants, ",")
end
local kb_layout, kb_variant = xkb(vars.KeyboardLayout or "us")

hl.config({
    input = {
        kb_layout  = kb_layout,
        kb_variant = kb_variant,
        kb_options = vars.kb_options,

        follow_mouse = vars.follow_mouse,

        sensitivity = vars.sensitivity, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = vars.touchpad_natural_scroll,
        },
    },
})

hl.gesture({
    fingers = vars.gesture_fingers,
    direction = vars.gesture_direction,
    action = "workspace"
})

-- Example per-device config
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Devices/ for more
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})
