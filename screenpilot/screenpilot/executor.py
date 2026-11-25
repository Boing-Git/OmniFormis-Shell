"""Runs one Action: checks it, maps its screenshot pixels to the desktop, and drives the input.

Refused (nothing is sent): a point outside the screenshot the model saw, a pointer action on or
near screenpilot's own STOP button (or confirm box), a key the input can't type.
"""
import asyncio

MARGIN = 12  # around the protected rects, in layout pixels


class Refused(Exception):
    pass


def _inside(rect, x, y):
    rx, ry, rw, rh = rect
    return rx - MARGIN <= x < rx + rw + MARGIN and ry - MARGIN <= y < ry + rh + MARGIN


async def execute(action, shot, inp, *, protected=(), on_point=None) -> str:
    """Does the action; returns a short note for the model. on_point(x, y) is awaited before a
    pointer action (shared mode: the AI cursor glides there first)."""
    w, h = shot.size

    def point(px, py):
        if px is None or py is None or not shot.frame.contains(px, py):
            raise Refused(f"({px}, {py}) is outside the {w}x{h} screenshot")
        x, y = shot.frame.to_layout(px, py)
        if any(_inside(r, x, y) for r in protected):
            raise Refused("that is screenpilot's own STOP button: the AI never touches it")
        return x, y

    async def go(px, py):
        x, y = point(px, py)
        if on_point:
            await on_point(x, y)
        await inp.move_to(x, y)
        return x, y

    k = action.kind
    if k in ("screenshot", "done"):
        return "ok"
    if k == "wait":
        await asyncio.sleep(1)
        return "waited 1 s"
    if k == "move":
        await go(action.x, action.y)
    elif k in ("click", "right_click", "middle_click", "double_click"):
        point(action.x, action.y)
        await go(action.x, action.y)
        if k == "double_click":
            await inp.double_click()
        else:
            await inp.click({"click": action.button or "left", "right_click": "right", "middle_click": "middle"}[k])
    elif k == "drag":
        point(action.x, action.y)
        x2, y2 = point(action.x2, action.y2)
        x1, y1 = await go(action.x, action.y)
        await inp.drag(x1, y1, x2, y2)
    elif k == "scroll":
        if action.x is not None:
            await go(action.x, action.y)
        await inp.scroll(action.dx, action.dy)
    elif k == "type":
        await inp.type_text(action.text)
    elif k == "key":
        combos = action.keys.split()
        if not combos:
            raise Refused("no key given")
        from .wayland import parse_combo
        for combo in combos:
            try:
                parse_combo(combo)
            except ValueError as e:
                raise Refused(str(e))
        for combo in combos:
            await inp.key(combo)
    elif k == "focus":
        await inp.focus_window(action.target)
    return f"{k} done"
