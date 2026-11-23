#!/usr/bin/env python3
"""The commands a local AI (assistant.py) may run on this desktop, and nothing else.

Every command has a description and a JSON schema for its arguments, so a model can call it
as a tool. They go through what the dotfiles already have: the omniformis CLI (Hyprland's
variables, Puffy's settings, shortcuts), Dial-E's Prefs (live over IPC, else its settings
file), scripts/shell, and the usual desktop tools (playerctl, wpctl, gtk-launch, xdg-open).

    tools.py list                      every tool, as Ollama's `tools` JSON
    tools.py call <name> '<json>'      run one; prints its result
    tools.py call <name> '<json>' --yes   run one that asks first (power off, reboot, log out)

DOTS_DRY_RUN=1 prints the commands that would run instead of running them (the tests use it).
"""
import json
import os
import re
import shutil
import subprocess
import sys
from pathlib import Path

HOME = Path.home()
DOTS = Path(__file__).resolve().parents[2]
SHELL = DOTS / "scripts" / "shell"
DRY = os.environ.get("DOTS_DRY_RUN") == "1"
STATE = Path(os.environ.get("XDG_STATE_HOME", HOME / ".local/state"))
CACHE = Path(os.environ.get("XDG_CACHE_HOME", HOME / ".cache")) / "dots-assistant"
DIAL_SETTINGS = STATE / "dial-quickshell" / "settings.json"
DIAL_SCHEMA = CACHE / "dial-e-settings.json"
DIAL_DIR = DOTS / "quickshell"


# a tool's own failure, said in plain words: goes back to the model as the tool's result
class ToolError(Exception):
    pass


def run(cmd, timeout=20, check=True):
    """Runs a command (a list: never through a shell), returns its stdout."""
    if DRY:
        print("DRY " + " ".join(map(str, cmd)), file=sys.stderr)
        return ""
    try:
        p = subprocess.run(list(map(str, cmd)), capture_output=True, text=True, timeout=timeout)
    except FileNotFoundError:
        raise ToolError(f"{cmd[0]} is not installed")
    except subprocess.TimeoutExpired:
        raise ToolError(f"{cmd[0]} took too long")
    if check and p.returncode != 0:
        raise ToolError((p.stderr or p.stdout).strip() or f"{cmd[0]} failed ({p.returncode})")
    return p.stdout


def detach(cmd):
    """Starts an app and leaves it running on its own."""
    if DRY:
        print("DRY " + " ".join(map(str, cmd)), file=sys.stderr)
        return
    subprocess.Popen(list(map(str, cmd)), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                     stdin=subprocess.DEVNULL, start_new_session=True)


# the shell running now (scripts/shell list marks it with *), or ""
def current_shell():
    out = run([SHELL, "list"], check=False) if not DRY else "dial-e *\t"
    for line in out.splitlines():
        if "*" in line.split("\t")[0]:
            return line.split()[0]
    return ""


# ── settings ── three sources, one shape: {source, key, value, type, options, help}
def dial_settings():
    """Dial-E's Prefs: live when it runs (and the schema cached), else the cache plus the saved file."""
    if current_shell() == "dial-e":
        try:
            rows = json.loads(run([SHELL, "ipc", "call", "prefs", "listJson"]))
            CACHE.mkdir(parents=True, exist_ok=True)
            DIAL_SCHEMA.write_text(json.dumps(rows))
            return rows, True
        except (ToolError, ValueError):
            pass
    try:
        rows = json.loads(DIAL_SCHEMA.read_text())
    except (OSError, ValueError):
        return [], False
    saved = {}
    try:
        saved = json.loads(DIAL_SETTINGS.read_text())
    except (OSError, ValueError):
        pass
    for r in rows:
        r["value"] = saved.get(r["key"], r.get("default"))
    return rows, False


# ── Dial-E's Advanced settings ── (primitive/Advanced.qml) every plain property of its settings
# files: read here from the files themselves, the same way Advanced.qml does, so they are known
# whether Dial-E runs or not. Saved changes live in Vars.advancedPath as { type: { key: value } }
def advanced_path():
    m = re.search(r'const advancedPath\s*=\s*"([^"]+)"', (DIAL_DIR / "variables.js").read_text())
    return Path(m.group(1)) if m else STATE / "dial-quickshell" / "advanced.json"


# the settings files Advanced.qml reads, as (type, label, path), from its own `files` list
def advanced_files():
    text = (DIAL_DIR / "primitive" / "Advanced.qml").read_text()
    return re.findall(r'\{ type: "(\w+)", label: "([^"]+)", path: "([^"]+)"', text)


# a property's value in the file when it is a plain literal (number, bool, string), else None
def literal(raw):
    raw = raw.strip().rstrip(";").split("//")[0].strip()
    if raw in ("true", "false"):
        return raw == "true"
    m = re.fullmatch(r'"([^"\\]*)"', raw)
    if m:
        return m.group(1)
    try:
        if not re.fullmatch(r"-?\d+(\.\d+)?|-?\.\d+", raw):
            return None
        return float(raw) if "." in raw else int(raw)
    except ValueError:
        return None


def advanced_settings():
    """[{type, label, key, kind, int, section, help, default, value}] from the files and the saved changes."""
    try:
        saved = json.loads(advanced_path().read_text())
    except (OSError, ValueError):
        saved = {}
    out = []
    for type_, label, path in advanced_files():
        try:
            lines = (DIAL_DIR / path).read_text().splitlines()
        except OSError:
            continue
        section, comment = "General", []
        for line in lines:
            sec = re.match(r"^\s*//\s*──\s*(.+?)\s*(──|$)", line)
            if sec:
                t = re.sub(r"\(.*$", "", sec.group(1)).strip()
                t = re.sub(r"^the ", "", t)
                section = t[:1].upper() + t[1:]
                comment = []
                continue
            c = re.match(r"^\s*//\s?(.*)$", line)
            if c:
                comment.append(c.group(1))
                continue
            p_ = re.match(r"^\s*property\s+(real|int|bool|string)\s+(\w+)\s*:(.*)$", line)
            if p_ and section.lower() != "worked out":
                kind = {"bool": "bool", "string": "text"}.get(p_.group(1), "number")
                default = literal(p_.group(3))
                value = saved.get(type_, {}).get(p_.group(2), default)
                out.append({"type": type_, "label": label, "key": p_.group(2), "kind": kind, "int": p_.group(1) == "int",
                            "section": section, "help": " ".join(comment).strip(), "default": default, "value": value})
            comment = []
    return out


# the range Settings > Advanced allows a number, so the AI can't set what the UI couldn't
def advanced_range(row):
    # as Advanced.qml's rangeOf: from its own value (0 .. 3x, a negative one mirrored)
    d = row["default"] if isinstance(row["default"], (int, float)) and not isinstance(row["default"], bool) else 0
    return [d * 3 if d < 0 else 0, max(0 if d < 0 else d * 3, 10 if row["int"] else 1)]


# "LockSettings.ringRadius" = value: live over IPC while Dial-E runs, else into advanced.json
def advanced_set(full_key, value):
    type_, _, key = full_key.partition(".")
    row = next((r for r in advanced_settings() if r["type"] == type_ and r["key"] == key), None)
    if not row:
        raise ToolError(f"unknown Advanced setting '{full_key}' (it is Type.key, from settings_search)")
    if row["kind"] == "number":
        try:
            v = float(str(value).strip())
        except ValueError:
            raise ToolError(f"{key} is a number")
        lo, hi = advanced_range(row)
        if row["default"] is not None and not lo <= v <= hi:
            raise ToolError(f"{key} goes from {lo:g} to {hi:g}")
        v = int(round(v)) if row["int"] else (int(v) if v.is_integer() else v)
    elif row["kind"] == "bool":
        v = str(value).strip().lower() in ("true", "1", "on", "yes")
    else:
        v = str(value).strip()
        if v in ("", "undefined", "null", "NaN") or re.search(r'[\n\r"\\]', v):
            raise ToolError(f"{key} can't be '{v}'")
    if current_shell() == "dial-e":
        r = run([SHELL, "ipc", "call", "advanced", "set", type_, key, str(v).lower() if isinstance(v, bool) else str(v)]).strip()
        if r.startswith("Error"):
            raise ToolError(r)
        return f"{row['label']} > {key} = {v}"
    path = advanced_path()
    try:
        saved = json.loads(path.read_text())
    except (OSError, ValueError):
        saved = {}
    saved.setdefault(type_, {})[key] = v
    if not DRY:
        path.parent.mkdir(parents=True, exist_ok=True)
        tmp = path.with_suffix(".tmp")
        tmp.write_text(json.dumps(saved, indent=2) + "\n")
        tmp.replace(path)
    return f"Dial-E isn't running: saved {row['label']} > {key} = {v}, it applies when Dial-E starts"


# every setting of every source, in one shape the model can read
def all_settings():
    out = []
    for r in advanced_settings():
        rng = advanced_range(r) if r["kind"] == "number" and r["default"] is not None else [None, None]
        out.append({"source": "dial-e-advanced", "key": r["type"] + "." + r["key"], "value": r["value"],
                    "type": "number" if r["kind"] == "number" else r["kind"], "min": rng[0], "max": rng[1],
                    "help": f'Advanced > {r["label"]} > {r["section"]}: {r["help"]}'})
    rows, _ = dial_settings()
    for r in rows:
        out.append({"source": "dial-e", "key": r["key"], "value": r.get("value"), "type": r.get("type"),
                    "options": r.get("options"), "min": r.get("min"), "max": r.get("max"),
                    "help": f'{r.get("group", "")} > {r.get("label", "")}: {r.get("help", "")}'})
    try:
        for r in json.loads(run(["omniformis", "hypr", "list", "--json"])):
            out.append({"source": "hyprland", "key": r["key"], "value": r.get("value"), "type": r.get("type"),
                        "options": r.get("enums") or None, "help": f'{r.get("category", "")}: {r.get("help", "")}'})
    except (ToolError, ValueError):
        pass
    try:
        for k, v in json.loads(run(["omniformis", "qs", "list", "--json"])).items():
            out.append({"source": "puffy", "key": k, "value": v, "type": type(v).__name__, "help": "Puffy shell"})
    except (ToolError, ValueError):
        pass
    return out


# a key and its help as lowercase words, for matching
def words(s):
    # "lockBlur" → "lock blur", so "lock" and "blur" both find it
    return re.sub(r"([a-z])([A-Z])", r"\1 \2", str(s)).lower()


# the best dozen settings for some words: a hit in the key counts twice
def settings_search(query, source=""):
    terms = words(query).split()
    hits = []
    for s in all_settings():
        if source and s["source"] != source:
            continue
        text = words(s["key"]) + " " + words(s["help"])
        score = sum(t in text for t in terms) + sum(t in words(s["key"]) for t in terms)
        if score:
            hits.append((score, s))
    hits.sort(key=lambda h: -h[0])
    return [{k: v for k, v in h[1].items() if v not in (None, "", [])} for h in hits[:12]] or "no setting matches"


# sets one setting where it lives (the source settings_search gave)
def setting_set(source, key, value):
    if source == "dial-e-advanced":
        return advanced_set(key, value)
    if source == "hyprland":
        return run(["omniformis", "hypr", "set", key, str(value)]).strip() or f"{key} = {value}"
    if source == "puffy":
        return run(["omniformis", "qs", "set", key, str(value)]).strip() or f"{key} = {value}"
    if source != "dial-e":
        raise ToolError("source is one of dial-e, dial-e-advanced, hyprland, puffy")
    rows, live = dial_settings()
    if live:
        r = run([SHELL, "ipc", "call", "prefs", "set", key, str(value)]).strip()
        if r.startswith("Error"):
            raise ToolError(r)
        return r
    # Dial-E isn't running: checked against its schema, saved for when it starts
    row = next((r for r in rows if r["key"] == key), None)
    if not row:
        raise ToolError(f"unknown Dial-E setting '{key}'" + ("" if rows else " (start Dial-E once so its settings are known)"))
    v = coerce(row, value)
    saved = {}
    try:
        saved = json.loads(DIAL_SETTINGS.read_text())
    except (OSError, ValueError):
        pass
    saved[key] = v
    if not DRY:
        DIAL_SETTINGS.parent.mkdir(parents=True, exist_ok=True)
        tmp = DIAL_SETTINGS.with_suffix(".tmp")
        tmp.write_text(json.dumps(saved, indent=2) + "\n")
        tmp.replace(DIAL_SETTINGS)
    return f"Dial-E isn't running: saved {key} = {v}, it applies when Dial-E starts"


# a value given as text, as the type Dial-E's schema wants, checked against its range and choices
def coerce(row, value):
    t = row.get("type")
    if t == "bool":
        if str(value).lower() in ("true", "on", "yes", "1"):
            return True
        if str(value).lower() in ("false", "off", "no", "0"):
            return False
        raise ToolError(f"{row['key']} is on or off")
    if t == "number":
        try:
            v = float(value)
        except ValueError:
            raise ToolError(f"{row['key']} takes a number")
        lo, hi = row.get("min"), row.get("max")
        if (lo is not None and v < lo) or (hi is not None and v > hi):
            raise ToolError(f"{row['key']} goes from {lo} to {hi}")
        return int(v) if v.is_integer() else v
    if row.get("options") and value not in row["options"]:
        raise ToolError(f"{row['key']} is one of {', '.join(map(str, row['options']))}")
    return str(value)


# shortcuts whose description, name or keys hold every word
def keybinds_search(query):
    binds = json.loads(run(["omniformis", "hypr", "binds", "--json"]))["binds"]
    terms = query.lower().split()
    hits = [b for b in binds if all(t in (b["description"] + " " + b["key"] + " " + " ".join(b["resolved"])).lower() for t in terms)]
    return [{"does": b["description"], "keys": ", ".join(b["resolved"]) or b["combo"]} for b in hits[:12]] or "no shortcut matches"


# ── shells ──
def shell_switch(name):
    run([SHELL, "switch", name], timeout=30)
    return f"switched to {name}"


# the running shell's IPC targets and functions (qs ipc show)
def shell_actions():
    return run([SHELL, "ipc", "show"]).strip() or "the running shell offers no actions"


BLOCKED_IPC = {("prefs", "resetAll")}  # would wipe every setting


# one IPC call to the running shell, except the ones in BLOCKED_IPC
def shell_action(target, function, args=None):
    if (target, function) in BLOCKED_IPC:
        raise ToolError("not allowed from the assistant")
    return run([SHELL, "ipc", "call", target, function] + [str(a) for a in (args or [])]).strip() or "done"


# ── theme ──
def wallpaper_set(path):
    p = Path(path).expanduser()
    if not p.is_file():
        raise ToolError(f"no picture at {p}")
    detach([DOTS / "scripts" / "theme-apply.sh", p])
    return f"wallpaper and colours from {p.name}"


# pictures in ~/Pictures/Wallpapers whose name holds the words (20 at most)
def wallpapers(query=""):
    root = HOME / "Pictures" / "Wallpapers"
    pics = [p for p in root.rglob("*") if p.suffix.lower() in (".jpg", ".jpeg", ".png", ".webp", ".gif")] if root.is_dir() else []
    pics = [p for p in pics if query.lower() in p.name.lower()]
    return [str(p) for p in pics[:20]] or f"no wallpaper matches in {root}"


# light <-> dark, through omniformis
def theme_toggle():
    return run(["omniformis", "theme", "toggle"], timeout=60).strip() or "switched light / dark"


# ── apps and files ──
def desktop_entries():
    dirs = [HOME / ".local/share/applications"] + [Path(d) / "applications" for d in
            os.environ.get("XDG_DATA_DIRS", "/run/current-system/sw/share").split(":")]
    seen = {}
    for d in dirs:
        for f in d.glob("*.desktop") if d.is_dir() else []:
            if f.name in seen:
                continue
            text = f.read_text(errors="ignore")
            if re.search(r"^NoDisplay=true", text, re.M):
                continue
            m = re.search(r"^Name=(.+)$", text, re.M)
            if m:
                seen[f.name] = m.group(1).strip()
    return seen


# installed apps whose name or id holds the words, shortest names first
def apps_search(query):
    q = query.lower()
    hits = [(i, n) for i, n in desktop_entries().items() if q in n.lower() or q in i.lower()]
    return [{"name": n, "id": i[:-8]} for i, n in sorted(hits, key=lambda h: len(h[1]))[:12]] or "no app matches"


# starts the best match with gtk-launch, detached
def app_open(name):
    entries = desktop_entries()
    q = name.lower()
    best = sorted((i for i, n in entries.items() if q in n.lower() or q in i.lower()), key=lambda i: len(entries[i]))
    if not best:
        raise ToolError(f"no app called {name}")
    detach(["gtk-launch", best[0][:-8]])
    return f"opened {entries[best[0]]}"


SKIP = {".cache", ".local", ".nix-defexpr", ".nix-profile", "node_modules", ".git", ".cargo", ".rustup", ".mozilla", ".steam"}


# names under a folder holding the words (15 at most), hidden folders and caches skipped
def files_search(query, folder="~"):
    root = Path(folder).expanduser()
    if not root.is_dir():
        raise ToolError(f"no folder {root}")
    q = query.lower()
    out = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP and not d.startswith(".")]
        for n in dirnames + filenames:
            if q in n.lower():
                out.append(os.path.join(dirpath, n))
                if len(out) >= 15:
                    return out
    return out or f"nothing called {query} in {root}"


# a folder in the file manager the dotfiles name (Files), a file in its own app
def open_path(path):
    p = Path(path).expanduser()
    if not p.exists():
        raise ToolError(f"nothing at {p}")
    if p.is_dir():
        try:
            fm = run(["omniformis", "hypr", "get", "Files"]).strip() or "nautilus"
        except ToolError:
            fm = "nautilus"
        detach([fm, p])
    else:
        detach(["xdg-open", p])
    return f"opened {p}"


# ── media, sound, windows ──
def media(action):
    if action == "status":
        return run(["playerctl", "metadata", "--format", "{{status}}: {{artist}} - {{title}}"], check=False).strip() or "nothing playing"
    run(["playerctl", {"play_pause": "play-pause", "next": "next", "previous": "previous"}[action]])
    return action.replace("_", "/")


# the default speaker: get, set (0-100 %) or mute; answers with the volume after
def volume(action, percent=None):
    if action == "set":
        if percent is None:
            raise ToolError("set needs a percent")
        run(["wpctl", "set-volume", "-l", "1.0", "@DEFAULT_AUDIO_SINK@", f"{max(0, min(100, int(percent)))}%"])
    elif action == "mute":
        run(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
    return run(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]).strip() or "done"


# focuses a workspace (Hyprland's Lua dispatcher)
def workspace(number):
    run(["hyprctl", "dispatch", f"hl.dsp.focus({{ workspace = {int(number)} }})"])
    return f"workspace {number}"


# lock, suspend, log out, reboot, shut down (call() asks first for the last three)
def power(action):
    cmd = {"lock": ["loginctl", "lock-session"], "suspend": ["systemctl", "suspend"],
           "logout": ["hyprctl", "dispatch", "hl.dsp.exit()"], "reboot": ["systemctl", "reboot"],
           "shutdown": ["systemctl", "poweroff"]}[action]
    detach(cmd)
    return action


# a short picture of the desktop now, for questions like "what's playing"
def status():
    vol = volume("get") if shutil.which("wpctl") else ""
    return {"shell": current_shell(), "volume": vol, "media": media("status"),
            "workspace": (json.loads(run(["hyprctl", "activeworkspace", "-j"]) or "{}").get("id") if not DRY else 1)}


# ── the list ── name: (function, description, parameters, required, asks first)
def p(type_, desc, enum=None):
    d = {"type": type_, "description": desc}
    if enum:
        d["enum"] = enum
    return d


TOOLS = {
    "settings_search": (settings_search, "Find settings of the desktop: the Dial-E shell (dial-e: its main settings; dial-e-advanced: every size, timing and shape of its control center, media player, screenshot tool and lock screen), Hyprland (gaps, animations, layout, modifiers, default apps, game mode) and the Puffy shell. Always search before setting, to get the exact source and key.",
                        {"query": p("string", "words to look for, e.g. 'lock blur' or 'gaps'"), "source": p("string", "only this source", ["dial-e", "dial-e-advanced", "hyprland", "puffy"])}, ["query"], False),
    "setting_set": (setting_set, "Change one setting found with settings_search.",
                    {"source": p("string", "where the setting lives", ["dial-e", "dial-e-advanced", "hyprland", "puffy"]), "key": p("string", "the exact key"), "value": p("string", "the new value")}, ["source", "key", "value"], False),
    "keybinds_search": (keybinds_search, "Find keyboard shortcuts by what they do or by key.", {"query": p("string", "e.g. 'screenshot' or 'SUPER + T'")}, ["query"], False),
    "shell_switch": (shell_switch, "Switch the desktop shell.", {"name": p("string", "the shell", ["dial-e", "puffy", "droplet"])}, ["name"], False),
    "shell_actions": (shell_actions, "List what the running shell can do (its IPC targets and functions).", {}, [], False),
    "shell_action": (shell_action, "Run one of the running shell's actions listed by shell_actions, e.g. target 'center' function 'go' args ['settings'].",
                     {"target": p("string", "IPC target"), "function": p("string", "function name"), "args": {"type": "array", "items": {"type": "string"}, "description": "its arguments"}}, ["target", "function"], False),
    "wallpapers": (wallpapers, "List wallpapers (pictures in ~/Pictures/Wallpapers), optionally by name.", {"query": p("string", "part of the file name")}, [], False),
    "wallpaper_set": (wallpaper_set, "Set the wallpaper and recolour the desktop from it.", {"path": p("string", "the picture's path")}, ["path"], False),
    "theme_toggle": (theme_toggle, "Switch the colours between light and dark.", {}, [], False),
    "apps_search": (apps_search, "Find installed apps.", {"query": p("string", "part of the app's name")}, ["query"], False),
    "app_open": (app_open, "Open an app by name (Files, Firefox, Steam, Zed...).", {"name": p("string", "the app's name")}, ["name"], False),
    "files_search": (files_search, "Find files and folders by name under the home folder (hidden ones skipped).",
                     {"query": p("string", "part of the name"), "folder": p("string", "where to look, default ~")}, ["query"], False),
    "open_path": (open_path, "Open a file in its app, or a folder in the file manager.", {"path": p("string", "the path")}, ["path"], False),
    "media": (media, "Control the music or video playing.", {"action": p("string", "what to do", ["play_pause", "next", "previous", "status"])}, ["action"], False),
    "volume": (volume, "Speaker volume.", {"action": p("string", "what to do", ["get", "set", "mute"]), "percent": p("integer", "0 to 100, for set")}, ["action"], False),
    "workspace": (workspace, "Go to a workspace.", {"number": p("integer", "the workspace number")}, ["number"], False),
    "power": (power, "Lock, suspend, log out, restart or shut down. Log out, restart and shut down ask the user first.",
              {"action": p("string", "what to do", ["lock", "suspend", "logout", "reboot", "shutdown"])}, ["action"], False),
    "status": (status, "What the desktop is doing now: shell, volume, media, workspace.", {}, [], False),
}
ASKS_FIRST = {("power", "logout"), ("power", "reboot"), ("power", "shutdown")}


# true for a step the user must confirm (ASKS_FIRST)
def asks_first(name, args):
    return any(name == n and args.get("action") == a for n, a in ASKS_FIRST)


# TOOLS as Ollama's `tools` list (JSON schema per function)
def ollama_tools():
    return [{"type": "function", "function": {"name": n, "description": d,
             "parameters": {"type": "object", "properties": props, "required": req}}}
            for n, (_, d, props, req, _) in TOOLS.items()]


def call(name, args, confirmed=False):
    """Runs a tool: ("ok", result) | ("error", text) | ("confirm", question)."""
    if name not in TOOLS:
        return "error", f"no tool {name}"
    fn, _, props, req, _ = TOOLS[name]
    args = {k: v for k, v in (args or {}).items() if k in props}
    missing = [r for r in req if r not in args]
    if missing:
        return "error", "missing " + ", ".join(missing)
    for k, v in args.items():
        enum = props[k].get("enum")
        if enum and v not in enum:
            return "error", f"{k} is one of {', '.join(enum)}"
    if asks_first(name, args) and not confirmed:
        return "confirm", {"logout": "Log out?", "reboot": "Restart the computer?", "shutdown": "Shut down the computer?"}[args["action"]]
    try:
        return "ok", fn(**args)
    except ToolError as e:
        return "error", str(e)
    except Exception as e:  # a tool's bug must not take the assistant down
        return "error", f"{type(e).__name__}: {e}"


# the command line (see the top of this file)
def main(argv):
    if argv[:1] == ["list"]:
        print(json.dumps(ollama_tools(), indent=2))
        return 0
    if len(argv) >= 2 and argv[0] == "call":
        kind, result = call(argv[1], json.loads(argv[2]) if len(argv) > 2 else {}, "--yes" in argv)
        print(json.dumps({"kind": kind, "result": result}))
        return 0 if kind == "ok" else 1
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
