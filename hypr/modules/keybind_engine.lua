--------------------------------------------------------------------------------
-- Keybind engine
--
-- Every shortcut lives in modules/keybinds.lua as one string holding the whole
-- combination, not just a key. A combination is written as tokens joined by "+":
--
--   "$MM + $TM + T"       $name expands a variable ($MM is the Main modifier)
--   "SUPER + SHIFT + T"   plain modifier names work as well
--   "$MM + $left"         any string variable from modules/variables.lua can be used
--   "$MM + {n}"           {n} is filled in by bind(), used for workspace style loops
--   ""                    an empty combination leaves the bind disabled
--
-- Bare modifier variables (MM, SM, TM, QM) may be written without the "$".
-- Any other bare word stays a literal key, so "left" is the arrow key while
-- "$left" is whatever the directional variable currently holds.
--------------------------------------------------------------------------------

local vars = require("modules.variables")
local binds = require("modules.keybinds")

local M = {}

-- Modifier spellings Hyprland understands, mapped to their canonical name
local MODIFIERS = {
    SUPER = "SUPER", WIN = "SUPER", LOGO = "SUPER", META = "SUPER", MOD4 = "SUPER",
    CTRL = "CTRL", CONTROL = "CTRL",
    ALT = "ALT", MOD1 = "ALT",
    SHIFT = "SHIFT", CAPS = "CAPS",
    MOD2 = "MOD2", MOD3 = "MOD3", MOD5 = "MOD5",
}

--------------------------------------------------------------------------------
-- Variables available to combinations
--------------------------------------------------------------------------------

local function build_variables()
    local out = {}

    -- Directional keys: the home row when vim keys are on, the arrow keys otherwise
    local vim = vars.vimkeys
    if vim == nil then
        vim = true
    end
    out.left = vim and (vars.VimLeftKey or "m") or "left"
    out.right = vim and (vars.VimRightKey or "i") or "right"
    out.up = vim and (vars.VimUpKey or "e") or "up"
    out.down = vim and (vars.VimDownKey or "n") or "down"

    -- Every string in variables.lua can be used as $name, and can override the above
    for name, value in pairs(vars) do
        if type(value) == "string" then
            out[name] = value
        end
    end
    return out
end

local VARIABLES = build_variables()

local function is_modifier(word)
    return MODIFIERS[word:upper()] ~= nil
end

--------------------------------------------------------------------------------
-- Resolving a combination
--------------------------------------------------------------------------------

local function trim(s)
    return s:match("^%s*(.-)%s*$")
end

local function expand(spec, subs, depth)
    if depth > 8 then
        return nil, "variables nest too deeply in '" .. spec .. "'"
    end

    local out = {}
    for raw in spec:gmatch("[^+]+") do
        local token = trim(raw)
        if token ~= "" then
            local name = token:match("^%$%{?([%w_]+)%}?$")
            -- A bare word only counts as a variable when it holds a modifier (MM -> SUPER)
            if not name and VARIABLES[token] and is_modifier(VARIABLES[token]) then
                name = token
            end

            if name then
                local value = VARIABLES[name]
                if value == nil then
                    return nil, "unknown variable $" .. name
                end
                local inner, err = expand(value, subs, depth + 1)
                if not inner then
                    return nil, err
                end
                for _, t in ipairs(inner) do
                    out[#out + 1] = t
                end
            else
                local missing
                token = token:gsub("{(%w+)}", function(key)
                    local v = subs and subs[key]
                    if v == nil then
                        missing = key
                        return "{" .. key .. "}"
                    end
                    return tostring(v)
                end)
                if missing then
                    return nil, "no value given for {" .. missing .. "}"
                end
                out[#out + 1] = token
            end
        end
    end
    return out
end

--- Turns a combination such as "$MM + $TM + T" into "SUPER + SHIFT + T".
--- Returns nil and a reason when it cannot be resolved.
function M.resolve(spec, subs)
    local tokens, err = expand(spec, subs, 0)
    if not tokens then
        return nil, err
    end

    local mods, seen, key = {}, {}, nil
    for _, token in ipairs(tokens) do
        local canonical = MODIFIERS[token:upper()]
        if canonical then
            if not seen[canonical] then
                seen[canonical] = true
                mods[#mods + 1] = canonical
            end
        elseif key then
            return nil, "'" .. spec .. "' has more than one key (" .. key .. ", " .. token .. ")"
        else
            key = token
        end
    end

    if not key then
        return nil, "'" .. spec .. "' has no key"
    end
    mods[#mods + 1] = key
    return table.concat(mods, " + ")
end

--------------------------------------------------------------------------------
-- Binding
--------------------------------------------------------------------------------

--- Binds `name` (an entry of modules/keybinds.lua, or a literal combination).
--- `subs` fills placeholders such as {n}. A bad or empty combination is skipped
--- and reported, it never stops the rest of the config from loading.
function M.bind(name, dispatcher, opts, subs)
    local spec = binds[name]
    if spec == nil then
        spec = name
    end
    if spec == "" then
        return nil
    end

    local combo, err = M.resolve(spec, subs)
    if not combo then
        print("[keybinds] " .. name .. ": " .. err)
        return nil
    end
    return hl.bind(combo, dispatcher, opts)
end

M.variables = VARIABLES
M.binds = binds

return M
