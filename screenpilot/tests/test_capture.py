import json
import unittest

from PIL import Image

from screenpilot import capture, context
from screenpilot.geometry import Frame

MONITORS = [{"name": "DP-1", "x": 0, "y": 0, "width": 1920, "height": 1080, "scale": 1, "transform": 0,
             "focused": True, "activeWorkspace": {"id": 1, "name": "1"},
             "specialWorkspace": {"address": "", "type": "", "name": ""}}]   # as 0.57 gives it with none open


def client(cls, ws, at=(100, 100), size=(400, 300), title="", **kw):
    c = {"class": cls, "initialClass": cls, "title": title, "workspace": {"id": ws, "name": str(ws)},
         "at": list(at), "size": list(size), "mapped": True, "hidden": False, "visible": True}
    c.update(kw)
    return c


class CensorTest(unittest.TestCase):
    def setUp(self):
        self.frame = Frame(0, 0, 1920, 1080, 960, 540)    # the model sees half size
        self.img = Image.new("RGB", (960, 540), (200, 30, 30))

    def test_blocklisted_window_on_screen_refuses(self):
        wins = capture.hypr_windows([client("org.keepassxc.KeePassXC", 1)], MONITORS)
        with self.assertRaises(capture.Blocked) as e:
            capture.censor(self.img, self.frame, wins, ["(?i)keepass"], "refuse", [])
        self.assertIn("KeePassXC", str(e.exception))

    def test_blocklisted_window_on_another_workspace_is_fine(self):
        wins = capture.hypr_windows([client("org.keepassxc.KeePassXC", 2, visible=False)], MONITORS)
        out = capture.censor(self.img, self.frame, wins, ["(?i)keepass"], "refuse", [])
        self.assertEqual(out.getpixel((100, 100)), (200, 30, 30))

    def test_blocklist_matches_titles_too(self):
        wins = capture.hypr_windows([client("firefox", 1, title="Bitwarden — vault")], MONITORS)
        with self.assertRaises(capture.Blocked):
            capture.censor(self.img, self.frame, wins, ["(?i)bitwarden"], "refuse", [])

    def test_blur_hides_only_that_window(self):
        img = self.img.copy()
        for x in range(50, 250, 2):                       # stripes inside the window's area
            for y in range(50, 200):
                img.putpixel((x, y), (255, 255, 255))
        wins = capture.hypr_windows([client("KeePassXC", 1, at=(100, 100), size=(400, 300))], MONITORS)
        out = capture.censor(img, self.frame, wins, ["(?i)keepass"], "blur", [])
        self.assertNotEqual(out.getpixel((100, 100)), (255, 255, 255))           # inside: a stripe no more
        self.assertEqual(out.getpixel((600, 400)), (200, 30, 30))               # outside: as it was

    def test_protected_rects_are_painted_flat(self):
        out = capture.censor(self.img, self.frame, [], [], "refuse", [(1728, 16, 176, 68)])
        self.assertEqual(out.getpixel((864 + 40, 8 + 15)), capture.PAINT)
        self.assertEqual(out.getpixel((100, 100)), (200, 30, 30))

    def test_sway_tree_windows(self):
        tree = {"nodes": [{"type": "output", "nodes": [{"type": "workspace", "visible": True, "nodes": [
            {"app_id": "foot", "name": "sh", "rect": {"x": 0, "y": 0, "width": 640, "height": 800}, "visible": True},
            {"app_id": None, "window_properties": {"class": "KeePassXC"}, "name": "db",
             "rect": {"x": 640, "y": 0, "width": 640, "height": 800}, "visible": True}],
            "floating_nodes": []}]}]}
        wins = capture.sway_windows(tree)
        self.assertEqual([w["name"] for w in wins], ["foot sh", "KeePassXC db"])
        self.assertEqual(wins[1]["rect"], (640, 0, 640, 800))


class ContextTest(unittest.TestCase):
    def test_trimmed_hyprland_context(self):
        clients = [client("firefox", 1, title="Docs", address="0xabc", pid=4, focusHistoryID=0),
                   client("foot", 2, title="sh", visible=False, focusHistoryID=1)]
        text = context.trim_hypr(clients, MONITORS)
        data = json.loads(text)
        self.assertEqual(data["active"]["class"], "firefox")
        self.assertEqual([w["class"] for w in data["windows"]], ["firefox", "foot"])
        self.assertNotIn("pid", text)
        self.assertNotIn("0xabc", text)


if __name__ == "__main__":
    unittest.main()
