# The assistant: a local AI that runs the desktop

Each shell has it in its own design, and **Super + A** opens it in whichever shell runs
(`scripts/shell ipc call assistant toggle`). Type what you want ("bigger gaps", "open
Downloads", "dark mode", "next song", "how long was I in Firefox today") and press Enter.

- **Dial-E**: the **Ask** control of the control center. With it at the mark, just type: the
  words go on the curved bar between the rings. The card in the middle says the steps and the
  answer; the inner ring has the questions asked before and a few to try (Yes / No there for
  a step that asks first). Settings → Extras → Ask the AI.
- **Puffy**: the launcher's **/ask** mode (also in its `/` menu). Enter on "Ask: …"; the
  answer and each step come in as the launcher's own rows. Settings → Extras.
- **Droplet**: pull a drop down out of the middle of the **top edge**. It stretches, pinches
  off and spreads into a bar; what it did drips out of the bar as a card; Esc, a click outside
  or pushing the bar back up sends it home. Settings circle → Ask the AI.

All three run the same `scripts/assistant/assistant.py`.

## What it can do, and only that

`scripts/assistant/tools.py` is the whole list (30 commands). The model can call nothing else,
and every command runs as a plain argument list, never through a shell. What it knows of this
desktop (where everything is, which tool to use first, how to write an automation) is
`scripts/assistant/context.md`, read into every question: edit it to teach it more.

- **Settings**: every Dial-E setting, and all ~300 of its Advanced ones (every size, timing
  and shape of the control center, media player, screenshot tool and lock: read from the
  settings files themselves), live or saved for when Dial-E next starts; every
  Hyprland variable of the dotfiles (gaps, animations, layout, modifiers, default apps, game
  mode), every Puffy setting. It searches before it sets, and values are checked (ranges,
  choices) before anything is written.
- **Shortcuts**: finds them by what they do or by key.
- **Windows and window rules**: lists the open windows; adds a rule for an app's windows
  ("every VSCodium window goes to the special workspace scratchpad": the app's window classes
  are found for it), lists and removes the rules it added. They live one per line in
  `hypr/modules/userRules.lua` (loaded by `winrules.lua`), apply at once to windows that open
  from then on, and stay after a reload.
- **Anything in the dotfiles**: Hyprland's whole config, matugen's templates, the shells, every
  app's config. It finds (by words, in names and lines), reads, and changes one exact piece at
  a time; only files inside the dotfiles, and never its own (`scripts/assistant/`) or `.git`.
  Each change keeps the file as it was (`~/.local/state/dots-assistant/backups/`, "undo that"
  puts it back). A Hyprland change reloads Hyprland, and is put back by itself if Hyprland
  reports a new config error; a matugen template change makes the theme again; a Nix change
  waits for your rebuild (it says so).
- **Shells**: switches between them; runs any action the running shell offers over IPC
  (except Dial-E's "reset all settings").
- **Look**: wallpaper (and the colours from it), light / dark.
- **Apps and files**: opens apps by name; finds files and folders in your home folder; opens
  a file in its app or a folder in your file manager. It never deletes or moves anything.
- **Automations**: runs one ("run game night"), lists them, and saves a new one from what you
  describe ("make an automation that opens Spotify and plays"); the steps are checked before
  anything is saved (`scripts/automate/`, see its README). Each shell's automation list ends
  with Make one, which opens the AI with "make an automation that " begun.
- **Media, volume, workspaces, status.**
- **Power**: lock and suspend at once; log out, restart and shut down ask you first (Yes / No
  on the card).

From a terminal: `scripts/assistant/tools.py list`, `tools.py call volume '{"action":"get"}'`,
`scripts/assistant/assistant.py "make the gaps bigger"`.

## Turn on the AI

It is in `~/Nixos` already (`modules/system/services/services.nix`: Ollama with CUDA and the
`qwen3:8b` model; `modules/system/core/environment.nix`: NixOS's CUDA cache, so it comes
ready-built). The first rebuild has to be told about that cache, since it is only trusted
after this rebuild:

```sh
sudo nixos-rebuild switch --flake ~/Nixos \
  --option extra-substituters https://cache.nixos-cuda.org \
  --option extra-trusted-public-keys cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M=
```

After that a plain `sudo nixos-rebuild switch --flake ~/Nixos` is enough. The model (about
5 GB) downloads once, in the background, after the rebuild. Ollama listens on 127.0.0.1 only:
nothing leaves the machine. Another model: set `DOTS_AI_MODEL` (and `DOTS_AI_URL` for another
server). Without Ollama the bar opens and says it can't reach the AI.

## Test

`python3 scripts/tests/assistant.test.py` (a fake Ollama; commands in dry-run mode).

## Screen time

`scripts/screentime.py` (started at login) counts how long each app has the focus, per day,
not while you're away (2 minutes without input) or asleep; `screen_time` is one of the AI's
commands. Each shell shows it: Dial-E's Screen time control, Puffy's Settings → Extras,
Droplet's Screen time circle (and its Apps are ordered by it). One switch for every shell
(`screentime.py on | off`, or any shell's Screen time setting). Kept in
`~/.local/state/screentime/<date>.json`; nothing leaves the machine.

## Not yet

Notes (skipped for now); voice.
