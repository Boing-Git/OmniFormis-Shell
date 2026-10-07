--------------------------------------------------------------------------------
-- Keybinds
--
-- One entry per shortcut, each holding the whole combination (modifiers and key).
-- Change them in the Settings app (click a shortcut, then press the new keys) or
-- edit them here. The syntax is documented in modules/keybind_engine.lua:
--   $MM, $SM, $TM, $QM   the modifier variables from variables.lua
--   $left $right $up $down   directional keys (home row when vimkeys is on)
--   {n}                  replaced with each number by the workspace and tab binds
--   empty string         disables the shortcut
--------------------------------------------------------------------------------

return {
    -- Applications
    -- Open the terminal
    TermBind = "$MM + T",
    -- Open the browser
    BrowserBind = "$MM + W",
    -- Open the code editor
    EditorBind = "$MM + X",
    -- Open the file manager
    FilesBind = "$MM + B",
    -- Open the file context menu for the copied file
    OmniActionBind = "$MM + O",

    -- Window
    -- Close the active window
    WindowCloseBind = "$MM + Q",
    -- Toggle floating for the active window
    WindowFloatBind = "$MM + Space",
    -- Maximize the active window
    WindowMaximizeBind = "$MM + F",
    -- Make the active window fullscreen
    WindowFullscreenBind = "$MM + $TM + F",
    -- Pin the active window
    WindowPinBind = "$MM + P",
    -- Center the active window
    WindowCenterBind = "$QM + $MM + Backslash",
    -- Center and resize the active window
    WindowCenterResizeBind = "$QM + $MM + $QM + Backslash",
    -- Drag a window with the mouse
    WindowDragBind = "$MM + mouse:272",
    -- Resize a window with the mouse
    WindowResizeBind = "$MM + mouse:273",

    -- Groups
    -- Toggle the active window group
    GroupToggleBind = "$MM + G",
    -- Move the active window out of its group
    GroupMoveOutBind = "$MM + $TM + G",
    -- Switch to the next tab in the group
    GroupNextBind = "$QM + Tab",
    -- Switch to the previous tab in the group
    GroupPrevBind = "$TM + $QM + Tab",
    -- Switch to the previous tab with the backwards dispatcher
    GroupBackBind = "$QM + $TM + $QM + Tab",
    -- Jump to a tab in the group by number
    GroupJumpBind = "$QM + {n}",

    -- Workspaces
    -- Go to a workspace by number
    WorkspaceGoBind = "$MM + {n}",
    -- Go to a workspace group by number
    WorkspaceGoGroupBind = "$QM + $MM + {n}",
    -- Move the window to a workspace by number
    WorkspaceMoveBind = "$MM + $QM + {n}",
    -- Move the window to a workspace group by number
    WorkspaceMoveGroupBind = "$QM + $MM + $QM + {n}",
    -- Go to the previous workspace with the scroll wheel
    WorkspacePrevScrollBind = "$MM + mouse_down",
    -- Go to the next workspace with the scroll wheel
    WorkspaceNextScrollBind = "$MM + mouse_up",
    -- Go to the previous workspace with Page Up
    WorkspacePrevPageBind = "$MM + Page_Up",
    -- Go to the next workspace with Page Down
    WorkspaceNextPageBind = "$MM + Page_Down",
    -- Go to the previous workspace with Prior
    WorkspacePrevPriorBind = "$MM + Prior",
    -- Go to the next workspace with Next
    WorkspaceNextNextBind = "$MM + Next",
    -- Go to the previous workspace group with the scroll wheel
    WorkspaceGroupPrevScrollBind = "$QM + $MM + mouse_down",
    -- Go to the next workspace group with the scroll wheel
    WorkspaceGroupNextScrollBind = "$QM + $MM + mouse_up",
    -- Move the window to the previous workspace with Page Up
    MoveWindowPrevPageBind = "$MM + $QM + Page_Up",
    -- Move the window to the next workspace with Page Down
    MoveWindowNextPageBind = "$MM + $QM + Page_Down",
    -- Move the window to the previous workspace with the scroll wheel
    MoveWindowPrevScrollBind = "$MM + $QM + mouse_down",
    -- Move the window to the next workspace with the scroll wheel
    MoveWindowNextScrollBind = "$MM + $QM + mouse_up",
    -- Move the window to the next workspace
    MoveWindowNextBind = "$QM + $MM + $TM + $right",
    -- Move the window to the previous workspace
    MoveWindowPrevBind = "$QM + $MM + $TM + $left",

    -- Special Workspaces
    -- Toggle the music workspace
    MusicWorkspaceBind = "$MM + Z",
    -- Toggle the scratchboard workspace
    ScratchboardBind = "$MM + S",
    -- Move the window to the scratchboard
    ScratchboardMoveBind = "$MM + $QM + S",
    -- Send the window to the scratchboard
    ScratchboardSendBind = "$QM + $MM + $TM + $up",
    -- Bring the window back from the scratchboard
    ScratchboardReturnBind = "$QM + $MM + $TM + $down",
    -- Toggle the system info workspace
    SysInfoBind = "$QM + $TM + Escape",

    -- Quickshell
    -- Open the launcher
    QsLauncherBind = "$MM + D",
    -- Open the Quickshell screenshot tool
    QsScreenshotBind = "$MM + $TM + S",
    -- Open circle to search
    QsLensBind = "$MM + $TM + X",
    -- Open the wallpaper switcher
    QsWallpaperBind = "$MM + $QM + W",
    -- Open the color scheme switcher
    QsColorSchemeBind = "$MM + $QM + T",
    -- Open the control center
    QsControlCenterBind = "$MM + C",
    -- Open the power menu
    QsPowerMenuBind = "$MM + $TM + P",
    -- Open the overview
    QsOverviewBind = "$MM + TAB",
    -- Open the game library
    QsGameLibraryBind = "$MM + $TM + G",
    -- Open the emoji picker
    QsEmojiPickerBind = "$MM + comma",
    -- Open the clipboard history
    QsClipboardBind = "$MM + V",
    -- Open the keybind cheat sheet
    QsCheatSheetBind = "$MM + $QM + K",
    -- Kill the shell
    ShellKillBind = "$QM + $MM + $TM + R",
    -- Launch the shell in the background
    ShellLaunchBind = "$QM + $MM + $QM + R",
    -- Reload the shell
    ShellReloadBind = "$MM + $TM + R",

    -- Media
    -- Play or pause with the keyboard
    MediaPlayPauseBind = "$MM + $QM + Space",
    -- Next track with the keyboard
    MediaNextBind = "$MM + $QM + Equal",
    -- Previous track with the keyboard
    MediaPrevBind = "$MM + $QM + Minus",
    -- Play or pause with the media key
    MediaPlayKeyBind = "XF86AudioPlay",
    -- Pause with the media key
    MediaPauseKeyBind = "XF86AudioPause",
    -- Next track with the media key
    MediaNextKeyBind = "XF86AudioNext",
    -- Previous track with the media key
    MediaPrevKeyBind = "XF86AudioPrev",
    -- Stop with the media key
    MediaStopKeyBind = "XF86AudioStop",

    -- Volume and Brightness
    -- Toggle mute with the keyboard
    VolumeMuteBind = "$MM + $TM + M",
    -- Toggle mute with the media key
    VolumeMuteKeyBind = "XF86AudioMute",
    -- Toggle the microphone mute
    MicMuteBind = "XF86AudioMicMute",
    -- Raise the volume
    VolumeUpBind = "XF86AudioRaiseVolume",
    -- Lower the volume
    VolumeDownBind = "XF86AudioLowerVolume",
    -- Raise the display brightness with the volume key
    BrightnessUpBind = "$QM + XF86AudioRaiseVolume",
    -- Lower the display brightness with the volume key
    BrightnessDownBind = "$QM + XF86AudioLowerVolume",
    -- Raise the display brightness with the scroll wheel
    BrightnessUpScrollBind = "$QM + mouse_up",
    -- Lower the display brightness with the scroll wheel
    BrightnessDownScrollBind = "$QM + mouse_down",
    -- Raise the display brightness with the laptop brightness key
    BrightnessUpKeyBind = "XF86MonBrightnessUp",
    -- Lower the display brightness with the laptop brightness key
    BrightnessDownKeyBind = "XF86MonBrightnessDown",

    -- Utilities
    -- Take a full screenshot
    ScreenshotBind = "Print",
    -- Take a screenshot of an area
    ScreenshotAreaBind = "$MM + $TM + S",
    -- Take a screenshot of an area with the extra modifier
    ScreenshotAreaAltBind = "$MM + $TM + $QM + S",
    -- Pick a color from the screen
    ColorPickerBind = "$MM + $TM + C",
    -- Suspend the system
    SuspendBind = "$MM + $TM + L",
    -- Reset the screen zoom
    ZoomResetBind = "$MM + $TM + Z",
    -- Zoom in with the scroll wheel
    ZoomInBind = "$MM + $TM + mouse_down",
    -- Zoom out with the scroll wheel
    ZoomOutBind = "$MM + $TM + mouse_up",

    -- Layout Scrolling
    -- Move one column left
    ScrollMoveLeftBind = "$MM + $left",
    -- Move one column right
    ScrollMoveRightBind = "$MM + $right",
    -- Make the column narrower
    ScrollResizeLeftBind = "$MM + $SM + $left",
    -- Make the column wider
    ScrollResizeRightBind = "$MM + $SM + $right",
    -- Shrink the column to the configured widths
    ScrollResizeConfLeftBind = "$MM + $QM + $left",
    -- Grow the column to the configured widths
    ScrollResizeConfRightBind = "$MM + $QM + $right",
    -- Set every column to the same width
    ScrollResizeAllBind = "$MM + $QM + A",
    -- Fit the active column
    ScrollFitActiveBind = "$MM + f",
    -- Expand into the free space
    ScrollFitExpandBind = "$MM + $TM + f",
    -- Fit every visible column
    ScrollFitVisibleBind = "$MM + $QM + f",
    -- Fit the active column into view
    ScrollFitIntoViewBind = "$MM + $SM + v",
    -- Promote the window to its own column
    ScrollPromoteBind = "$MM + p",
    -- Swap the column with the one on the left
    ScrollSwapLeftBind = "$MM + $TM + $left",
    -- Swap the column with the one on the right
    ScrollSwapRightBind = "$MM + $TM + $right",
    -- Stop the view from following focus
    ScrollInhibitBind = "$MM + i",
    -- Move the window out of its column
    ScrollExpelBind = "$MM + e",
    -- Pull the next window into this column
    ScrollConsumeBind = "$MM + $SM + C",
    -- Pull in or push out the next window
    ScrollConsumeExpelNextBind = "$MM + x",
    -- Pull in or push out the previous window
    ScrollConsumeExpelPrevBind = "$MM + $TM + x",

    -- Layout Dwindle
    -- Focus the window on the left with the bracket key
    DwindleFocusBracketLeftBind = "$MM + BracketLeft",
    -- Focus the window on the right with the bracket key
    DwindleFocusBracketRightBind = "$MM + BracketRight",
    -- Focus the window on the left
    DwindleFocusLeftBind = "SUPER + $left",
    -- Focus the window on the right
    DwindleFocusRightBind = "SUPER + $right",
    -- Focus the window above
    DwindleFocusUpBind = "SUPER + $up",
    -- Focus the window below
    DwindleFocusDownBind = "SUPER + $down",
    -- Move the window to the left
    DwindleMoveLeftBind = "$MM + $SM + $left",
    -- Move the window to the right
    DwindleMoveRightBind = "$MM + $SM + $right",
    -- Move the window up
    DwindleMoveUpBind = "$MM + $SM + $up",
    -- Move the window down
    DwindleMoveDownBind = "$MM + $SM + $down",
    -- Move the workspace view to the left
    DwindleViewLeftBind = "$QM + $MM + $left",
    -- Move the workspace view to the right
    DwindleViewRightBind = "$QM + $MM + $right",
    -- Make the window narrower
    DwindleShrinkBind = "$MM + $TM + $right",
    -- Make the window wider
    DwindleGrowBind = "$MM + $TM + $left",

    -- Layout Master
    -- Focus the previous window
    MasterFocusPrevBind = "$MM + $up",
    -- Focus the next window
    MasterFocusNextBind = "$MM + $down",
    -- Focus the master window
    MasterFocusMasterBind = "$MM + m",
    -- Swap with the previous window
    MasterSwapPrevBind = "$MM + $TM + $up",
    -- Swap with the next window
    MasterSwapNextBind = "$MM + $TM + $down",
    -- Swap the window with the master
    MasterSwapWithMasterBind = "$MM + Return",
    -- Make the master area smaller
    MasterShrinkBind = "$MM + $left",
    -- Make the master area larger
    MasterGrowBind = "$MM + $right",
    -- Reset the master area size
    MasterResetSizeBind = "$MM + $TM + $left",
    -- Roll the windows forward
    MasterRollNextBind = "$MM + r",
    -- Roll the windows backward
    MasterRollPrevBind = "$MM + $TM + r",
    -- Add a master window
    MasterAddBind = "$MM + i",
    -- Remove a master window
    MasterRemoveBind = "$MM + d",
    -- Rotate the orientation forward
    MasterOrientationNextBind = "$MM + o",
    -- Rotate the orientation backward
    MasterOrientationPrevBind = "$MM + $TM + o",
    -- Center the master
    MasterOrientationCenterBind = "$MM + c",
    -- Put the master on the left
    MasterOrientationLeftBind = "$MM + $left",
    -- Put the master on top
    MasterOrientationTopBind = "$MM + $up",

    -- Layout Monocle
    -- Cycle to the next window with Tab
    MonocleNextTabBind = "$SM + Tab",
    -- Cycle to the next window
    MonocleNextBind = "$MM + $right",
    -- Cycle to the previous window with Tab
    MonoclePrevTabBind = "$SM + $TM + Tab",
    -- Cycle to the previous window
    MonoclePrevBind = "$MM + $left",
}
