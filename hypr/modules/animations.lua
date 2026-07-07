local vars = require("modules.variables")

local AnimateStyle = vars.AnimateStyle

local style_map = {
    expressive = "Expressive",
    spring = "Spring",
    springy = "Spring",
    jelly = "Jelly",
    flyingcards = "FlyingCards",
    snappy = "Snappy",
    cinematic = "Cinematic",
    minimal = "Minimal",
    fluid = "Fluid",
    aggressive = "Aggressive",
    elegant = "Elegant",
    playful = "Playful",
    elastic = "Elastic",
    swift = "Swift",
    relaxed = "Relaxed",
    slipstream = "slipStream",
    standard = "Standard",
    fluent = "Fluent",
    none = "None"
}

local style_lower = AnimateStyle and string.lower(AnimateStyle) or "expressive"
local module_name = style_map[style_lower] or "Expressive"

require("modules.animations." .. module_name)

animations = {
    enabled = true,
}

-- Layer Animation Compatibility
local layer_styles = {
    jelly = "slide",
    flyingcards = "slide",
    relaxed = "fade",
    expressive = "fade",
    playful = "fade",
    elegant = "fade",
    minimal = "fade",
    spring = "fade",
    springy = "fade",
    snappy = "fade",
    swift = "fade",
    cinematic = "fade",
    fluent = "popin 75%",
    fluid = "fade",
    elastic = "fade",
    standard = "slide",
    aggressive = "fade",
    wind = "slide",
    slipstream = "slide",
    none = "fade"
}

local current_layer_style = layer_styles[style_lower] or "fade"

local animated_layers = {
    "rofi", 
    "waybar", 
    "mako", 
    "dunst", 
    "swaync-control-center", 
    "swaync-notification-window", 
    "org.quickshell", 
    "gtk-layer-shell",
    "anyrun"
}

local layer_rules = {}
for _, layer in ipairs(animated_layers) do
    table.insert(layer_rules, "animation " .. current_layer_style .. ", " .. layer)
end

hl.config({
    layerrule = layer_rules
})