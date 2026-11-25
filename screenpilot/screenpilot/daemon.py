"""screenpilotd: one asyncio process behind a Unix socket ($XDG_RUNTIME_DIR/screenpilot.sock).

Protocol: one JSON object per line. Requests carry "cmd"; replies and pushed events carry "type".
    {"cmd": "status"}                      -> {"type": "status", "state": ..., ...}
    {"cmd": "ask" | "act", "text": ...}    -> events while it runs, then {"type": "answer" | "error"}
    {"cmd": "stop"} / {"cmd": "resume"}    -> {"type": "ok", "state": ...}
    {"cmd": "subscribe"}                   -> status, then every event (the overlay)
    {"cmd": "backend", "name"?: ...}       -> {"type": "ok", "backend": ...}

States: idle, thinking, acting, paused, halted. Only `resume` leaves halted.
"""
import asyncio
import dataclasses
import json
import os
import shutil
import signal
import subprocess
import sys
import time
from pathlib import Path

from . import agent, config, proc
from .sandbox import Sandbox

LINE_LIMIT = 64 * 1024
CAPTURE_MODES = ("monitor", "window", "region")


def log(*args):
    print("screenpilotd:", *args, file=sys.stderr, flush=True)


def overlay_dir() -> Path:
    """The overlay's Quickshell config: the package's share dir, or the source tree's."""
    return Path(os.environ.get("SCREENPILOT_OVERLAY") or Path(__file__).resolve().parent.parent / "overlay")


class Daemon:
    def __init__(self, cfg, *, input=None, tts=None):
        self.cfg = cfg
        self.input = input
        self.tts = tts
        self.task = None
        self.subscribers = set()
        self.protected_rects = []
        self.reason = ""
        self.state = "halted" if config.halt_path().exists() else "idle"
        self.run_kind = None
        self.capture_mode = "monitor"
        self.sandbox = Sandbox()
        self.overlay = None
        self.overlay_cmd = ["qs", "-p", str(overlay_dir())]
        self.overlay_restart_s = 2
        self.overlay_starts = 0

    # ── the parts later modules provide (the tests replace them) ──
    def sandbox_display(self):
        """What ACT looks at in sandbox mode: the sandbox's WAYLAND_DISPLAY. None otherwise (ASK
        always looks at the user's own screen)."""
        if self.cfg["mode"] == "sandbox" and self.run_kind == "act":
            return self.sandbox.display
        return None

    async def prepare_act(self):
        """Points the AI's input at its target before an ACT run."""
        if self.cfg["mode"] == "sandbox":
            display = await self.sandbox.start()
            if getattr(self.input, "display", None) != display:
                self._close_input()
                from .wayland import WaylandInput
                self.input = await asyncio.to_thread(WaylandInput, display, self.cfg["delayMs"] / 1000)
                self.input.display = display
                self.input.focus_window = self.sandbox.focus
        else:
            raise RuntimeError("shared mode is not built yet")

    def _close_input(self):
        if hasattr(self.input, "close"):
            self.input.close()
        self.input = None

    async def execute(self, action, shot):
        from . import executor
        sandboxed = self.sandbox_display() is not None
        if sandboxed:  # absolute motion spans the sandbox's one output, which is the whole shot
            f = shot.frame
            self.input.box = (f.ox, f.oy, f.lw, f.lh)
        try:
            return await executor.execute(action, shot, self.input,
                                          protected=() if sandboxed else self.protected_rects)
        except executor.Refused as e:
            return f"refused: {e}"  # the model hears why and tries something else

    async def capture(self, mode="monitor"):
        from . import capture
        sandboxed = self.sandbox_display() is not None
        return await capture.grab(self.cfg, mode, sandbox_env=self.sandbox.env() if sandboxed else None,
                                  protected=() if sandboxed else self.protected_rects)

    async def context(self):
        from . import context
        return await context.describe(self.sandbox.env() if self.sandbox_display() else None)

    def backend(self):
        from . import backends
        return backends.make(self.cfg)

    # ── state ──
    def status(self):
        return {"type": "status", "state": self.state, "reason": self.reason,
                "backend": self.cfg["backend"], "mode": self.cfg["mode"]}

    def broadcast(self, event):
        line = (json.dumps(event) + "\n").encode()
        for w in list(self.subscribers):
            if w.is_closing():
                self.subscribers.discard(w)
            else:
                w.write(line)

    def set_state(self, state):
        # nothing but resume() leaves halted, so a run that is still unwinding can't undo a STOP
        if self.state == "halted" or self.state == state:
            return
        self.state = state
        self.broadcast({"type": "state", "state": state})

    def _halt(self, reason):
        """The part of STOP that needs no event loop: safe inside a signal handler."""
        self.state = "halted"
        self.reason = reason
        try:
            config.halt_path().write_text(reason)
        except OSError as e:
            log("can't write the halt marker:", e)
        for undo in (getattr(self.input, "release_all", None), getattr(self.tts, "stop", None), proc.kill_all):
            if undo:
                try:
                    undo()
                except Exception as e:  # one failing part must not keep the others from stopping
                    log("stop:", e)

    def stop(self, reason="stop"):
        self._halt(reason)
        if self.task and not self.task.done():
            self.task.cancel()
        self.broadcast({"type": "state", "state": "halted", "reason": reason})
        self.broadcast({"type": "cursor", "hide": True})

    def resume(self):
        config.halt_path().unlink(missing_ok=True)
        if hasattr(self.input, "unblock"):
            self.input.unblock()
        if self.state == "halted":
            self.state, self.reason = "idle", ""
            self.broadcast({"type": "state", "state": "idle"})

    def install_signal_handler(self):
        """SIGUSR1 = STOP, even when the event loop is stuck: Python runs the handler between
        bytecodes (and after an interrupted system call), not on the loop."""
        loop = asyncio.get_running_loop()

        def on_signal(signum, frame):
            self._halt("signal")
            loop.call_soon_threadsafe(self.stop, "signal")
        signal.signal(signal.SIGUSR1, on_signal)

    # ── runs ──
    def start(self, kind, text, capture_mode="monitor"):
        if self.state == "halted":
            raise RuntimeError("halted: run `screenpilot resume` first")
        if self.task and not self.task.done():
            raise RuntimeError("busy: another request is running")
        self.capture_mode = capture_mode if kind == "ask" else "monitor"  # ACT sees the whole screen
        self.run_kind = kind
        run = agent.run_act if kind == "act" else agent.run_ask
        self.task = asyncio.ensure_future(self._run(run, text))
        return self.task

    async def _run(self, run, text):
        try:
            event = {"type": "answer", "text": await run(self, text)}
        except asyncio.CancelledError:
            event = {"type": "error", "text": f"stopped ({self.reason or 'cancelled'})"}
        except TimeoutError:
            event = {"type": "error", "text": "took too long, gave up"}
        except Exception as e:
            log(f"{type(e).__name__}: {e}")
            event = {"type": "error", "text": str(e) or type(e).__name__}
        self.set_state("idle")
        self.broadcast(event)  # the overlay shows how it ended (a keybind run has no terminal)
        return event

    # ── socket ──
    @staticmethod
    def _send(writer, event):
        if not writer.is_closing():
            writer.write((json.dumps(event) + "\n").encode())

    async def handle(self, reader, writer):
        try:
            while True:
                try:
                    line = await reader.readuntil(b"\n")
                except asyncio.IncompleteReadError:
                    break
                except asyncio.LimitOverrunError:
                    self._send(writer, {"type": "error", "text": "request too long"})
                    break
                try:
                    req = json.loads(line)
                    cmd = req["cmd"]
                except (ValueError, KeyError, TypeError):
                    self._send(writer, {"type": "error", "text": "send one JSON object per line, with a \"cmd\""})
                    continue
                await self.dispatch(cmd, req, reader, writer)
                await writer.drain()
                if cmd in ("ask", "act"):
                    break
        except ConnectionError:
            pass
        finally:
            self.subscribers.discard(writer)
            writer.close()

    async def dispatch(self, cmd, req, reader, writer):
        send = lambda event: self._send(writer, event)
        if cmd == "status":
            send(self.status())
        elif cmd == "stop":
            self.stop(str(req.get("reason") or "user"))
            send({"type": "ok", "state": self.state})
        elif cmd == "resume":
            self.resume()
            send({"type": "ok", "state": self.state})
        elif cmd == "subscribe":
            self.subscribers.add(writer)
            send(self.status())
        elif cmd == "backend":
            if req.get("name"):
                try:
                    config.set_backend(req["name"])
                except ValueError as e:
                    return send({"type": "error", "text": str(e)})
                self.cfg["backend"] = req["name"]
                self.broadcast(self.status())
            send({"type": "ok", "backend": self.cfg["backend"]})
        elif cmd == "overlay":
            try:
                rects = [tuple(float(v) for v in r) for r in req["rects"]]
                if any(len(r) != 4 or isinstance(v, bool) for r in req["rects"] for v in r):
                    raise ValueError
            except (KeyError, TypeError, ValueError):
                return send({"type": "error", "text": "rects is a list of [x, y, w, h]"})
            self.protected_rects = [tuple(int(v) if v == int(v) else v for v in r) for r in rects]
            send({"type": "ok"})
        elif cmd == "prompt":
            if self.task and not self.task.done():
                return send({"type": "error", "text": "busy: another request is running"})
            self.broadcast({"type": "prompt", "mode": "act" if req.get("mode") == "act" else "ask"})
            send({"type": "ok"})
        elif cmd in ("ask", "act"):
            text = str(req.get("text", "")).strip()
            if not text:
                return send({"type": "error", "text": f"{cmd} what? Give it some words."})
            try:
                task = self.start(cmd, text, req.get("mode") if req.get("mode") in CAPTURE_MODES else "monitor")
            except RuntimeError as e:
                return send({"type": "error", "text": str(e)})
            await self._follow(task, reader, writer)
        elif cmd == "sandbox":
            try:
                send({"type": "ok", "text": await self.sandbox_cmd(req.get("action"), req.get("command") or [])})
            except Exception as e:
                send({"type": "error", "text": str(e)})
        elif cmd == "shot":
            try:
                shot = await self.capture(req.get("mode") if req.get("mode") in CAPTURE_MODES else "monitor")
            except Exception as e:
                return send({"type": "error", "text": str(e)})
            send({"type": "ok", "path": self._save_shot(shot), "frame": dataclasses.asdict(shot.frame)})
        else:
            send({"type": "error", "text": f"unknown cmd {cmd!r}"})

    async def sandbox_cmd(self, action, command):
        if action == "start":
            return "the sandbox runs on " + await self.sandbox.start()
        if action == "stop":
            if self.task and not self.task.done() and self.sandbox_display():
                self.stop("the sandbox was closed")
            if getattr(self.input, "display", None) == self.sandbox.display:
                self._close_input()
            await self.sandbox.stop()
            return "the sandbox is closed"
        if action == "show":
            await proc.run(["hyprctl", "dispatch", 'hl.dsp.workspace.toggle_special("screenpilot")'], timeout=5)
            return "ok"
        if action == "run":
            if not command:
                raise RuntimeError("run what? e.g. screenpilot sandbox run foot")
            await self.sandbox.start()
            await self.sandbox.run([str(c) for c in command])
            return f"started {command[0]} in the sandbox"
        if action == "shot":
            from . import capture
            await self.sandbox.start()
            shot = await capture.grab(self.cfg, sandbox_env=self.sandbox.env())
            return self._save_shot(shot)
        raise RuntimeError(f"unknown sandbox action {action!r}")

    @staticmethod
    def _save_shot(shot):
        path = config.state_dir() / "shots" / time.strftime("%Y%m%d-%H%M%S.png")
        path.parent.mkdir(exist_ok=True)
        path.write_bytes(shot.png)
        return str(path)

    async def _follow(self, task, reader, writer):
        """Streams the run's events to the client that asked, until the answer, or until that
        client hangs up (which is STOP when stopOnClientDisconnect is on). The connection
        carries this one run: anything else it sends meanwhile is ignored, and it closes after."""
        self.subscribers.add(writer)
        gone = None
        try:
            while True:
                gone = asyncio.ensure_future(reader.read(1))
                done, _ = await asyncio.wait({task, gone}, return_when=asyncio.FIRST_COMPLETED)
                if task in done:
                    self.subscribers.discard(writer)
                    self._send(writer, {"type": "error", "text": f"stopped ({self.reason})"}
                               if task.cancelled() else task.result())
                    return
                if gone.result() == b"":
                    if self.cfg["stopOnClientDisconnect"]:
                        self.stop("the client that started it went away")
                    return
        finally:
            self.subscribers.discard(writer)
            if gone:  # also collects a broken-pipe error it may have ended with
                gone.cancel()
                await asyncio.gather(gone, return_exceptions=True)

    async def keep_overlay(self):
        """The overlay (STOP button, status, AI cursor; a separate Quickshell instance) runs as
        long as the daemon does. Losing it during a run is STOP: its button is gone."""
        env = {k: v for k, v in os.environ.items() if k != "QML_IMPORT_PATH"}
        env.setdefault("SCREENPILOT_CLI", shutil.which("screenpilot") or "screenpilot")
        while True:
            self.overlay = await asyncio.create_subprocess_exec(*self.overlay_cmd, env=env,
                                                                stdin=subprocess.DEVNULL)
            self.overlay_starts += 1
            code = await self.overlay.wait()
            if self.state in ("thinking", "acting", "paused"):
                self.stop("the overlay (and its STOP button) went away")
            log(f"overlay exited ({code}), starting it again")
            await asyncio.sleep(self.overlay_restart_s)

    async def serve_on(self, path):
        path = Path(path)
        path.unlink(missing_ok=True)
        server = await asyncio.start_unix_server(self.handle, str(path), limit=LINE_LIMIT)
        os.chmod(path, 0o600)
        return server

    async def serve(self):
        server = await self.serve_on(config.socket_path())
        config.pid_path().write_text(str(os.getpid()))
        self.install_signal_handler()
        quit_ = asyncio.Event()
        loop = asyncio.get_running_loop()
        for sig in (signal.SIGTERM, signal.SIGINT):
            loop.add_signal_handler(sig, quit_.set)
        log("listening on", config.socket_path(), "state", self.state)
        keeper = asyncio.ensure_future(self.keep_overlay())
        await quit_.wait()
        if self.input:
            self.input.release_all()
        keeper.cancel()
        if self.overlay and self.overlay.returncode is None:
            self.overlay.terminate()
        await self.sandbox.stop()
        server.close()


def main():
    asyncio.run(Daemon(config.load()).serve())


if __name__ == "__main__":
    main()
