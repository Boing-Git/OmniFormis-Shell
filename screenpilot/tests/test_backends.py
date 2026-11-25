import json
import unittest
from types import SimpleNamespace

import httpx

from screenpilot import backends, config
from screenpilot.actions import Action
from screenpilot.capture import Shot
from screenpilot.geometry import Frame

SHOT = Shot(b"\x89PNG fake", Frame(0, 0, 1920, 1080, 1000, 800))


class Block(SimpleNamespace):
    def to_dict(self):
        return {k: v for k, v in vars(self).items()}


def tool(id, name, **input):
    return Block(type="tool_use", id=id, name=name, input=input, toolset_name="computer")


def reply(*content, stop="tool_use"):
    return SimpleNamespace(content=list(content), stop_reason=stop, stop_details=None)


class FakeClaude:
    def __init__(self, *responses):
        self.responses = list(responses)
        self.calls = []
        self.beta = SimpleNamespace(messages=SimpleNamespace(create=self.create))

    async def create(self, **kw):
        self.calls.append(json.loads(json.dumps(kw, default=lambda o: o.to_dict())))
        return self.responses.pop(0)


def last_results(call):
    return [b for b in call["messages"][-1]["content"] if b["type"] == "tool_result"]


class ClaudeTest(unittest.IsolatedAsyncioTestCase):
    def backend(self, *responses):
        self.fake = FakeClaude(*responses)
        return backends.Claude(dict(config.DEFAULTS), client=self.fake)

    async def test_ask_sends_the_question_before_the_screenshot(self):
        b = self.backend(reply(Block(type="text", text="Press Save."), stop="end_turn"))
        self.assertEqual(await b.ask("what now?", SHOT, "{}"), "Press Save.")
        call = self.fake.calls[0]
        content = call["messages"][0]["content"]
        self.assertEqual([c["type"] for c in content], ["text", "image"])
        self.assertIn("what now?", content[0]["text"])
        self.assertEqual(call["fallbacks"], "default")
        self.assertIn("untrusted", call["system"])

    async def test_a_batch_runs_one_action_per_step_then_returns_every_result(self):
        b = self.backend(reply(Block(type="text", text="Opening it."), tool("t1", "left_click", coordinate=[10, 20]),
                               tool("t2", "type", text="hello")),
                         reply(Block(type="text", text="Typed hello."), stop="end_turn"))
        s = b.session("type hello")
        # what Claude said before its actions is the first one's reason (the confirm check reads it)
        self.assertEqual(await s.step(SHOT, "{}", ""), Action("click", 10, 20, reason="Opening it."))
        self.assertEqual(await s.step(SHOT, "{}", "click done"), Action("type", text="hello"))
        self.assertEqual(await s.step(SHOT, "{}", "type done"), Action("done", text="Typed hello."))
        first, second = self.fake.calls
        self.assertEqual(first["tools"][0]["type"], "computer_toolset_20260801")
        self.assertFalse(first["tools"][0]["configs"]["zoom"]["enabled"])
        results = last_results(second)
        self.assertEqual([r["tool_use_id"] for r in results], ["t1", "t2"])
        self.assertTrue(all(r["toolset_name"] == "computer" for r in results))
        self.assertEqual(second["messages"][1]["role"], "assistant")     # its turn, passed back whole

    async def test_screenshot_is_answered_with_the_fresh_shot(self):
        b = self.backend(reply(tool("t1", "screenshot")), reply(Block(type="text", text="Done."), stop="end_turn"))
        self.assertEqual(await b.session("look").step(SHOT, "{}", ""), Action("done", text="Done."))
        (result,) = last_results(self.fake.calls[1])
        self.assertEqual(result["content"][0]["type"], "image")

    async def test_a_refused_action_fails_the_rest_of_its_batch(self):
        b = self.backend(reply(tool("t1", "left_click", coordinate=[1, 1]), tool("t2", "type", text="x")),
                         reply(Block(type="text", text="Couldn't."), stop="end_turn"))
        s = b.session("x")
        await s.step(SHOT, "{}", "")
        self.assertEqual(await s.step(SHOT, "{}", "refused: that is the STOP button"), Action("done", text="Couldn't."))
        r1, r2 = last_results(self.fake.calls[1])
        self.assertTrue(r1["is_error"])
        self.assertIn("STOP", r1["content"][0]["text"])
        self.assertTrue(r2["is_error"])
        self.assertEqual(r2["content"][0]["text"], "Not executed: an earlier computer action in this turn failed.")

    def test_no_credentials_says_where_the_key_goes(self):
        import os
        from unittest import mock
        with mock.patch.dict(os.environ, {"HOME": "/nonexistent", "XDG_CONFIG_HOME": "/nonexistent"}, clear=True):
            with self.assertRaisesRegex(RuntimeError, "screenpilot/env"):
                backends.Claude(dict(config.DEFAULTS))

    async def test_refusal_is_an_error(self):
        b = self.backend(reply(stop="refusal"))
        with self.assertRaisesRegex(RuntimeError, "declined"):
            await b.ask("?", SHOT, "{}")


def local(*answers):
    seen = []

    def handler(request):
        seen.append(json.loads(request.content))
        return httpx.Response(200, json={"choices": [{"message": {"content": answers[len(seen) - 1]}}]})
    b = backends.Local(dict(config.DEFAULTS), http=httpx.AsyncClient(transport=httpx.MockTransport(handler)))
    return b, seen


class LocalTest(unittest.IsolatedAsyncioTestCase):
    async def test_ask_sends_image_and_question(self):
        b, seen = local("<think>hm</think>Click the blue button.")
        self.assertEqual(await b.ask("what now?", SHOT, "{}"), "Click the blue button.")
        user = seen[0]["messages"][-1]["content"]
        self.assertEqual([c["type"] for c in user], ["text", "image_url"])
        self.assertTrue(user[1]["image_url"]["url"].startswith("data:image/png;base64,"))
        self.assertEqual(seen[0]["model"], "qwen3-vl:8b")

    async def test_step_maps_per_mille_and_remembers_what_happened(self):
        b, seen = local('{"action": "click", "x": 500, "y": 500, "reason": "menu"}', '{"action": "done", "text": "ok"}')
        s = b.session("open the menu")
        self.assertEqual(await s.step(SHOT, "{}", ""), Action("click", 500, 400, reason="menu"))
        self.assertEqual(await s.step(SHOT, "{}", "click done"), Action("done", text="ok"))
        self.assertIn("click done", seen[1]["messages"][-1]["content"][0]["text"])

    async def test_one_retry_then_an_error(self):
        b, seen = local("no idea", '{"action": "wait"}')
        self.assertEqual(await b.session("x").step(SHOT, "{}", ""), Action("wait"))
        b, seen = local("no idea", "still no idea")
        with self.assertRaisesRegex(RuntimeError, "local model"):
            await b.session("x").step(SHOT, "{}", "")


if __name__ == "__main__":
    unittest.main()
