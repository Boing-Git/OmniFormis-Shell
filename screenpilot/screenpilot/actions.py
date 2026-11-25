"""The one action type both backends produce and the executor runs."""
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
