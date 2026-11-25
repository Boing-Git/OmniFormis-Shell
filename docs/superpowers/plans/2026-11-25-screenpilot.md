# screenpilot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A screen-aware assistant daemon (ASK / ACT / SPEAK) for Hyprland with a sandboxed or shared AI cursor and a STOP the AI cannot bypass.

**Architecture:** One Python asyncio daemon (`screenpilotd`) behind a Unix socket, a thin CLI, a standalone Quickshell overlay (STOP button, status, AI cursor, confirm/prompt boxes), one raw-Wayland input client for both the nested-sway sandbox and Hyprland, pluggable Claude / local backends, piper TTS.

**Tech Stack:** Python 3.14 stdlib asyncio + anthropic, httpx, pillow, evdev (pyatspi optional); grim, slurp, sway 1.12, piper-tts 1.8, pw-play; Quickshell; Nix flake + NixOS module.

**Spec:** `docs/superpowers/specs/2026-11-25-screenpilot-design.md`

## Global Constraints

- Code under `screenpilot/` (package `screenpilot/screenpilot/`, tests `screenpilot/tests/`, stdlib `unittest`: `python3 -m unittest discover -s screenpilot/tests -t screenpilot`).
- Socket `$XDG_RUNTIME_DIR/screenpilot.sock`, JSON lines; halt marker `$XDG_RUNTIME_DIR/screenpilot.halted`.
- State `~/.local/state/screenpilot/` (`settings.json`, `runs/`); secrets only from `~/.config/screenpilot/env`.
- Defaults: `mode = "sandbox"`, `backend = "local"`, `confirm = "risky"`, `maxSteps = 20`, `timeoutS = 300`, `maxEdge = 1568`, `idleMs = 1500`, `blockAction = "refuse"`, `atspi = false`, `localModel = "qwen3-vl:8b"`, `localUrl = "http://127.0.0.1:11434/v1"`, voice `en_US-lessac-medium`.
- Keys: STOP `SUPER + Escape` (`submap_universal`), resume `SUPER + SHIFT + Escape`, ask `SUPER + SHIFT + A`, act `SUPER + CTRL + A`, say selection `SUPER + ALT + S`, show sandbox `SUPER + ALT + A`.
- Hyprland is configured in Lua: `hyprctl dispatch 'hl.dsp.…'`, `hyprctl eval '<lua>'`.
- Never test on the live shell by restarting it; live pointer tests are announced to the user first.
- Commit and push after each task. Commit messages end with the Co-Authored-By line.

## Review Focus

- A request line that is not JSON, or is huge → an error reply; the daemon keeps serving (Task 1).
- A second `act` while one runs → refused as busy, the first is untouched (Task 1).
- The daemon restarting while the halt marker exists → it starts halted (Task 1).
- Model coordinates outside the screenshot → the action is refused, nothing is clicked (Task 4).
- Text with non-ASCII, emoji, newlines and tabs → typed as written (Task 4).

---

### Task 1: Daemon core, CLI, STOP

**Files:**
- Create: `screenpilot/pyproject.toml`, `screenpilot/screenpilot/{__init__,config,proc,daemon,cli,agent,actions}.py`
- Test: `screenpilot/tests/test_stop.py`, `screenpilot/tests/test_protocol.py`

**Interfaces:**
- Produces:
  - `config.load() -> dict` (defaults above, overlaid by the JSON file at `$SCREENPILOT_CONFIG`, then `settings.json`'s `backend`); `config.set_backend(name: str)`.
  - `proc.run(args, *, env=None, input=None, timeout=None) -> bytes` (async; the child is killed if the awaiting task is cancelled; every live child is in `proc.CHILDREN`); `proc.kill_all()`.
  - `actions.Action` dataclass: `kind, x, y, x2, y2, button="left", dx=0, dy=0, text="", keys="", target="", reason=""`; `KINDS`.
  - `daemon.Daemon(cfg, *, capture, input, tts, backends)`: `.state` in `idle|thinking|acting|paused|halted`; `stop(reason) -> None` (synchronous); `resume()`; `async handle(reader, writer)`; `async serve(path)`; `.events` broadcast to subscribers.
  - `agent.run_act(d: Daemon, goal: str) -> str` and `agent.run_ask(d, question) -> str` (async; real parts filled in by later tasks).
  - Input protocol used by everyone: `move_to(x, y)`, `press(button)`, `release(button)`, `click(button)`, `double_click()`, `drag(x1, y1, x2, y2)`, `scroll(dx, dy)`, `type_text(s)`, `key(combo)`, `focus_window(selector)`, `release_all()`, attribute `held: set`. Async methods except `release_all`.

- [ ] **Step 1: Write the failing tests**
  - `test_stop_halts_running_loop_within_200ms`: fake backend whose `step()` presses `BTN_LEFT` on a fake input then awaits `asyncio.sleep(30)`; start `act`, wait until `state == "acting"` or `"thinking"`, `t0`; `d.stop("test")`; `await asyncio.wait_for(task, 0.2)` raises nothing beyond `CancelledError`; assert `time.monotonic() - t0 < 0.2`, `fake.held == set()`, `d.state == "halted"`, marker file exists.
  - `test_act_refused_until_resume`: after stop, `act` replies `{"type": "error"}` containing "halted"; after `resume`, accepted.
  - `test_starts_halted_when_marker_exists`.
  - `test_garbage_line_gets_error_and_daemon_survives` (send `b"not json\n"`, then `{"cmd":"status"}` still answers); a 1 MiB line → error.
  - `test_second_act_is_busy`.
  - `test_cli_stop_escalates`: with no daemon listening, `cli.stop_escalation(sock, pid_file, kill=fake)` calls the fallback in order socket → SIGUSR1 → `systemctl --user kill --signal=KILL screenpilot` + `restart`, each with its 150 ms wait.
- [ ] **Step 2: Run, expect failures (modules missing).**
- [ ] **Step 3: Implement.** `stop()` order: state + marker, cancel run task, `input.release_all()`, `tts.stop()`, `proc.kill_all()`, broadcast `{"type":"state","state":"halted"}` and `{"type":"cursor","hide":true}`. `SIGUSR1` installed with `signal.signal` (runs even when the loop is blocked) and does the same synchronous work. Lines over 64 KiB rejected. Pid file `$XDG_RUNTIME_DIR/screenpilot.pid`. CLI `screenpilot` subcommands: `ask act shot say stop resume status backend sandbox prompt`, entry points `screenpilot`, `screenpilotd`.
- [ ] **Step 4: Tests pass.**
- [ ] **Step 5: Live check:** run `screenpilotd` from the worktree, `screenpilot status` → idle; `screenpilot stop` → halted; `screenpilot resume` → idle; `kill -STOP` the daemon, `screenpilot stop` → escalation reaches the fallback (with systemd absent it prints what it would kill).
- [ ] **Step 6: Commit + push.**

### Task 2: Overlay, Hyprland file, STOP button and keybind

**Files:**
- Create: `screenpilot/overlay/shell.qml`, `hypr/modules/screenpilot.lua`
- Modify: `hypr/modules/keybinds.lua` (entries `ScreenpilotStopBind`, `ScreenpilotResumeBind`, `ScreenpilotAskBind`, `ScreenpilotActBind`, `ScreenpilotSayBind`, `ScreenpilotSandboxBind`), `hypr/hyprland.lua` (`require("modules.screenpilot")`)
- Modify: `screenpilot/screenpilot/daemon.py` (starts/watches `qs -p <overlay>`; `{"cmd":"overlay","rects":[[x,y,w,h],…]}`)

**Interfaces:**
- Consumes: socket protocol of Task 1.
- Produces: `Daemon.protected_rects: list[tuple]` (layout coords, default one 160×64 rect at the focused monitor's top-right, 16 px margin); overlay layer namespaces `screenpilot-stop` (button, confirm, prompt) and `screenpilot-cursor`; overlay events `state`, `cursor {x,y,ms|hide}`, `confirm {id,question}` → reply `{"cmd":"confirm","id","yes"}`; `prompt {mode}`.

- [ ] **Step 1:** Overlay: per-screen STOP button (red, ≥ 140×56, label STOP + status line) visible in `thinking|acting|paused`, status line also briefly in `halted`; click runs `screenpilot stop` via `Process`; reports its rects on connect. `Socket` + `SplitParser` from `Quickshell.Io`. No MultiEffect (Qt 6.12 crash).
- [ ] **Step 2:** `screenpilot.lua`: binds through `kb.bind` with `{ submap_universal = true }` on STOP and resume; layer rule `no_screen_share` for namespace `^screenpilot`; window rule for class `^wlroots$`: workspace `special:screenpilot silent`, `render_unfocused = true`. Command is `screenpilot` from PATH.
- [ ] **Step 3: Verify live** (overlay only appears while a fake run is active; tell the user): button click halts; the STOP bind added with `hyprctl eval` fires inside the `omniformis_capture` submap; `grim` of the screen while the button shows → the button area is not the button (check the pixels).
- [ ] **Step 4: Commit + push.**

### Task 3: Capture, frames, blocklist, context

**Files:**
- Create: `screenpilot/screenpilot/{geometry,capture,context}.py`
- Test: `screenpilot/tests/test_geometry.py`, `screenpilot/tests/test_capture.py`

**Interfaces:**
- Produces:
  - `geometry.Frame(ox, oy, lw, lh, img_w, img_h)` with `to_layout(px, py) -> (float, float)`, `from_layout(x, y)`, `contains(px, py) -> bool`; `geometry.logical_size(mon: dict) -> (w, h)` (Hyprland monitor JSON: `width/height/scale/transform`); `geometry.fit(w, h, max_edge) -> (w, h)`.
  - `capture.Shot(png: bytes, frame: Frame, size: (w, h), path: str|None)`; `async capture.grab(cfg, mode="monitor"|"window"|"region", *, wayland_display=None, protected=[]) -> Shot` raising `capture.Blocked(app)`.
  - `context.describe(sandbox: bool) -> str` (trimmed JSON text).
- [ ] **Step 1: Failing tests:** `logical_size({"width":2560,"height":1440,"scale":1.25,"transform":0}) == (2048, 1152)`; transform 1 → `(1152, 2048)`; `Frame(1920, 0, 2048, 1152, 1568, 882).to_layout(784, 441) == (2944, 576)`; round trip `from_layout(to_layout(p)) ≈ p`; `fit(1920, 1080, 1568) == (1568, 882)`; `fit(800, 600, 1568) == (800, 600)`; blocklist: a client `{"class":"KeePassXC", at, size}` visible on the captured workspace → `Blocked`; on another workspace → no error; `blur` mode returns an image whose pixels in that rect changed; protected rect pixels are painted flat.
- [ ] **Step 2–4:** implement with grim (`-o`, `-g "x,y wxh"`), `slurp`, Pillow `LANCZOS`; run tests; `screenpilot shot` writes a PNG to `runs/shots/` and prints its frame — check it on DP-1.
- [ ] **Step 5: Commit + push.**

### Task 4: Wayland input, executor, sandbox

**Files:**
- Create: `screenpilot/screenpilot/{wayland,executor,sandbox}.py`
- Test: `screenpilot/tests/test_keymap.py`, `screenpilot/tests/test_executor.py`

**Interfaces:**
- Consumes: `Frame` (Task 3), input protocol (Task 1).
- Produces:
  - `wayland.WaylandInput(display: str, extent: (w, h))` implementing the input protocol: `zwlr_virtual_pointer_v1` (absolute motion, `BTN_LEFT/RIGHT/MIDDLE = 0x110/0x111/0x112`, wheel axis) and `zwp_virtual_keyboard_v1` (keymap via memfd + `socket.send_fds`, grown per new keysym like wtype; modifiers by mask Shift 1, Ctrl 4, Alt 8, Super 64); socket timeout 1 s.
  - `wayland.keymap_text(keysyms: list[int]) -> str`; `wayland.parse_combo(s) -> (mods: int, keysym: int)` (names: Return Enter Tab Escape Esc BackSpace Delete Home End Page_Up Page_Down Insert Left Right Up Down space F1–F12 Menu Print, single characters; aliases ctrl/control, alt, shift, super/cmd/meta/win; case-insensitive).
  - `executor.execute(action: Action, shot: Shot, inp, *, protected, banned_combos) -> str` (result note) raising `executor.Refused(reason)`.
  - `sandbox.Sandbox(cfg)`: `async start() -> str` (its `WAYLAND_DISPLAY`), `async stop()`, `async run(cmd: list[str])`, `running: bool`, `swaymsg(args) -> bytes`.
- [ ] **Step 1: Failing tests:** `parse_combo("ctrl+shift+t") == (5, ord("t"))`; `parse_combo("super+Return") == (64, 0xff0d)`; `parse_combo("bogus+x")` raises `ValueError`; `keymap_text([ord("a"), 0x1F600])` contains `0x61` and `0x101f600`; executor: click at `(2000, 10)` on a 1568×882 shot → `Refused`; click inside a protected rect → `Refused`; `key("super+Escape")` when that combo is banned → `Refused`; `type` of `"héllo 😀\n\t"` reaches the fake input unchanged.
- [ ] **Step 2–4:** implement; tests pass.
- [ ] **Step 5: Verify in the sandbox** (nested sway in `special:screenpilot`, never the host): `screenpilot sandbox start`, `sandbox run foot sh -c 'cat > /tmp/…'`, type text with Unicode + Return → file content matches; right-click and drag in a `gnome-text-editor` window inside → visible in a sandbox shot; host `hyprctl cursorpos` unchanged across the run; `stop` during a slow drag → `held` empty and sway shows no stuck button.
- [ ] **Step 6: Commit + push.**

### Task 5: Shared mode: AI cursor, real cursor save/restore, yield, guards

**Files:**
- Create: `screenpilot/screenpilot/{shared,userwatch}.py`
- Modify: `executor.py` (glide event before pointer actions), `daemon.py` (pause/resume on user input, per-step guard checks)
- Test: `screenpilot/tests/test_shared.py`

**Interfaces:**
- Produces: `shared.SharedInput(WaylandInput)` adding `async burst()` context (save `hyprctl cursorpos`, restore after), absolute move method chosen by config `sharedMove = "virtual"|"hyprctl"`, `key` through `hl.dsp.send_shortcut` when a target window is known; `shared.compositor_binds() -> set[(mods, keysym)]` from `hyprctl -j binds`; `shared.guards_ok(d) -> str|None` (overlay alive, STOP bind present); `userwatch.watch(on_input)` (evdev keyboards/mice; async).
- [ ] **Step 1: Failing tests:** `compositor_binds` from a canned `hyprctl -j binds` (modmask 64 key Escape) contains `(64, 0xff1b)`; user input during a burst sets `paused`, and `idleMs` of quiet resumes it (fake clock); with `stopOnUserInput` it halts instead; `guards_ok` returns a reason when the overlay pid is gone.
- [ ] **Step 2–4:** implement; tests pass.
- [ ] **Step 5: Live check (tell the user first; it moves their cursor):** which absolute move works on Hyprland (virtual `motion_absolute` vs `hl.dsp.cursor.move`) → set the default; the AI cursor glides then a right-click lands on a target in a test window; the real cursor is back where it was; moving the mouse mid-burst pauses.
- [ ] **Step 6: Commit + push.**

### Task 6: TTS

**Files:** Create `screenpilot/screenpilot/tts.py`; Test `screenpilot/tests/test_tts.py`

**Interfaces:** Produces `tts.TTS` protocol (`say(text)`, `stop()`), `tts.Piper(model, config)` (queue; `piper -m M --output-raw | pw-play --rate R --format s16 --channels 1 -`, R from the voice JSON); `tts.speakable(text) -> str`.
- [ ] **Step 1: Failing tests:** `speakable("**Hi** `x = 1`\n```py\ncode\n```\n- item")` → `"Hi. item"`-like plain text without backticks, asterisks or the code block; `stop()` empties the queue and kills the player (fake processes).
- [ ] **Step 2–4:** implement; `screenpilot say "hello"` is heard; `stop` mid-sentence cuts it.
- [ ] **Step 5: Commit + push.**

### Task 7: Backends, ASK, the backend switch

**Files:**
- Create: `screenpilot/screenpilot/backends.py`
- Modify: `agent.py` (`run_ask`), `quickshell/primitive/Prefs.qml` (`screenAiClaude`, Extras), `puffy/windows/SettingsApp/ExtrasPage.qml`, `droplet/Settings.qml`
- Test: `screenpilot/tests/test_actions.py`

**Interfaces:**
- Produces: `backends.make(cfg) -> Backend`; `Backend.ask(question, shot, context) -> str`; `Backend.session(goal) -> Session`; `Session.step(shot, context, note) -> Action`; `actions.from_claude(tool_input: dict, scale) -> Action`; `actions.from_json(text: str) -> Action` (tolerates ```json fences and prose around one object).
- [ ] **Step 1:** read the claude-api reference for the computer-use tool version, beta header and model; write it into `backends.py` constants.
- [ ] **Step 2: Failing tests:** `from_claude({"action":"left_click","coordinate":[10,20]})` → `Action("click", 10, 20)`; `"type"`, `"key"` (`"ctrl+l"`), `"scroll"` (direction + amount), `"left_click_drag"`, `"double_click"`, `"right_click"`, `"screenshot"` map; `from_json('```json\n{"action":"click","x":5,"y":6}\n```')` → click; invalid JSON raises `ValueError`; unknown action raises.
- [ ] **Step 3–4:** implement; tests pass; `screenpilot ask "what is on my screen?"` answers with both backends (local after `ollama pull qwen3-vl:8b`; Claude only if the env file has a key) and speaks.
- [ ] **Step 5:** each shell's Extras gets "Screen AI: Claude" (off = local), read from `screenpilot backend`, set with `screenpilot backend claude|local`, like Screen time. Check each shell loads (rig for Puffy/Droplet; no live restart).
- [ ] **Step 6: Commit + push.**

### Task 8: ACT, confirmation, logs

**Files:**
- Create: `screenpilot/screenpilot/safety.py`
- Modify: `agent.py` (`run_act`), `daemon.py` (confirm round trip)
- Test: `screenpilot/tests/test_safety.py`, `screenpilot/tests/test_act.py`

**Interfaces:**
- Produces: `safety.risky(action, context) -> str|None`; `safety.RunLog(root, keep=20)` (`step(action, shot)`, writes `actions.jsonl` + PNGs, prunes); `Daemon.confirm(question) -> bool` (overlay Yes/No; no overlay → False).
- [ ] **Step 1: Failing tests:** `risky(type "sudo rm -rf x")`, `risky(click, title "Confirm purchase")`, password-field typing → reasons; plain click → None; policy `risky` asks before step 1; `never` doesn't; denied → run ends "declined"; act loop with a scripted fake session (`click`, `type`, `done`) runs 3 steps and logs 2 actions; `maxSteps` cut off; timeout cut off; 21 runs → 20 kept.
- [ ] **Step 2–4:** implement; tests pass.
- [ ] **Step 5: Live ACT** in the sandbox ("open a terminal and type hello") with the local model, then in shared mode on a harmless window (announced); STOP mid-run by key and by button.
- [ ] **Step 6: Commit + push.**

### Task 9: Nix, wiring, checklist, README

**Files:**
- Create: `screenpilot/package.nix`, `screenpilot/module.nix`, `screenpilot/checklist.sh`, `screenpilot/README.md`
- Modify: `flake.nix` (`packages.x86_64-linux.screenpilot`, `devShells.x86_64-linux.screenpilot`, `nixosModules.screenpilot`), `~/Nixos/flake.nix` (import + `services.screenpilot = { enable = true; user = "boing"; }`, not committed)

**Interfaces:** `services.screenpilot.{enable, mode, backend, claudeModel, localModel, localUrl, voice, confirm, blocklist, stopKey, envFile, user}`.
- [ ] **Step 1:** `nix build .#screenpilot` succeeds and its tests run in `checkPhase`; voice fetched with a pinned hash.
- [ ] **Step 2:** `nixos-rebuild build --flake ~/Nixos --override-input omniformis path:$PWD` succeeds (no switch).
- [ ] **Step 3:** `checklist.sh` walks every manual check (capture, overlay, move, click, right-click, type, combo, TTS, STOP button, STOP key, ASK and ACT in both modes), each with a y/n prompt.
- [ ] **Step 4:** README: setup, env file, switching backend, and the honest limits of each mode.
- [ ] **Step 5: Commit + push.**
