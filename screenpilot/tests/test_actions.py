import unittest

from screenpilot.actions import Action, from_claude, from_json


class FromClaudeTest(unittest.TestCase):
    def test_clicks(self):
        self.assertEqual(from_claude("left_click", {"coordinate": [10, 20]}), Action("click", 10, 20))
        self.assertEqual(from_claude("right_click", {"coordinate": [1, 2]}), Action("right_click", 1, 2))
        self.assertEqual(from_claude("middle_click", {"coordinate": [1, 2]}), Action("middle_click", 1, 2))
        self.assertEqual(from_claude("double_click", {"coordinate": [1, 2]}), Action("double_click", 1, 2))
        self.assertEqual(from_claude("left_click", {"coordinate": [1, 2], "text": "ctrl+shift"}).keys, "ctrl+shift")

    def test_drag_move_scroll(self):
        self.assertEqual(from_claude("left_click_drag", {"start_coordinate": [1, 2], "coordinate": [3, 4]}),
                         Action("drag", 1, 2, 3, 4))
        self.assertEqual(from_claude("mouse_move", {"coordinate": [5, 6]}), Action("move", 5, 6))
        self.assertEqual(from_claude("scroll", {"scroll_direction": "down", "scroll_amount": 3, "coordinate": [5, 6]}),
                         Action("scroll", 5, 6, dy=3))
        self.assertEqual(from_claude("scroll", {"scroll_direction": "left", "scroll_amount": 2}), Action("scroll", dx=-2))

    def test_keyboard_and_the_rest(self):
        self.assertEqual(from_claude("type", {"text": "hi"}), Action("type", text="hi"))
        self.assertEqual(from_claude("key", {"text": "ctrl+l", "repeat": 2}), Action("key", keys="ctrl+l ctrl+l"))
        self.assertEqual(from_claude("wait", {"duration": 2}), Action("wait"))
        self.assertEqual(from_claude("screenshot", {}), Action("screenshot"))

    def test_members_screenpilot_switched_off_raise(self):
        for name in ("triple_click", "zoom", "hold_key", "left_mouse_down", "cursor_position", "bogus"):
            with self.assertRaises(ValueError, msg=name):
                from_claude(name, {})


class FromJsonTest(unittest.TestCase):
    SIZE = (1000, 800)

    def test_fenced_json_in_per_mille(self):
        a = from_json('```json\n{"action": "click", "x": 500, "y": 250}\n```', self.SIZE)
        self.assertEqual(a, Action("click", 500, 200))

    def test_prose_and_thinking_around_it(self):
        a = from_json('<think>hmm {"no": 1}</think> Sure! {"action": "type", "text": "a {b}", "reason": "fill"} done',
                      self.SIZE)
        self.assertEqual(a, Action("type", text="a {b}", reason="fill"))

    def test_every_kind(self):
        self.assertEqual(from_json('{"action": "drag", "x": 0, "y": 0, "x2": 1000, "y2": 1000}', self.SIZE),
                         Action("drag", 0, 0, 1000, 800))
        self.assertEqual(from_json('{"action": "scroll", "x": 100, "y": 100, "direction": "up", "amount": 4}', self.SIZE),
                         Action("scroll", 100, 80, dy=-4))
        self.assertEqual(from_json('{"action": "key", "keys": "ctrl+a Delete"}', self.SIZE), Action("key", keys="ctrl+a Delete"))
        self.assertEqual(from_json('{"action": "focus", "window": "firefox"}', self.SIZE), Action("focus", target="firefox"))
        self.assertEqual(from_json('{"action": "done", "text": "Opened it."}', self.SIZE), Action("done", text="Opened it."))

    def test_bad_replies_raise(self):
        for bad in ("no json here", '{"action": "fly"}', '{"x": 1}', "[1, 2]", '{"action": "click", "x": "left"}'):
            with self.assertRaises(ValueError, msg=bad):
                from_json(bad, self.SIZE)


if __name__ == "__main__":
    unittest.main()
