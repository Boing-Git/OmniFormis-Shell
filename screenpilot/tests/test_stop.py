import asyncio
import signal
import subprocess
import sys
import time
import unittest

from screenpilot import cli, config, proc
from helpers import make_daemon, private_runtime


class StopTest(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        private_runtime(self)

    async def test_stop_halts_running_loop_within_200ms(self):
        d = make_daemon()
        task = d.start("act", "something slow")
        while not d.input.held:
            await asyncio.sleep(0.005)
        t0 = time.monotonic()
        d.stop("test")
        await asyncio.wait_for(task, 0.2)
        self.assertLess(time.monotonic() - t0, 0.2)
        self.assertEqual(d.input.held, set())
        self.assertEqual(d.state, "halted")
        self.assertTrue(config.halt_path().exists())

    async def test_act_refused_until_resume(self):
        d = make_daemon()
        d.stop("test")
        with self.assertRaisesRegex(RuntimeError, "halted"):
            d.start("act", "anything")
        d.resume()
        self.assertEqual(d.state, "idle")
        self.assertFalse(config.halt_path().exists())
        task = d.start("act", "anything")
        d.stop("test")
        await asyncio.wait({task}, timeout=0.2)  # stopped before its first step, it ends cancelled
        self.assertTrue(task.done())

    async def test_starts_halted_when_marker_exists(self):
        config.halt_path().write_text("earlier")
        self.assertEqual(make_daemon().state, "halted")

    async def test_cancelled_run_kills_its_child_process(self):
        task = asyncio.create_task(proc.run(["sleep", "30"]))
        while not proc.CHILDREN:
            await asyncio.sleep(0.005)
        child = next(iter(proc.CHILDREN))
        task.cancel()
        with self.assertRaises(asyncio.CancelledError):
            await task
        self.assertIsNotNone(await asyncio.wait_for(child.wait(), 1))

    async def test_signal_halts_like_stop(self):
        d = make_daemon()
        d.install_signal_handler()
        self.addCleanup(signal.signal, signal.SIGUSR1, signal.SIG_DFL)
        task = d.start("act", "something slow")
        while not d.input.held:
            await asyncio.sleep(0.005)
        signal.raise_signal(signal.SIGUSR1)
        self.assertEqual(d.input.held, set())        # released inside the handler itself
        self.assertTrue(config.halt_path().exists())
        await asyncio.wait_for(task, 0.2)
        self.assertEqual(d.state, "halted")


class EscalationTest(unittest.TestCase):
    def setUp(self):
        private_runtime(self)
        config.pid_path().write_text("424242")
        self.kills, self.runs = [], []

    def run_cmd(self, args, **kw):
        self.runs.append(list(args))
        return subprocess.CompletedProcess(args, 0)

    def test_falls_back_to_the_service_when_nothing_answers(self):
        layer = cli.stop_escalation(kill=lambda pid, sig: self.kills.append((pid, sig)), run=self.run_cmd)
        self.assertEqual(layer, "service")
        self.assertEqual(self.kills, [(424242, signal.SIGUSR1)])
        self.assertEqual(self.runs, [["systemctl", "--user", "kill", "--signal=KILL", "screenpilot.service"],
                                     ["systemctl", "--user", "restart", "screenpilot.service"]])
        self.assertTrue(config.halt_path().exists())

    def test_signal_layer_counts_when_the_handler_writes_the_marker(self):
        def kill(pid, sig):
            config.halt_path().write_text("signal")
        self.assertEqual(cli.stop_escalation(kill=kill, run=self.run_cmd), "signal")
        self.assertEqual(self.runs, [])


if __name__ == "__main__":
    unittest.main()
