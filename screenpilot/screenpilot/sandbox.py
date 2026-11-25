"""The AI's own desktop: a nested sway in a window on Hyprland's special workspace "screenpilot"
(hypr/modules/screenpilot.lua puts it there, and keeps it drawing while hidden: without that,
screenshots of it hang). It has its own seat, cursor and keyboard focus; the AI's input goes to
its socket, never to the user's session. STOP halts the AI, not the sandbox: its apps stay.

Its apps get a home of their own (~/.local/state/screenpilot/sandbox-home, kept between runs so a
login inside stays) and a private D-Bus session: they start fresh instead of restoring the
user's session or handing the request to an app already running on the user's desktop (seen:
a text editor started inside restored the user's open files). It is a separate desktop, not a
security boundary: the apps still run as the user and can reach any file by its path.
"""
import asyncio
import os
import re
import shlex
import subprocess

from . import config, proc

CONFIG = """# screenpilot's sandbox: the AI's own desktop
output * bg #1d2733 solid_color
exec sh -c 'echo "$WAYLAND_DISPLAY" > {dir}/display'
"""


class Sandbox:
    def __init__(self):
        self.dir = config.runtime_dir() / "screenpilot-sandbox"
        self.proc = None
        self.display = None

    @property
    def running(self):
        return self.proc is not None and self.proc.returncode is None and self.display is not None

    def env(self):
        """For talking to the sandbox from the daemon: grim, swaymsg, the input client."""
        return dict(os.environ, WAYLAND_DISPLAY=self.display or "", SWAYSOCK=str(self.dir / "sway.sock"))

    def sway_env(self):
        """sway's own, which its apps inherit."""
        home = config.state_dir() / "sandbox-home"
        env = dict(os.environ, HOME=str(home), WLR_BACKENDS="wayland", WLR_LIBINPUT_NO_DEVICES="1",
                   SWAYSOCK=str(self.dir / "sway.sock"), XDG_RUNTIME_DIR=str(config.runtime_dir()))
        for var, sub in (("XDG_CONFIG_HOME", ".config"), ("XDG_DATA_HOME", ".local/share"),
                         ("XDG_STATE_HOME", ".local/state"), ("XDG_CACHE_HOME", ".cache")):
            env[var] = str(home / sub)
        env.pop("DBUS_SESSION_BUS_ADDRESS", None)
        return env

    def sway_cmd(self):
        # --unsupported-gpu: sway refuses NVIDIA's driver without it (it runs fine nested)
        return ["dbus-run-session", "--", "sway", "--unsupported-gpu", "-c", str(self.dir / "sway.conf")]

    async def start(self) -> str:
        """Starts it if it isn't running; returns its WAYLAND_DISPLAY."""
        if self.running:
            return self.display
        self.dir.mkdir(mode=0o700, exist_ok=True)
        marker = self.dir / "display"
        marker.unlink(missing_ok=True)
        (self.dir / "sway.conf").write_text(CONFIG.format(dir=self.dir))
        env = self.sway_env()
        os.makedirs(env["HOME"], exist_ok=True)
        with open(self.dir / "sway.log", "wb") as log:
            self.proc = await asyncio.create_subprocess_exec(
                *self.sway_cmd(), env=env, stdin=subprocess.DEVNULL, stdout=log, stderr=log)
        for _ in range(100):
            if marker.exists() and marker.read_text().strip():
                self.display = marker.read_text().strip()
                return self.display
            if self.proc.returncode is not None:
                break
            await asyncio.sleep(0.1)
        await self.stop()
        raise RuntimeError(f"the sandbox (sway) didn't start: see {self.dir / 'sway.log'}")

    async def stop(self):
        p, self.proc = self.proc, None
        if p and p.returncode is None:
            try:
                await proc.run(["swaymsg", "exit"], env=dict(self.env(), WAYLAND_DISPLAY=self.display or ""), timeout=2)
                await asyncio.wait_for(p.wait(), 3)
            except (RuntimeError, OSError, TimeoutError):
                p.kill()
                await p.wait()
        self.display = None

    async def swaymsg(self, *args) -> bytes:
        return await proc.run(["swaymsg", *args], env=self.env(), timeout=5)

    async def run(self, cmd):
        """Starts an app inside the sandbox."""
        await self.swaymsg("exec", shlex.join(cmd))

    async def focus(self, target):
        """Focuses a sandbox window by app id or title (a regex, case-insensitive)."""
        target = re.sub(r'["\\\]\[]', "", target or "")
        for key in ("app_id", "class", "title"):
            try:
                await self.swaymsg(f'[{key}="(?i){target}"]', "focus")
                return
            except RuntimeError:
                continue
        raise RuntimeError(f"no sandbox window matches {target!r}")
