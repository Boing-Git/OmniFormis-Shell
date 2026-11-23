# CLAUDE.md

Quickshell (QML) project: corner dials, starting with a wallpaper switcher.

## How we split the work

**UI is mine to build. Functionality is yours.**

### UI changes → teach me, don't do it for me

UI means anything about how it looks or moves: layout, sizes, positions, colours, borders, shapes, fonts, animations, transitions, visual states, new visual components.

When I ask for a UI change:
- **Don't edit the files.** Teach me how to make the change myself.
- Tell me **which file and which part** to change (`file:line`), and **why there**.
- Explain the **QML concept** behind it (anchors, Behavior, states, Shape, etc.) in plain words, short.
- Show a **small snippet** of the change, but leave the typing to me. Point out what to tweak to experiment (e.g. "try 300 instead of 200 for duration").
- If there are a few ways to do it, give the one you'd pick and say why in one line.
- After I've made it, review it if I ask: say what's good, what to fix, and why.
- Only edit UI code yourself if I explicitly say "do it for me" / "you do it".

### Functionality → you do it

Functionality means logic and wiring: data, models, file scanning, processes/commands, state, signals, config values, maths, performance, fixing bugs. It also covers filling in **placeholders** I've built in the UI (e.g. I make a button or an empty item and ask you to make it work).

When I ask for functionality:
- Implement it directly.
- Don't change the look of my UI while doing it. If the logic needs a UI change, tell me what to add and let me do it.
- Briefly say what you did and where.

### Not sure which one it is?

Ask me in one line before starting.

## Project notes

- Settings: `variables.js`, imported as `import "variables.js" as Vars` → `Vars.xxx`.
- Colours: always `Roles.xxx` (`Roles.qml`, the one colour file): the design's colours (Settings → Design → Colours: the theme's M3 roles, or Apple's glass whites), same names as `Colors.qml` (a link to `~/.config/color-schemes/current/quickTheme.qml`), which only Roles reads. Shapes likewise go through `M3Shapes.styled` (Design → Shapes). Primitives never default colours: every colour must be passed in.
- Generic parts live in `primitive/` (`DialDelegate`, `DialRotation`, `DialRing`, `DialBand`, `CrossfadeImage`, `LoadingIndicator`, `M3Shapes`, `ShapeMorph` (an M3 shape that morphs into another on a spring when its `shape` changes), `SpringValue`, `SearchBar`, `SymbolIcon` (every Material Symbols icon: one vector shape, smooth and seam-free), `SmoothText` (every label: smooth when turned or scaled), `IconButton` (M3E icon button: round, squares up while pressed, state layer)), registered in `primitive/qmldir` and imported with `import "primitive"`.
- Dials live in 8 spots: the 4 corners (quarter circles) and the middle of each edge (`"top"`, `"bottom"`, `"left"`, `"right"`: half circles). A dial reads its spot with `corner: Dials.spotOf("<name>")`; Edit in the control center's Dials control moves them (`Dials.moveTo`), saved in `Vars.dialPositionsPath`. Content must use the dial's `startDeg` / `sweepDeg` / `midDeg` (90° or 180°), never assume a quarter.
- Control center parts live in `controlcenter/` (own `qmldir`, imported with `import "controlcenter"`): `WifiControl`, `BluetoothControl`, `MediaPlayer` (each exposes a `control` object), `ControlTile` / `DevicePill` (ring delegates), `TimelineRing`, `CurvedText`, `KnobRing` (the volume / brightness tick rings) with `AudioLevel` / `BrightnessLevel` (ddcutil, or brightnessctl on a laptop), `ArrangeLayer` (Edit: the dragged pill and the 8 drop spots). Pass the dial as `dial: center.dialItem` (plain `dial: dial` binds to itself).
- Control center settings (no magic numbers in the QML): `controlcenter/ControlCenterSettings.qml` (dial, outer ring, knobs, inner ring / pills, date badge, default timeline, corner card), `MediaSettings.qml` (media only, including its own `controlCenter` copy of ControlCenterSettings used while Media is selected) and `ArrangeSettings.qml` (Edit: wiggle, dragged icon, drop spots, the Screenshot pill's pull-off). Each has plain settings on top and a "worked out" section that links dependent values.
- The screenshot tool lives in `screenshot/` (own `qmldir`, `import "screenshot"`): `ScreenshotTool` (the overlay window, freeze with grim, crop with magick, wl-copy / Satty), `SelectionBox` (the rectangle and its handles), settings in `ScreenshotSettings.qml` (M3E sizes from `Design language/src/tokens/defaults/`). It registers itself as `Dials.screenshot` (`start(x, y)`).
- Live settings: `primitive/Prefs.qml` (singleton, `Prefs.xxx`): the values that can be changed from inside the shell with no reload (feel, sound, hints, corners, notifications, pop-ups, wallpaper sort). Defaults come from `variables.js`; changes are saved in `Vars.settingsPath` and win. Each has a type, group and help line in `Prefs.schema`; `qs ipc call prefs list | get | set | toggle | reset`. Use `Prefs.scrollMomentum` / `Prefs.energy` / `Prefs.openSpring` instead of the `Vars` ones in new dials.
- Notifications: the shell is the notification server (`Notifs.qml`: `list`, `apps`, `unseen`, `info(n)`, `open` / `dismiss`). `NotifyOsd.qml` is the arrival dial (a pop-up named `notify`, lives on the control center's spot until moved); `controlcenter/NotifyControl.qml` is the control. `Apps.qml` gives an app its M3 shape from its id (`Apps.shapeFor`), the same in the launcher and in notifications.
- Settings: `controlcenter/SettingsControl.qml` (the menu on the inner ring: groups, Back, a setting's value on the tick ring) and `HyprSettings.qml` (Hyprland variables and the theme, read and written through the `omniformis` CLI). Notifications and Settings share `ReaderSettings.qml` / `ReaderCard.qml` (the card in the middle) and `CurvedParagraph`.
- Shortcuts: the Settings control's Shortcuts group lists `omniformis hypr binds --json` (`HyprSettings.binds`); a click on one records the keys pressed next (`keycapture.js`, ported from old_quickshell; Hyprland sits in the `omniformis_capture` submap meanwhile) and `setBind` writes it. `controlcenter/KeyChips.qml` draws a combination as chips in the gap. A control's `gapClick` takes a click in the gap when it has no `value`.
- A control can bring `value` (a level like the knobs': `value` 0..1, `steps`, `text`, `subject`, `set(v)`): one `KnobRing` in the knobs' place turns it; a value with `options` / `index` / `setIndex(i)` is shown as chips instead (`OptionRing`, a chip can carry colour dots). A theme change runs `Vars.themeScript` with `DIAL_SHELL_RELOADS=1` (so it doesn't kill the shell), then the shell reloads itself and Settings comes back to the same pill (`Vars.settingsResumePath`). `hint` names a first-contact line (`Hints.qml`). `qs ipc call center go <key>` opens the control center on one control.
- The lock screen lives in `lock/` (own `qmldir`, `import "lock"`): `LockScreen` (session lock, PAM with `Vars.lockPamConfig`, the typed state, `qs ipc call lock lock`; registers as `Dials.lock`, `lock(fromSize)`; no unlock call by design), `LockSurface` (one per screen: a sheet out of the power dial's spot, then the whole-circle dial: clock, date, the password ring with one M3 bead per letter turning one notch per key), `LockSettings`, and `EclipseBeads` (Lock → Look → Lock face: Eclipse, docs/lockscreen-concepts.md concept 1: the time as beads, each letter pulls one onto the ring, unlock sends them to the dials' spots). It survives a reload (`PersistentProperties`, and no reloads while locked) and a crash (`Vars.lockStatePath` + Hyprland's `allow_session_lock_restore`). The wallpaper is pre-blurred with ImageMagick into `Vars.lockCachePath`: no MultiEffect, since Qt 6.12 crashes on effect masks and on a layered item holding an effect used as a `fillItem`. Hyprland side: `DialLockBind` (Super + L), `misc.session_lock_xray` (the sheet grows over the desktop), hypridle's `lock_cmd`.
- Motion: spatial Behaviors use `Prefs.fastSpatial` / `Prefs.defaultSpatial` (never `Vars.expressiveFastSpatial` / `Vars.expressiveDefaultSpatial` directly), colour and opacity the `Vars.expressive*Effects` curves. Bounce 0 (`Prefs.calm`) means nothing overshoots anywhere: those two curves turn calm, every `SpringValue` runs at damping ≥ 1, and overshoot flourishes (selection wiggles, the loading indicator's springy morph) skip.
- One setting, one effect: no setting may only work while another is on (two switches for one thing were merged into one choice: `ticks`, `cornerVolume`; glass at 100% means solid, so there is no Translucent master). `Prefs._migrate` converts settings files saved before a merge.
- Translucent shell (Settings → Look): glass per kind (`glassDials` / `glassRings` / `glassPopups` / `glassLock`), frost (`frostDials` / `frostPopups` / `frostOver`), `lockBlur`. Containers only, through `Prefs.glass(colour, kind)`: `DialDelegate`'s background (its `glassKind`: "dial", or "popup" on the OSDs), `DialBand` and `SearchBar` ("ring"), the lock's dial ("lock"). What sits on them stays solid. Frost is Hyprland's blur behind the shell's layers: the dials' windows are the `quickshell` namespace, the OSDs' `quickshell-popup`; `Prefs.applyFrost()` sets the two layer rules live with `hyprctl eval` (and again after a Hyprland config reload). Blur strength is Hyprland's own, shared with the windows. With Hyprland's blur off, dial and pop-up glass stays at 90% at least.
- Liquid glass (Settings → Liquid glass; `Prefs.liquidGlass` "off" / "on" / "button", plus every setting of the liquid glass library in `Dotfiles/liquidglass-main`, as `Prefs.liquid*`): `primitive/LiquidGlass.qml` is a `ShaderEffect` running the library's shader (`primitive/shaders/liquidglass.frag`, ported: a disc or an arc band instead of a rounded box), in place of the flat fill of the same containers as the translucent glass (`DialDelegate`'s disc, `DialBand`, `SearchBar`, the lock's disc and band). It sees the wallpaper, not the windows (a layer window can't): `primitive/Backdrop.qml` (singleton; shell.qml binds the wallpaper and the screen size) and a blurred copy made with ImageMagick into `Vars.liquidCachePath`; `LiquidBackdrop` holds the two pictures per window (a `DialDelegate` makes one, `dial.liquidBackdrop`; glass on a dial finds its dial by walking up). The kind's Glass solidity fills the glass's body and clears across the bevel, so the toggle alone shows it. Shader edits: run `scripts/build-shaders.sh` (qsb); Qt loads the `.qsb`. Shader paths go through `Qt.resolvedUrl` (a plain path resolves next to the *using* file), and texture-source Images must be drawn (opacity 0, not `visible: false`) or they never pass on a new picture.
- `CornerWhisper.qml`: what a closed corner says (the volume as an arc, a bead per new notification), one tiny window per spot. `Workspaces.qml`: Hyprland's workspaces for the OSD and the launcher's drop spots (`AppDragLayer.qml`). `primitive/DragGhost`, `HintPill`, `ShapeImage` are shared parts for anything dragged, hinted, or cut to a shape.
- Crowding rule: a new feature is a control tile (or a pop-up that shares a spot) first, and only gets a hot corner of its own once it's used daily.
- Every top-level window (`PanelWindow`) sets `screen: Dials.screen` (the first real monitor). A monitor that disconnects and comes back (DisplayPort monitors do as they sleep) closes the shell's layer windows, so `shell.qml` reloads the shell once the screens settle after a change (after the unlock, if locked).
- New QML files must be added to the `qmldir` of their folder (root, `primitive/`, `controlcenter/` or `screenshot/`), or they aren't found.
- Test with `qs -p ./` and check the output for errors/warnings.
- Theming: the wallpaper dial (and Puffy) theme through `scripts/theme-apply.sh` (`Prefs.applyTheme(path)`): matugen with the repo's config, an explicit source (never prompts), one run at a time, a log in `~/.local/state/theme-apply/`. Settings → Wallpaper → Scheme / Theme from (`Prefs.themeScheme`, `themeSource`), each chip with dots from the wallpaper (`theme-apply.sh --preview`).
- Settings → Advanced (`primitive/Advanced.qml`): every plain `property` of ControlCenterSettings, MediaSettings, ArrangeSettings, ReaderSettings, ScreenshotSettings and LockSettings, read from the files themselves (the comment above a property is its help, `// ── x ──` its group, `readonly` ones are worked out and skipped). Each settings file calls `Advanced.adopt(cfgRoot, "<type>")`, so a new plain setting shows up by itself. Saved in `Vars.advancedPath`.
- Presets (`Presets.qml`, Settings → Presets, `qs ipc call preset ...`): every value of Prefs and Advanced, the dials' spots, the wallpaper and Hyprland's variables, one JSON per preset in `Vars.presetsPath`; applying saves "Before last apply" first (the undo).
- Clipboard (`controlcenter/ClipboardControl.qml`): cliphist's copies on the inner ring, pins kept by the shell (`Vars.clipboard.pinsDir`), the tile pauses keeping copies (the flag `scripts/clip-store.sh` checks).
- Shells: Dial-E (this folder), Puffy (`../puffy`), Droplet (`../droplet`). Start, restart and switch only through `scripts/shell` (it refuses while the lock is up). Settings → Shell and the About card (`About.qml`, the About pill in the Dials control) switch from here.
- Mascots: `primitive/Mascot.qml` (kind "dial-e" / "puffy" / "droplet"): drawn, coloured by roles passed in, springy, calm under Bounce 0. Pupils use `Roles.on_primary_fixed` on `Roles.primary_fixed` whites (the same in light and dark).
- Liquid glass, Sees: Live: only the dial that is out streams, only the windows under its box (`LiquidBackdrop.awake` / `area`), at `Vars.liquid.liveFps`; a capture that stops is started again; windows get Hyprland's rounding and border; workspace and special-workspace changes slide or fade with Hyprland's own animation (`Backdrop._beginSwitch`). The glass shader has a fourth shape, `"box"`, for cards (the tour, About). Lock → Look → Lock sheet: Blur or Liquid glass.
- Design → Ring colours (three or one) and Unpicked size (every ring's unpicked items, `Prefs.inactiveScale`).
- Tests: `test-dial-heading.qml` (Enter acts on where a spinning ring is heading), `scripts/tests/theme-apply.test.sh`, `scripts/tests/glass-bench.sh` (the glass's CPU / GPU cost; opens the control center).

## Comment standard

- A comment sits directly above the thing it explains, with **no blank line** between them.
- Leave **one blank line** between a comment and any code above it that it does *not* explain (no gap needed right after an opening `{`).
- End-of-line comments explain their own line, so they need no gaps.

## Spoilers: the mascots' secrets

On the About card (the About pill in the control center's Dials control): tap Dial-E seven times; hold Puffy until it has puffed all the way up; pull Droplet down as if pouring it. Each tells you about its shell.
