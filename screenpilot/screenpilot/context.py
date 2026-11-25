"""The text that goes with each screenshot: which windows, workspaces and monitors there are.
Trimmed to what helps the model (no addresses, pids or format details)."""
import json
import os

from . import proc


def _compact(data):
    return json.dumps(data, ensure_ascii=False, separators=(",", ":"))


def trim_hypr(clients, monitors):
    windows = sorted(clients, key=lambda c: c.get("focusHistoryID", 99))
    keep = lambda c: {"class": c["class"], "title": c["title"][:120], "workspace": c["workspace"]["name"],
                      "at": c["at"], "size": c["size"], "onScreen": c.get("visible", True)}
    return _compact({
        "active": keep(windows[0]) if windows else None,
        "windows": [keep(c) for c in windows[:30]],
        "monitors": [{"name": m["name"], "at": [m["x"], m["y"]], "scale": m["scale"], "focused": m["focused"],
                      "workspace": m["activeWorkspace"]["name"]} for m in monitors],
    })


async def describe(sandbox_display=None) -> str:
    if sandbox_display:
        from .capture import sway_windows
        env = dict(os.environ, WAYLAND_DISPLAY=sandbox_display)
        tree = json.loads(await proc.run(["swaymsg", "-t", "get_tree", "-r"], env=env, timeout=5))
        return _compact({"sandbox": True, "windows": sway_windows(tree)})
    from .capture import hypr
    return trim_hypr(await hypr("clients"), await hypr("monitors"))
