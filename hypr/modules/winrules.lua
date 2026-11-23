--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

local vars = require("modules.variables")
local hw = require("modules.hardware")
local windowOpacity = vars.windowOpacity or "0.9"
local singleWindowGapsOut = vars.GameMode and "0" or (vars.singleWindowGapsOut or "10")

local has_virtual = false
local monitors = hl.get_monitors()
if type(monitors) == "table" then
    for _, m in ipairs(monitors) do
        if m.name and m.name:match("HEADLESS") then
            has_virtual = true
            break
        end
    end
end

--------------------------------------------------------------------------------
-- ## Global Window Rules
--------------------------------------------------------------------------------

-- Low-spec hardware keeps windows opaque, blending each one over what's behind it is costly
if not hw.low_spec then
    hl.window_rule({
        name = "global-opacity",
        match = { fullscreen = false },
        opacity = windowOpacity .. " override " .. vars.inactive_opacity .. " override"
    })
end

hl.window_rule({
    name = "native-opaque-apps",
    match = { class = "^(foot|equibop|imv|swappy)$" },
    opaque = true
})

if not hw.low_spec then
    hl.window_rule({
        name = "wezterm-lazygit-opacity",
        match = { class = "^(wezterm|org\\.wezfurlong\\.wezterm)$", title = ".*lazygit.*" },
        opacity = "0.95 0.95"
    })
end



hl.window_rule({
    name = "center-all-floating",
    match = { float = true, xwayland = false },
    center = true
})

hl.window_rule({
    name = "center-all-imageviewer",
    match = { class = "com.gabm.satty" },
    float = true,
    center = true
})
--------------------------------------------------------------------------------
-- ## Floating Applications
--------------------------------------------------------------------------------

local float_classes = {
    "guifetch", "yad", "zenity", "wev", "org\\.gnome\\.FileRoller", "file-roller",
    "blueman-manager", "com\\.github\\.GradienceTeam\\.Gradience", "feh", "imv",
    "system-config-printer", "quickshell"
}

for _, app_class in ipairs(float_classes) do
    hl.window_rule({
        name = "float-" .. app_class:gsub("\\.", ""),
        match = { class = app_class },
        float = true
    })
end

--------------------------------------------------------------------------------
-- ## Float, Resize, and Center Specific Apps
--------------------------------------------------------------------------------

hl.window_rule({
    name = "nmtui-terminal",
    match = { class = "foot", title = "nmtui" },
    float = true,
    size = "60% 70%",
    center = true
})

hl.window_rule({
    name = "gnome-settings",
    match = { class = "org\\.gnome\\.Settings" },
    float = true,
    size = "70% 80%",
    center = true
})

hl.window_rule({
    name = "audio-controls",
    match = { class = "^(org\\.pulseaudio\\.pavucontrol|yad-icon-browser)$" },
    float = true,
    size = "60% 70%",
    center = true
})

hl.window_rule({
    name = "nwg-look",
    match = { class = "nwg-look" },
    float = true,
    size = "50% 60%",
    center = true
})

hl.window_rule({
    name = "nautilus-previewer",
    match = { class = "org.gnome.NautilusPreviewer" },
    float = true,
    size = "50% 60%",
    center = true,
})

--------------------------------------------------------------------------------
-- ## Special Workspaces
--------------------------------------------------------------------------------

hl.window_rule({
    name = "system-info-class",
    match = { class = ".*" .. vars.SysInfo .. ".*" },
    workspace = "special:sysinfo"
})

hl.window_rule({
    name = "system-info-title",
    match = { title = ".*" .. vars.SysInfo .. ".*" },
    workspace = "special:sysinfo"
})

hl.window_rule({
    name = "music-apps",
    match = { class = "^(feishin|Supersonic|Cider|com\\.github\\.th_ch\\.youtube_music|Plexamp|com-maxrave-simpmusic-MainKt)$" },
    workspace = "special:music"
})

if has_virtual then
    hl.window_rule({
        name = "music-spotify",
        match = { class = "^(Spotify|spotify)$" },
        workspace = "6"
    })
else
    hl.window_rule({
        name = "music-spotify",
        match = { class = "^(Spotify|spotify)$" },
        workspace = "special:music"
    })
end

hl.window_rule({
    name = "communication-apps",
    match = { class = "^(discord|equibop|vesktop|whatsapp)$" },
    workspace = "special:communication"
})

hl.window_rule({
    name = "todo-apps",
    match = { class = "Todoist" },
    workspace = "special:todo"
})

--------------------------------------------------------------------------------
-- ## Dialogs
--------------------------------------------------------------------------------

local float_titles = {
    "^(Select|Open)( a)? (File|Folder)(s)?$",
    "^File (Operation|Upload)( Progress)?$",
    "^.* Properties$",
    "^Export Image as PNG$",
    "^GIMP Crash Debug$",
    "^Save As$",
    "^Library$"
}

for i, app_title in ipairs(float_titles) do
    hl.window_rule({
        name = "float-dialog-" .. i,
        match = { title = app_title },
        float = true
    })
end

--------------------------------------------------------------------------------
-- ## Picture in Picture
--------------------------------------------------------------------------------

hl.window_rule({
    name = "picture-in-picture",
    match = { title = "^Picture(-| )in(-| )[Pp]icture$" },
    move = "100%-w-2% 100%-w-3%",
    keep_aspect_ratio = true,
    float = true,
    pin = true
})

--------------------------------------------------------------------------------
-- ## Creative Software
--------------------------------------------------------------------------------

hl.window_rule({
    name = "creative-software",
    match = { class = "^(krita|gimp|inkscape|darktable|resolve|kdenlive|shotcut|blender|godot)$" },
    opaque = true
})

--------------------------------------------------------------------------------
-- ## Utilities & Games
--------------------------------------------------------------------------------

hl.window_rule({
    name = "ueberzugpp",
    match = { class = "^(ueberzugpp_.*)$" },
    float = true,
    no_initial_focus = true
})

hl.window_rule({
    name = "steam-main",
    match = { class = "steam" },
    rounding = 10
})

hl.window_rule({
    name = "steam-friends",
    match = { class = "steam", title = "Friends List" },
    float = true
})

-- UPDATED: Added hl2_linux to match TF2 natively
hl.window_rule({
    name = "games-tearing",
    match = { class = "^(steam_app_(default|[0-9]+)|gamescope|hl2_linux)$" },
    opaque = true,
    immediate = true,
    idle_inhibit = "always"
})

hl.window_rule({
    name = "minecraft-atlauncher",
    match = { class = "com-atlauncher-App", title = "ATLauncher Console" },
    float = true
})

hl.window_rule({
    name = "minecraft-pandora",
    match = { class = "PandoraLauncher", title = "Minecraft Game Output" },
    float = true
})

hl.window_rule({
    name = "fusion360",
    match = { class = "fusion360\\.exe", title = "^(Fusion360|Marking Menu)$" },
    no_blur = true
})
--------------------------------------------------------------------------------
-- ## Workspace Rules
--------------------------------------------------------------------------------

-- FIXED: Converted from string list parameters into proper Lua tables
if vars.enableSingleWindowGaps ~= false then
    hl.workspace_rule({
        workspace = "w[tv1]s[false]",
        gaps_out = singleWindowGapsOut
    })

    hl.workspace_rule({
        workspace = "f[1]s[false]",
        gaps_out = singleWindowGapsOut
    })
end

if vars.enableSpecialWorkspaceGaps then
    hl.workspace_rule({
        workspace = "s[true]",
        gaps_out = singleWindowGapsOut
    })
end


if has_virtual then
    for i = 1, 5 do
        hl.workspace_rule({
            workspace = tostring(i),
            monitor = "DP-1"
        })
    end
    for i = 6, 10 do
        hl.workspace_rule({
            workspace = tostring(i),
            monitor = "HEADLESS-2"
        })
    end
end

hl.layer_rule({
    name = "quickshell-blur",
    match = { namespace = "quickshell" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.1
})

--------------------------------------------------------------------------------
-- ## Rules added from the shells' AI
--------------------------------------------------------------------------------

-- userRules.lua (scripts/assistant/tools.py: window_rule_add), loaded so that a broken line
-- there can't take the rest of the config down with it
local ok, user_rules = pcall(require, "modules.userRules")
if ok and type(user_rules) == "table" then
    for _, rule in ipairs(user_rules) do hl.window_rule(rule) end
end
