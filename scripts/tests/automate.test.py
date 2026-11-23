#!/usr/bin/env python3
"""scripts/automate/automate.py: checking, saving, listing, and a dry run.
Run: python3 scripts/tests/automate.test.py"""
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parents[1] / "automate"
sys.path.insert(0, str(HERE))
import automate

example = json.loads((HERE / "examples" / "game-night.json").read_text())
assert automate.problems(example) == [], automate.problems(example)
assert automate.problems({"steps": []}) == ["steps is a list of at least one step"]
assert automate.problems({"steps": [{"open": "x", "uri": "y"}]})[0].startswith("step 1: one of")
assert "media is one of" in automate.problems({"steps": [{"media": "explode"}]})[0]
assert "wait is one of" in automate.problems({"steps": [{"wait": {"moon": "x"}}]})[0]
assert "run is a command" in automate.problems({"steps": [{"run": "rm -rf /"}]})[0]


# the command line, on a folder of its own
def cli(*args, folder):
    env = dict(os.environ, AUTOMATIONS_DIR=folder)
    p = subprocess.run([sys.executable, HERE / "automate.py", *args], capture_output=True, text=True, env=env, timeout=30)
    return p.returncode, p.stdout, p.stderr


with tempfile.TemporaryDirectory() as d:
    assert cli("save", "game-night", json.dumps(example), folder=d)[0] == 0
    code, out, err = cli("save", "Bad Name", json.dumps(example), folder=d)
    assert code != 0
    assert cli("save", "broken", '{"steps": [{"media": "explode"}]}', folder=d)[0] == 1 and not (Path(d) / "broken.json").exists()
    rows = json.loads(cli("list", "--json", folder=d)[1])
    assert [{k: r[k] for k in ("id", "name", "icon", "steps", "ok")} for r in rows] == [{"id": "game-night", "name": "Game night", "icon": "sports_esports", "steps": 8, "ok": True}], rows
    assert rows[0]["says"][0] == "Opening steam" and len(rows[0]["says"]) == 8

    # a dry run says each step and what it would run, and finishes
    code, out, _ = cli("run", "game-night", "--dry-run", folder=d)
    events = [json.loads(l) for l in out.splitlines()]
    assert code == 0 and events[-1] == {"done": True, "name": "Game night"}, events[-3:]
    ran = [e["dry"] for e in events if "dry" in e]
    assert ["xdg-open", "steam://rungameid/2073850"] in ran and ["playerctl", "--player=spotify", "play"] in ran, ran

    # a wait that runs out of time stops the rest, unless it's optional
    missing = str(Path(d) / "never")
    cli("save", "waits", json.dumps({"steps": [{"wait": {"file": missing}, "timeout": 1}, {"notify": "after"}]}), folder=d)
    code, out, _ = cli("run", "waits", folder=d)
    assert code == 1 and json.loads(out.splitlines()[-1])["done"] is False
    cli("save", "waits", json.dumps({"steps": [{"wait": {"file": missing}, "timeout": 1, "optional": True}, {"sleep": 0}]}), folder=d)
    assert cli("run", "waits", folder=d)[0] == 0

print("automate: all passed")
