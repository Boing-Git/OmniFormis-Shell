"""Fakes shared by the tests: an input that remembers what it holds, a backend whose step never
ends (an in-flight model request), and a daemon that needs no screen."""
import asyncio
import os
import tempfile

from screenpilot import config, daemon


def private_runtime(test):
    """Points XDG_RUNTIME_DIR and XDG_STATE_HOME at a fresh temp dir for one test."""
    tmp = tempfile.TemporaryDirectory()
    test.addCleanup(tmp.cleanup)
    for var in ("XDG_RUNTIME_DIR", "XDG_STATE_HOME"):
        old = os.environ.get(var)
        os.environ[var] = tmp.name
        test.addCleanup(lambda v=var, o=old: os.environ.pop(v) if o is None else os.environ.__setitem__(v, o))
    return tmp.name


class FakeInput:
    def __init__(self):
        self.held = set()
        self.log = []

    async def press(self, button):
        self.held.add(button)

    async def release(self, button):
        self.held.discard(button)

    async def type_text(self, s):
        self.log.append(("type", s))

    async def key(self, combo):
        self.log.append(("key", combo))

    def release_all(self):
        self.held.clear()


class SlowBackend:
    """Each step holds the left button, then waits like a slow model request."""
    def __init__(self, d):
        self.d = d

    def session(self, goal):
        return self

    async def step(self, shot, context, note):
        await self.d.input.press("left")
        await asyncio.sleep(30)

    async def ask(self, question, shot, context):
        await asyncio.sleep(30)


class FakeDaemon(daemon.Daemon):
    async def capture(self):
        return None

    async def context(self):
        return ""

    def backend(self):
        return SlowBackend(self)


def make_daemon():
    return FakeDaemon(config.load(), input=FakeInput())
