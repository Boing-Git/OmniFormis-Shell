----------------------------------------------------------------------------------------
--- These variables will be used in various locations in the hypr config so set them ---
----------------------------------------------------------------------------------------

local vars = {

    -- General
    -- Set the browser ("zen-beta", "firefox", "chromium", "brave")
    Browser = "zen-beta",
    -- Set the terminal ("wezterm", "foot", "kitty", "alacritty")
    Term = "wezterm",
    -- Set the code editor ("code", "cursor", "zed", "nvim")
    Editor = "code",
    -- Set the file manager ("nautilus", "thunar", "dolphin", "nemo")
    Files = "nautilus",
    -- Set the system info app ("btop", "htop", "nvtop")
    SysInfo = "btop",
    -- Enable game mode (hides shell UI)
    GameMode = false,
    -- Select layout ("Scrolling", "Dwindle", "Master", "Monocle")
    Layout = "Scrolling",

    -- Input
    -- Set keyboard layout
    kb_layout = "us",
    -- Set keyboard options
    kb_options = "",
    -- Set follow mouse mode
    follow_mouse = 1,
    -- Set mouse sensitivity
    sensitivity = 0,
    -- Enable touchpad natural scroll
    touchpad_natural_scroll = false,

    -- Gestures
    -- Set the number of gesture fingers
    gesture_fingers = 3,
    -- Set the gesture direction
    gesture_direction = "vertical",

    -- Enable vim keys for navigation
    vimkeys = true,

    -- Modifiers
    -- Set the Main modifier ("SUPER", "ALT", "SHIFT", "CTRL")
    MM = "SUPER",
    -- Set the Second modifier ("SHIFT", "ALT", "CTRL", "SUPER")
    SM = "ALT",
    -- Set the Third modifier ("ALT", "SHIFT", "CTRL", "SUPER")
    TM = "SHIFT",
    -- Set the Fourth modifier ("CTRL", "ALT", "SHIFT", "SUPER")
    QM = "CTRL",

    -- App Launcher
    -- Set the key to open launcher
    QuickLauncherKey = "D",
    -- Set the key to take a screenshot
    QsScreenshotKey = "S",
    -- Set the key to open wallpaper menu
    QsWallpaperKey = "W",
    -- Set the key to open color scheme menu
    QsColorSchemeKey = "T",
    -- Set the key to open control center
    QsControlCenterKey = "C",
    -- Set the key to open power menu
    QsPowerMenuKey = "P",
    -- Set the key to open overview
    QsOverviewKey = "TAB",
    -- Set the key to open emoji picker
    QsEmojiPickerKey = "comma",
    -- Set the key to open clipboard
    QsClipboardKey = "V",

    -- Decoration
    -- Set the gap size between windows (inner)
    gaps_in = 5,
    -- Set the gap size between windows and screen edge (outer)
    gaps_out = 10,
    -- Set the border size
    border_size = 2,
    -- Set window rounding
    rounding = 17,
    -- Set rounding power (higher = sharper corners)
    rounding_power = 20,
    -- Set active window opacity
    active_opacity = 1.0,
    -- Set inactive window opacity
    inactive_opacity = 0.9,
    -- Set window opacity for window rules
    windowOpacity = "0.9",
    -- Set gap size for single window
    singleWindowGapsOut = "10",

    -- Shadows
    -- Enable window shadows
    shadow_enabled = true,
    -- Set shadow range
    shadow_range = 4,
    -- Set shadow render power
    shadow_render_power = 3,

    -- Blur
    -- Enable blur
    blur_enabled = true,
    -- Set blur size
    blur_size = 3,
    -- Set number of blur passes
    blur_passes = 1,
    -- Set blur vibrancy
    blur_vibrancy = 0.1696,

    -- Groupbar
    -- Enable group bar
    groupBar = true,

    -- General
    -- Enable resize on border
    resize_on_border = false,
    -- Enable screen tearing
    allow_tearing = false,

    -- Misc
    -- Set force default wallpaper (0 to disable)
    force_default_wallpaper = 0,
    -- Enable disabling hyprland logo
    disable_hyprland_logo = true,
    -- Enable session lock restore
    allow_session_lock_restore = true,
    -- Set variable refresh rate (0 = off, 1 = on, 2 = fullscreen only)
    vrr = 0,
    -- Enable xwayland force zero scaling
    xwayland_force_zero_scaling = true,
    -- Enable xwayland nearest neighbor
    xwayland_use_nearest_neighbor = true,

    -- Environment Variables
    -- Set X cursor size
    env_xcursor_size = 24,
    -- Set Hypr cursor size
    env_hyprcursor_size = 24,
    -- Set Qt scale factor
    env_qt_scale_factor = 1,

    -- Animation Style
    -- Select animation style ("expressive", "spring", "jelly", "flyingcards", "snappy", "cinematic", "minimal", "fluid", "aggressive", "elegant", "playful", "elastic", "swift", "relaxed", "slipstream", "standard", "fluent", "none")
    AnimateStyle = "expressive",
}

return vars
