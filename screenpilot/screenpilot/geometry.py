"""Where a pixel of what the model saw is on the desktop.

Every capture covers a rectangle of the layout (Hyprland's logical coordinates: monitor positions,
window `at`/`size`, `hyprctl dispatch` moves) and is scaled to the image the model gets. A Frame
holds both, so a point the model names maps straight back, whatever the monitor's scale,
rotation or position: grim's image is already upright, and only the logical size depends on them.
"""
from dataclasses import dataclass


def logical_size(mon: dict) -> tuple:
    """A Hyprland monitor's size in layout coordinates (`hyprctl -j monitors` gives pixels)."""
    w, h = mon["width"] / mon["scale"], mon["height"] / mon["scale"]
    return (h, w) if mon.get("transform", 0) % 2 else (w, h)


def fit(w: int, h: int, max_edge: int) -> tuple:
    """The size to scale (w, h) to so its long edge is at most max_edge."""
    if max(w, h) <= max_edge:
        return (w, h)
    s = max_edge / max(w, h)
    return (round(w * s), round(h * s))


@dataclass
class Frame:
    ox: float       # the captured rectangle, in layout coordinates
    oy: float
    lw: float
    lh: float
    img_w: int      # the image the model sees
    img_h: int

    def to_layout(self, px, py):
        return (self.ox + px * self.lw / self.img_w, self.oy + py * self.lh / self.img_h)

    def from_layout(self, x, y):
        return ((x - self.ox) * self.img_w / self.lw, (y - self.oy) * self.img_h / self.lh)

    def contains(self, px, py):
        return 0 <= px < self.img_w and 0 <= py < self.img_h
