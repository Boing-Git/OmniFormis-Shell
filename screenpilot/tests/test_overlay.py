import asyncio
import json
import unittest

from screenpilot import config
from helpers import make_daemon, private_runtime


class OverlayProtocolTest(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        private_runtime(self)
        self.d = make_daemon()
        self.server = await self.d.serve_on(config.socket_path())
        self.addAsyncCleanup(self._close)

    async def _close(self):
        self.d.stop("cleanup")
        self.server.close()
        await self.server.wait_closed()

    async def connect(self, *requests):
        r, w = await asyncio.open_unix_connection(str(config.socket_path()))
        for req in requests:
            w.write(json.dumps(req).encode() + b"\n")
        await w.drain()
        self.addCleanup(w.close)
        return r, w

    async def next_event(self, r, kind):
        while True:
            event = json.loads(await asyncio.wait_for(r.readline(), 1))
            if event["type"] == kind:
                return event

    async def test_overlay_reports_its_rects(self):
        r, _ = await self.connect({"cmd": "overlay", "rects": [[10, 20, 30, 40], [1930, 16, 168, 64]]})
        await self.next_event(r, "ok")
        self.assertEqual(self.d.protected_rects, [(10, 20, 30, 40), (1930, 16, 168, 64)])

    async def test_bad_rects_are_refused_and_kept(self):
        self.d.protected_rects = [(1, 2, 3, 4)]
        r, _ = await self.connect({"cmd": "overlay", "rects": [[1, 2, "x", 4]]})
        self.assertEqual((await self.next_event(r, "error"))["type"], "error")
        self.assertEqual(self.d.protected_rects, [(1, 2, 3, 4)])

    async def test_prompt_reaches_subscribers(self):
        sub, _ = await self.connect({"cmd": "subscribe"})
        await self.next_event(sub, "status")
        r, _ = await self.connect({"cmd": "prompt", "mode": "ask"})
        await self.next_event(r, "ok")
        self.assertEqual((await self.next_event(sub, "prompt"))["mode"], "ask")

    async def test_prompt_while_halted_says_why_on_the_overlay(self):
        sub, _ = await self.connect({"cmd": "subscribe"})
        await self.next_event(sub, "status")
        self.d.stop("test")
        r, _ = await self.connect({"cmd": "prompt", "mode": "ask"})
        self.assertIn("halted", (await self.next_event(r, "error"))["text"])
        self.assertIn("halted", (await self.next_event(sub, "error"))["text"])

    async def test_prompt_refused_while_running(self):
        await self.connect({"cmd": "act", "text": "slow"})
        while not self.d.input.held:
            await asyncio.sleep(0.005)
        r, _ = await self.connect({"cmd": "prompt", "mode": "act"})
        self.assertIn("busy", (await self.next_event(r, "error"))["text"])

    async def test_end_of_a_run_reaches_subscribers(self):
        sub, _ = await self.connect({"cmd": "subscribe"})
        await self.next_event(sub, "status")
        await self.connect({"cmd": "act", "text": "slow"})
        while not self.d.input.held:
            await asyncio.sleep(0.005)
        self.d.stop("test")
        self.assertIn("stopped", (await self.next_event(sub, "error"))["text"])


class OverlayProcessTest(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        private_runtime(self)

    async def test_overlay_dying_during_a_run_is_stop(self):
        d = make_daemon()
        d.overlay_cmd = ["sleep", "0.05"]
        keeper = asyncio.ensure_future(d.keep_overlay())
        self.addCleanup(keeper.cancel)
        task = d.start("act", "slow")
        await asyncio.wait({task}, timeout=1)
        self.assertEqual(d.state, "halted")
        self.assertIn("overlay", d.reason)

    async def test_overlay_dying_while_idle_is_restarted(self):
        d = make_daemon()
        d.overlay_cmd = ["true"]
        d.overlay_restart_s = 0.01
        keeper = asyncio.ensure_future(d.keep_overlay())
        self.addCleanup(keeper.cancel)
        await asyncio.sleep(0.3)
        self.assertEqual(d.state, "idle")
        self.assertGreater(d.overlay_starts, 2)


if __name__ == "__main__":
    unittest.main()
