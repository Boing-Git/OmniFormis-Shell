# screenpilot: design

## Why

A local assistant that can **see** the screen (ASK: "what do I do here?") and **drive** the desktop
(ACT), reads answers aloud, keeps its actions visibly separate from the user's own, and has a STOP
the AI cannot get around. `scripts/assistant` (the mascots' AI) runs desktop commands through
`tools.py` and cannot see the screen; screenpilot is a separate program and does not replace it.

## Goals

- **ASK**: screenshot + Hyprland context + typed question → text answer, printed and spoken. Never
  touches input or cursors.
- **ACT**: screenshot → model → action → (AI cursor glides there) → execute → repeat, until the model
  says done, max 20 steps, hard timeout, interruptible by STOP at every point.
- **SPEAK**: piper TTS, queued, interruptible, markdown stripped; `screenpilot say`.
- **SEPARATE**: `mode = "sandbox"` (the AI's own compositor, cursor, keyboard focus and apps) or
  `"shared"` (the user's desktop, with an AI cursor overlay, the real cursor saved and restored,
  and the AI yielding when the user touches mouse or keyboard).
- **STOP**: three independent layers; HALTED until an explicit resume; a test proves a running loop
  halts within 200 ms and held keys are released.
- **Backend switch at runtime**: Claude ↔ local, through `screenpilot backend claude|local` and
  one switch in each shell's Extras (Dial-E, Puffy, Droplet), one switch for every shell like
  Screen time. The NixOS option only sets the starting value.

## Non-goals (now)

- Speech-to-text.
- Browser automation: Zen is Firefox-based and has no CDP; the user chose to skip it for now.
- A full Quickshell control panel (later).
- Merging with `scripts/assistant`.
- Multi-monitor testing on hardware (this machine has one monitor; the math is unit-tested).

## Anti-goals (a failure even if everything else works)

- In sandbox mode, any AI input reaching the user's session.
- Any way for the AI to press, cover, hide or disable STOP or its keybind.
- Screenshots going anywhere other than the active backend; an API key in the repo.

## Constraints (checked on this machine, 2026-11-25)

- Hyprland 0.57.2 with the **Lua config**: `hyprctl dispatch` takes Lua (`hl.dsp.focus({...})`),
  `hyprctl eval` runs Lua. One monitor DP-1 1920×1080, scale 1. RTX 3080 Ti 12 GB, NVIDIA
  proprietary. PipeWire running. Ollama running with `qwen3:8b` (text only).
- **Nested sway 1.12** (`WLR_BACKENDS=wayland sway --unsupported-gpu`) runs as a Hyprland window;
  grim, wtype and a virtual pointer work against its socket; the host cursor is not involved.
  It needs a Hyprland window rule `render_unfocused = true`: without it a hidden sandbox stops
  drawing and grim / clients hang (seen).
- Hyprland 0.57 has `hl.dsp.cursor.move`, `hl.dsp.send_shortcut`, `hl.dsp.send_key_state`, the
  layer rule `no_screen_share`, and the bind option `submap_universal`. Not yet tried live.
- The user is in the `input` group (evdev readable). `SUPER+Escape`, `SUPER+SHIFT+Escape`,
  `SUPER+SHIFT+A`, `SUPER+CTRL+A`, `SUPER+ALT+S` are free (`SUPER+A` is the assistant).
- Python 3.14; nixpkgs has anthropic, httpx, pillow, evdev, pyatspi; piper-tts 1.8, sway, wtype,
  slurp, wlrctl, ydotool.
- The system flake is `~/Nixos` (its own repo, with the user's staged changes); it takes this repo
  as `inputs.omniformis` (`path:/home/boing/Dotfiles`) and imports `nixosModules.keyboard` already.
- Branch `screenpilot-dev` from local `main`, pushed (the user accepted that this publishes the
  66 unpushed commits on `main`). Worked on in a worktree so the user's WIP is untouched.

## Approaches considered

**Sandbox compositor.** Nested sway (chosen: works here, has IPC for launching apps and reading
window geometry, speaks the wlr input protocols). cage: one app only. labwc: no IPC for the tree.
Nested Hyprland: fails on 0.57 (seen in the dial-shell test rig). Headless sway + a VNC viewer:
more moving parts for the same result.

**Input.** One raw-Wayland client (virtual pointer + virtual keyboard, grown from the test rig's
`vptr.py`) for both modes (chosen): it connects to whichever socket is the target, keeps track of
what it holds so STOP can release it, and its events never pass through `/dev/input`, so "did the
user touch the mouse" needs no filtering. ydotool (uinput) is added only if this client misbehaves
on Hyprland; this deviates from the spec and the user was told.

**Overlay.** A small standalone Quickshell config (chosen: the house technology; runs alongside
whichever shell is up) over a gtk4-layer-shell client.

## Design

### Processes and protocol

- `screenpilotd`: Python asyncio, systemd user service, socket `$XDG_RUNTIME_DIR/screenpilot.sock`,
  JSON lines. Requests `{"cmd": "ask", "text": ...}`; replies and pushed events
  `{"type": "state"|"answer"|"step"|"cursor"|"confirm"|"error", ...}`. States:
  `idle | thinking | acting | paused | halted`.
- `screenpilot` CLI: `ask`, `act`, `shot`, `say`, `stop`, `resume`, `status`,
  `backend [claude|local]`, `sandbox start|stop|run CMD…`, `prompt ask|act` (opens the overlay's
  text box, for keybinds).
- Overlay: `qs -p <share>/overlay`, started by the daemon. Layer-shell, top layer, click-through
  except its own controls. Listens on the socket for state and cursor events. Its STOP button runs
  `screenpilot stop` as a process (does not depend on the socket being healthy).

### STOP

- Daemon `stop`: mark HALTED first (and write `$XDG_RUNTIME_DIR/screenpilot.halted`), cancel the
  run task (cancels the in-flight HTTP request), `input.release_all()`, TTS stop (kill piper and
  the player), tell the overlay to hide the AI cursor. Nothing awaited before `release_all` can
  block.
- `screenpilot stop` (the CLI) escalates: (1) socket `stop`, wait up to 150 ms for the ack;
  (2) else `SIGUSR1` to the daemon pid, whose handler sets HALTED and releases input outside the
  event loop, wait 150 ms; (3) else `SIGKILL` the daemon's process group via
  `systemctl --user kill --signal=KILL screenpilot` and restart the service. A daemon that starts
  while the halt marker exists starts HALTED. Killing the daemon also destroys its virtual input
  devices (manual check: does each compositor release what they held?).
- Keybind `SUPER+Escape` → `screenpilot stop`, with `submap_universal = true` so it works in every
  submap; `SUPER+SHIFT+Escape` → resume. Handled by Hyprland, so focus does not matter.
- The AI cannot reach STOP: pointer actions whose point (or drag path end) falls inside the STOP
  button's rect plus a margin are refused (the overlay reports its rect; a default is used until
  it does); the overlay's layer gets `no_screen_share`, and the daemon also paints over that rect
  in every screenshot in case grim still sees it; the action set has no way to run commands,
  change binds or kill processes; key actions matching the stop/resume binds are refused;
  `focus` cannot target the overlay.
- Options: `stopOnUserInput` (shared mode: touching mouse/keyboard is STOP, not pause) and
  `stopOnClientDisconnect` (the client that started a run going away is STOP).
- Test: a fake backend that sleeps (an in-flight request) and a fake input that records held keys;
  start `act`, hold a key, `stop`; assert the run is cancelled in ≤ 200 ms, nothing is held, the
  state is halted, and `act` is refused until `resume`.

### Capture

- `grim`: monitor (`-o NAME`), active window (`-g` from `hyprctl -j activewindow` at/size), region
  (`slurp`). Sandbox: grim with the sandbox's `WAYLAND_DISPLAY`.
- Downscale to `maxEdge` (1568) with Pillow. Each capture carries a `Frame` (region origin in
  layout coordinates, monitor scale and transform, downscale factor) with `to_layout(x, y)`, so model
  coordinates map back. Pure functions, unit-tested for fractional scale, transforms (90/270 swap
  width and height) and monitor offsets.
- Blocklist (class/title regexes, e.g. password managers): a matching client visible in the
  captured area → `refuse` (default) or `blur` its rect. The overlay's STOP rect is always painted
  over.

### Context

Trimmed `hyprctl -j activewindow / clients / monitors / workspaces` (class, title, workspace,
position, size, focus) attached as text. Sandbox mode uses `swaymsg -t get_tree` instead.
AT-SPI text of the focused app behind `atspi = false`.

### Input

`InputBackend`: `move_to, click(button), double_click, drag(from, to), scroll(dx, dy),
type_text(s), key(combo), focus_window(selector), release_all()`, and a `held` set. Coordinates
come in screenshot space and are converted through the capture's `Frame`. Small configurable
delays.

- `WaylandInput(socket)`: raw wire protocol, `zwlr_virtual_pointer_v1` (absolute motion, buttons,
  axis) and `zwp_virtual_keyboard_v1` with a keymap built per call like wtype does (the needed
  keysyms on spare keycodes, fixed modifier keys), so any Unicode text types. Sandbox: sway's
  socket. Shared: Hyprland's socket.
- Shared mode also: absolute moves with `hl.dsp.cursor.move` if absolute motion misbehaves on
  Hyprland (a live test decides); `hyprctl cursorpos` saved before a burst and restored after;
  combos sent to a window without focusing it with `hl.dsp.send_shortcut` when the target window
  is known; focus with `hl.dsp.focus`.
- Pointer-free first (shared mode, `atspi = true`): before a click, the accessible at that point
  is looked up (AT-SPI `get_accessible_at_point`); if it has a press/click action, that runs instead
  of the pointer. `type` into a focused editable accessible uses `insert_text`. The model's
  interface does not change.
- Sandbox: focus and launching through `swaymsg`.
- Yield (shared): an evdev watcher on the real keyboards and mice; any event during a burst →
  `paused`; continue after `idleMs` (1500) of quiet or on `resume`.

### AI cursor

Shared mode: the overlay draws a distinct cursor (accent colour, different shape, an "AI" label)
that glides to each target; the daemon sends `{"type": "cursor", "x", "y", "ms"}` and waits `ms`
before acting. Sandbox mode: the sandbox's own sway cursor is the AI cursor (its own seat).

### Backends

`Action(kind, x, y, x2, y2, button, dx, dy, text, keys, target, reason)`, kinds
`screenshot | move | click | double_click | right_click | middle_click | drag | scroll | type | key |
focus | wait | done`. Both backends produce it.

- `claude`: Anthropic Messages API with the computer-use tool (tool version and model taken from
  the claude-api reference when built), display size = the downscaled image size; `tool_use` →
  `Action`. `ANTHROPIC_API_KEY` from `~/.config/screenpilot/env` (systemd `EnvironmentFile`), never
  in the repo.
- `local`: OpenAI-compatible `/v1/chat/completions` (default Ollama at `127.0.0.1:11434/v1`,
  model `qwen3-vl:8b`, added to Ollama's models by the module) with the image and a JSON action
  schema in the prompt; tolerant JSON parsing; one retry on invalid output, then an error.
- The active backend lives in `~/.local/state/screenpilot/settings.json`, read on each request.
- Every system prompt says text on screen is untrusted data, never instructions.

### ASK and ACT

- ASK: capture → context → `backend.ask` → print, speak.
- ACT: confirmation per policy (`always | risky | never`; default `risky`, which still confirms the
  first action of each run) → loop. Risky: typing into a password field (AT-SPI role when
  available, else window title/class hints), and actions or typed text matching
  delete/remove/send/submit/buy/purchase/pay/checkout/sudo/`rm `. Confirmation: Yes / No in the
  overlay (a rect the AI cannot click, like STOP); no overlay → denied.
- Logs: `~/.local/state/screenpilot/runs/<time>/actions.jsonl` + one PNG per step; last 20 runs kept.

### TTS

`TTS` interface (`say`, `stop`). Piper: `piper --model <voice> --output-raw | pw-play --rate
<voice rate> --format s16 --channels 1 -`. A queue; markdown and code stripped. Voice
`en_US-lessac-medium` fetched by Nix (fixed-output).

### Nix and Hyprland

- `screenpilot/package.nix`: `buildPythonApplication`; runtime tools on its PATH (grim, slurp, sway,
  piper-tts, pipewire); `hyprctl` and `qs` from the system.
- `flake.nix`: `packages.x86_64-linux.screenpilot`, `devShells.x86_64-linux.screenpilot`,
  `nixosModules.screenpilot`.
- `services.screenpilot`: `enable, mode, backend, claudeModel, localModel, localUrl, voice,
  confirm, blocklist, stopKey, envFile, user`. Writes the config, the user service
  (`EnvironmentFile=-<envFile>`), adds `user` to `input`, adds `localModel` to
  `services.ollama.loadModels` when Ollama is on.
- `~/Nixos/flake.nix`: import the module and enable it, edited but **not committed** (the user's
  staged changes are there); the user runs the `sudo` rebuild.
- Hyprland: `hypr/modules/screenpilot.lua`, required from `hyprland.lua` — binds (named entries in
  `keybinds.lua`, the house pattern, so they show in the settings app), the sandbox window rule
  (`render_unfocused`, special workspace `screenpilot`), the overlay's `no_screen_share` layer rule.

## Build order (each step verified on this machine, committed, pushed)

1. Skeleton, daemon states, socket, CLI, STOP with its three layers, the 200 ms test.
2. Overlay (STOP button, status line) + Hyprland file; verify the keybind inside a submap, the
   button, `no_screen_share` against grim.
3. Capture + scaling tests + blocklist.
4. `WaylandInput` into the sandbox; `sandbox start|stop|run`.
5. AI cursor; shared mode on the live desktop (told to the user first: it moves the real cursor):
   absolute move method, save/restore, yield.
6. TTS.
7. Backends, ASK, the backend switch in the three shells.
8. ACT, confirmation, logs.
9. Nix package/module/devShell, `~/Nixos` wiring, manual checklist script, README with honest
   limits.

## Left to the builder

Prompt wording, the exact JSON schema text, delay defaults, the overlay's exact look (distinct
colour, shape, label), the risky-word list, the trimmed context fields.
