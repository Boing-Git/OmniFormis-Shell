
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
    -- the clipboard history (cliphist), pausable from the shells' Clipboard tile
    hl.exec_cmd("wl-paste --type text --watch ~/Dotfiles/scripts/clip-store.sh")
    hl.exec_cmd("wl-paste --type image --watch ~/Dotfiles/scripts/clip-store.sh")
    hl.exec_cmd("awww-daemon --format xrgb")
    hl.exec_cmd("sleep 1 && awww restore")
    -- the chosen shell (Dial-E, Puffy or Droplet): scripts/shell remembers which
    hl.exec_cmd("~/Dotfiles/scripts/shell start")
    -- the assistant (pull a drop down from the top edge, or Super + A): next to any shell
    hl.exec_cmd("env -u QML_IMPORT_PATH qs -p ~/Dotfiles/assistant")
    hl.exec_cmd("hypridle")
 end)

-- A monitor that comes back (a DisplayPort monitor does after a suspend or a long sleep) got
-- a black wallpaper: awww-daemon paints a new output black until it is told to restore
hl.on("monitor.added", function ()
    hl.exec_cmd("sleep 1 && awww restore")
end)
