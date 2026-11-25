import unittest

from screenpilot import wayland
from screenpilot.wayland import Halted, keymap_text, keysym_for_char, parse_combo


class Recorder(wayland.Input):
    """The input logic with the wire replaced by a list."""
    def __init__(self):
        super().__init__(delay=0)
        self.sent = []

    def _motion(self, x, y):
        self.sent.append(("motion", x, y))

    def _button(self, code, state):
        self.sent.append(("button", code, state))

    def _axis(self, axis, notches):
        self.sent.append(("axis", axis, notches))

    def _key(self, code, state):
        self.sent.append(("key", self.keysyms[code - 1], state))

    def _mods(self, mask):
        self.sent.append(("mods", mask))

    def _keymap(self, keysyms):
        self.sent.append(("keymap", list(keysyms)))

    def typed(self):
        return [k for kind, k, state in (e for e in self.sent if e[0] == "key") if state == 1]


class ComboTest(unittest.TestCase):
    def test_modifiers_and_key(self):
        self.assertEqual(parse_combo("ctrl+shift+t"), (5, ord("t")))
        self.assertEqual(parse_combo("super+Return"), (64, 0xff0d))
        self.assertEqual(parse_combo("alt+F4"), (8, 0xffc1))
        self.assertEqual(parse_combo("Escape"), (0, 0xff1b))
        self.assertEqual(parse_combo("ctrl+T"), (4, ord("t")))           # shift is said, not implied
        self.assertEqual(parse_combo("cmd+Page_Down"), (64, 0xff56))
        self.assertEqual(parse_combo("ctrl++"), (4, ord("+")))

    def test_unknown_parts_raise(self):
        for bad in ("bogus+x", "ctrl+", "ctrl+shift", "", "ctrl+notakey"):
            with self.assertRaises(ValueError, msg=bad):
                parse_combo(bad)

    def test_keysyms_for_text(self):
        self.assertEqual(keysym_for_char("a"), 0x61)
        self.assertEqual(keysym_for_char("é"), 0xe9)
        self.assertEqual(keysym_for_char("😀"), 0x101f600)
        self.assertEqual(keysym_for_char("\n"), 0xff0d)
        self.assertEqual(keysym_for_char("\t"), 0xff09)

    def test_keymap_text(self):
        text = keymap_text([ord("a"), 0x1F600 + 0x1000000])
        self.assertIn("<K1> = 9;", text)
        self.assertIn("key <K1> {[ 0x61 ]};", text)
        self.assertIn("key <K2> {[ 0x101f600 ]};", text)
        self.assertIn('include "complete"', text)


class InputLogicTest(unittest.IsolatedAsyncioTestCase):
    async def test_text_is_typed_as_written_with_one_keymap(self):
        r = Recorder()
        await r.type_text("héllo 😀\n\t")
        self.assertEqual(r.typed(), [keysym_for_char(c) for c in "héllo 😀\n\t"])
        self.assertEqual(sum(1 for e in r.sent if e[0] == "keymap"), 1)
        self.assertEqual(r.held, set())

    async def test_combo_sets_and_clears_modifiers(self):
        r = Recorder()
        await r.key("ctrl+shift+t")
        mods = [e for e in r.sent if e[0] == "mods"]
        self.assertEqual(mods, [("mods", 5), ("mods", 0)])

    async def test_release_all_lets_go_and_blocks_until_unblocked(self):
        r = Recorder()
        await r.press("left")
        r.release_all()
        self.assertIn(("button", 0x110, 0), r.sent)
        self.assertEqual(r.held, set())
        with self.assertRaises(Halted):
            await r.click()
        with self.assertRaises(Halted):
            await r.type_text("x")
        r.unblock()
        await r.click()

    async def test_drag_holds_then_releases(self):
        r = Recorder()
        await r.drag(0, 0, 100, 50)
        buttons = [e for e in r.sent if e[0] == "button"]
        self.assertEqual(buttons, [("button", 0x110, 1), ("button", 0x110, 0)])
        self.assertEqual([e for e in r.sent if e[0] == "motion"][-1], ("motion", 100, 50))


if __name__ == "__main__":
    unittest.main()
