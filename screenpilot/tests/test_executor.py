import unittest

from screenpilot.actions import Action
from screenpilot.capture import Shot
from screenpilot.executor import Refused, execute
from screenpilot.geometry import Frame
from screenpilot.wayland import keysym_for_char
from test_keymap import Recorder


class ExecutorTest(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        self.shot = Shot(b"", Frame(0, 0, 1920, 1080, 1568, 882))
        self.inp = Recorder()

    async def run_action(self, action, protected=()):
        return await execute(action, self.shot, self.inp, protected=protected)

    async def test_click_outside_the_screenshot_is_refused(self):
        for x, y in ((2000, 10), (-1, 10), (10, 882)):
            with self.assertRaises(Refused):
                await self.run_action(Action("click", x, y))
        with self.assertRaises(Refused):
            await self.run_action(Action("click"))           # no point at all
        self.assertEqual(self.inp.sent, [])

    async def test_click_on_the_stop_button_is_refused(self):
        protected = [(1728, 16, 176, 68)]
        x, y = self.shot.frame.from_layout(1800, 40)
        with self.assertRaises(Refused):
            await self.run_action(Action("click", x, y), protected)
        x, y = self.shot.frame.from_layout(1720, 40)         # just outside, inside the margin
        with self.assertRaises(Refused):
            await self.run_action(Action("click", x, y), protected)
        self.assertEqual(self.inp.sent, [])

    async def test_drag_ending_on_the_stop_button_is_refused(self):
        x2, y2 = self.shot.frame.from_layout(1800, 40)
        with self.assertRaises(Refused):
            await self.run_action(Action("drag", 10, 10, x2, y2), [(1728, 16, 176, 68)])
        self.assertEqual(self.inp.sent, [])

    async def test_click_lands_in_layout_coordinates(self):
        await self.run_action(Action("right_click", 784, 441))
        self.assertIn(("motion", 960, 540), self.inp.sent)
        self.assertIn(("button", 0x111, 1), self.inp.sent)

    async def test_text_reaches_the_input_unchanged(self):
        await self.run_action(Action("type", text="héllo 😀\n\t"))
        self.assertEqual(self.inp.typed(), [keysym_for_char(c) for c in "héllo 😀\n\t"])

    async def test_several_combos_in_one_key_action(self):
        await self.run_action(Action("key", keys="ctrl+a Delete"))
        self.assertEqual(self.inp.typed(), [ord("a"), 0xffff])

    async def test_bad_combo_is_refused_not_crashed(self):
        with self.assertRaises(Refused):
            await self.run_action(Action("key", keys="ctrl+notakey"))

    async def test_modifier_click_holds_the_modifiers_for_that_click_only(self):
        await self.run_action(Action("click", 784, 441, keys="ctrl+shift"))
        kinds = [e for e in self.inp.sent if e[0] in ("mods", "button")]
        self.assertEqual(kinds, [("mods", 5), ("button", 0x110, 1), ("button", 0x110, 0), ("mods", 0)])

    async def test_scroll_at_a_point_moves_there_first(self):
        await self.run_action(Action("scroll", 784, 441, dy=3))
        self.assertEqual(self.inp.sent[0], ("motion", 960, 540))
        self.assertEqual(self.inp.sent[1:], [("axis", 0, 1)] * 3)   # one notch at a time, like a wheel


if __name__ == "__main__":
    unittest.main()
