# The assistant: a local AI that runs the desktop

Pull a drop down out of the middle of the top edge (or press **Super + A**). It stretches,
pinches off and spreads into a bar. Type what you want ("bigger gaps", "open Downloads",
"dark mode", "next song", "switch to Puffy") and press Enter. What it did drips out of the
bar as a card. Esc, a click outside or pushing the bar back up sends it home.

It works the same under Dial-E, Puffy and Droplet: it is its own small Quickshell instance
(`assistant/`), started at login next to the shell.

## What it can do, and only that

`scripts/assistant/tools.py` is the whole list (19 commands). The model can call nothing else,
and every command runs as a plain argument list, never through a shell.

- **Settings**: every Dial-E setting (live, or saved for when Dial-E next starts), every
  Hyprland variable of the dotfiles (gaps, animations, layout, modifiers, default apps, game
  mode), every Puffy setting. It searches before it sets, and values are checked (ranges,
  choices) before anything is written.
- **Shortcuts**: finds them by what they do or by key.
- **Shells**: switches between them; runs any action the running shell offers over IPC
  (except Dial-E's "reset all settings").
- **Look**: wallpaper (and the colours from it), light / dark.
- **Apps and files**: opens apps by name; finds files and folders in your home folder; opens
  a file in its app or a folder in your file manager. It never deletes or moves anything.
- **Media, volume, workspaces, status.**
- **Power**: lock and suspend at once; log out, restart and shut down ask you first (Yes / No
  on the card).

From a terminal: `scripts/assistant/tools.py list`, `tools.py call volume '{"action":"get"}'`,
`scripts/assistant/assistant.py "make the gaps bigger"`.

## Turn on the AI (NixOS, as root)

Ollama with your graphics card (CUDA), and one model that can call tools, about 5 GB:

```nix
services.ollama = {
  enable = true;
  package = pkgs.ollama-cuda;
  loadModels = [ "qwen3:8b" ];
};
```

then `sudo nixos-rebuild switch --flake ~/Nixos`. It listens on 127.0.0.1 only: nothing leaves
the machine. Another model: set `DOTS_AI_MODEL` (and `DOTS_AI_URL` for another server) in the
session's environment. Without Ollama the bar opens and says it can't reach the AI.

## Test

`python3 scripts/tests/assistant.test.py` (a fake Ollama; commands in dry-run mode).

## Not yet

Notes (skipped for now); Dial-E's ~300 Advanced settings (only its main settings are tools);
voice.
