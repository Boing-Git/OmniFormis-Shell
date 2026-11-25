"""What needs the user's OK before the AI does it, and the record of every run.

Risky: typed text or the AI's own words about an action naming something that deletes, sends,
buys or takes root; typing while a password is being asked for; keys that delete for good or
send. The policy (`confirm`): always (every action), risky (those, and the first action of each
run), never.
"""
import dataclasses
import json
import re
import shutil
import time

RISKY_WORDS = re.compile(r"\b(delete|remove|erase|wipe|format|send|submit|post|publish|buy|purchase|pay|"
                         r"checkout|transfer|sudo|su|rm|uninstall|shutdown|reboot|poweroff|kill)\b", re.I)
PASSWORD_PLACE = re.compile(r"password|passphrase|passcode|pin ?entry|pinentry|unlock|keyring|polkit|"
                            r"authenticat|sign ?in|log ?in|bitwarden|keepass|1password", re.I)
RISKY_KEYS = {"shift+delete", "ctrl+return", "ctrl+enter", "shift+del"}


def _active(context):
    try:
        a = json.loads(context).get("active") or {}
    except (ValueError, AttributeError):
        return ""
    return f"{a.get('class', '')} {a.get('title', '')}"


def risky(action, context) -> str | None:
    """Why this action needs a yes, or None."""
    if action.kind == "type" and PASSWORD_PLACE.search(_active(context)):
        return "it would type where a password is asked for"
    for words in (action.text if action.kind == "type" else "", action.reason):
        m = RISKY_WORDS.search(words or "")
        if m:
            return f"it looks like it would {m.group(1).lower()} something"
    if action.kind == "key" and any(k.lower() in RISKY_KEYS for k in action.keys.split()):
        return f"{action.keys} can delete or send for good"
    return None


def describe(action) -> str:
    what = action.text or action.keys or action.target
    where = f" at ({action.x:.0f}, {action.y:.0f})" if action.x is not None and action.y is not None else ""
    return f"{action.kind.replace('_', ' ')}{where}" + (f": {what}" if what else "") + \
        (f" ({action.reason})" if action.reason else "")


def question(action, context, policy, first) -> str | None:
    """The question to ask before this action, or None to go ahead."""
    if policy == "never":
        return None
    why = risky(action, context)
    if why:
        return f"Let the AI {describe(action)}? {why[0].upper() + why[1:]}."
    if policy == "always" or first:
        return f"Let the AI start: {describe(action)}?"
    return None


class RunLog:
    """~/.local/state/screenpilot/runs/<time>/: goal.txt, actions.jsonl, one PNG per step."""

    def __init__(self, root, goal, keep=20):
        root.mkdir(parents=True, exist_ok=True)
        self.dir = root / (time.strftime("%Y%m%d-%H%M%S-") + f"{time.time_ns() % 10**9:09d}")
        self.dir.mkdir()
        (self.dir / "goal.txt").write_text(goal)
        self.n = 0
        runs = sorted(p for p in root.iterdir() if p.is_dir())
        for old in runs[:-keep]:
            shutil.rmtree(old, ignore_errors=True)

    def step(self, action, shot, result):
        self.n += 1
        png = self.dir / f"{self.n:02d}.png"
        if shot is not None:
            png.write_bytes(shot.png)
        with open(self.dir / "actions.jsonl", "a") as f:
            f.write(json.dumps({"t": time.strftime("%Y-%m-%dT%H:%M:%S%z"), "step": self.n,
                                "action": dataclasses.asdict(action), "screenshot": str(png),
                                "result": result}) + "\n")
