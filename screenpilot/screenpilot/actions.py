"""The one action type both backends produce and the executor runs."""
import json
import re
from dataclasses import dataclass

KINDS = ("screenshot", "move", "click", "double_click", "right_click", "middle_click", "drag",
         "scroll", "type", "key", "focus", "wait", "done")


@dataclass
class Action:
    kind: str
    x: float | None = None          # screenshot pixels
    y: float | None = None
    x2: float | None = None         # drag end
    y2: float | None = None
    button: str = "left"
    dx: int = 0                     # scroll notches, positive = right / down
    dy: int = 0
    text: str = ""                  # type: what to type; done: the answer
    keys: str = ""                  # key: a combo like "ctrl+shift+t"
    target: str = ""                # focus: a window or workspace
    reason: str = ""                # the model's own words, for the log and the overlay

    def __post_init__(self):
        if self.kind not in KINDS:
            raise ValueError(f"unknown action {self.kind!r}")


_SCROLL = {"up": (0, -1), "down": (0, 1), "left": (-1, 0), "right": (1, 0)}
_CLICKS = {"left_click": "click", "right_click": "right_click", "middle_click": "middle_click",
           "double_click": "double_click"}


def from_claude(name: str, inp: dict) -> Action:
    """A computer toolset call (computer_toolset_20260801: the action is the block's name)."""
    xy = inp.get("coordinate") or [None, None]
    if name in _CLICKS:
        return Action(_CLICKS[name], *xy, keys=inp.get("text") or "")
    if name == "left_click_drag":
        return Action("drag", *inp["start_coordinate"], *inp["coordinate"])
    if name == "mouse_move":
        return Action("move", *xy)
    if name == "scroll":
        dx, dy = _SCROLL[inp["scroll_direction"]]
        n = int(inp.get("scroll_amount", 3))
        return Action("scroll", *xy, dx=dx * n, dy=dy * n)
    if name == "type":
        return Action("type", text=inp["text"])
    if name == "key":
        return Action("key", keys=" ".join([inp["text"]] * int(inp.get("repeat", 1))))
    if name in ("wait", "screenshot"):
        return Action(name)
    raise ValueError(f"screenpilot doesn't do the computer action {name!r}")


def _number(v):
    if isinstance(v, bool) or not isinstance(v, (int, float)):
        raise ValueError(f"not a number: {v!r}")
    return v


def from_json(text: str, size) -> Action:
    """The local model's reply: one JSON object somewhere in it (fences, prose and <think> around
    it are skipped). Its x and y are per mille of the screenshot (0..1000, as Qwen-VL points)."""
    text = re.sub(r"<think>.*?</think>", "", text, flags=re.S)
    decoder = json.JSONDecoder()
    for start in [m.start() for m in re.finditer(r"\{", text)]:
        try:
            obj, _ = decoder.raw_decode(text, start)
        except ValueError:
            continue
        if isinstance(obj, dict) and "action" in obj:
            break
    else:
        raise ValueError("no JSON object with an \"action\" in the reply")
    w, h = size
    px = lambda k: None if obj.get(k) is None else _number(obj[k]) * w / 1000
    py = lambda k: None if obj.get(k) is None else _number(obj[k]) * h / 1000
    kind, reason = obj["action"], str(obj.get("reason", ""))
    if kind in ("click", "double_click", "right_click", "middle_click", "move"):
        return Action(kind, px("x"), py("y"), keys=str(obj.get("keys", "")), reason=reason)
    if kind == "drag":
        return Action("drag", px("x"), py("y"), px("x2"), py("y2"), reason=reason)
    if kind == "scroll":
        dx, dy = _SCROLL.get(obj.get("direction", "down"), (0, 1))
        n = int(_number(obj.get("amount", 3)))
        return Action("scroll", px("x"), py("y"), dx=dx * n, dy=dy * n, reason=reason)
    if kind == "type":
        return Action("type", text=str(obj["text"]), reason=reason)
    if kind == "key":
        return Action("key", keys=str(obj["keys"]), reason=reason)
    if kind == "focus":
        return Action("focus", target=str(obj["window"]), reason=reason)
    if kind == "wait":
        return Action("wait", reason=reason)
    if kind == "done":
        return Action("done", text=str(obj.get("text", "")), reason=reason)
    raise ValueError(f"unknown action {kind!r}")
