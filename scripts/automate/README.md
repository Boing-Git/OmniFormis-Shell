# automate

Small desktop automations, kept as JSON files: open apps, wait until a window or a media player
is there, play music, open links (`steam://rungameid/…`), run commands. One Python file with no
dependencies, so it works under any shell, bar or keybind daemon, and on any compositor.

```sh
automate.py list                       # what there is
automate.py run game-night             # one JSON line per step, as it goes
automate.py run game-night --dry-run   # what it would do
automate.py save focus '{"name": "Focus", "steps": [{"open": "vscodium"}, {"media": "pause"}]}'
```

Automations live in `~/.config/automations/<id>.json` (or `$AUTOMATIONS_DIR`). The format and
every step are described at the top of `automate.py`; `examples/game-night.json` opens Steam and
Spotify, plays Spotify, waits for Steam's window, opens THE FINALS' library page and starts it.

## Use it anywhere

Copy `automate.py` anywhere on your `PATH`; nothing else is needed. Then, for example:

- a Hyprland bind: `bind = SUPER, G, exec, automate.py run game-night`
- sway / i3: `bindsym $mod+g exec automate.py run game-night`
- a Quickshell, Waybar or eww button: run `automate.py list --json` for the list (each has
  `id`, `name`, `icon`, `steps` and `says`, what each step does), and `automate.py run <id>`,
  reading its JSON lines (`{"step": 2, "of": 8, "doing": "Opening spotify"}`, then
  `{"done": true}` or `{"done": false, "error": "…"}`) to show how far it has got.

What it uses when it's there: `gtk-launch` (apps by their desktop entry), `xdg-open`, `playerctl`,
`notify-send` (else D-Bus through `busctl`), and `hyprctl`, `swaymsg` or `niri` to see windows
(without them a window wait looks for a process).

## In these dotfiles

Dial-E's Automations control, Puffy's launcher (`/run`), Droplet's Automations circle, and the
AI in all three ("run game night", "make an automation that…"). Each behind a switch in its
Extras / Settings. Tests: `python3 scripts/tests/automate.test.py`.
