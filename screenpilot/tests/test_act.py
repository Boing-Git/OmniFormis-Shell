import asyncio
import json
import unittest

from screenpilot import config
from screenpilot.actions import Action
from screenpilot.capture import Shot
from screenpilot.geometry import Frame
from helpers import FakeDaemon, private_runtime
from test_keymap import Recorder

SHOT = Shot(b"png", Frame(0, 0, 100, 100, 100, 100))


class Scripted:
    """A model that answers with these actions in turn (then keeps clicking)."""
    def __init__(self, *actions, delay=0):
        self.actions, self.delay, self.notes = list(actions), delay, []

    def session(self, goal):
        return self

    async def step(self, shot, context, note):
        self.notes.append(note)
        await asyncio.sleep(self.delay)
        return self.actions.pop(0) if self.actions else Action("click", 5, 5)


class ActDaemon(FakeDaemon):
    def __init__(self, script, **cfg):
        super().__init__(dict(config.load(), **cfg), input=Recorder())
        self.script, self.done = script, []

    async def capture(self, mode="monitor"):
        return SHOT

    async def context(self):
        return json.dumps({"active": {"class": "foot", "title": "~"}})

    def backend(self):
        return self.script

    async def execute(self, action, shot):
        self.done.append(action.kind)
        return f"{action.kind} done"


class ActLoopTest(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        private_runtime(self)

    async def run_act(self, d, goal="do it"):
        return await asyncio.wait_for(d.start("act", goal), 5)

    async def test_runs_until_done_and_logs_each_action(self):
        d = ActDaemon(Scripted(Action("click", 1, 1), Action("type", text="hi"), Action("done", text="Finished.")),
                      confirm="never")
        self.assertEqual(await self.run_act(d), {"type": "answer", "text": "Finished."})
        self.assertEqual(d.done, ["click", "type"])
        self.assertEqual(d.script.notes, ["", "click done", "type done"])
        (run,) = (config.state_dir() / "runs").iterdir()
        self.assertEqual(len((run / "actions.jsonl").read_text().splitlines()), 2)

    async def test_max_steps(self):
        d = ActDaemon(Scripted(), confirm="never", maxSteps=3)
        self.assertIn("3 steps", (await self.run_act(d))["text"])
        self.assertEqual(len(d.done), 3)

    async def test_timeout(self):
        d = ActDaemon(Scripted(delay=1), confirm="never", timeoutS=0.05)
        self.assertEqual((await self.run_act(d))["type"], "error")

    async def test_no_overlay_to_ask_means_no(self):
        d = ActDaemon(Scripted(Action("click", 1, 1)), confirm="risky")
        self.assertIn("no", (await self.run_act(d))["text"].lower())
        self.assertEqual(d.done, [])

    async def test_the_first_action_waits_for_yes(self):
        d = ActDaemon(Scripted(Action("click", 1, 1), Action("done", text="ok")), confirm="risky")
        asked = []
        d.listeners.add(Answerer(d, asked, yes=True))
        self.assertEqual((await self.run_act(d))["text"], "ok")
        self.assertEqual(len(asked), 1)
        self.assertEqual(d.done, ["click"])

    async def test_no_stops_the_run(self):
        d = ActDaemon(Scripted(Action("click", 1, 1)), confirm="risky")
        d.listeners.add(Answerer(d, [], yes=False))
        self.assertIn("said no", (await self.run_act(d))["text"])
        self.assertEqual(d.done, [])

    async def test_refused_action_tells_the_model(self):
        d = FakeDaemon(config.load(), input=Recorder())
        d.cfg["mode"], d.run_kind, d.sandbox.display = "sandbox", "act", "wayland-9"
        note = await d.execute(Action("click", 5000, 5), SHOT)
        self.assertTrue(note.startswith("refused:"))


class Answerer:
    """Stands in for the overlay: answers every confirm question."""
    def __init__(self, d, asked, yes):
        self.d, self.asked, self.yes = d, asked, yes

    def is_closing(self):
        return False

    def write(self, line):
        event = json.loads(line)
        if event["type"] == "confirm":
            self.asked.append(event["question"])
            asyncio.get_running_loop().call_soon(self.d.answer_confirm, event["id"], self.yes)


if __name__ == "__main__":
    unittest.main()
