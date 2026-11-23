#!/usr/bin/env python3
"""screentime.py's daemon against a fake Hyprland event socket, with fast ticks.
Run: python3 scripts/tests/screentime.test.py"""
import datetime
import json
import os
import socket
import subprocess
import sys
import tempfile
import time
from pathlib import Path

SCRIPT = Path(__file__).resolve().parents[1] / "screentime.py"

with tempfile.TemporaryDirectory() as d:
    d = Path(d)
    (d / "hypr" / "test").mkdir(parents=True)
    server = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    server.bind(str(d / "hypr" / "test" / ".socket2.sock"))
    server.listen(1)
    env = dict(os.environ, XDG_RUNTIME_DIR=str(d), HYPRLAND_INSTANCE_SIGNATURE="test", XDG_STATE_HOME=str(d / "state"),
               SCREENTIME_TICK="0.05", SCREENTIME_FLUSH="0.1", PATH="/nonexistent")  # no hyprctl: nothing focused at start
    run = lambda *a: subprocess.run([sys.executable, SCRIPT, *a], env=env, capture_output=True, text=True)
    daemon = subprocess.Popen([sys.executable, SCRIPT, "daemon"], env=env)
    conn, _ = server.accept()

    # a second daemon gives way to the first
    assert run("daemon").returncode == 0

    conn.sendall(b"workspace>>1\nactivewindow>>firefox,Some page\n")
    time.sleep(1.0)
    conn.sendall(b"activewindow>>kitty,~\n")
    time.sleep(0.5)
    run("idle")                       # away: nothing counts
    time.sleep(0.6)
    run("active")
    run("off")                        # switched off: nothing counts
    time.sleep(0.6)
    run("on")
    conn.sendall(b"activewindow>>,\n")  # the desktop itself: nothing counts
    time.sleep(0.4)
    daemon.terminate()
    daemon.wait()

    apps = json.loads((d / "state" / "screentime" / f"{datetime.date.today().isoformat()}.json").read_text())
    assert 0.8 <= apps["firefox"] <= 1.3, apps
    assert 0.3 <= apps["kitty"] <= 0.8, apps
    assert set(apps) == {"firefox", "kitty"}, apps

    out = json.loads(run("json", "3").stdout)
    assert out["on"] is True and len(out["days"]) == 3 and out["days"][0]["apps"]["firefox"] == apps["firefox"]
    assert "firefox" in run("today").stdout

print("screentime: all passed")
