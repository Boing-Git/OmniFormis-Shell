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


class Fake(BaseHTTPRequestHandler):
    def do_POST(self):
        seen.append(json.loads(self.rfile.read(int(self.headers["Content-Length"]))))
        body = json.dumps({"message": replies.pop(0)}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *a):
        pass


def tool_call(name, args):
    return {"role": "assistant", "content": "", "tool_calls": [{"function": {"name": name, "arguments": args}}]}


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

print("assistant: all passed")
