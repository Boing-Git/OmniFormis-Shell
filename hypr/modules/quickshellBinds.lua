local bind = require("modules.keybind_engine").bind

-- Bind each shortcut to the specific Quickshell global identifier
bind("QsLauncherBind", hl.dsp.global("quickshell:launcher"), { description = "Launcher" })
bind("QsScreenshotBind", hl.dsp.global("quickshell:screenshot"), { description = "Screenshot" })
bind("QsLensBind", hl.dsp.global("quickshell:lens"), { description = "Circle to Search" })
bind("QsWallpaperBind", hl.dsp.global("quickshell:wallpaper"), { description = "Wallpaper" })
bind("QsColorSchemeBind", hl.dsp.global("quickshell:color_scheme"), { description = "Color Scheme" })
bind("QsControlCenterBind", hl.dsp.global("quickshell:control_center"), { description = "Control Center" })
bind("QsPowerMenuBind", hl.dsp.global("quickshell:power_menu"), { description = "Power Menu" })
bind("QsOverviewBind", hl.dsp.global("quickshell:overview"), { description = "Overview" })
bind("QsGameLibraryBind", hl.dsp.global("quickshell:game_library"), { description = "Game Library" })
bind("QsEmojiPickerBind", hl.dsp.global("quickshell:emoji_picker"), { description = "Emoji Picker" })
bind("QsClipboardBind", hl.dsp.global("quickshell:clipboard"), { description = "Clipboard" })
bind("QsCheatSheetBind", hl.dsp.global("quickshell:cheat_sheet"), { description = "Keybind Cheat Sheet" })
