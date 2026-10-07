local vars = require("modules.variables")
local kb = require("modules.keybind_engine")
require("modules.quickshellBinds")

-- Every shortcut is a named entry in modules/keybinds.lua, resolved by the engine
local bind = kb.bind

-- Programs the shortcuts launch (see variables.lua)
local Browser = vars.Browser
local Term = vars.Term
local Editor = vars.Editor
local Files = vars.Files
local SysInfo = vars.SysInfo

-- Helper variables to track state
local current_zoom = 1.0
local step = 0.25
local max_zoom = 3.0
local min_zoom = 1.0

--------------------------------------------------------------------------------
-- ## Script Logic (Embedded in Lua for Manual Adjustments Later)
--------------------------------------------------------------------------------
local function workspace_action(action_type, target_ws, is_group)
    -- This handles the old wsaction.fish logic locally in pure Lua
    local prefix = is_group and "group:" or ""
    if action_type == "workspace" then
        hl.dispatch(hl.dsp.focus({ workspace = prefix .. target_ws }))
    elseif action_type == "movetoworkspace" then
        hl.dispatch(hl.dsp.window.move({ workspace = prefix .. target_ws }))
    end
end

--------------------------------------------------------------------------------
-- ## Hexecute Setting gestures
--------------------------------------------------------------------------------

-- 1. Triggers when long pressing the combination
-- hl.bind(QM .. " + Alt_L", hl.dsp.exec_cmd("hexecute"), { long_press = true })

--------------------------------------------------------------------------------
-- ## Shell keybinds
--------------------------------------------------------------------------------

-- Media Controls
bind("MediaPlayPauseBind", hl.dsp.exec_cmd("playerctl play-pause"))
bind("MediaPlayKeyBind", hl.dsp.exec_cmd("playerctl play-pause"))
bind("MediaPauseKeyBind", hl.dsp.exec_cmd("playerctl play-pause"))
bind("MediaNextBind", hl.dsp.exec_cmd("playerctl next"))
bind("MediaNextKeyBind", hl.dsp.exec_cmd("playerctl next"))
bind("MediaPrevBind", hl.dsp.exec_cmd("playerctl previous"))
bind("MediaPrevKeyBind", hl.dsp.exec_cmd("playerctl previous"))
bind("MediaStopKeyBind", hl.dsp.exec_cmd("playerctl pause"))

-- Quickshell management (Kill, Launch, Reload)
bind("ShellKillBind", hl.dsp.exec_cmd("omniformis kill"))
bind("ShellLaunchBind", hl.dsp.exec_cmd("omniformis launch -d"))
bind("ShellReloadBind", hl.dsp.exec_cmd("omniformis reload"))

--------------------------------------------------------------------------------
-- ## Workspaces Loops (Programmatic & Scriptless)
--------------------------------------------------------------------------------

for i = 0, 9 do
    local n = { n = tostring(i) }
    local ws = (i == 0) and 10 or i

    -- Go to workspace #
    bind("WorkspaceGoBind", function() workspace_action("workspace", ws, false) end, nil, n)

    -- Go to workspace group #
    bind("WorkspaceGoGroupBind", function() workspace_action("workspace", ws, true) end, nil, n)

    -- Move window to workspace #
    bind("WorkspaceMoveBind", function() workspace_action("movetoworkspace", ws, false) end, nil, n)

    -- Move window to workspace group #
    bind("WorkspaceMoveGroupBind", function() workspace_action("movetoworkspace", ws, true) end, nil, n)
end

-- Go to workspace -1/+1 directional navigation (Swapped to monitor-relative 'm' to stop boundary errors)
bind("WorkspacePrevScrollBind", hl.dsp.focus({ workspace = "m-1" }))
bind("WorkspaceNextScrollBind", hl.dsp.focus({ workspace = "m+1" }))
bind("WorkspacePrevPageBind", hl.dsp.focus({ workspace = "m-1" }))
bind("WorkspaceNextPageBind", hl.dsp.focus({ workspace = "m+1" }))

bind("WorkspacePrevPriorBind", hl.dsp.focus({ workspace = "m-1" }))
bind("WorkspaceNextNextBind", hl.dsp.focus({ workspace = "m+1" }))

-- Go to workspace group -1/+1
bind("WorkspaceGroupPrevScrollBind", hl.dsp.focus({ workspace = "r-10" }))
bind("WorkspaceGroupNextScrollBind", hl.dsp.focus({ workspace = "r+10" }))

--------------------------------------------------------------------------------
-- ## Move Window Utilities
--------------------------------------------------------------------------------

bind("MoveWindowPrevPageBind", hl.dsp.window.move({ workspace = "m-1" }))
bind("MoveWindowNextPageBind", hl.dsp.window.move({ workspace = "m+1" }))
bind("MoveWindowPrevScrollBind", hl.dsp.window.move({ workspace = "m-1" }))
bind("MoveWindowNextScrollBind", hl.dsp.window.move({ workspace = "m+1" }))
bind("MoveWindowNextBind", hl.dsp.window.move({ workspace = "m+1" }))
bind("MoveWindowPrevBind", hl.dsp.window.move({ workspace = "m-1" }))

-- Move window to/from special workspace
bind("ScratchboardSendBind", hl.dsp.window.move({ workspace = "special:scratchboard" }))
bind("ScratchboardReturnBind", hl.dsp.window.move({ workspace = "+0" }))
bind("ScratchboardMoveBind", hl.dsp.window.move({ workspace = "special:scratchboard" }))

--------------------------------------------------------------------------------
-- ## Window Groups
--------------------------------------------------------------------------------

bind("GroupNextBind", hl.dsp.group.next())
bind("GroupPrevBind", hl.dsp.group.prev())
for i = 0, 5 do
    -- Maps 0 to tab 5, otherwise matches the index number
    local ws = (i == 0) and 5 or i

    -- Switch to a specific window inside the group by its index (1-based)
    bind("GroupJumpBind", hl.dsp.group.active({ index = ws }), { desc = "Jump to group tab " .. ws }, { n = tostring(i) })
end

-- Replaced hyprctl string with native dispatch
bind("GroupBackBind", function()
    hl.dispatch("changegroupactive", "b")
end)
bind("GroupToggleBind", hl.dsp.group.toggle())

-- Move the active window out of its current group
bind("GroupMoveOutBind", hl.dsp.window.move({ out_of_group = true, window = "active" }))

--------------------------------------------------------------------------------
-- ## Window Actions (Focus, Resize, Management)
--------------------------------------------------------------------------------

-- Mouse drag & window sizing gestures
bind("WindowDragBind", hl.dsp.window.drag(), { mouse = true })
bind("WindowResizeBind", hl.dsp.window.resize(), { mouse = true })

-- Alignment and Toggles
bind("WindowCenterBind", hl.dsp.window.center())

-- Replaced hyprctl strings with native dispatch logic
bind("WindowCenterResizeBind", function()
    hl.dispatch("resizeactive", "exact 55% 70%")
    hl.dispatch("centerwindow", "1")
end)

bind("WindowPinBind", hl.dsp.window.pin())
bind("WindowFullscreenBind", hl.dsp.window.fullscreen({mode = "fullscreen"}))
bind("WindowMaximizeBind", hl.dsp.window.fullscreen({mode = "maximized"}))
bind("WindowFloatBind", hl.dsp.window.float("active"))
bind("WindowCloseBind", hl.dsp.window.close("active"))

--------------------------------------------------------------------------------
-- ## Special System Workspace Targets
--------------------------------------------------------------------------------

bind("MusicWorkspaceBind", hl.dsp.workspace.toggle_special("music"))
bind("ScratchboardBind", hl.dsp.workspace.toggle_special("scratchboard"))

-- Toggle SysInfo workspace and launch the dynamic app via app2unit
-- Removed hyprctl client check. Singleton logic should be handled by app2unit script.
bind("SysInfoBind", function()
    hl.dispatch(hl.dsp.workspace.toggle_special("sysinfo"))
    hl.dispatch(hl.dsp.exec_cmd("app2unit -- " .. Term .. " -e " .. SysInfo))
end)

--------------------------------------------------------------------------------
-- ## Core Applications (Mapped dynamically to variables.lua options)
--------------------------------------------------------------------------------

bind("TermBind", hl.dsp.exec_cmd("app2unit -- " .. Term))
bind("BrowserBind", hl.dsp.exec_cmd("app2unit -- " .. Browser))
bind("EditorBind", hl.dsp.exec_cmd("app2unit -- " .. Editor))
bind("FilesBind", hl.dsp.exec_cmd("app2unit -- " .. Files))

--------------------------------------------------------------------------------
-- ## Utilities
--------------------------------------------------------------------------------

bind("ScreenshotBind", hl.dsp.exec_cmd("grim - | satty --filename -"))
bind("ScreenshotAreaBind", hl.dsp.exec_cmd("bash -c 'geom=$(slurp) && sleep 0.1 && grim -g \"$geom\" - | satty --filename -'"))
bind("ScreenshotAreaAltBind", hl.dsp.exec_cmd("bash -c 'geom=$(slurp) && sleep 0.1 && grim -g \"$geom\" - | satty --filename -'"))
bind("ColorPickerBind", hl.dsp.exec_cmd("hyprpicker -a"))

-- OmniAction Context Menu (Triggers on currently copied file)
bind("OmniActionBind", hl.dsp.exec_cmd("'/run/media/boing/Games/pc backup/SideProjects/OmniMenu/omniaction_clip.sh'"))
--------------------------------------------------------------------------------
-- ## System Volume Inputs
--------------------------------------------------------------------------------

bind("MicMuteBind", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"))
bind("VolumeMuteKeyBind", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
bind("VolumeMuteBind", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"))
bind("VolumeUpBind", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"))
bind("VolumeDownBind", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"))

--------------------------------------------------------------------------------
-- ## Display Brightness Inputs (laptop backlight, then DDC/CI)
--------------------------------------------------------------------------------

-- A laptop panel has a kernel backlight, which brightnessctl drives through logind without
-- root. Without one (a desktop), or without brightnessctl, it falls back to DDC/CI.
local function brightness(sign)
    return hl.dsp.exec_cmd("brightnessctl -q -c backlight set 5%" .. sign .. " || ddcutil setvcp 10 " .. sign .. " 5")
end

bind("BrightnessUpBind", brightness("+"))
bind("BrightnessDownBind", brightness("-"))
bind("BrightnessUpScrollBind", brightness("+"))
bind("BrightnessDownScrollBind", brightness("-"))
bind("BrightnessUpKeyBind", brightness("+"))
bind("BrightnessDownKeyBind", brightness("-"))

--------------------------------------------------------------------------------
-- ## Power Management
--------------------------------------------------------------------------------

bind("SuspendBind", hl.dsp.exec_cmd("systemctl suspend-then-hibernate"))

--------------------------------------------------------------------------------
--- ## Misc 
-------------------------------------------------------------------------------

-- Function to update the zoom globally
local function set_zoom(value)
    current_zoom = math.max(min_zoom, math.min(max_zoom, value))
    hl.config({
        cursor = {
            zoom_factor = current_zoom
        }
    })
end

--------------------------------------------------------------------------------
-- ## Zoom Key Bindings
--------------------------------------------------------------------------------

-- FIXED: Combined modifiers and key into a single string format
bind("ZoomResetBind", function()
    set_zoom(1.0)
end)

-- FIXED: Combined modifier and mouse actions into single strings
bind("ZoomInBind", function()
    set_zoom(current_zoom + step)
end)

bind("ZoomOutBind", function()
    set_zoom(current_zoom - step)
end)

--------------------------------------------------------------------------------
-- ## Shortcut recording
--------------------------------------------------------------------------------

-- The settings app switches to this otherwise empty submap while it records a new shortcut, so
-- Hyprland hands every key to the app instead of running the bind that is being replaced.
-- The bind inside is an emergency exit that returns to the normal binds.
hl.define_submap("omniformis_capture", function()
    hl.bind("CTRL + ALT + SHIFT + SUPER + F12", hl.dsp.submap("reset"))
end)
