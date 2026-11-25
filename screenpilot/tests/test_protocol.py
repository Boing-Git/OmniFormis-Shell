import asyncio
import json
import time
import unittest

from screenpilot import cli, config
from helpers import make_daemon, private_runtime


class ProtocolTest(unittest.IsolatedAsyncioTestCase):
    async def asyncSetUp(self):
        private_runtime(self)
        self.d = make_daemon()
        self.server = await self.d.serve_on(config.socket_path())
        self.addAsyncCleanup(self._close)

    async def _close(self):
        self.d.stop("cleanup")
        self.server.close()
        await self.server.wait_closed()

    async def send(self, raw: bytes):
        r, w = await asyncio.open_unix_connection(str(config.socket_path()))
        w.write(raw)
        await w.drain()
        return r, w

    async def reply(self, obj):
        r, w = await self.send(json.dumps(obj).encode() + b"\n")
        line = await asyncio.wait_for(r.readline(), 1)
        w.close()
        return json.loads(line)

    async def test_garbage_line_gets_error_and_daemon_survives(self):
        r, w = await self.send(b"not json\n")
        self.assertEqual(json.loads(await r.readline())["type"], "error")
        w.close()
        self.assertEqual((await self.reply({"cmd": "status"}))["state"], "idle")

    async def test_huge_line_gets_error(self):
        r, w = await asyncio.open_unix_connection(str(config.socket_path()))
        w.write(b"x" * (1 << 20) + b"\n")  # no drain: the daemon hangs up before reading it all
        self.assertEqual(json.loads(await asyncio.wait_for(r.readline(), 1))["type"], "error")
        w.close()
        self.assertEqual((await self.reply({"cmd": "status"}))["state"], "idle")

    async def test_second_act_is_busy(self):
        r, w = await self.send(b'{"cmd": "act", "text": "slow"}\n')
        while not self.d.input.held:
            await asyncio.sleep(0.005)
        busy = await self.reply({"cmd": "act", "text": "another"})
        self.assertEqual(busy["type"], "error")
        self.assertIn("busy", busy["text"])
        self.assertNotEqual(self.d.state, "halted")
        w.close()

    async def test_stop_over_socket_within_200ms(self):
        r, w = await self.send(b'{"cmd": "act", "text": "slow"}\n')
        while not self.d.input.held:
            await asyncio.sleep(0.005)
        t0 = time.monotonic()
        ack = await self.reply({"cmd": "stop"})
        self.assertEqual(ack["state"], "halted")
        while True:
            event = json.loads(await asyncio.wait_for(r.readline(), 0.2))
            if event["type"] in ("answer", "error"):
                break
        self.assertLess(time.monotonic() - t0, 0.2)
        self.assertEqual(event["type"], "error")
        self.assertEqual(self.d.input.held, set())
        w.close()

    async def test_mode_switches_and_is_remembered(self):
        self.assertEqual((await self.reply({"cmd": "mode", "name": "shared"}))["mode"], "shared")
        self.assertEqual(self.d.cfg["mode"], "shared")
        self.assertEqual(config.load()["mode"], "shared")
        self.assertEqual((await self.reply({"cmd": "mode", "name": "everywhere"}))["type"], "error")
        self.assertEqual((await self.reply({"cmd": "mode"}))["mode"], "shared")

    async def test_mode_is_not_switched_mid_run(self):
        r, w = await self.send(b'{"cmd": "act", "text": "slow"}\n')
        while not self.d.input.held:
            await asyncio.sleep(0.005)
        self.assertIn("busy", (await self.reply({"cmd": "mode", "name": "shared"}))["text"])
        w.close()

    async def test_cli_stop_reaches_the_socket(self):
        layer = await asyncio.to_thread(cli.stop_escalation)
        self.assertEqual(layer, "socket")
        self.assertEqual(self.d.state, "halted")

    async def test_client_going_away_stops_when_asked(self):
        self.d.cfg["stopOnClientDisconnect"] = True
        r, w = await self.send(b'{"cmd": "act", "text": "slow"}\n')
        while not self.d.input.held:
            await asyncio.sleep(0.005)
        w.close()
        for _ in range(40):
            if self.d.state == "halted":
                break
            await asyncio.sleep(0.005)
        self.assertEqual(self.d.state, "halted")


if __name__ == "__main__":
    unittest.main()
