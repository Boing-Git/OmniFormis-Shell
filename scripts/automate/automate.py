#!/usr/bin/env python3
"""automate: small desktop automations, kept as JSON files, for any shell (or none).

    automate.py list [--json]            the automations: id, name, steps
    automate.py run <id> [--dry-run]     runs one; a JSON line per step (shells show them)
    automate.py show <id>                one, as JSON
    automate.py save <id> '<json>'       checks one and saves it (a script or an AI can write them)
    automate.py check <id | file>        what's wrong with one, if anything
    automate.py remove <id>

An automation is a file <id>.json in $AUTOMATIONS_DIR (default ~/.config/automations):

    {"name": "Game night", "icon": "sports_esports",
     "steps": [
        {"open": "steam"},                               an app: its desktop entry (name or id), or a command
        {"open": "spotify"},
        {"wait": {"player": "spotify"}, "timeout": 40},  until Spotify's media player is there
        {"media": "play", "player": "spotify"},          play / pause / play-pause / next / previous / stop
        {"wait": {"window": "steam"}, "timeout": 120},   until a window whose class holds "steam" is open
        {"uri": "steam://nav/games/details/2073850"},     a link or a file, in its app (xdg-open)
        {"sleep": 2},
        {"uri": "steam://rungameid/2073850"}
     ]}

Steps: open, run (a command, as a list of words: never through a shell), uri, wait (window,
player, process or file; "timeout" in seconds, 60 by default), media, sleep, notify. Any step can
say "optional": true: if it fails (or a wait runs out of time) the rest still runs.

Needs only Python 3, and uses what it finds: gtk-launch, xdg-open, playerctl, notify-send, and
hyprctl, swaymsg or niri to see windows (without them, a window wait looks for a process).
"""
import json
import os
import re
import shlex
import shutil
import subprocess
import sys
import time
from pathlib import Path

DIR = Path(os.environ.get("AUTOMATIONS_DIR") or Path(os.environ.get("XDG_CONFIG_HOME") or Path.home() / ".config") / "automations")
ID = re.compile(r"[a-z0-9][a-z0-9-]{0,40}")
KINDS = ("open", "run", "uri", "wait", "media", "sleep", "notify")
WAITS = ("window", "player", "process", "file")
MEDIA = ("play", "pause", "play-pause", "next", "previous", "stop")
EXTRAS = {"optional", "timeout", "player"}
DRY = False


# ── checking ──
def problems(a):
    """What's wrong with an automation (a dict), in plain words; [] when it's fine."""
    if not isinstance(a, dict):
        return ["an automation is a JSON object"]
    out = []
    if not isinstance(a.get("name", ""), str) or not isinstance(a.get("icon", ""), str):
        out.append("name and icon are text")
    steps = a.get("steps")
    if not isinstance(steps, list) or not steps:
        return out + ["steps is a list of at least one step"]
    for i, s in enumerate(steps, 1):
        kinds = [k for k in KINDS if isinstance(s, dict) and k in s]
        if len(kinds) != 1:
            out.append(f"step {i}: one of {', '.join(KINDS)}")
            continue
        k, v = kinds[0], s[kinds[0]]
        extra = set(s) - {k} - EXTRAS
        if extra:
            out.append(f"step {i}: unknown {', '.join(sorted(extra))}")
        if k in ("open", "uri", "notify") and not (isinstance(v, str) and v.strip()):
            out.append(f"step {i}: {k} needs text")
        elif k == "run" and not (isinstance(v, list) and v and all(isinstance(w, str) for w in v)):
            out.append(f"step {i}: run is a command as a list of words")
        elif k == "wait" and not (isinstance(v, dict) and len(v) == 1 and next(iter(v)) in WAITS
                                  and isinstance(next(iter(v.values())), str) and next(iter(v.values())).strip()):
            out.append(f"step {i}: wait is one of {', '.join(WAITS)}, e.g. {{\"window\": \"steam\"}}")
        elif k == "media" and v not in MEDIA:
            out.append(f"step {i}: media is one of {', '.join(MEDIA)}")
        elif k == "sleep" and not (isinstance(v, (int, float)) and not isinstance(v, bool) and 0 <= v <= 600):
            out.append(f"step {i}: sleep is 0 to 600 seconds")
        t = s.get("timeout", 60)
        if not (isinstance(t, (int, float)) and not isinstance(t, bool) and 0 < t <= 3600):
            out.append(f"step {i}: timeout is 1 to 3600 seconds")
    return out


def path_of(name):
    if not ID.fullmatch(name or ""):
        raise SystemExit(f"automate: an id is lowercase letters, digits and dashes, not '{name}'")
    return DIR / f"{name}.json"


def load(name):
    p = Path(name) if name.endswith(".json") else path_of(name)
    try:
        return json.loads(p.read_text())
    except FileNotFoundError:
        raise SystemExit(f"automate: no automation '{name}' (in {DIR})")
    except ValueError as e:
        raise SystemExit(f"automate: {p} isn't valid JSON ({e})")


def everything():
    """(id, automation) for each file in DIR, by name."""
    found = []
    for p in sorted(DIR.glob("*.json")) if DIR.is_dir() else []:
        try:
            found.append((p.stem, json.loads(p.read_text())))
        except ValueError:
            found.append((p.stem, {"name": p.stem, "steps": [], "broken": True}))
    return found


# ── doing ──
# (if whoever reads it goes away, e.g. the shell that started it restarts, it carries on unheard)
def say(**event):
    global say
    try:
        print(json.dumps(event), flush=True)
    except (BrokenPipeError, OSError):
        sys.stdout = open(os.devnull, "w")
        say = lambda **e: None


def spawn(cmd):
    """Starts something and leaves it running on its own."""
    if DRY:
        say(dry=cmd)
        return True
    try:
        subprocess.Popen(cmd, stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        return True
    except OSError:
        return False


def output(cmd, timeout=10):
    """A command's exit code and output; (127, "") when it isn't there."""
    if not shutil.which(cmd[0]):
        return 127, ""
    try:
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout)
        return p.returncode, p.stdout
    except (OSError, subprocess.TimeoutExpired):
        return 1, ""


def desktop_id(name):
    """The desktop entry (its id) of the app called `name`: an exact id or name first, then
    the shortest that holds it; None for none."""
    q = name.lower().strip()
    dirs = [Path(os.environ.get("XDG_DATA_HOME") or Path.home() / ".local/share")] + \
           [Path(d) for d in (os.environ.get("XDG_DATA_DIRS") or "/usr/local/share:/usr/share").split(":")]
    entries = {}
    for d in dirs:
        for f in (d / "applications").glob("*.desktop") if (d / "applications").is_dir() else []:
            if f.stem in entries:
                continue
            text = f.read_text(errors="ignore")
            m = re.search(r"^Name=(.+)$", text, re.M)
            if m and not re.search(r"^NoDisplay=true", text, re.M):
                entries[f.stem] = m.group(1).strip().lower()
    exact = [i for i, n in entries.items() if q in (i.lower(), n)]
    near = sorted((i for i, n in entries.items() if q in i.lower() or q in n), key=lambda i: len(entries[i]))
    return (exact or near or [None])[0]


def open_app(name):
    did = desktop_id(name)
    if did and shutil.which("gtk-launch"):
        return spawn(["gtk-launch", did])
    return spawn(shlex.split(name))


def window_names():
    """The open windows' classes and titles (lowercase), or None when no compositor says."""
    code, out = output(["hyprctl", "clients", "-j"])
    if code == 0:
        try:
            return [str(c.get(k, "")).lower() for c in json.loads(out) for k in ("class", "initialClass", "title")]
        except ValueError:
            pass
    code, out = output(["swaymsg", "-t", "get_tree"])
    if code == 0:
        names, todo = [], [json.loads(out)]
        while todo:
            n = todo.pop()
            names += [str(n.get("app_id") or "").lower(), str((n.get("window_properties") or {}).get("class") or "").lower(), str(n.get("name") or "").lower()]
            todo += n.get("nodes", []) + n.get("floating_nodes", [])
        return names
    code, out = output(["niri", "msg", "-j", "windows"])
    if code == 0:
        try:
            return [str(w.get(k) or "").lower() for w in json.loads(out) for k in ("app_id", "title")]
        except ValueError:
            pass
    return None


def ready(kind, value):
    v = value.lower()
    if kind == "window":
        names = window_names()
        if names is not None:
            return any(v in n for n in names)
        kind = "process"
    if kind == "player":
        code, out = output(["playerctl", "-l"])
        return code == 0 and any(v in line.lower() for line in out.split())
    if kind == "process":
        return output(["pgrep", "-if", value])[0] == 0
    return Path(value).expanduser().exists()


def wait(spec, timeout):
    kind, value = next(iter(spec.items()))
    if DRY:
        say(dry=["wait", kind, value])
        return True
    end = time.monotonic() + timeout
    while time.monotonic() < end:
        if ready(kind, value):
            return True
        time.sleep(0.5)
    return False


def describe(s):
    k = next(k for k in KINDS if k in s)
    v = s[k]
    return {"open": f"Opening {v}", "run": "Running " + " ".join(v) if k == "run" else "", "uri": f"Opening {v}",
            "wait": "Waiting for " + " ".join(next(iter(v.items()))) if k == "wait" else "",
            "media": f"Media: {v}", "sleep": f"Waiting {v} s", "notify": f"Saying \"{v}\""}[k]


def do(s):
    k = next(k for k in KINDS if k in s)
    v = s[k]
    if k == "open":
        return open_app(v)
    if k == "run":
        return spawn(v)
    if k == "uri":
        return spawn(["xdg-open", v])
    if k == "wait":
        return wait(v, s.get("timeout", 60))
    if k == "media":
        return spawn(["playerctl"] + (["--player=" + s["player"]] if s.get("player") else []) + [v])
    if k == "sleep":
        if not DRY:
            time.sleep(v)
        return True
    # a notification: notify-send, else straight over D-Bus (busctl); best effort, like any notification
    if shutil.which("notify-send"):
        return spawn(["notify-send", "Automation", v])
    if shutil.which("busctl"):
        return spawn(["busctl", "--user", "call", "org.freedesktop.Notifications", "/org/freedesktop/Notifications",
                      "org.freedesktop.Notifications", "Notify", "susssasa{sv}i", "Automation", "0", "bolt", "Automation", v, "0", "0", "6000"])
    return True


def run(name):
    a = load(name)
    why = problems(a)
    if why:
        say(done=False, error="; ".join(why))
        return 1
    steps = a["steps"]
    for i, s in enumerate(steps, 1):
        say(step=i, of=len(steps), doing=describe(s))
        ok = do(s)
        say(step=i, of=len(steps), ok=ok)
        if not ok and not s.get("optional"):
            say(done=False, error=f"step {i} ({describe(s)}) didn't work")
            return 1
    say(done=True, name=a.get("name", name))
    return 0


def main(argv):
    global DRY
    DRY = "--dry-run" in argv
    argv = [a for a in argv if a != "--dry-run"]
    cmd = argv[0] if argv else ""
    if cmd == "list":
        rows = [{"id": i, "name": a.get("name", i), "icon": a.get("icon", ""), "steps": len(a.get("steps") or []),
                 "ok": not problems(a), "says": [describe(s) for s in a["steps"]] if not problems(a) else []} for i, a in everything()]
        print(json.dumps(rows) if "--json" in argv else "\n".join(f"{r['id']}\t{r['name']}\t{r['steps']} steps" + ("" if r["ok"] else "\t(broken: automate.py check " + r["id"] + ")") for r in rows) or f"none yet (in {DIR})")
        return 0
    if cmd == "run" and len(argv) == 2:
        return run(argv[1])
    if cmd == "show" and len(argv) == 2:
        print(json.dumps(load(argv[1]), indent=2))
        return 0
    if cmd == "check" and len(argv) == 2:
        why = problems(load(argv[1]))
        print("\n".join(why) or "fine")
        return 1 if why else 0
    if cmd == "save" and len(argv) == 3:
        p = path_of(argv[1])
        try:
            a = json.loads(argv[2])
        except ValueError as e:
            print(f"automate: not valid JSON ({e})", file=sys.stderr)
            return 1
        why = problems(a)
        if why:
            print("\n".join(why), file=sys.stderr)
            return 1
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(json.dumps(a, indent=2) + "\n")
        print(p)
        return 0
    if cmd == "remove" and len(argv) == 2:
        path_of(argv[1]).unlink(missing_ok=True)
        return 0
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
