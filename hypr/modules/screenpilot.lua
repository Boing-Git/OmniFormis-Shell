--------------------------------------------------------------------------------
-- screenpilot (screenpilot/): the AI that sees the screen and can act
--
-- STOP and resume are Hyprland's own binds, so they work whatever has the focus, in every
-- submap (submap_universal) and while an input inhibitor such as the lock is up (locked).
-- Hyprland runs binds only for real keyboards, never for the AI's virtual one, so the AI can't
-- press any of these. Without screenpilot installed the binds do nothing.
--------------------------------------------------------------------------------

local bind = require("modules.keybind_engine").bind
local sp = "screenpilot "

bind("ScreenpilotStopBind", hl.dsp.exec_cmd(sp .. "stop"),
    { description = "Stop the screen AI", submap_universal = true, locked = true })
bind("ScreenpilotResumeBind", hl.dsp.exec_cmd(sp .. "resume"),
    { description = "Resume the screen AI", submap_universal = true, locked = true })
bind("ScreenpilotAskBind", hl.dsp.exec_cmd(sp .. "prompt ask"), { description = "Ask the screen AI" })
bind("ScreenpilotActBind", hl.dsp.exec_cmd(sp .. "prompt act"), { description = "Let the screen AI act" })
bind("ScreenpilotSayBind", hl.dsp.exec_cmd(sp .. "say --selection"), { description = "Read the selection aloud" })
bind("ScreenpilotSandboxBind", hl.dsp.workspace.toggle_special("screenpilot"), { description = "Show the screen AI's desktop" })

-- (The overlay is kept out of the model's screenshots by the daemon itself: no_screen_share on
-- a layer does not hide it from grim on Hyprland 0.57.)

-- The sandbox (a nested sway; its window's class is wlroots) lives in its own special
-- workspace and keeps drawing while hidden, or the AI's screenshots of it would hang
hl.window_rule({
    name = "screenpilot-sandbox",
    match = { class = "^wlroots$" },
    workspace = "special:screenpilot silent",
    render_unfocused = true,
})
