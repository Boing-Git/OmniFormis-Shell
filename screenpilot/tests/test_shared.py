import asyncio
import unittest

from screenpilot import shared
from screenpilot.actions import Action
from screenpilot.capture import Shot
from screenpilot.executor import execute
from screenpilot.geometry import Frame
from helpers import make_daemon, private_runtime
from test_keymap import Recorder

MON = {"x": 0, "y": 0, "width": 1920, "height": 1080, "scale": 1, "transform": 0}


class SharedPureTest(unittest.TestCase):
    def test_layout_box_spans_every_monitor(self):
        left = dict(MON, x=-1080, y=-200, width=1920, height=1080, transform=1)   # rotated, scale 1
        right = dict(MON, x=0, y=0, width=2560, height=1440, scale=1.25)
        self.assertEqual(shared.layout_box([left, right]), (-1080, -200, 1080 + 2048, 1920 + 0))

    def test_guard_finds_a_missing_stop_shortcut_or_overlay(self):
        # a Lua bind shows its function, not its command: it is found by its description
        binds = [{"key": "Escape", "modmask": 64, "dispatcher": "function: 0x5f1", "arg": "118",
                  "description": "Stop the screen AI"}]
        self.assertIsNone(shared.guard_problem(binds, overlay_alive=True))
        self.assertIn("STOP shortcut", shared.guard_problem([], overlay_alive=True))
        self.assertIn("overlay", shared.guard_problem(binds, overlay_alive=False))

    def test_shortcut_for_hyprland(self):
        self.assertEqual(shared.hypr_shortcut("ctrl+shift+t"), ("CTRL SHIFT", "t"))
        self.assertEqual(shared.hypr_shortcut("super+Return"), ("SUPER", "Return"))
        self.assertEqual(shared.hypr_shortcut("F5"), ("", "F5"))


class YieldTest(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        private_runtime(self)

    async def running(self, **cfg):
        d = make_daemon()
        d.cfg.update({"mode": "shared", "idleMs": 60, **cfg})
        d.input = Recorder()
        task = d.start("act", "slow")
        while d.state not in ("thinking", "acting"):
            await asyncio.sleep(0.005)
        self.addAsyncCleanup(self._end, d, task)
        return d

    async def _end(self, d, task):
        d.stop("cleanup")
        await asyncio.wait({task}, timeout=1)

    async def test_touching_the_mouse_pauses_and_lets_go(self):
        d = await self.running()
        await d.input.press("left")
        d.on_user_input()
        self.assertEqual(d.state, "paused")
        self.assertTrue(d.input.paused)
        self.assertEqual(d.input.held, set())

    async def test_quiet_for_idle_ms_carries_on(self):
        d = await self.running()
        d.on_user_input()
        await asyncio.sleep(0.03)
        d.on_user_input()                  # still busy: the clock starts again
        await asyncio.sleep(0.04)
        self.assertEqual(d.state, "paused")
        await asyncio.sleep(0.1)
        self.assertEqual(d.state, "thinking")
        self.assertFalse(d.input.paused)

    async def test_resume_carries_on_at_once(self):
        d = await self.running(idleMs=10_000)
        d.on_user_input()
        d.resume()
        self.assertEqual(d.state, "thinking")
        self.assertFalse(d.input.paused)

    async def test_stop_on_user_input_when_asked(self):
        d = await self.running(stopOnUserInput=True)
        d.on_user_input()
        self.assertEqual(d.state, "halted")

    async def test_input_while_idle_changes_nothing(self):
        d = make_daemon()
        d.cfg["mode"] = "shared"
        d.on_user_input()
        self.assertEqual(d.state, "idle")


class PausedInputTest(unittest.IsolatedAsyncioTestCase):
    async def test_input_waits_while_paused(self):
        r = Recorder()
        r.paused = True
        typing = asyncio.ensure_future(r.type_text("ab"))
        await asyncio.sleep(0.1)
        self.assertEqual(r.typed(), [])
        r.paused = False
        await asyncio.wait_for(typing, 1)
        self.assertEqual(r.typed(), [ord("a"), ord("b")])


class GlideTest(unittest.IsolatedAsyncioTestCase):
    async def test_the_ai_cursor_glides_before_the_pointer_moves(self):
        r = Recorder()
        seen = []

        async def glide(x, y):
            seen.append(("glide", x, y, len(r.sent)))
        await execute(Action("click", 784, 441), Shot(b"", Frame(0, 0, 1920, 1080, 1568, 882)), r, on_point=glide)
        self.assertEqual(seen, [("glide", 960, 540, 0)])   # before anything was sent


if __name__ == "__main__":
    unittest.main()
