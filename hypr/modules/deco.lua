-----------------------
local Utils = require("utils")
local vars = require("modules.variables")
local hw = require("modules.hardware")
local colors = Utils.colors

-- Hyprland's blur `contrast` defaults to 0.8916 (an ~11% cut) when left unset, which barely
-- registers on dark, already-low-luminance surfaces but visibly flattens a light, near-white
-- translucent panel toward mid-gray — the washed-out card look in light mode. Push contrast back
-- to neutral specifically when the active scheme is light; dark mode keeps Hyprland's own default
-- (the same value it was already implicitly using) so its look is unchanged.
local isLightMode = colors.mode == "light"

local function isFramed()
    local f = io.open(os.getenv("HOME") .. "/Dotfiles/quickshell/theme/variables.js", "r")
    if f then
        local content = f:read("*a")
        f:close()
        if content:match('var%s+panelStyle%s*=%s*["\']Framed["\']') then
            return true
        end
    end
    return false
end

local layer_rules = {
    "blur, quickshell",
    "blur_popups, quickshell",
    "ignorealpha 0.5, quickshell",
    "ignorezero, quickshell",
    "blur, quickshell:bezel",
    "ignorealpha 0.5, quickshell:bezel",
    "ignorezero, quickshell:bezel"
}

hl.config({
    layerrule = layer_rules,
    general = {
        gaps_in  = vars.GameMode and 0 or vars.gaps_in,
        gaps_out = vars.GameMode and 0 or vars.gaps_out,

        border_size = vars.GameMode and 0 or vars.border_size,

        col = {
            active_border = { colors = { Utils.hex_to_rgba(colors.primary), Utils.hex_to_rgba(colors.tertiary) }, angle = 45 },
            inactive_border = Utils.hex_to_rgba(colors.shadow, 1),
        },
    },
    decoration = {
        rounding       = (vars.GameMode or isFramed()) and 0 or vars.rounding,
        rounding_power = vars.rounding_power,

        dim_inactive = true,
        dim_strength = 0.12,
        -- Change transparency of focused and unfocused windows (opaque on low-spec hardware,
        -- where blending every window over the ones behind it is the expensive part)
        active_opacity   = hw.low_spec and 1.0 or vars.active_opacity,
        inactive_opacity = hw.low_spec and 1.0 or vars.inactive_opacity,

        shadow = {
            enabled      = (not vars.GameMode) and (not hw.low_spec) and vars.shadow_enabled,
            range        = vars.shadow_range,
            render_power = vars.shadow_render_power,
            color        = "rgba(000000e0)",
        }, -- ADDED COMMA

        blur = {
            enabled    = (not vars.GameMode) and (not hw.low_spec) and vars.blur_enabled,
            size       = vars.blur_size,
            passes     = vars.blur_passes,
            vibrancy   = vars.blur_vibrancy,
            contrast   = isLightMode and 1.0 or 0.8916,
            brightness = 1.0,
        },
    },
    group = {
        insert_after_current = true,   -- Open new tabs right next to your currently focused tab
        focus_removed_window = true,   -- Switch focus to a window when it is kicked out of a group
        ["col.border_active"] = Utils.hex_to_rgba(Utils.colors.primary, 0.8),        -- Active group window border color
        ["col.border_inactive"] = Utils.hex_to_rgba(Utils.colors.surface_variant, 0.5),      -- Inactive group window border color
        ["col.border_locked_active"] = Utils.hex_to_rgba(Utils.colors.tertiary, 0.8), -- Border color when the active group is locked
        ["col.border_locked_inactive"] = Utils.hex_to_rgba(Utils.colors.tertiary_container, 0.5),

        groupbar = {
            enabled = vars.groupBar,
            font_family = "Rubik",      -- Set your favorite UI font
            font_size = 10,
            height = 14,                -- Height of the tab bar container above the window
            stacked = false,            -- True = vertical tab bar stack; False = standard horizontal browser tabs
            gradients = true,           -- Smooth out tab background transitions
            render_titles = true,       -- Show application names on the tabs
            scrolling = true,           -- Cycle tabs using your mouse wheel over the tab bar

            -- Set the curve style for the group bar (2.0 is a circle)
                gradient_rounding_power = 10,
                
            -- Tab Colors (Format: rgba or hex strings)
            ["col.active"] = Utils.hex_to_rgba(Utils.colors.primary, 0.8),          -- Background of the focused tab
            ["col.inactive"] = Utils.hex_to_rgba(Utils.colors.surface_variant, 0.5),        -- Background of un-focused tabs
            ["col.locked_active"] = Utils.hex_to_rgba(Utils.colors.tertiary, 0.8),   -- Background of focused tab when group is locked
            ["col.locked_inactive"] = Utils.hex_to_rgba(Utils.colors.tertiary_container, 0.5)  -- Background of un-focused tabs when group is locked
        }
    }
})
