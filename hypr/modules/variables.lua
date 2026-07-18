----------------------------------------------------------------------------------------
--- These variables will be used in various locations in the hypr config so set them ---
----------------------------------------------------------------------------------------

local vars = {

    -- General
    -- Set the browser
    Browser = "zen-beta",
    -- Set the terminal
    Term = "wezterm",
    -- Set the code editor
    Editor = "antigravity",
    -- Set the file manager
    Files = "nautilus",
    -- Set the system info app
    SysInfo = "btop",
    -- Enable game mode (disables animations and system resources taking things out of the shell UI)
    GameMode = false,
    -- Select layout for hyprland
    Layout = "Scrolling",

    -- Input
    -- Set keyboard layout
    kb_layout = "us",
    -- Set keyboard options
    kb_options = "caps:escape",
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
    -- Set the Main modifier
    MM = "SUPER",
    -- Set the Second modifier
    SM = "ALT",
    -- Set the Third modifier
    TM = "SHIFT",
    -- Set the Fourth modifier 
    QM = "CTRL",

    -- Quickshell Keybinds
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
    -- Set rounding power (higher = larger area the rounding is applied)
    rounding_power = 20,
    -- Set active window opacity
    active_opacity = 1.0,
    -- Set inactive window opacity
    inactive_opacity = 0.95,
    -- Set window opacity for window rules
    windowOpacity = "0.9",
    -- Set gap size for single window
    singleWindowGapsOut = "10",

    -- Shadows
    -- Enable window shadows
    shadow_enabled = true,
    -- Set shadow range
    shadow_range = 40,
    -- Set shadow render power
    shadow_render_power = 3,

    -- Blur
    -- Enable blur
    blur_enabled = true,
    -- Set blur size
    blur_size = 10,
    -- Set number of blur passes
    blur_passes = 3,
    -- Set blur vibrancy
    blur_vibrancy = 0.1696,

    -- Groupbar
    -- Enable group bar
    groupBar = false,

    -- General
    -- Enable resize on border
    resize_on_border = true,
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
    -- Set cursor theme
    cursor_theme = "GoogleDot-Black",
    -- Set X cursor size
    env_xcursor_size = 24,
    -- Set Hypr cursor size
    env_hyprcursor_size = 24,
    -- Set Qt scale factor
    env_qt_scale_factor = 1,

    -- Animation Style
    -- Select animation style for hyprland ("expressive", "spring", "jelly", "flyingcards", "snappy", "cinematic", "minimal", "fluid", "aggressive", "elegant", "playful", "elastic", "swift", "relaxed", "slipstream", "standard", "fluent", "custom", "none")
    AnimateStyle = "slipstream",
    
    -- --- Custom Animation Profile ---
    
    -- Custom Curves
    -- Set Custom Standard Curve
    CustomStandard = "0.98, 0.09, 0.42, 0.50",
    -- Set Custom Standard Decelerate Curve
    CustomStandardDecelerate = "0.0, 0.0, 0.0, 1.0",
    -- Set Custom Standard Accelerate Curve
    CustomStandardAccelerate = "0.3, 0.0, 1.0, 1.0",
    -- Set Custom Emphasized Decelerate Curve
    CustomEmphasizedDecelerate = "0.05, 0.7, 0.1, 1.0",
    -- Set Custom Emphasized Accelerate Curve
    CustomEmphasizedAccelerate = "0.3, 0.0, 0.8, 0.15",
    -- Set Custom Expressive Spatial Fast Curve
    CustomExpressiveSpatialFast = "0.42, 1.67, 0.21, 0.9",
    -- Set Custom Expressive Spatial Slow Curve
    CustomExpressiveSpatialSlow = "0.39, 1.29, 0.35, 0.98",

}

return vars
