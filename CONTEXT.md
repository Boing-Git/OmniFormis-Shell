# Context for the overhaul (answers found in the repo and the system, 2026-11-23)

Every question the overhaul prompt asked, answered from the code or the machine, with where it
was found. "Ask" marks the ones only you can answer; the default used meanwhile is given.

## Discovery (Q1-Q20)

| Q | Answer | Evidence |
|---|---|---|
| Q1 | All shells are Quickshell 0.3.2 (QML, Qt 6.12, nixpkgs). Entry: `shell.qml` of each folder. Launched by `hypr/modules/autostart.lua` through `scripts/shell start` (was a bare `qs`). IPC: Quickshell `IpcHandler`s (`qs ipc call <target> <fn>`). | `qs --version`, autostart.lua |
| Q2 | Three shells: Dial-E (`quickshell/`, the dial shell), Puffy (`puffy/`, was `old_quickshell/`, the original OmniFormis shell), Droplet (`droplet/`, was `circle-shell/`). They share nothing in QML (Quickshell won't import above a shell's folder); they share the theme files (matugen), `scripts/theme-apply.sh`, `scripts/shell` and the omniformis CLI. No other shells. | top-level folders, imports |
| Q3 | Dial-E: `primitive/Prefs.qml` (singleton with a schema: type, group, label, help, range; saved in `~/.local/state/dial-quickshell/settings.json`, watched, applied live; `qs ipc call prefs ...`). Hyprland variables go through the omniformis CLI into `hypr/modules/variables.lua`. Now also `primitive/Advanced.qml` (the settings files) and `Presets.qml`. Puffy: its own Settings app + `omniformis qs`. | Prefs.qml, HyprSettings.qml |
| Q4 | Every Hyprland control did nothing: the omniformis CLI couldn't start (built in a nix-shell against glibc-2.42-67, since garbage collected: "required file not found"), and HyprSettings swallowed the error. Fixed by packaging it with Nix; writes now reload and are checked against `hyprctl configerrors`. | `ldd`/`readelf` of `~/.local/bin/omniformis` |
| Q5 | `primitive/LiquidGlass.qml` (a ShaderEffect, `shaders/liquidglass.frag`, built to .qsb), fed by `LiquidBackdrop` per window from `Backdrop` (wallpaper, a grim snapshot, or per-window ScreencopyViews for Sees: Live). Used by DialDelegate, DialBand, SearchBar, the lock, and now the tour and About cards. | CLAUDE.md, the files |
| Q6 | Dials: control center, app launcher, wallpaper, power, the OSDs (volume, brightness, workspaces, notify), the lock's whole-circle dial. | `grep DialDelegate` |
| Q7 | Selected vs unselected sizes: ControlTile, DevicePill, AppLauncher, PowerMenu, WallpaperRing, WorkspaceOsd, OptionRing (all now use Unpicked size). | `grep selected ?` |
| Q8 | Nothing in the repo besides the todo line "interative dot matrix for something". Proposal: the lock clock (docs/lockscreen-concepts.md, concept 1). **Ask**: is that its purpose? | `grep -i "dot.?matrix"` |
| Q9 | cliphist 0.7.0 with `wl-paste --watch` for text and images (autostart); no UI existed. wl-clip-persist isn't installed. | autostart.lua, `cliphist version` |
| Q10 | matugen 4.2.0; config was a stale Nix store copy at `~/.config/matugen` (the repo's `matugen/` is linked live after the next rebuild; `theme-apply.sh` passes the repo config meanwhile); templates for 12 apps x dark/light; triggered by the wallpaper dial (now through theme-apply). Spicetify 2.46.4, theme M3E (`spicetify/Themes/M3E`, its `color.ini` links to `~/.config/color-schemes/current/spicetify.ini`), color_scheme MaterialYou, Spotify from nixpkgs copied to `~/.local/share/spotify-spicetify` by `~/.local/bin/spotify`. | `matugen --version`, `spicetify -c` |
| Q11 | Steam is the NixOS package (FHS, bwrap), started from the desktop. The breakage did not reproduce (shell alive and responsive through Steam's start, its main window, a dial opened over it, and shutdown). Its window churn did restart every live-glass capture in all 8 dial windows; that's fixed. **Ask**: what did "breaks" look like (a crash, a freeze, the glass)? | test on 2026-11-23, shell log |
| Q12 | Dial-E's own lock (`lock/`): WlSessionLock + PAM service `system-auth`, a password ring, crash-safe re-lock (`~/.local/state/dial-quickshell/locked` + `misc.allow_session_lock_restore`). No fingerprint reader (`fprintd` absent). Locked by hypridle (`loginctl lock-session` → `qs ipc call lock lock`) and Super+L. **Ask**: what isn't good about it? | lock/LockScreen.qml, hypridle.conf |
| Q13 | VSCodium (`EDITOR=codium`); Antigravity IDE is the Hyprland `Editor` variable. | env, variables.lua |
| Q14 | NixOS 26.11, kernel 7.3.1, RTX 3080 Ti (proprietary driver, `NVreg_PreserveVideoMemoryAllocations=1`), one monitor DP-1 1920x1080 @ 240 Hz scale 1, systemd-boot, no initramfs tool to call (NixOS builds it), no LUKS, SDDM (Qt6, Wayland greeter, theme pixie), Qt 6.12. Present: ImageMagick, grim, awww 0.12.1, cliphist, jq, busctl, nvidia-smi. Missing: piper, espeak-ng, chromium, ffmpeg, plymouth, ollama, llama-server. | `uname`, `lspci`, `hyprctl monitors`, `command -v` |
| Q15 | `quickshell/Lively-ux.md` (7 lines of notes): now the skill `.claude/skills/lively-ux/`. gux-expert is a user skill at `~/.claude/skills/gux-expert` (now with the 60:30:10 rule). | find |
| Q16 | M3E pieces exist: `primitive/M3Shapes`, `ShapeMorph`, `SpringValue`, `LoadingIndicator`, `IconButton`, `SymbolIcon`; tokens in `variables.js` (springs, curves copied from `Design language/src/tokens`). Sounds: `sounds/tick.mp3`. No TTS. | primitive/ |
| Q17 | All Dial-E settings are its own; theme files, presets folder, the shell choice and the clipboard pause are shared. Wallpapers: `~/Pictures/Wallpapers` (the wallpaper dial's folder). | variables.js |
| Q18 | Special workspaces: `scratchboard`, `music`, `sysinfo` (toggle binds in `hypr/modules/binds.lua`, rules in winrules.lua). The shell tracks workspaces through Quickshell.Hyprland (raw events); the glass now listens to `activespecial(v2)` too. | binds.lua, Backdrop.qml |
| Q19 | The help is Dial-E's tour (`Onboarding.qml`, the Help pill in the control center's Dials control). Puffy has a keybind cheat sheet of its own. | ControlCenter.qml |
| Q20 | A hidden headless sway session with a virtual pointer (`~/.cache/dial-quickshell/test-rig`, copied per session), `qs list --all` + `qs log -i <id>` for the live shell, `quickshell/test-dial-heading.qml`, `scripts/tests/`. Hyprland can't run headless here, so Hyprland-only behaviour is checked on the live session. | memory notes |

## Per task

| Task | Answer |
|---|---|
| B1 | matugen 4.2.0 errors out without `--prefer` or an index ("no preference was inputted, and a terminal was not detected"); the dial's index setting allowed 4 (valid: 0-3), and an index past an image's colours fails. Run by WallpaperDial.qml; the deployed config was a stale store copy. All 24 templates kept. |
| B2 | Theme M3E, scheme MaterialYou; Spotify is nixpkgs' copied to a writable folder (not Flatpak); matugen writes the file Spicetify reads (through two links); it was Spicetify not applying: the stale hook selected the removed `text` theme and `spotify_path` pointed at the launcher script. |
| B3 | See Q11. |
| B4 | Hyprland 0.57.1 (Lua config). Values go into `hypr/modules/variables.lua` (written by omniformis, auto-reloaded). Broke when the CLI's glibc was collected, not from a Hyprland upgrade. |
| B5 | The ring's apps are the full DesktopEntries list (search spins to a match, it doesn't filter); rotation is DialRotation's scroll; Enter read the index under the mark (the visual one). |
| G1 | Glass: LiquidGlass (shader) everywhere it's liquid; flat translucency via `Prefs.glass(kind)`; Hyprland's own blur only for the frost layer rules (kept). The shader is built ahead to .qsb (`scripts/build-shaders.sh` fetches qsb with nix shell). |
| G2 | Capture was per-window ScreencopyView (hyprland-toplevel-export), all 8 dial windows, every window, at 240 Hz while any dial was open. Quickshell has no region capture, the shader crops. Dials open at their spot (corner square or edge rectangle of expandedSize). |
| G3 | Capture source is per toplevel (pre-composite): no borders, rounding, shadow or blur; the shell's own layers were never in it. Borders and rounding are now drawn from Hyprland's options; shadows and blur-behind are not. |
| G4 | It dies when a capture fails (a window hidden, resized, going fullscreen): Quickshell drops that capture for good. The frame doesn't freeze; the window vanishes from the glass. Now restarted with backoff and logged. Not tied to suspend. |
| G5 | Specials: `scratchboard`, `music`, `sysinfo`; the glass didn't listen to activespecial, so it showed stale windows. |
| G6 | workspacesIn: slide, m3EmphasizedDecel, 121 ms; workspacesOut: slide, m3EmphasizedAccel, 194 ms; specials inherit fade, 194 ms. Read live from `hyprctl animations -j`. |
| G7 | The tour card (Onboarding.qml), opened by the Help pill; its background was a flat rectangle. |
| S1-S4 | Stored as above (Q3); only the Settings control and IPC write; shells pick changes up by watching their files. Prefs has migrations (`_migrate`) and clamps values; unknown keys are dropped on save (kept as is). Advanced: 300 settings. |
| S3 | Presets in `~/.config/dial-quickshell/presets` (not in the repo, since they hold your wallpaper paths; copy one in to share). Wallpaper, scheme and Hyprland values included. |
| U1 | The outer ring is the control center's control tiles; the three colours came from the tile's index (`tileColorCycle`). Uniform defaults to none (Three stays the default). |
| U3 | New (no UI existed). Opens as a Clipboard control in the control center (the crowding rule). Pins and their pictures survive reboots (kept by the shell). Password managers' copies: cliphist skips sensitive ones. |
| U5 | The installed matugen lists 10 types (incl. vibrant and smart). Dark / light is the Theme setting (set-theme.sh links the mode's files); all templates come from the same run. |
| U6 | See Q8. |
| M1 | Each shell starts from autostart (now through `scripts/shell`). They can overlap during a switch: Quickshell's notification server re-registers once the name frees up. No keybind called shell IPC. |
| M2 | M3Shapes/ShapeMorph exist; Qt 6.12 Shapes (CurveRenderer). Mascots live in `quickshell/primitive/Mascot.qml`, coloured by roles. |
| M3 | No offline TTS installed: text only. **Ask**: a language and voice, if you want voice (default English, none). |
| L1/L2 | See Q12. One monitor. Test path: the hidden sway session locks for real with its own PAM stack (password "opensesame"); never on the live session. TTY escape if the lock ever dies (Hyprland's red "lockdead" screen): Ctrl+Alt+F3, log in, run `hyprctl --instance 0 eval 'hl.exec_cmd("~/Dotfiles/scripts/shell start")'`; the shell comes back, locks again from its marker, and takes your password back on the session's TTY (Ctrl+Alt+F1 or F2). |
| X1 | SDDM is the display manager (Qt6 build, Wayland greeter under kwin, theme pixie from a flake input, no autologin). docs/sddm-evaluation.md. |
| X2 | systemd-boot, NixOS initrd, no LUKS, Plymouth not enabled, no `quiet splash`. |
| X3 | VSCodium; no local AI server installed (no ollama / llama-server). **Ask**: which local server and models, if any. |

## Mismatches with the prompt

- The prompt expects a separate "Settings app"; Dial-E's settings live in the control center's Settings control (Puffy has the separate app). Everything was added there.
- Dial-E's folder keeps its name `quickshell/` (home-manager links `~/.config/quickshell` to it); only Puffy's and Droplet's folders were renamed.
- The prompt's "settings schema for everything" exists already as `Prefs.schema`; Advanced reads the rest from the settings files instead of a second schema.
