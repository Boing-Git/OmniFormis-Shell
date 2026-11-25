"""screenpilot: the command line for screenpilotd.

    screenpilot ask "what do I do here?"     answer about the screen (printed and spoken)
    screenpilot act "open a terminal"        let the AI do it
    screenpilot stop | resume | status
    screenpilot backend [claude|local]       which model answers (one switch for every shell)
    screenpilot say "text" | --selection     read aloud
    screenpilot shot [--mode window]         save what the model would see
    screenpilot sandbox start|stop|show|run CMD...
    screenpilot prompt ask|act               the overlay's text box (for keybinds)
"""
import argparse
import json
import os
import signal
import socket
import subprocess
import sys
import time

from . import config

SERVICE = "screenpilot.service"


def request(obj, *, timeout=None, follow=False):
    """Sends one request and returns the final reply. With follow, the run's events before it
    go to stderr as they come."""
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
        s.settimeout(timeout)
        s.connect(str(config.socket_path()))
        s.sendall(json.dumps(obj).encode() + b"\n")
        for line in s.makefile("rb"):
            event = json.loads(line)
            if follow and event.get("type") not in ("answer", "error"):
                if event.get("type") in ("state", "step"):
                    print(event.get("text") or event.get("state"), file=sys.stderr, flush=True)
                continue
            return event
    raise ConnectionError("screenpilotd closed the connection")


def stop_escalation(*, kill=os.kill, run=subprocess.run, wait=0.15) -> str:
    """STOP that doesn't trust the daemon: the socket, then SIGUSR1 (handled outside its event
    loop), then killing the whole service (every child with it) and starting it again halted.
    Returns which layer did it."""
    try:
        if request({"cmd": "stop", "reason": "user"}, timeout=wait).get("state") == "halted":
            return "socket"
    except (OSError, ValueError):
        pass
    halt = config.halt_path()
    try:
        pid = int(config.pid_path().read_text())
        halt.unlink(missing_ok=True)  # so a marker that appears now is the handler's answer
        kill(pid, signal.SIGUSR1)
        deadline = time.monotonic() + wait
        while time.monotonic() < deadline:
            if halt.exists():
                return "signal"
            time.sleep(0.01)
    except (OSError, ValueError):
        pass
    halt.write_text("stop: the daemon did not answer")  # it starts again halted
    run(["systemctl", "--user", "kill", "--signal=KILL", SERVICE], check=False)
    run(["systemctl", "--user", "restart", SERVICE], check=False)
    return "service"


def main(argv=None):
    p = argparse.ArgumentParser(prog="screenpilot", description=__doc__,
                                formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    ask = sub.add_parser("ask")
    ask.add_argument("text", nargs="+")
    ask.add_argument("--mode", default="monitor", choices=("monitor", "window", "region"),
                     help="what to show the model: the focused monitor, the active window, or a region you pick")
    sub.add_parser("act").add_argument("text", nargs="+")
    for name in ("stop", "resume", "status"):
        sub.add_parser(name)
    sub.add_parser("backend").add_argument("name", nargs="?", choices=config.BACKENDS)
    sub.add_parser("mode").add_argument("name", nargs="?", choices=config.MODES)
    say = sub.add_parser("say")
    say.add_argument("text", nargs="*")
    say.add_argument("--selection", action="store_true", help="read the selected text (primary selection)")
    sub.add_parser("shot").add_argument("--mode", default="monitor", choices=("monitor", "window", "region"))
    sb = sub.add_parser("sandbox")
    sb.add_argument("action", choices=("start", "stop", "show", "run", "shot"))
    sb.add_argument("command", nargs=argparse.REMAINDER)
    sub.add_parser("prompt").add_argument("mode", choices=("ask", "act"))
    a = p.parse_args(argv)

    if a.cmd == "stop":
        print("stopped (" + stop_escalation() + ")")
        return 0
    if a.cmd in config.RUNTIME and not config.socket_path().exists():  # no daemon: the file alone
        if a.name:
            config.set(a.cmd, a.name)
        print(config.load()[a.cmd])
        return 0

    req = {"cmd": a.cmd}
    if a.cmd in ("ask", "act"):
        req["text"] = " ".join(a.text)
        if a.cmd == "ask":
            req["mode"] = a.mode
    elif a.cmd in config.RUNTIME and a.name:
        req["name"] = a.name
    elif a.cmd == "say":
        text = " ".join(a.text)
        if a.selection:
            text = subprocess.run(["wl-paste", "--primary", "--no-newline"], capture_output=True, text=True).stdout
        req["text"] = text
    elif a.cmd == "shot":
        req["mode"] = a.mode
    elif a.cmd == "sandbox":
        req.update(action=a.action, command=a.command)
    elif a.cmd == "prompt":
        req["mode"] = a.mode

    try:
        event = request(req, follow=a.cmd in ("ask", "act"))
    except OSError as e:
        print(f"screenpilot: can't reach screenpilotd ({e}). Is the service running?", file=sys.stderr)
        return 1
    if event.get("type") == "error":
        print("screenpilot: " + event.get("text", "failed"), file=sys.stderr)
        return 1
    if a.cmd == "status":
        print(event["state"] + (f" ({event['reason']})" if event.get("reason") else "")
              + f", {event['backend']}, {event['mode']}")
    elif a.cmd in config.RUNTIME:
        print(event[a.cmd])
    elif a.cmd == "shot":
        print(event["path"])
        print("frame: " + json.dumps(event["frame"]), file=sys.stderr)
    else:
        print(event.get("text") or event.get("path") or event.get("state") or "ok")
    return 0


if __name__ == "__main__":
    sys.exit(main())
