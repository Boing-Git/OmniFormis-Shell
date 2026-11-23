#!/usr/bin/env python3
"""Screen time: how long each app had your attention, per day. Shared by every shell.

The daemon (started at login, next to any shell) follows Hyprland's focused window on its
event socket and adds the time to that app (its window class). Time doesn't count while you
are away (hypridle runs `screentime.py idle` / `active`), while the machine sleeps (time is
added in short ticks, and a gap longer than a few ticks isn't), or while it is switched off.

    screentime.py daemon             follow the focused window (one at a time; autostart)
    screentime.py json [days]        the last <days> days (default 7), today first, as JSON
    screentime.py today              today, as text
    screentime.py on | off | status  the one switch every shell's Screen time setting turns
    screentime.py idle | active      from hypridle

Kept in ~/.local/state/screentime/<date>.json as {"<window class>": seconds}; delete a file
to forget a day. Nothing leaves the machine.
"""
import datetime
import fcntl
import json
import os
import signal
import socket
import subprocess
import sys
import time
from pathlib import Path

STATE = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local/state")) / "screentime"
OFF = STATE / "off"
IDLE = STATE / "idle"
TICK = float(os.environ.get("SCREENTIME_TICK", "5"))   # seconds between two counts
FLUSH = float(os.environ.get("SCREENTIME_FLUSH", "15"))  # seconds between two writes


def day_file(day):
    return STATE / f"{day.isoformat()}.json"


def load(day):
    try:
        d = json.loads(day_file(day).read_text())
        return {k: float(v) for k, v in d.items()} if isinstance(d, dict) else {}
    except (OSError, ValueError):
        return {}


def save(day, apps):
    # a temp file renamed over the real one: never a half-written day
    STATE.mkdir(parents=True, exist_ok=True)
    tmp = day_file(day).with_suffix(".tmp")
    tmp.write_text(json.dumps({k: round(v, 1) for k, v in sorted(apps.items(), key=lambda a: -a[1])}, indent=1))
    tmp.replace(day_file(day))


def event_socket():
    rt = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    sig = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
    return Path(rt) / "hypr" / sig / ".socket2.sock"


def focused_now():
    # the window focused when the daemon starts (events only say what changes)
    try:
        out = subprocess.run(["hyprctl", "activewindow", "-j"], capture_output=True, text=True, timeout=3).stdout
        return (json.loads(out or "{}") or {}).get("class", "") or ""
    except (OSError, ValueError, subprocess.TimeoutExpired):
        return ""


def daemon():
    STATE.mkdir(parents=True, exist_ok=True)
    lock = open(STATE / "daemon.lock", "w")
    try:
        fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
    except OSError:
        return 0  # one is running already
    st = {"day": datetime.date.today()}
    st["apps"] = load(st["day"])
    # stopped (logging out): what was counted since the last write is kept
    signal.signal(signal.SIGTERM, lambda *_: sys.exit(0))
    try:
        follow(st)
    finally:
        save(st["day"], st["apps"])
    return 0


def follow(st):
    current = focused_now()
    last = flushed = time.monotonic()
    buf, sock = b"", None
    while True:
        if sock is None:
            try:
                sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
                sock.connect(str(event_socket()))
                sock.settimeout(TICK)
            except OSError:
                sock = None
                time.sleep(TICK)  # Hyprland not there (yet): try again
        if sock is not None:
            try:
                data = sock.recv(4096)
                if not data:
                    raise OSError("closed")
                buf += data
            except socket.timeout:
                pass
            except OSError:
                sock.close()
                sock = None

        # count what was focused until now (not across a sleep), then take in what changed
        now = time.monotonic()
        gap, last = now - last, now
        today = datetime.date.today()
        if today != st["day"]:
            save(st["day"], st["apps"])
            st["day"], st["apps"] = today, load(today)
        if current and gap <= TICK * 3 and not OFF.exists() and not IDLE.exists():
            st["apps"][current] = st["apps"].get(current, 0) + gap
        while b"\n" in buf:
            line, buf = buf.split(b"\n", 1)
            name, _, value = line.decode(errors="ignore").partition(">>")
            if name == "activewindow":
                current = value.split(",", 1)[0]
        if now - flushed >= FLUSH:
            save(st["day"], st["apps"])
            flushed = now


def days(n):
    today = datetime.date.today()
    return [{"date": (today - datetime.timedelta(days=i)).isoformat(), "apps": load(today - datetime.timedelta(days=i))}
            for i in range(n)]


def pretty(seconds):
    m = int(seconds // 60)
    return f"{m // 60} h {m % 60} min" if m >= 60 else f"{m} min" if m >= 1 else "< 1 min"


def main(argv):
    cmd = argv[0] if argv else ""
    if cmd == "daemon":
        return daemon()
    if cmd == "json":
        print(json.dumps({"on": not OFF.exists(), "days": days(int(argv[1]) if len(argv) > 1 else 7)}))
        return 0
    if cmd == "today":
        apps = days(1)[0]["apps"]
        for k, v in sorted(apps.items(), key=lambda a: -a[1]):
            print(f"{pretty(v):>12}  {k}")
        print(f"{pretty(sum(apps.values())):>12}  in all")
        return 0
    if cmd in ("on", "off"):
        STATE.mkdir(parents=True, exist_ok=True)
        OFF.touch() if cmd == "off" else OFF.unlink(missing_ok=True)
        return 0
    if cmd == "status":
        print("off" if OFF.exists() else "on")
        return 0
    if cmd in ("idle", "active"):
        STATE.mkdir(parents=True, exist_ok=True)
        IDLE.touch() if cmd == "idle" else IDLE.unlink(missing_ok=True)
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
