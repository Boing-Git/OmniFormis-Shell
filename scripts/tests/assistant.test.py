#!/usr/bin/env python3
"""assistant.py against a fake Ollama (a scripted conversation), tools in dry-run mode.
Run: python3 scripts/tests/assistant.test.py"""
import json
import os
import subprocess
import sys
import threading
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

HERE = Path(__file__).resolve().parents[1] / "assistant"
replies, seen = [], []


# the fake Ollama: answers each request with the next scripted reply, keeps what it was sent
class Fake(BaseHTTPRequestHandler):
    # /api/chat: record the request, answer with the next reply
    def do_POST(self):
        seen.append(json.loads(self.rfile.read(int(self.headers["Content-Length"]))))
        body = json.dumps({"message": replies.pop(0)}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(body)

    # quiet
    def log_message(self, *a):
        pass


# a model reply that calls one tool
def tool_call(name, args):
    return {"role": "assistant", "content": "", "tool_calls": [{"function": {"name": name, "arguments": args}}]}


# assistant.py on a prompt (tools dry-run, the fake server's address), its events
def run(prompt, url):
    env = dict(os.environ, DOTS_DRY_RUN="1", DOTS_AI_URL=url)
    out = subprocess.run([sys.executable, HERE / "assistant.py", prompt], capture_output=True, text=True, env=env, timeout=60)
    return [json.loads(l) for l in out.stdout.splitlines() if l.strip()]


server = HTTPServer(("127.0.0.1", 0), Fake)
threading.Thread(target=server.serve_forever, daemon=True).start()
url = f"http://127.0.0.1:{server.server_port}"

# a tool, its result back to the model, then the answer
replies[:] = [tool_call("volume", {"action": "set", "percent": 40}), {"role": "assistant", "content": "Volume is at 40%."}]
ev = run("volume to 40", url)
assert [e["type"] for e in ev] == ["thinking", "tool", "thinking", "answer"], ev
assert ev[1]["name"] == "volume" and ev[1]["ok"], ev[1]
assert ev[3]["text"] == "Volume is at 40%."
assert len(seen[0]["tools"]) > 10 and seen[0]["messages"][0]["role"] == "system"
assert seen[1]["messages"][-1]["role"] == "tool" and seen[1]["messages"][-1]["tool_name"] == "volume"

# a wrong argument comes back to the model as an error, not a crash
seen.clear()
replies[:] = [tool_call("media", {"action": "explode"}), {"role": "assistant", "content": "I can't do that."}]
ev = run("explode the music", url)
assert ev[1]["type"] == "tool" and not ev[1]["ok"] and "one of" in ev[1]["result"], ev
assert seen[1]["messages"][-1]["content"].startswith("Error:")

# restarting the computer stops and asks; nothing runs
replies[:] = [tool_call("power", {"action": "reboot"})]
ev = run("restart", url)
assert ev[-1] == {"type": "confirm", "name": "power", "args": {"action": "reboot"}, "question": "Restart the computer?"}, ev

# an unknown tool is an error for the model
replies[:] = [tool_call("rm_rf", {}), {"role": "assistant", "content": "Sorry."}]
ev = run("delete everything", url)
assert ev[1]["ok"] is False and "no tool" in ev[1]["result"]

# no Ollama: one clear error
server.shutdown()
ev = run("hello", "http://127.0.0.1:9")
assert ev[-1]["type"] == "error" and "Ollama" in ev[-1]["text"], ev

# Dial-E's Advanced settings: read from its files (as Advanced.qml does), saved for when it starts
import tempfile
sys.path.insert(0, str(HERE))
import tools
adv = tools.advanced_settings()
assert len(adv) > 250 and any(r["type"] == "LockSettings" and r["key"] == "ringRadius" for r in adv)
with tempfile.TemporaryDirectory() as d:
    tools.advanced_path = lambda: Path(d) / "advanced.json"
    tools.current_shell = lambda: "droplet"
    assert tools.call("setting_set", {"source": "dial-e-advanced", "key": "LockSettings.ringRadius", "value": "240"})[0] == "ok"
    assert json.loads((Path(d) / "advanced.json").read_text()) == {"LockSettings": {"ringRadius": 240}}
    kind, why = tools.call("setting_set", {"source": "dial-e-advanced", "key": "LockSettings.ringRadius", "value": "9999"})
    assert kind == "error" and "goes from" in why

# window rules: written one per line, read back, a bad value refused before anything is written
with tempfile.TemporaryDirectory() as d:
    tools.USER_RULES = Path(d) / "userRules.lua"
    tools.app_classes = lambda app: ["codium", "vscodium"]
    tools.DRY = False
    tools.run = lambda cmd, **kw: ""
    kind, said = tools.call("window_rule_add", {"app": "vscodium", "workspace": "special:scratchpad"})
    assert kind == "ok" and "special:scratchpad" in said, said
    assert tools.read_rules() == [{"name": "ai-vscodium-workspace", "match": {"class": "(?i)^(codium|vscodium)$"}, "workspace": "special:scratchpad"}]
    assert tools.call("window_rule_add", {"app": "vscodium", "size": "huge"})[0] == "error"
    assert tools.call("window_rule_add", {"app": "vscodium"})[0] == "error"
    assert tools.call("window_rule_remove", {"name": "ai-vscodium-workspace"})[0] == "ok" and tools.read_rules() == []

# dotfile edits: one exact piece, kept for undo; Hyprland refusing one puts it back; nothing
# outside the repo, and not the assistant's own files
with tempfile.TemporaryDirectory() as d:
    tools.FILES, tools.BACKUPS = Path(d) / "dots", Path(d) / "backups"
    lua = tools.FILES / "hypr/modules/variables.lua"
    lua.parent.mkdir(parents=True)
    lua.write_text("gaps_in = 5,\ngaps_out = 5,\n")
    errors = []
    tools.run = lambda cmd, **kw: "\n".join(errors) if cmd[1] == "configerrors" else ""
    assert tools.call("dotfiles_find", {"query": "gaps_out"})[1] == ["hypr/modules/variables.lua:2: gaps_out = 5,"]
    assert tools.call("dotfile_edit", {"path": "hypr/modules/variables.lua", "find": "= 5,", "replace": "= 9,"})[0] == "error"  # twice
    assert tools.call("dotfile_edit", {"path": "hypr/modules/variables.lua", "find": "gaps_in = 5,", "replace": "gaps_in = 9,"})[0] == "ok"
    assert lua.read_text() == "gaps_in = 9,\ngaps_out = 5,\n"
    tools.run = lambda cmd, **kw: ("bad line 2" if lua.read_text().startswith("gaps_in = 9,\ngaps_out = x") else "") if cmd[1] == "configerrors" else ""
    kind, why = tools.call("dotfile_edit", {"path": "hypr/modules/variables.lua", "find": "gaps_out = 5,", "replace": "gaps_out = x,"})
    assert kind == "error" and "bad line 2" in why and lua.read_text() == "gaps_in = 9,\ngaps_out = 5,\n", why
    assert tools.call("dotfile_undo", {"path": "hypr/modules/variables.lua"})[0] == "ok"
    assert lua.read_text() == "gaps_in = 5,\ngaps_out = 5,\n"
    assert tools.call("dotfile_read", {"path": "/etc/passwd"})[0] == "error"
    # words in any order, `_` as a space; the indentation a model gets wrong is put right
    assert tools.call("dotfiles_find", {"query": "keyboard gaps out"})[1] == ["hypr/modules/variables.lua:2: gaps_out = 5,"]
    assert tools.replaced("a = {\n    b = 1,\n    c = 2,\n}\n", "     c = 2,\n", "     c = 3,\n") == "a = {\n    b = 1,\n    c = 3,\n}\n"
    assert tools.replaced("x = 1\nx = 1\n", "x = 1", "x = 2") is None
    assert tools.call("dotfile_edit", {"path": "scripts/assistant/tools.py", "find": "a", "replace": "b"})[0] == "error"

print("assistant: all passed")
