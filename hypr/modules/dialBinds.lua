local bind = require("modules.keybind_engine").bind

-- Each bind is an IPC call to the shell that runs now, through the switcher (scripts/shell
-- finds its instance). A plain `qs ipc call` only reaches a shell started from
-- ~/.config/quickshell, and the switcher starts them from the repo's folders
local dial = "~/Dotfiles/scripts/shell ipc call "

bind("DialWallpaperBind", hl.dsp.exec_cmd(dial .. "wallpaper toggle"), { description = "Wallpaper Dial" })
bind("DialAppsBind", hl.dsp.exec_cmd(dial .. "apps toggle"), { description = "App Launcher Dial" })
bind("DialCenterBind", hl.dsp.exec_cmd(dial .. "center toggle"), { description = "Control Center Dial" })
bind("DialPowerBind", hl.dsp.exec_cmd(dial .. "power toggle"), { description = "Power Menu Dial" })
bind("DialScreenshotBind", hl.dsp.exec_cmd(dial .. "screenshot open"), { description = "Screenshot Tool" })
bind("DialLockBind", hl.dsp.exec_cmd(dial .. "lock lock"), { description = "Lock Screen" })
