#!/usr/bin/env python3
"""Asks the local AI (Ollama) to do something on the desktop, with tools.py as its hands.

    assistant.py "make the gaps bigger"
    assistant.py --yes power '{"action": "reboot"}'     run a step the user confirmed
    assistant.py --warm                                    wake the model (each shell runs this
                                                           as its AI opens): {"type": "ready"}

It prints one JSON line per event, for the overlay (assistant/shell.qml) or a terminal:
    {"type": "thinking"}
    {"type": "tool", "name": ..., "args": {...}, "ok": true, "result": ...}
    {"type": "confirm", "name": ..., "args": {...}, "question": "Restart the computer?"}
    {"type": "answer", "text": "..."}
    {"type": "error", "text": "..."}

The model and server: DOTS_AI_MODEL (default qwen3:8b) and DOTS_AI_URL (default
http://127.0.0.1:11434). Nothing leaves the machine.
"""
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import tools  # noqa: E402

MODEL = os.environ.get("DOTS_AI_MODEL", "qwen3:8b")
URL = os.environ.get("DOTS_AI_URL", "http://127.0.0.1:11434").rstrip("/")
MAX_STEPS = 8
# tokens the model may see at once: the tools and context.md alone take ~6k (Ollama's default is 4k)
CONTEXT = int(os.environ.get("DOTS_AI_CONTEXT", "16384"))

SYSTEM = """You are {name}, the mascot of this desktop's shell: friendly, a little playful, never chatty. You run this Linux desktop (NixOS, Hyprland) for its user through tools, and nothing else.
- To change a setting: settings_search first, then setting_set with the exact source and key it gave.
- Use only what a tool returned; never invent keys, paths or values.
- After acting, answer in one short sentence in plain words: what changed. No markdown.
- Say something changed only when a tool said so; if a tool failed and you couldn't fix it, say it didn't work and why.
- If nothing fits, say so in one sentence.
The running shell is {shell}.

""" + (Path(__file__).resolve().parent / "context.md").read_text()


# one event as a JSON line, flushed at once so the overlay sees it as it happens
def emit(**event):
    print(json.dumps(event), flush=True)


# one round with the model: the conversation so far and the tools in, its message out
def chat(messages):
    body = json.dumps({"model": MODEL, "messages": messages, "tools": tools.ollama_tools(),
                       "stream": False, "think": False, "options": {"temperature": 0.2, "num_ctx": CONTEXT}}).encode()
    req = urllib.request.Request(URL + "/api/chat", body, {"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=180) as r:
        return json.loads(r.read())["message"]


# a request, start to end: the model picks tools, they run, results go back, until it answers
def missing_model():
    """The reason the model can't answer yet ("" if it can): Ollama down, or the model not there."""
    try:
        with urllib.request.urlopen(URL + "/api/tags", timeout=5) as r:
            names = [m.get("name", "") for m in json.loads(r.read()).get("models", [])]
    except (urllib.error.URLError, ValueError, TimeoutError) as e:
        return f"The local AI isn't running at {URL} ({getattr(e, 'reason', e)}). Is Ollama on?"
    if MODEL not in names and MODEL + ":latest" not in names:
        return f"The model {MODEL} isn't here yet: it may still be downloading (or run: ollama pull {MODEL})."
    return ""


def warm():
    # loads the model into the graphics card and keeps it there a while, so the first question
    # doesn't wait for it
    why = missing_model()
    if why:
        emit(type="error", text=why)
        return 1
    # (the same num_ctx as chat: another would load the model again)
    body = json.dumps({"model": MODEL, "keep_alive": "15m", "options": {"num_ctx": CONTEXT}}).encode()
    try:
        urllib.request.urlopen(urllib.request.Request(URL + "/api/generate", body, {"Content-Type": "application/json"}), timeout=120).read()
    except (urllib.error.URLError, TimeoutError) as e:
        emit(type="error", text=f"The local AI didn't wake ({getattr(e, 'reason', e)}).")
        return 1
    emit(type="ready")
    return 0


# each shell's AI is its mascot
NAMES = {"dial-e": "Dial-E", "puffy": "Puffy", "droplet": "Droplet"}


def ask(prompt):
    shell = tools.current_shell() or "unknown"
    messages = [{"role": "system", "content": SYSTEM.replace("{shell}", shell).replace("{name}", NAMES.get(shell, "the assistant"))},
                {"role": "user", "content": prompt}]
    for _ in range(MAX_STEPS):
        emit(type="thinking")
        try:
            msg = chat(messages)
        except urllib.error.URLError as e:
            emit(type="error", text=missing_model() or f"The local AI isn't answering at {URL} ({getattr(e, 'reason', e)}).")
            return 1
        except (ValueError, KeyError, TimeoutError) as e:
            emit(type="error", text=f"The local AI gave no usable answer ({e}).")
            return 1
        messages.append(msg)
        calls = msg.get("tool_calls") or []
        if not calls:
            emit(type="answer", text=(msg.get("content") or "").strip() or "Done.")
            return 0
        for c in calls:
            fn = c.get("function", {})
            name, args = fn.get("name", ""), fn.get("arguments") or {}
            if isinstance(args, str):
                try:
                    args = json.loads(args)
                except ValueError:
                    args = {}
            kind, result = tools.call(name, args)
            if kind == "confirm":
                # stops here: the user says yes in the overlay, which runs it with --yes
                emit(type="confirm", name=name, args=args, question=result)
                return 0
            emit(type="tool", name=name, args=args, ok=kind == "ok", result=result)
            messages.append({"role": "tool", "tool_name": name,
                             "content": json.dumps(result) if kind == "ok" else "Error: " + str(result)})
    emit(type="answer", text="That took too many steps; I stopped.")
    return 0


# the command line (see the top of this file)
def main(argv):
    if argv[:1] == ["--warm"]:
        return warm()
    if argv[:1] == ["--yes"] and len(argv) >= 2:
        kind, result = tools.call(argv[1], json.loads(argv[2]) if len(argv) > 2 else {}, confirmed=True)
        emit(type="tool", name=argv[1], args={}, ok=kind == "ok", result=result)
        return 0 if kind == "ok" else 1
    prompt = " ".join(argv).strip()
    if not prompt:
        print(__doc__)
        return 2
    return ask(prompt)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
