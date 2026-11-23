local bind = require("modules.keybind_engine").bind

-- Dial-Quickshell runs as its own instance, so each bind sends an IPC call to it
local dial = "qs ipc call "

bind("DialWallpaperBind", hl.dsp.exec_cmd(dial .. "wallpaper toggle"), { description = "Wallpaper Dial" })
bind("DialAppsBind", hl.dsp.exec_cmd(dial .. "apps toggle"), { description = "App Launcher Dial" })
bind("DialCenterBind", hl.dsp.exec_cmd(dial .. "center toggle"), { description = "Control Center Dial" })
bind("DialPowerBind", hl.dsp.exec_cmd(dial .. "power toggle"), { description = "Power Menu Dial" })
bind("DialScreenshotBind", hl.dsp.exec_cmd(dial .. "screenshot open"), { description = "Screenshot Tool" })
bind("DialLockBind", hl.dsp.exec_cmd(dial .. "lock lock"), { description = "Lock Screen" })

-- the assistant runs as its own instance too (~/Dotfiles/assistant), next to any shell
bind("AssistantBind", hl.dsp.exec_cmd("qs -p ~/Dotfiles/assistant ipc call assistant toggle"), { description = "Ask the local AI" })
