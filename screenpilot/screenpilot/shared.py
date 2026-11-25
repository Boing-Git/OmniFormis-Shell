"""Shared mode: the AI on the user's own desktop, with the one real pointer.

The AI's pointer and keyboard are the same Wayland client as in the sandbox, pointed at Hyprland.
Its events never pass through /dev/input, so the user's own (userwatch.py) are easy to tell
apart, and Hyprland runs no binds for them. Around each action the real cursor is saved and put
back; key combos aimed at a window go there with send_shortcut, without moving the focus.
"""
import contextlib
import json
import re

from . import proc
from .geometry import logical_size
from .wayland import WaylandInput

STOP_DESCRIPTION = "Stop the screen AI"  # hypr/modules/screenpilot.lua's STOP bind
HYPR_MODS = {"ctrl": "CTRL", "control": "CTRL", "shift": "SHIFT", "alt": "ALT", "option": "ALT",
             "mod1": "ALT", "super": "SUPER", "cmd": "SUPER", "meta": "SUPER", "win": "SUPER",
             "logo": "SUPER", "mod4": "SUPER"}


def layout_box(monitors):
    """The rectangle around every monitor, in layout coordinates: what absolute motion spans."""
    rects = [(m["x"], m["y"], *logical_size(m)) for m in monitors]
    x0, y0 = min(r[0] for r in rects), min(r[1] for r in rects)
    x1, y1 = max(r[0] + r[2] for r in rects), max(r[1] + r[3] for r in rects)
    return (x0, y0, x1 - x0, y1 - y0)


def guard_problem(binds, overlay_alive):
    """Why the AI must not go on (STOP has lost a way in), or None."""
    if not overlay_alive:
        return "the overlay (and its STOP button) isn't running"
    if not any(b.get("description") == STOP_DESCRIPTION for b in binds):
        return "the STOP shortcut is missing from Hyprland's binds"
    return None


def hypr_shortcut(combo):
    """"ctrl+shift+t" -> ("CTRL SHIFT", "t") for send_shortcut."""
    parts = combo.strip().split("+")
    if combo.strip().endswith("++"):
        parts = parts[:-2] + ["+"]
    *mods, key = parts
    return " ".join(HYPR_MODS[m.strip().lower()] for m in mods), key.strip()


async def dispatch(lua):
    out = (await proc.run(["hyprctl", "dispatch", lua], timeout=5)).decode().strip()
    if out != "ok":
        raise RuntimeError(out.splitlines()[0] if out else "hyprctl dispatch failed")


def _selector(target):
    return re.sub(r"[\"'\\\[\]]", "", target or "")


class SharedInput(WaylandInput):
    def __init__(self, display, delay=0.06, move="virtual"):
        super().__init__(display, delay)
        self.move = move  # "virtual": absolute motion; "hyprctl": Hyprland moves the cursor

    async def move_to(self, x, y):
        await self._gate()
        if self.move == "hyprctl":
            await dispatch(f"hl.dsp.cursor.move({{ x = {round(x)}, y = {round(y)} }})")
        else:
            self._motion(x, y)

    async def focus_window(self, target):
        t = _selector(target)
        for key in ("class", "title"):
            try:
                return await dispatch(f"hl.dsp.focus({{ window = '{key}:(?i){t}' }})")
            except RuntimeError:
                continue
        raise RuntimeError(f"no window matches {target!r}")

    async def send_shortcut(self, combo, window):
        """A combo to one window, without moving the focus or touching the pointer."""
        await self._gate()
        mods, key = hypr_shortcut(combo)
        await dispatch(f"hl.dsp.send_shortcut({{ mods = '{mods}', key = '{_selector(key)}', "
                       f"window = 'class:(?i){_selector(window)}' }})")

    @contextlib.asynccontextmanager
    async def burst(self, user_moved):
        """Puts the real cursor back where it was after an action, unless the user took it."""
        pos = json.loads(await proc.run(["hyprctl", "-j", "cursorpos"], timeout=5))
        try:
            yield
        finally:
            if not user_moved():
                await dispatch(f"hl.dsp.cursor.move({{ x = {pos['x']}, y = {pos['y']} }})")
