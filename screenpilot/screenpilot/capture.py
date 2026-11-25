"""What the model sees: grim, scaled down, with blocklisted apps refused (or blurred) and the
overlay's protected rects painted over.

Shared mode: the focused monitor, the active window or a slurp region of the user's desktop.
Sandbox mode: the nested sway's whole output.
"""
import asyncio
import io
import json
import os
import re
from dataclasses import dataclass

from PIL import Image, ImageDraw, ImageFilter

from . import proc
from .geometry import Frame, fit, logical_size

PAINT = (24, 24, 24)  # what covers the overlay's rects in a screenshot


class Blocked(Exception):
    """A blocklisted app is on screen and the policy is to refuse."""


@dataclass
class Shot:
    png: bytes
    frame: Frame
    path: str | None = None

    @property
    def size(self):
        return (self.frame.img_w, self.frame.img_h)


async def hypr(what):
    return json.loads(await proc.run(["hyprctl", "-j", what], timeout=5))


def hypr_windows(clients, monitors):
    """Hyprland's clients that are on screen now, as {"name", "rect"} (layout coordinates)."""
    shown = {m["activeWorkspace"]["id"] for m in monitors}
    shown |= {m["specialWorkspace"]["id"] for m in monitors if m["specialWorkspace"].get("id")}  # no "id" when none is open
    out = []
    for c in clients:
        if not c.get("mapped", True) or c.get("hidden") or not c.get("visible", True):
            continue
        if c["workspace"]["id"] not in shown:
            continue
        out.append({"name": f"{c['class']} {c['initialClass']} {c['title']}", "rect": (*c["at"], *c["size"])})
    return out


def sway_windows(tree):
    """The nested sway's windows that are on screen, the same shape as hypr_windows."""
    out = []

    def walk(node, visible):
        visible = visible and node.get("visible", True) is not False
        if node.get("app_id") or node.get("window_properties"):
            if visible:
                app = node.get("app_id") or node["window_properties"].get("class", "")
                r = node["rect"]
                out.append({"name": f"{app} {node.get('name') or ''}".strip(), "rect": (r["x"], r["y"], r["width"], r["height"])})
        for child in node.get("nodes", []) + node.get("floating_nodes", []):
            walk(child, visible)
    walk(tree, True)
    return out


def _overlaps(a, b):
    return a[0] < b[0] + b[2] and b[0] < a[0] + a[2] and a[1] < b[1] + b[3] and b[1] < a[1] + a[3]


def _image_box(frame, rect):
    x0, y0 = frame.from_layout(rect[0], rect[1])
    x1, y1 = frame.from_layout(rect[0] + rect[2], rect[1] + rect[3])
    return tuple(int(round(v)) for v in (max(0, x0), max(0, y0), min(frame.img_w, x1), min(frame.img_h, y1)))


def censor(img, frame, windows, blocklist, action, protected):
    """Refuses or blurs blocklisted windows in the captured area; paints over protected rects."""
    area = (frame.ox, frame.oy, frame.lw, frame.lh)
    patterns = [re.compile(p) for p in blocklist]
    for w in windows:
        if not _overlaps(w["rect"], area) or not any(p.search(w["name"]) for p in patterns):
            continue
        if action != "blur":
            raise Blocked(f"a blocklisted app is on screen ({w['name'].split()[0]}): not capturing")
        box = _image_box(frame, w["rect"])
        if box[2] > box[0] and box[3] > box[1]:
            region = img.crop(box).resize((max(1, (box[2] - box[0]) // 24), max(1, (box[3] - box[1]) // 24)))
            img.paste(region.resize((box[2] - box[0], box[3] - box[1])).filter(ImageFilter.GaussianBlur(8)), box[:2])
    draw = ImageDraw.Draw(img)
    for rect in protected:
        if _overlaps(rect, area):
            x0, y0, x1, y1 = _image_box(frame, rect)
            draw.rectangle((x0, y0, x1 - 1, y1 - 1), fill=PAINT)
    return img


async def grab(cfg, mode="monitor", *, wayland_display=None, protected=()) -> Shot:
    """One screenshot as the model will see it."""
    env = None
    if wayland_display:  # the sandbox: its one output, at scale 1
        env = dict(os.environ, WAYLAND_DISPLAY=wayland_display)
        raw = await proc.run(["grim", "-"], env=env, timeout=10)
        img = Image.open(io.BytesIO(raw)).convert("RGB")
        ox, oy, lw, lh = 0, 0, img.width, img.height
        tree = json.loads(await proc.run(["swaymsg", "-t", "get_tree", "-r"], env=env, timeout=5))
        windows = sway_windows(tree)
    else:
        monitors, clients = await asyncio.gather(hypr("monitors"), hypr("clients"))
        windows = hypr_windows(clients, monitors)
        if mode == "window":
            active = await hypr("activewindow")
            if not active:
                raise RuntimeError("no active window to capture")
            (ox, oy), (lw, lh) = active["at"], active["size"]
            raw = await proc.run(["grim", "-g", f"{ox},{oy} {lw}x{lh}", "-"], timeout=10)
        elif mode == "region":
            sel = (await proc.run(["slurp"], timeout=120)).decode().strip()    # "x,y wxh"
            m = re.fullmatch(r"(-?\d+),(-?\d+) (\d+)x(\d+)", sel)
            if not m:
                raise RuntimeError("no region chosen")
            ox, oy, lw, lh = map(int, m.groups())
            raw = await proc.run(["grim", "-g", sel, "-"], timeout=10)
        else:
            mon = next((m for m in monitors if m["focused"]), monitors[0])
            ox, oy = mon["x"], mon["y"]
            lw, lh = logical_size(mon)
            raw = await proc.run(["grim", "-o", mon["name"], "-"], timeout=10)
        img = Image.open(io.BytesIO(raw)).convert("RGB")
    w, h = fit(img.width, img.height, cfg["maxEdge"])
    if (w, h) != img.size:
        img = img.resize((w, h), Image.LANCZOS)
    frame = Frame(ox, oy, lw, lh, w, h)
    img = censor(img, frame, windows, cfg["blocklist"], cfg["blockAction"], protected)
    buf = io.BytesIO()
    img.save(buf, "PNG")
    return Shot(buf.getvalue(), frame)
