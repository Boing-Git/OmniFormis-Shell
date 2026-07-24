--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

local vars = require("modules.variables")
local windowOpacity = vars.windowOpacity or "0.9"
local singleWindowGapsOut = vars.GameMode and "0" or (vars.singleWindowGapsOut or "10")

--------------------------------------------------------------------------------
-- ## Global Window Rules
--------------------------------------------------------------------------------

hl.window_rule({
    name = "global-opacity",
    match = { fullscreen = false },
    opacity = windowOpacity .. " override"
})

hl.window_rule({
    name = "native-opaque-apps",
    match = { class = "^(foot|equibop|imv|swappy)$" },
    opaque = true
})



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
    match = { class = "^(feishin|Spotify|Supersonic|Cider|com\\.github\\.th_ch\\.youtube_music|Plexamp|com-maxrave-simpmusic-MainKt)$" },
    workspace = "special:music"
})

hl.window_rule({
    name = "music-spotify-wayland",
    match = { initial_title = "^(Spotify( Free)?)$" },
    workspace = "special:music"
})

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

hl.window_rule({
    name = "games-tearing",
    match = { class = "^(steam_app_(default|[0-9]+)|gamescope)$" },
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
    no_blur = true -- FIXED: Changed from noblur to no_blur
})

--------------------------------------------------------------------------------
-- ## Xwayland Popups
--------------------------------------------------------------------------------

hl.window_rule({
    name = "xwayland-popups",
    match = { xwayland = true, title = "^win[0-9]+$" },
    no_dim = true,
    no_shadow = true,
    rounding = 10
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

hl.layer_rule({
    name = "quickshell-blur",
    match = { namespace = "quickshell" },
    blur = true,
    blur_popups = true,
    ignore_alpha = 0.1
})
