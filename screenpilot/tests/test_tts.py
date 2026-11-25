import asyncio
import unittest

from screenpilot.tts import Piper, speakable


class SpeakableTest(unittest.TestCase):
    def test_markdown_and_code_are_not_read_out(self):
        out = speakable("## Steps\n**Hi** there `x = 1`\n```py\ncode()\n```\n- open [the menu](http://x.y/z)\n1. press OK")
        for gone in ("`", "*", "#", "code()", "http", "x = 1"):
            self.assertNotIn(gone, out)
        self.assertEqual(out, "Steps. Hi there. open the menu. press OK")

    def test_plain_text_stays(self):
        self.assertEqual(speakable("Click Save, then close it."), "Click Save, then close it.")
        self.assertEqual(speakable("   \n```\nonly code\n```"), "")


class FakePiper(Piper):
    """piper and the player replaced by commands that just wait."""
    def piper_cmd(self):
        return ["cat"]

    def player_cmd(self):
        return ["sleep", "30"]


class QueueTest(unittest.IsolatedAsyncioTestCase):
    async def test_stop_empties_the_queue_and_kills_the_player(self):
        t = FakePiper("voice.onnx", rate=22050)
        t.say("first")
        t.say("second")
        while not t.procs:
            await asyncio.sleep(0.01)
        procs = list(t.procs)
        t.stop()
        self.assertTrue(t.queue.empty())
        for p in procs:
            await asyncio.wait_for(p.wait(), 1)
        await asyncio.wait_for(t.worker, 1)
        self.assertEqual(t.procs, [])

    async def test_nothing_speakable_is_not_queued(self):
        t = FakePiper("voice.onnx", rate=22050)
        t.say("```\ncode\n```")
        self.assertTrue(t.queue.empty())
        self.assertIsNone(t.worker)


class SayCommandTest(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        from helpers import make_daemon, private_runtime
        from screenpilot import config
        private_runtime(self)
        self.d = make_daemon()
        self.server = await self.d.serve_on(config.socket_path())
        self.path = str(config.socket_path())
        self.addAsyncCleanup(self._close)

    async def _close(self):
        self.d.stop("cleanup")
        self.server.close()
        await self.server.wait_closed()

    async def reply(self, obj):
        import json
        r, w = await asyncio.open_unix_connection(self.path)
        w.write(json.dumps(obj).encode() + b"\n")
        line = await asyncio.wait_for(r.readline(), 1)
        w.close()
        return json.loads(line)

    async def test_say_needs_a_voice(self):
        self.assertIn("voice", (await self.reply({"cmd": "say", "text": "hi"}))["text"])

    async def test_say_queues_speech(self):
        self.d.tts = FakePiper("voice.onnx", rate=22050)
        self.assertEqual((await self.reply({"cmd": "say", "text": "hello there"}))["type"], "ok")
        while not self.d.tts.procs:
            await asyncio.sleep(0.01)
        self.d.tts.stop()


if __name__ == "__main__":
    unittest.main()
