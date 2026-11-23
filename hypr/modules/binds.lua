
local vars = require("modules.variables")
local kb = require("modules.keybind_engine")
require("modules.quickshellBinds")
require("modules.dialBinds")

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
-- ## Script Logic
--
-- These helpers RETURN a dispatcher object. They never dispatch on their own, so
-- they are safe to pass straight into bind(). (Calling hl.dispatch() or
-- hl.dsp.window.move() while the config loads would run it once at startup and
-- hand nil to the bind, which is what caused the popup errors.)
--------------------------------------------------------------------------------

-- A "workspace group" is a block of GROUP_SIZE workspaces: group 1 = 1..10,
-- group 2 = 11..20 and so on. Jumping to a group lands on its first workspace.
-- Change GROUP_SIZE if your groups are a different size.
local GROUP_SIZE = 10

local function group_first_ws(group)
    return (group - 1) * GROUP_SIZE + 1
end

local function go_to(ws)
    return hl.dsp.focus({ workspace = ws })
end

local function move_to(ws, follow)
    return hl.dsp.window.move({ workspace = ws, follow = follow ~= false })
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
-- ## Workspaces Loops
--------------------------------------------------------------------------------

for i = 0, 9 do
    local n = { n = tostring(i) }
    local ws = (i == 0) and 10 or i        -- key 0 = workspace / group 10
    local group_ws = group_first_ws(ws)

    -- Go to workspace #
    bind("WorkspaceGoBind", go_to(ws), nil, n)

    -- Go to workspace group #
    bind("WorkspaceGoGroupBind", go_to(group_ws), nil, n)

    -- Move window to workspace # (and follow it)
    bind("WorkspaceMoveBind", move_to(ws, true), nil, n)

    -- Move window to workspace group # (and follow it)
    bind("WorkspaceMoveGroupBind", move_to(group_ws, true), nil, n)
end

-- Go to workspace -1/+1 (monitor-relative 'm' to stop boundary errors)
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

bind("MoveWindowPrevPageBind", move_to("m-1", true))
bind("MoveWindowNextPageBind", move_to("m+1", true))
bind("MoveWindowPrevScrollBind", move_to("m-1", true))
bind("MoveWindowNextScrollBind", move_to("m+1", true))
bind("MoveWindowNextBind", move_to("m+1", true))
bind("MoveWindowPrevBind", move_to("m-1", true))

-- Move window to/from special workspace
bind("ScratchboardSendBind", move_to("special:scratchboard", false))
-- "e+0" = the current workspace, which pulls the window out of the special one
bind("ScratchboardReturnBind", move_to("e+0", true))
bind("ScratchboardMoveBind", move_to("special:scratchboard", false))

--------------------------------------------------------------------------------
-- ## Window Groups
--------------------------------------------------------------------------------

bind("GroupNextBind", hl.dsp.group.next())
bind("GroupPrevBind", hl.dsp.group.prev())
for i = 0, 5 do
    -- Maps 0 to tab 5, otherwise matches the index number
    local tab = (i == 0) and 5 or i

    -- Switch to a specific window inside the group by its index (1-based)
    bind("GroupJumpBind", hl.dsp.group.active({ index = tab }), { desc = "Jump to group tab " .. tab }, { n = tostring(i) })
end

-- Go back one tab (same as GroupPrevBind, so keep one of them disabled in keybinds.lua)
bind("GroupBackBind", hl.dsp.group.prev())
bind("GroupToggleBind", hl.dsp.group.toggle())

-- Move the active window out of its current group
bind("GroupMoveOutBind", hl.dsp.window.move({ out_of_group = true }))

--------------------------------------------------------------------------------
-- ## Window Actions (Focus, Resize, Management)
--------------------------------------------------------------------------------

-- Mouse drag & window sizing gestures
bind("WindowDragBind", hl.dsp.window.drag(), { mouse = true })
bind("WindowResizeBind", hl.dsp.window.resize(), { mouse = true })

-- Alignment and Toggles
bind("WindowCenterBind", hl.dsp.window.center())

-- Resize to 55% x 70% and center. hl.dispatch() only accepts dispatcher objects,
-- not ("name", "args") strings, so the percentage resize goes through hyprctl.
-- If this does nothing on your build, replace it with a pixel size:
--   hl.dsp.window.resize({ x = 1056, y = 756, relative = false })
bind("WindowCenterResizeBind", hl.dsp.exec_cmd(
    "hyprctl dispatch resizeactive exact 55% 70% ; hyprctl dispatch centerwindow 1"
))

bind("WindowPinBind", hl.dsp.window.pin())
bind("WindowFullscreenBind", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
bind("WindowMaximizeBind", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
bind("WindowFloatBind", hl.dsp.window.float({ action = "toggle" }))
bind("WindowCloseBind", hl.dsp.window.close())

--------------------------------------------------------------------------------
-- ## Special System Workspace Targets
--------------------------------------------------------------------------------

bind("MusicWorkspaceBind", hl.dsp.workspace.toggle_special("music"))
bind("ScratchboardBind", hl.dsp.workspace.toggle_special("scratchboard"))

-- Toggle SysInfo workspace and launch the dynamic app via app2unit
-- Singleton logic should be handled by the app2unit script.
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
bind("VolumeUpBind", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 1%+"))
bind("VolumeDownBind", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"))

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

bind("SuspendBind", hl.dsp.exec_cmd("systemctl suspend"))

--------------------------------------------------------------------------------
-- ## Misc
--------------------------------------------------------------------------------

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

bind("ZoomResetBind", function()
    set_zoom(1.0)
end)

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

-- the AI in whichever shell runs (each has its own: Dial-E's Ask control, Puffy's panel,
-- Droplet's drop from the top edge), through scripts/shell
bind("AssistantBind", hl.dsp.exec_cmd("~/Dotfiles/scripts/shell ipc call assistant toggle"), { description = "Ask the local AI" })
