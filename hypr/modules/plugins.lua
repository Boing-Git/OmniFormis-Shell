-- Plugin is now managed natively by Nix via mkHyprlandPlugin, but since we use hyprland.lua instead of the home-manager hyprland.conf, we must load the nix-profile binary manually!
local function file_exists(name)
   local f = io.open(name, "r")
   if f ~= nil then io.close(f) return true else return false end
end

local hw = require("modules.hardware")

local plugin_path = "/etc/profiles/per-user/" .. os.getenv("USER") .. "/lib/libhyprglass.so"
if not file_exists(plugin_path) then
    plugin_path = os.getenv("HOME") .. "/.nix-profile/lib/libhyprglass.so"
end

-- The liquid glass shader is too heavy for low-spec GPUs, so it isn't loaded there at all
if not hw.low_spec then
    os.execute("hyprctl plugin load " .. plugin_path .. " &")
end
local vars = require("modules.variables")
local Utils = require("utils")
local colors = Utils.colors

-- Create a 12% opacity tint from the background color
local bg_hex = colors.background:sub(5) -- Extract RRGGBB from 0xAARRGGBB
local tint_color = tonumber("0x1f" .. bg_hex, 16)

local function configure_hyprglass()
    if not hl.plugin.hyprglass then return false end
    
    local hg = hl.plugin.hyprglass

    hg.preset("glass", {
        blur_strength          = 2.0,
        blur_iterations        = 3,
        chromatic_aberration   = 0.8,
        fresnel_strength       = 0.8,
        edge_thickness         = 0.08,
        tint_color             = tint_color,
        lens_distortion        = 0.9,
        brightness             = 1.0,
        contrast               = 1.7,
        saturation             = 1,
        vibrancy               = 0.8,
        vibrancy_darkness      = 1,
        adaptive_boost         = 0.5,
    })

    hg.preset("apple", {
        blur_strength          = 0.8,
        blur_iterations        = 2,
        refraction_strength    = 0.8,
        chromatic_aberration   = 0.6,
        fresnel_strength       = 1.0,
        specular_strength      = 1.0,
        glass_opacity          = 1.0,
        edge_thickness         = 0.1,
        lens_distortion        = 0.5,
        brightness             = 1.1,
        contrast               = 1.0,
        saturation             = 1.0,
        vibrancy               = 0.2,
        vibrancy_darkness      = 0.0,
        adaptive_dim           = 0.0,
        adaptive_boost         = 0.2,
    })

    local system_theme = "dark"
    local handle = io.popen("gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null")
    if handle then
        local result = handle:read("*a")
        handle:close()
        if result and result:match("prefer%-light") then
            system_theme = "light"
        end
    end

    hg.config({
        enabled = (not vars.GameMode) and (not hw.low_spec) and vars.liquidGlass,
        default_theme = system_theme,
        default_preset = vars.liquidGlassPreset or "glass",
        tint_color = tint_color,

        brightness = 0.9,
        dark = { brightness = 0.82 },
        light = { adaptive_boost = 0.5 },
    })

    -- Layer surfaces: each call whitelists the namespace and configures it
    hg.layer("waybar", { preset = "subtle", mask_threshold = 0.05 })
    hg.layer("swaync")
    -- hg.layer("quickshell", { preset = "apple", mask_threshold = 0.05 })
    -- hg.layer("quickshell:bezel", { preset = "apple", mask_threshold = 0.05 })
    hg.layer("debug-panel", { exclude = true })

    -- Presets
    hg.preset("clear", {
        glass_opacity = 0.8,
        blur_strength = 1.5,
        dark = { brightness = 0.7 },
        light = { brightness = 1.2 },
    })

    hg.preset("contrasted", {
        inherits = "high_contrast",
        contrast = 1.2,
        adaptive_dim = 1.5,
        dark = { tint_color = 0x02142aa9 },
    })
    return true
end

-- On low-spec hardware the plugin is only present if it was loaded before LowSpec turned on,
-- and then configure_hyprglass() has just switched it off, so there's nothing to wait for
if not configure_hyprglass() and not hw.low_spec then
    local retries = 0
    local t
    t = hl.timer(function()
        if configure_hyprglass() or retries >= 50 then
            t:set_enabled(false)
        end
        retries = retries + 1
    end, { timeout = 100, type = "repeat" })
end
