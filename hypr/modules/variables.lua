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
    Editor = "antigravity-ide",
    -- Set the file manager
    Files = "nautilus",
    -- Set the system info app
    SysInfo = "btop",
    -- Frees up GPU/CPU for games: no blur, shadows, rounding, border, gaps or window animations, opaque windows, liquid glass and translucency off, lighter panel-corner anti-aliasing, and every desktop widget (clock, calendar, media player, system vitals, audio visualizer) hidden and fully stopped rather than just not animating
    GameMode = false,
    -- Low-spec mode for old or weak hardware such as older ThinkPads, turns off blur, shadows, translucency and heavy shell effects ("auto", "on", "off")
    LowSpec = "auto",
    -- Select layout for hyprland
    Layout = "Scrolling",

    -- Input
    -- The keyboard layout everywhere: Hyprland (and so every app and the lock), and through Nix the login screen and the text consoles. An XKB layout with its variant in brackets, such as us, us(colemak_dh), us(dvorak), de or fr(azerty); several separated by commas, switched with the keyboard options. Shortcuts stay on the same keys: change them in Shortcuts
    KeyboardLayout = "us(colemak_dh)",
    -- Set keyboard options
    kb_options = "grp:alt_shift_toggle",
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

    -- Navigation Keys
    -- Key that moves left when vim keys are on
    VimLeftKey = "m",
    -- Key that moves down when vim keys are on
    VimDownKey = "n",
    -- Key that moves up when vim keys are on
    VimUpKey = "e",
    -- Key that moves right when vim keys are on
    VimRightKey = "i",

    -- Decoration
    -- Set the gap size between windows (inner)
    gaps_in = 5,
    -- Set the gap size between windows and screen edge (outer)
    gaps_out = 13,
    -- Set the border size
    border_size = 2,
    -- Set window rounding
    rounding = 8,
    -- Set rounding power (higher = larger area the rounding is applied)
    rounding_power = 10,
    -- Set active window opacity
    active_opacity = 1.0,
    -- Set inactive window opacity
    inactive_opacity = 0.95,
    -- Set window opacity for window rules
    windowOpacity = "0.9",
    -- Enable gap size for single window
    enableSingleWindowGaps = false,
    -- Set gap size for single window
    singleWindowGapsOut = 30,
    -- Enable special workspace gaps rule
    enableSpecialWorkspaceGaps = false,

    -- Shadows
    -- Enable window shadows
    shadow_enabled = true,
    -- Set shadow range
    shadow_range = 30,
    -- Set shadow render power
    shadow_render_power = 2,

    -- Blur
    -- Enable blur
    blur_enabled = true,
    -- Set blur size
    blur_size = 4,
    -- Set number of blur passes
    blur_passes = 4,
    -- Set blur vibrancy
    blur_vibrancy = 0.1696,

    -- Liquid Glass
    liquidGlass = false,
    liquidGlassPreset = "apple",

    -- Groupbar
    -- Enable group bar
    groupBar = true,

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
    -- Enable session lock xray (the lock screen grows over the desktop and goes back into its corner, instead of over black)
    session_lock_xray = true,
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
    AnimateStyle = "expressive",
    
    -- --- Custom Animation Profile ---
    
    -- Custom Curves
    -- Set Custom Standard Curve
    CustomStandard = "0.98, 0.09, 0.42, 0.50",
    -- Set Custom Standard Decelerate Curve
    CustomStandardDecelerate = "0.00, 0.00, 0.00, 1.00",
    -- Set Custom Standard Accelerate Curve
    CustomStandardAccelerate = "1.00, 0.13, 0.63, 0.42",
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
