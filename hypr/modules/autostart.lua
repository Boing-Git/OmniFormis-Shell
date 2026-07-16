
-------------------
---- AUTOSTART ----
-------------------
local vars = require("modules.variables")

-- See https://wiki.hypr.land/Configuring/Basics/Autostart/

-- Autostart necessary processes (like notifications daemons, status bars, etc.)
-- Or execute your favorite apps at launch like this:
--
 hl.on("hyprland.start", function () 
    hl.exec_cmd("hyprctl setcursor " .. vars.cursor_theme .. " " .. tostring(vars.env_hyprcursor_size))
    hl.exec_cmd("qs")
    hl.exec_cmd("blanket")
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")
    hl.exec_cmd("awww-daemon --format xrgb")
    hl.exec_cmd("hypridle")
    -- Auto mount external drives
    local automount_path = "/home/boing/Dotfiles/scripts/external-drive-automount.sh"
    if hy3.fs.exists(automount_path) then
        hl.exec_cmd(automount_path)
    end
 end)
