local vars = require("modules.variables")

if vars.GameMode then
    hl.config({
        animations = {
            enabled = false
        }
    })
    return
end

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
    custom = "Custom",
    none = "None"
}

local style_lower = AnimateStyle and string.lower(AnimateStyle)
local module_name = style_map[style_lower]

local is_vert = false
local pill_dir = "top"
local home_dir = os.getenv("HOME") or "/home/boing"
local f = io.open(home_dir .. "/Dotfiles/quickshell/theme/variables.js", "r")
if f then
    local content = f:read("*a")
    f:close()
    if content then
        if string.find(content, 'pillPosition%s*=%s*"Bottom"') or string.find(content, "pillPosition%s*=%s*'Bottom'") then
            pill_dir = "bottom"
        elseif string.find(content, 'pillPosition%s*=%s*"Left"') or string.find(content, "pillPosition%s*=%s*'Left'") then
            is_vert = true
            pill_dir = "left"
        elseif string.find(content, 'pillPosition%s*=%s*"Right"') or string.find(content, "pillPosition%s*=%s*'Right'") then
            is_vert = true
            pill_dir = "right"
        end
    end
end
local suffix = is_vert and "Vert" or ""

if style_lower == "custom" then
    require("modules.animations.Custom" .. suffix)
else
    require("modules.animations." .. module_name .. suffix)
end

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
    custom = "fade",
    none = "fade"
}

local current_layer_style = layer_styles[style_lower] or "fade"
if current_layer_style == "slide" then
    current_layer_style = "slide " .. pill_dir
end

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
table.insert(layer_rules, "noanim, quickshell")

hl.config({
    layerrule = layer_rules
})