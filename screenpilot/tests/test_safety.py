import json
import tempfile
import unittest
from pathlib import Path

from screenpilot import safety
from screenpilot.actions import Action
from screenpilot.capture import Shot
from screenpilot.geometry import Frame

CTX = json.dumps({"active": {"class": "foot", "title": "~"}})
SHOT = Shot(b"png", Frame(0, 0, 10, 10, 10, 10))


def ctx(cls, title):
    return json.dumps({"active": {"class": cls, "title": title}})


class RiskyTest(unittest.TestCase):
    def test_dangerous_words_in_what_is_typed_or_meant(self):
        self.assertIn("sudo", safety.risky(Action("type", text="sudo rm -rf x"), CTX))
        self.assertIn("purchase", safety.risky(Action("click", 1, 1, reason="click Confirm purchase"), CTX))
        self.assertIn("send", safety.risky(Action("click", 1, 1, reason="Send the email"), CTX).lower())
        self.assertIsNotNone(safety.risky(Action("key", keys="shift+Delete"), CTX))

    def test_typing_where_a_password_is_asked(self):
        self.assertIn("password", safety.risky(Action("type", text="hunter2"), ctx("Bitwarden", "Unlock vault")))
        self.assertIn("password", safety.risky(Action("type", text="x"), ctx("pinentry-qt", "")))
        self.assertIsNone(safety.risky(Action("click", 3, 3), ctx("Bitwarden", "Unlock vault")))

    def test_ordinary_actions_pass(self):
        self.assertIsNone(safety.risky(Action("click", 1, 1, reason="open the menu"), CTX))
        self.assertIsNone(safety.risky(Action("type", text="hello world"), CTX))
        self.assertIsNone(safety.risky(Action("key", keys="ctrl+l"), CTX))
        self.assertIsNone(safety.risky(Action("type", text="the sender's address"), CTX))  # whole words only

    def test_policy(self):
        plain, bad = Action("click", 1, 1), Action("type", text="sudo reboot")
        self.assertIsNone(safety.question(plain, CTX, "never", first=True))
        self.assertIsNone(safety.question(bad, CTX, "never", first=False))
        self.assertIsNotNone(safety.question(plain, CTX, "risky", first=True))   # the first action of a run
        self.assertIsNone(safety.question(plain, CTX, "risky", first=False))
        self.assertIsNotNone(safety.question(bad, CTX, "risky", first=False))
        self.assertIsNotNone(safety.question(plain, CTX, "always", first=False))


class RunLogTest(unittest.TestCase):
    def test_steps_are_logged_with_their_screenshot(self):
        with tempfile.TemporaryDirectory() as d:
            log = safety.RunLog(Path(d), "the goal", keep=20)
            log.step(Action("click", 1, 2), SHOT, "click done")
            log.step(Action("type", text="hi"), SHOT, "type done")
            lines = [json.loads(line) for line in (log.dir / "actions.jsonl").read_text().splitlines()]
            self.assertEqual([entry["action"]["kind"] for entry in lines], ["click", "type"])
            self.assertTrue(Path(lines[0]["screenshot"]).exists())
            self.assertIn("t", lines[0])
            self.assertEqual(lines[1]["result"], "type done")

    def test_only_the_last_runs_are_kept(self):
        with tempfile.TemporaryDirectory() as d:
            for i in range(21):
                safety.RunLog(Path(d), f"run {i}", keep=20)
            runs = sorted(Path(d).iterdir())
            self.assertEqual(len(runs), 20)
            self.assertEqual((runs[-1] / "goal.txt").read_text(), "run 20")
            self.assertEqual((runs[0] / "goal.txt").read_text(), "run 1")


if __name__ == "__main__":
    unittest.main()
