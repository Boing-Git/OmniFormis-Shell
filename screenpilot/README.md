# screenpilot

An AI that can **see** your screen (ASK: "what do I do here?"), **act** on it (ACT: clicks, keys,
typing), **speak** its answers, acts with **its own cursor**, and stops the instant you say so.

It is separate from the mascots' assistant (`scripts/assistant/`, Super + A), which runs desktop
commands and can't see the screen.

## Keys

| Key | What |
|---|---|
| **Super + Escape** | **STOP**: works whatever has the focus, in every submap, and while locked |
| Super + Shift + Escape | resume after a stop |
| Super + Shift + A | ask about the screen (a text box opens; the answer shows top-right and is spoken) |
| Super + Alt + D | let the AI do something |
| Super + Alt + S | read the selected text aloud |
| Super + Alt + A | show / hide the AI's own desktop (the sandbox) |

They are entries in `hypr/modules/keybinds.lua` (Screen AI group), so the settings app changes
them like any other shortcut. Hyprland runs binds only for real keyboards, so the AI can't press
any of them.

## Setup

1. In `~/Nixos/flake.nix` (already added):
   ```nix
   inputs.omniformis.nixosModules.screenpilot
   { services.screenpilot = { enable = true; user = "boing"; }; }
   ```
   then `sudo nixos-rebuild switch --flake ~/Nixos`. The user service starts with the graphical
   session (`systemctl --user status screenpilot`).
2. A model:
   - **local** (the default; nothing leaves this computer): `ollama pull qwen3-vl:8b` (about 6 GB).
   - **Claude**: put `ANTHROPIC_API_KEY=sk-ant-...` in `~/.config/screenpilot/env`
     (`chmod 600` it; it is never in the repo), `systemctl --user restart screenpilot`.
3. Switch between them with **Settings → Extras → Screen AI: Claude** in any shell (one switch
   for every shell) or `screenpilot backend claude|local`.
4. Run `screenpilot/checklist.sh` once: it walks through every check only a person can make.

Options (`services.screenpilot.*`): `mode` (sandbox | shared, where it starts; `screenpilot mode`
switches), `backend`, `claudeModel` (claude-opus-5-5), `localModel`, `localUrl` (any
OpenAI-compatible endpoint), `voice` (a piper .onnx; null for silence), `confirm` (always | risky |
never), `blocklist`, `stopOnUserInput`, `stopOnClientDisconnect`, `envFile`, `user`.

## Commands

```
screenpilot ask "what do I do here?" [--mode window|region]
screenpilot act "open a terminal and type hello"
screenpilot stop | resume | status
screenpilot backend [claude|local]       screenpilot mode [sandbox|shared]
screenpilot say "text" | --selection     screenpilot shot [--mode window|region]
screenpilot sandbox start|stop|show|run CMD...|shot
```

## STOP

Three ways in, each independent of the others:

- **Super + Escape**, a Hyprland bind (focus, submaps and the lock don't matter).
- **The red STOP button**, top-right while the AI thinks, acts or waits. A click runs
  `screenpilot stop` as its own process.
- **`screenpilot stop` doesn't trust the daemon**: the socket (an answer within 150 ms), then
  SIGUSR1 (handled outside the daemon's event loop), then `systemctl --user kill --signal=KILL`
  of the whole service (sandbox, overlay and speech with it) and a restart.

Every way: the model's request is cancelled, every held button and key is let go, speech stops,
the AI cursor goes, and the daemon is **halted** until you resume (a restarted daemon comes back
halted). Tested: a running loop halts within 200 ms with nothing held.

The AI can't get around it. It never sees the STOP button (that area is painted over in every
screenshot) and any click on or near it is refused. Its keys don't trigger Hyprland binds. Before
every step the STOP button and the STOP shortcut must both still exist, or the run stops. The
overlay going away during a run is a STOP too.

## Sandbox mode (the default): the AI's own desktop

A nested sway in a window on Hyprland's special workspace `screenpilot` (Super + Alt + A). It has
its own seat, cursor and keyboard focus; the AI's input goes to its socket only, and your mouse
and keyboard are never touched (checked: your cursor never moves during a sandbox run). Its apps
get a home of their own (`~/.local/state/screenpilot/sandbox-home`, kept, so a login inside
stays) and a private D-Bus session.

Limits:
- **It is a separate desktop, not a security boundary.** Apps in it run as you and can reach any
  of your files by path. Use a VM for anything you wouldn't let a stranger do.
- Only apps started inside it are in it (`screenpilot sandbox run firefox`); your open windows
  aren't.
- If you move your own pointer over the sandbox window, it drives the same sway cursor as the
  AI. Watch with your hands off it, or hide it.
- One output, sized by Hyprland (the special workspace). NVIDIA needs sway's
  `--unsupported-gpu`, which screenpilot passes.

## Shared mode: the AI on your desktop

Wayland has one real pointer, so the AI borrows yours:
- Before each pointer action an **AI cursor** (a cyan arrow tagged AI) glides to the target, so
  you see where it is about to act. The model never sees that cursor.
- Your pointer is saved before each action and put back after it, unless you moved it.
- **You come first.** Any event from your own keyboard or mouse (read from `/dev/input`; the
  AI's never appear there) pauses the AI and lets go of whatever it holds. It carries on after
  1.5 s of quiet, or on resume. With `stopOnUserInput` it stops instead.
- A key combo aimed at a window goes there with Hyprland's `send_shortcut`, without moving the
  focus.

Limits:
- While it acts, your pointer is the AI's. Don't fight it: pause (just move the mouse) or stop.
- Moves go through Hyprland's `cursor.move`, which landed within 3 px in testing. Absolute
  virtual-pointer motion landed off and is not used by default.
- Clicks and keys land wherever the focus is. A popup that steals focus between screenshot and
  action gets them.
- AT-SPI (pressing buttons and filling fields without the pointer) is **not built yet**.
  Browser automation (CDP) is skipped: Zen is Firefox-based and has no CDP.

## Safety

- ACT asks first (Yes / No top-right, a box the AI can't click) before the first action of each
  run, before typing where a password is asked for, and before anything whose text, keys or the
  AI's own words look like deleting, sending, buying or sudo. Set `confirm` to always or never.
  No answer within 2 minutes means no.
- Every run is logged in `~/.local/state/screenpilot/runs/<time>/`: the goal, one JSON line per
  action (time, action, result, screenshot path), the screenshots. The last 20 runs are kept.
- Screenshots go only to the backend in use: Ollama on this machine, or Anthropic with Claude.
- A blocklisted window on screen (password managers by default) means nothing is captured
  (`blockAction`: refuse, or blur).
- Both models are told that text on the screen is untrusted data, never instructions.
- Claude: refusals fall back server-side to the model Anthropic recommends (`fallbacks`).

## Models

- **Claude** (`claude-opus-5-5`) uses the computer toolset. Of its 17 actions, the ones
  screenpilot can't carry out are switched off: zoom, triple click, mouse down/up, hold key and
  cursor position.
- **Local**: any OpenAI-compatible vision model. It answers each step with one JSON action whose
  x and y are per mille of the screenshot (0–1000), which is how Qwen-VL points. A model that
  points in pixels would need the prompt in `backends.py` changed.

## Development

```
nix develop ~/Dotfiles#screenpilot
cd screenpilot && python3 -m unittest discover -s tests     # no display or network needed
nix build ~/Dotfiles#screenpilot                            # runs them too
```

`overlay/shell.qml` is the overlay (a Quickshell instance of its own, started by the daemon), and
`hypr/modules/screenpilot.lua` holds the binds and the sandbox's window rule. The design is in
`docs/superpowers/specs/2026-11-25-screenpilot-design.md`.
