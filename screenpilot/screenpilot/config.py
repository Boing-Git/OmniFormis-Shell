"""Settings and where things live.

The NixOS module writes a JSON file and points SCREENPILOT_CONFIG at it; anything missing there
takes the default below. The settings changed at runtime, the backend (each shell's switch,
`screenpilot backend claude|local`) and the mode (`screenpilot mode sandbox|shared`), live in
~/.local/state/screenpilot/settings.json and win.
Paths are computed on each call so tests can point XDG_* at a temp dir.
"""
import json
import os
from pathlib import Path

BACKENDS = ("claude", "local")
MODES = ("sandbox", "shared")
RUNTIME = {"backend": BACKENDS, "mode": MODES}  # `screenpilot backend|mode <value>` (and each shell's switch)

DEFAULTS = {
    "mode": "sandbox",                  # sandbox | shared
    "backend": "local",                 # claude | local
    "confirm": "risky",                 # always | risky | never
    "maxSteps": 20,
    "timeoutS": 300,
    "maxEdge": 1568,                    # long edge of what the model sees, in pixels
    "idleMs": 1500,                     # shared mode: quiet time before the AI carries on
    "delayMs": 60,                      # between input events
    "blockAction": "refuse",            # refuse | blur
    "blocklist": ["(?i)keepass", "(?i)bitwarden", "(?i)1password", "(?i)seahorse", "(?i)gnome-keyring"],
    "atspi": False,
    "stopOnUserInput": False,
    "stopOnClientDisconnect": False,
    "claudeModel": "",                  # filled in by backends.py's default when empty
    "localModel": "qwen3-vl:8b",
    "localUrl": "http://127.0.0.1:11434/v1",
    "voice": "",                        # path to a piper .onnx voice; empty = no speech
    "sharedMove": "hyprctl",            # hyprctl (Hyprland moves the cursor) | virtual (absolute motion)
    "keepRuns": 20,
}


def runtime_dir() -> Path:
    return Path(os.environ.get("XDG_RUNTIME_DIR") or f"/run/user/{os.getuid()}")


def state_dir() -> Path:
    base = os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state")
    d = Path(base) / "screenpilot"
    d.mkdir(parents=True, exist_ok=True)
    return d


def socket_path() -> Path:
    return runtime_dir() / "screenpilot.sock"


def halt_path() -> Path:
    return runtime_dir() / "screenpilot.halted"


def pid_path() -> Path:
    return runtime_dir() / "screenpilot.pid"


def _read_json(path) -> dict:
    try:
        data = json.loads(Path(path).read_text())
    except (OSError, ValueError):
        return {}
    return data if isinstance(data, dict) else {}


def load() -> dict:
    cfg = dict(DEFAULTS)
    if os.environ.get("SCREENPILOT_CONFIG"):
        cfg.update({k: v for k, v in _read_json(os.environ["SCREENPILOT_CONFIG"]).items() if k in DEFAULTS})
    for key, value in _read_json(state_dir() / "settings.json").items():
        if value in RUNTIME.get(key, ()):
            cfg[key] = value
    return cfg


def set(key: str, value: str) -> None:
    """One of the settings changed at runtime (RUNTIME); it wins over the NixOS one from now on."""
    if value not in RUNTIME.get(key, ()):
        raise ValueError(f"{key} is one of {', '.join(RUNTIME.get(key, ()))}")
    path = state_dir() / "settings.json"
    data = _read_json(path)
    data[key] = value
    tmp = path.with_suffix(".tmp")
    tmp.write_text(json.dumps(data))
    tmp.replace(path)
