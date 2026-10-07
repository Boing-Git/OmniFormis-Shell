<div align="center">

# OmniFormis Shell

A deeply modular, dynamic, and hardware-accelerated desktop environment built for **NixOS** and **Arch Linux**, leveraging **Hyprland** with **Quickshell**.

![NixOS](https://img.shields.io/badge/OS-NixOS-5277C3?style=for-the-badge&logo=nixos&logoColor=white)
![Arch Linux](https://img.shields.io/badge/OS-Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)
![Hyprland](https://img.shields.io/badge/WM-Hyprland-00A9FF?style=for-the-badge&logo=hyprland&logoColor=white)
![Quickshell](https://img.shields.io/badge/Shell-Quickshell-8B5CF6?style=for-the-badge&logo=qt&logoColor=white)

</div>

---

## ✨ Overview

Welcome to OmniFormis Shell! This repository represents my fully customized, aesthetic, and automated desktop setup, featuring a unified environment that seamlessly supports both **NixOS** and **Arch Linux**. 

The entire system is glued together by a unified theming engine based on **Material 3 Expressive**, leveraging Pywal/Matugen methodologies to dynamically theme the OS based on the current wallpaper and color scheme.

## 🚀 Key Technologies & Stack

* **Desktop Environment**: [Hyprland](https://hyprland.org/) with [Quickshell](https://outfoxxed.me/quickshell/) (QtQuick/QML-based native Wayland shell with fluid animations)
* **Keyboard Layout**: [Colemak-DH](https://colemakmods.github.io/mod-dh/) with dedicated home-row directional navigation (`m, n, e, i`)
* **Terminal Emulator**: [WezTerm](https://wezfurlong.org/wezterm/)
* **Shell & Prompt**: [Fish](https://fishshell.com/) with [Starship](https://starship.rs/)
* **Editor**: [Neovim](https://neovim.io/) / [Antigravity IDE](https://antigravity.google) / [VS Codium](https://vscodium.com/)
* **Launcher**: [Quickshell App Launcher](quickshell/) with fuzzy scoring, clipboard history, and math evaluations (replacing Fuzzel/Rofi)
* **Audio Visualizer**: [Cava](https://github.com/karlstav/cava)
* **System Monitoring**: Custom system monitoring implemented directly in Quickshell (replacing Btop), Htop, Nvtop
* **Theming & Color**: [Matugen](https://github.com/InioX/matugen) + Custom `omniformis` Rust CLI tool + Bash Scripts (`color-schemes/set-theme.sh`)
* **Declarative System**: [Nix Flakes & Home Manager](nix/) module integration

## 🌟 Features at a Glance

| | |
|---|---|
| 🎛️ **Live settings** | Every setting applies the moment you change it, no shell restart unless it truly needs one |
| 🪟 **Attached panels** | Panels fuse into the screen edge with concave inverted corners that stay seamless while morphing |
| 📶 **Wi-Fi & Bluetooth** | Full connect, pair, forget and scan flows with real connection states and error feedback |
| 🔔 **Notification center** | Cards slide, fade and reflow as notifications arrive and disappear |
| 🎨 **Scheme switcher** | Every colour scheme previews itself, in the active light or dark mode |
| 🖼️ **Wallpaper switcher** | Loading indicators on thumbnails and while a wallpaper is being applied |
| 🦀 **`omniformis` CLI** | Validated, atomic, script-friendly control over every Quickshell and Hyprland variable |
| ⌨️ **Shortcuts** | Click a shortcut, press the keys, done. Full combinations with variables |
| ⌨️ **Colemak-DH** | Home-row navigation across the whole desktop |

### 🎛️ Live Settings Engine

Changing a setting never restarts the shell unless it has to. Where a change goes is worked out at runtime by [`SettingsApply`](quickshell/core/SettingsApply.qml), not read from a hand-kept list, so a new variable is live the moment the shell exposes it.

| Setting | What happens |
|---|---|
| Quickshell variable the shell exposes on `Vars` | Applied instantly. Components bind to it, so they update on the spot |
| Hyprland variable | Saved, then a single `hyprctl reload`. The shell keeps running |
| Quickshell variable nothing binds to live | The only case that reloads the shell |

* Values are converted to the type the live property already has, so text stays text and switches stay booleans.
* Saving is debounced and sent as one ordered batch. Dragging a slider never spawns a process per step.
* One engine drives the Unified settings pages, the Quick & Presets controls (panel style, position, glass mode, clock pill mode) and the Bezier editor.

### 🪟 Attached Panels & Seamless Morphing

* **Attached style**: the panel is square where it meets the screen edge and blends into it through concave **inverted corners**. Framed and floating styles are supported too, and the detached settings window keeps fully rounded corners.
* **No seams while morphing**: inverted corners tuck slightly under the panel, so the springy resize never exposes a hairline gap.
* **Content stays inside**: Launcher, Power Menu, Emoji Picker, Scheme Switcher, notification popup and Polkit dialog clip their content to the panel, even mid-animation.
* **Crisp curves everywhere**: every rounded surface is anti-aliased, and scaled tiles are drawn as vectors instead of stretched textures, so corners stay smooth on hover and press.

### ⚙️ Expressive Settings App

* **One visual language**: every page uses the sidebar's item look, with `surface_container_high` at rest, `surface_container_highest` on hover, `primary_container` when selected, and a springy press-scale.
* **Corner rules**: the selected item is a full pill. Every other item keeps its group-edge radii, large only at the top and bottom of a group and small wherever two items touch. Selection never distorts its neighbours.
* **Circular icon badges** on the Wi-Fi and Bluetooth pages, using solid Material 3 accent colours so icons stay readable on dark cards.
* **Interactive drag splitter** for the sidebar with spring-backed easing.
* **Liquid Glass, translucency and blur presets** switch instantly and update Hyprland in the same step.
* **Bezier curve editor** to visualise and tune Hyprland and Quickshell animation profiles, saved as reusable presets.
* **Quick & Presets**: save your whole look (wallpaper, scheme, mask shape, panel settings) and restore it in one click.

### 📶 Wi-Fi

* Toggle Wi-Fi, scan for networks and connect with one click. Known and open networks connect straight away, new secured ones ask for a password.
* Passwords go to NetworkManager through Quickshell's native API, never onto a command line.
* Live states on every row: *Connecting…*, *Connected*, *Saved*, *Available*, and *Couldn't connect* with an automatic retry prompt for a wrong password.
* Right-click to forget a network. Reveal a saved password (after confirming your sudo password) and copy it.
* Scanning runs while the page is open and stops when you leave it.

### 🔵 Bluetooth

* Toggle the adapter, control discoverable and pairable, and see paired devices with live *Connecting… / Connected · 80% / Paired* status including battery level.
* **Pairing mode** scans automatically, pairs with one click, cancels a pairing in progress, and stops scanning when you leave the view or switch Bluetooth off.
* Right-click to forget a device.

### 🔔 Animated Notification Center

* Notifications are synced into the list incrementally, so existing cards keep their identity: new ones scale and fade in, dismissed ones scale and fade out, and the rest glide into place.
* Swipe a card away or click it. Both take the same collapse-and-remove path.
* The empty state and the action bar fade in and out with the list.

### 🎨 Colour Scheme Switcher

* Each tile is painted with the scheme's own surface and shows its **primary, secondary and tertiary** swatches, so you see the result before applying it.
* Follows the active light or dark mode and refreshes when you toggle it. The active scheme is detected automatically and badged.
* Live incremental search, animated tile add and remove, hover and press feedback, and Colemak-DH keyboard navigation.

### 🖼️ Wallpaper Switcher

* Every thumbnail shows a **loading indicator** until its image has decoded.
* A second indicator runs while a wallpaper is applied and its colours are generated.

### 🕒 Smart Clock Pill

* **Always Visible**: pinned, with screen margin reserved by an exclusive LayerShell strut ([ClockStrut.qml](quickshell/panels/ClockStrut.qml)).
* **Dodge Windows**: watches window geometry on the active workspace and slides away when a window overlaps it.
* **Auto Hide**: tucks into the edge and returns when you hover it.
* Works from any edge: Top, Bottom, Left or Right.

### 🦀 The `omniformis` CLI

Every Quickshell and Hyprland variable is scriptable, validated and safe to call from several places at once.

```bash
omniformis qs set panelOpacity 0.8          # typed and validated
omniformis qs toggle gameMode               # flip a boolean
omniformis hypr set kb_variant colemak_dh
omniformis hypr get vimkeys --json
omniformis qs list --json | jq              # machine-readable
omniformis theme set material-you dark      # hot-swap scheme and mode
omniformis bezier save my-curve             # preset names are sanitised
```

* **Typed values**: numbers, booleans, strings and JSON arrays are checked against the variable's type. Bad input exits with a clear error instead of corrupting a config.
* **Safe writes**: atomic file replacement plus a lock, so parallel calls from the UI never clobber each other.
* **Script-friendly**: `--json` output, clean pipe handling, `toggle`, and negative values just work.
* **Portable**: `OMNIFORMIS_DOTFILES` relocates the checkout, and `OMNIFORMIS_NO_SIDE_EFFECTS=1` disables shell and Hyprland restarts for tests and scripting.
* **Template filters** for alpha, lightening, darkening and saturation in theme templates.

### ⌨️ Shortcuts

Every keybind is one named entry in [`hypr/modules/keybinds.lua`](hypr/modules/keybinds.lua) holding its **whole combination**, modifiers and key together, instead of just a key.

```lua
TermBind          = "$MM + T",
WindowCloseBind   = "$MM + Q",
ScrollMoveLeftBind = "$MM + $left",
WorkspaceGoBind   = "$MM + {n}",       -- one bind per number, 0 to 9
QsPowerMenuBind   = "$MM + $TM + P",
```

**Record a shortcut**

Open *Shortcuts & Modifiers* in the Settings app, click a shortcut and press the keys you want.

* Modifiers appear live as you hold them, and the first real key completes the combination.
* Hyprland is switched to a quiet submap while you record, so even shortcuts that are already bound can be captured. It always switches back, with a watchdog in case the shell ever dies mid-recording.
* Mouse combinations work too: hold a modifier and scroll, or click a button, to record `mouse_up`, `mouse_down` or `mouse:272`.
* Media and hardware keys (`XF86AudioPlay`, volume, brightness) are recognised, and any other key is recorded by its hardware code.
* Press `Esc` to cancel, or use the block button to disable a shortcut.

**Variables**

* `$MM`, `$SM`, `$TM` and `$QM` stand for the Main, Second, Third and Fourth modifiers set in `variables.lua`. Change a modifier once and every shortcut that uses it follows.
* `$left`, `$right`, `$up` and `$down` are the directional keys: the home row while `vimkeys` is on (`VimLeftKey`, `VimDownKey`, `VimUpKey`, `VimRightKey`), the arrow keys otherwise.
* Any other string in `variables.lua` can be used as `$name`, and `{n}` is filled in by the workspace and tab binds.
* While recording, modifiers are stored as variables automatically (switch it off with *Use variables when recording*). Use the pencil button to type a combination yourself, with one-click chips to insert variables.
* Empty means disabled.

**Checked before you commit**

* A typed combination is validated as you type: unknown variables, missing keys and more than one key are rejected.
* Shortcuts that resolve to the same keys are flagged on the page, so clashes are easy to spot. Layout shortcuts only count while their layout is active.

```bash
omniformis hypr binds                       # every shortcut, resolved, with clashes marked
omniformis hypr binds --json                # the same for scripts
omniformis hypr set TermBind '$MM + Return' # validated like the UI
omniformis hypr get TermBind
```

**Declaratively (Nix)**

```nix
programs.omniformis.hyprland.binds = {
  TermBind = "$MM + Return";
  WindowCloseBind = "$MM + $TM + Q";
  SuspendBind = "";                # disabled
};
```

Shortcuts you do not list keep their defaults, and the categories and comments the Settings app reads stay intact.

### ⌨️ Colemak-DH Layout & Home-Row Navigation

* **Home-row directions** everywhere: `m` = Left, `n` = Down, `e` = Up, `i` = Right for window focus, column shifting, layout cycling and the shell's own grids and lists. The four keys are variables (`VimLeftKey` and friends), so a QWERTY layout can use `h j k l` with one edit.
* **Conflict-free binds**: displaced actions are remapped (`MusicWorkspaceKey` to `Z`, `FilesKey` to `B`), and `F` stays fullscreen.
* Ships with `kb_variant = "colemak_dh"`. For a QWERTY toggle on `Alt + Shift`, set `kb_layout = "us,us"` and `kb_variant = "colemak_dh,"` in `hypr/modules/variables.lua`.

### ⚡ App Launcher

* **Fuzzy scoring** that prioritises prefixes, word boundaries, camel-case capitals and consecutive matches.
* **Shadow-key model syncing** keeps typing instant, even with large app lists.
* **Built-ins**: inline maths (`=25 * 4`), emoji picker (`emoji ...`), clipboard history with image previews, and web search (`web ...`).

### 🎨 Wallpaper Palette Engine

* **Median saturation analysis** in [auto_scheme_matugen.sh](scripts/auto_scheme_matugen.sh) classifies wallpapers correctly, including dark or monochrome ones with tiny neon accents.
* **Histogram accent extraction** pulls the most vibrant colours through a 16-colour quantisation, keeping accents punchy on dark and OLED themes.
* **Automatic Material 3 scheme choice** among `expressive`, `vibrant`, `fidelity`, `monochrome`, `neutral` and `tonal-spot`.

### 🎮 Steam Game Library

* [extract_steam_games.py](scripts/extract_steam_games.py) recursively reads `libraryfolders.vdf` across every mounted drive and Steam root.
* Banners are discovered and cached for a navigable Game Library widget.

### ❄️ Declarative Nix Module

* `programs.omniformis` serialises Nix attributes straight into Quickshell's `variables.js` and Hyprland's `variables.lua`, with per-tool `enable` switches.
* Works on any Linux user, with no hardcoded home paths, and falls back to `osConfig.programs.omniformis` when set at the system level.

### 💻 Old ThinkPads & Low-Spec Mode

The same config runs on an NVIDIA desktop and on a 2011 ThinkPad. `LowSpec` in [`variables.lua`](hypr/modules/variables.lua) (also in the Settings app, under General) defaults to `"auto"`, which turns it on for machines with 4 or fewer CPU threads or 6 GB of RAM or less. `"on"` and `"off"` override it. Hyprland decides in [`hardware.lua`](hypr/modules/hardware.lua) and Quickshell follows live.

| | In low-spec mode |
|---|---|
| Hyprland | No blur, shadows or liquid glass, opaque windows, 8-bit output without colour management |
| Quickshell | Opaque panels, no wallpaper mask or audio visualizer, 4× instead of 32× multisampling on layers |

On every machine:

* NVIDIA environment variables and the software cursor only apply when the NVIDIA driver is loaded, so Intel and AMD keep hardware video decoding and a hardware cursor.
* The shell reacts to setting changes instead of polling for them ten times a second.
* The brightness keys, including a laptop's `XF86MonBrightness` keys, drive the backlight with `brightnessctl` and fall back to DDC/CI.

**Minimum GPU**: Hyprland needs OpenGL ES 3.0. On ThinkPads that means Sandy Bridge graphics (X220, T420) or newer. The X201, T410, X200 and older only reach OpenGL ES 2.0 and can't start Hyprland at all.

---

## 🛠️ Installation

OmniFormis Shell features a unified installer that automatically detects your operating system and executes the appropriate setup logic for both NixOS and Arch Linux.

```bash
git clone https://github.com/Boing-Git/My-Dotfiles ~/Dotfiles
cd ~/Dotfiles
chmod +x scripts/install.sh
./scripts/install.sh
```

### ❄️ Nix Flake / Home Manager

If you are using NixOS or Home Manager, OmniFormis Shell provides a convenient Nix module that you can import into your system flake to declaratively configure Quickshell and Hyprland!

**1. Add OmniFormis to your flake inputs:**
```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    omniformis.url = "github:Boing-Git/OmniFormis-Shell";
  };
  
  # ...
}
```

**2. Import the module into your Home Manager configuration:**
```nix
{ inputs, ... }: {
  imports = [ inputs.omniformis.homeManagerModules.default ];

  programs.omniformis = {
    enable = true;
    
    # Toggle individual dotfiles
    wezterm.enable = true;
    fish.enable = true;
    quickshell.enable = true;
    hyprland.enable = true;
    
    # Configure Quickshell variables
    quickshell.settings = {
      radiusSmall = 12;
      fontFamily = "Google Sans Flex";
      clockPillMode = "Always Visible";
      # ... any variables you want to override
    };

    # Configure Hyprland variables
    hyprland.settings = {
      Browser = "zen-beta";
      shadow_enabled = false;
      # ... any variables you want to override
    };
  };
}
```
You can toggle any module on or off (`cava`, `nvim`, `btop`, `spicetify`, `qt5ct`, etc.) just by setting `.enable = true`. This allows you to selectively install parts of the environment without polluting your `~/.config`.
This module intelligently serializes attributes directly into `.pragma library` Javascript and Lua tables respectively, and gracefully falls back to system-wide settings (`osConfig.programs.omniformis`) if specified in your OS flake.

You can also drop into a developer environment anytime with Cargo and Rust toolchains preconfigured:
```bash
nix develop
# or
nix-shell shell.nix
```

### 🧰 Manual Installation

If the automated installer fails or you prefer to set things up manually, follow these steps:

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Boing-Git/My-Dotfiles ~/Dotfiles
   ```

2. **Copy Configuration Files**:
   Copy all relevant dotfiles into your `~/.config/` directory, excluding repository-specific files.
   ```bash
   mkdir -p ~/.config
   rsync -av --exclude={'.git','README.md','CONTRIBUTING.md','LICENSE','install.sh','RELEASE.md','scripts'} ~/Dotfiles/ ~/.config/
   ```

3. **Install the OmniFormis CLI Tool**:
   The custom CLI is required for theme management. Download the pre-compiled binary:
   ```bash
   mkdir -p ~/.local/bin
   curl -L "https://github.com/Boing-Git/OmniFormis-Shell/releases/latest/download/omniformis" -o ~/.local/bin/omniformis
   chmod +x ~/.local/bin/omniformis
   ```
   *Make sure `~/.local/bin` is added to your shell's PATH.*

4. **Install Dependencies**:
   Ensure you have all the required dependencies listed in the **Dependencies** section below installed on your system.

### 📦 Dependencies

Since NixOS uses a separate Flake repository for dependency resolution, Arch Linux users (or anyone installing manually) must ensure the following packages are installed on their system. Most of these can be found in the Arch official repositories or the AUR.

* **Core & Utilities**: `hyprland`, `quickshell`, `hypridle`, `git`, `jq`, `eza`, `zoxide`, `wl-clipboard`, `cliphist`, `xdg-utils`, `tree`, `nitch`, `ddcutil`, `brightnessctl`, `lm_sensors`, `networkmanager`, `pipewire`, `app2unit`, `swappy`, `libqalculate`, `hexecute`
* **Development Libraries & Tools**: `rust`, `cargo`, `gcc`, `rustup`, `cmake`, `ninja`, `pkgconf`, `qt6-base`, `qt6-declarative`, `python3` (with `tkinter`, `gobject`, `pywebview`, `flask`, `emoji`)
* **Applications**: `vscodium`, `wezterm`, `nautilus`, `file-roller`, `spotify`, `github-desktop`, `github-cli`, `blanket`, `satty`, `grim`, `upscayl`, `loupe`, `playerctl`, `vlc`, `obs-studio`, `losslesscut`, `handbrake`, `zen-browser`
* **Theming & Visuals**: `matugen`, `gtk3`, `cairo`, `pango`, `gobject-introspection`, `awww`, `cava`, `fftw`, `cbonsai`, `hyperhdr`, `mpvpaper`
* **Fonts & Icons**: `ttf-space-mono-nerd`, `ttf-cascadia-code-nerd`, `ttf-material-symbols-variable`, `ttf-rubik`, `papirus-icon-theme`, `googledot-cursor-theme`

## 🎨 Architecture & Modules

This repository avoids monolithic configuration files. Every component is meticulously split into clean, logical modules:

### [Quickshell (OmniFormis Core)](quickshell/)
A custom-built, hardware-accelerated QML desktop shell powering the core user interface on top of Hyprland.
* **Full Shell Experience**: Includes top panels, volume OSDs, notification daemons, an M3-styled Control Center, and workspace trackers.
* **Built-in Settings App**: A unified, responsive GUI (`SettingsApp/UnifiedSettingsPage.qml`) that parses your system configuration dynamically. You can toggle special workspace rules, adjust window gaps via sliders, and customize layouts—all without touching a text editor!
* **Dynamic Widgets & Interactions**: Features an analog desktop clock, segmented pill headers, and precise hover-zone transitions.
* **Material You Theming**: Colors are extracted directly from the system scheme via the Rust CLI and injected as QML Singletons for real-time UI updates.
* **Dynamic Manager**: A custom `omniformis` Rust CLI tool lets you swap themes, change animations (15+ profiles like *Springy*, *Jelly*, *Cinematic*), and layouts on the fly.
* **Live by design**: settings apply instantly through the Live Settings Engine instead of restarting the shell.

### 🌈 Dynamic Color Engine
The `color-schemes/` directory acts as the brain for system-wide color coordination. Using `set-theme.sh` and the Rust CLI, changing a scheme instantly updates:
* OmniFormis Shell / Quickshell UI
* Quickshell Borders & Animations
* GTK & Qt applications (via `qt5ct`, `qt6ct`, `nwg-look`)
* Terminal Emulators
* Spotify (via imperative `spicetify` hooks)

#### Generating a New Theme
You can easily generate and scaffold a new theme based on Material You using the built-in `omniformis` CLI tool and your QML templates.

```bash
omniformis theme generate color-schemes/template_light.qml color-schemes/template_dark.qml
```
*Note: Make sure your template files include a comment on the first line (e.g., `// Gruvbox Dark Medium`) so the generator can automatically extract the proper theme name!*

## 📁 Repository Structure

```text
~/Dotfiles/
├── btop/                  # System monitor (btop)
├── cava/                  # Audio visualizer
├── color-schemes/         # Core theming engine & scripts
├── fastfetch/             # System information fetcher
├── fish/                  # Fish shell aliases, functions, and config
├── flake.nix              # Nix Flake definition
├── hypr/                  # Hyprland modular window manager configuration
├── matugen/               # Material color generation
├── nix/                   # Home Manager declarative module
├── nvim/                  # Neovim configuration
├── nvtop/                 # GPU usage monitor
├── nwg-look/              # GTK settings
├── qt5ct/                 # Qt5 theme settings
├── qt6ct/                 # Qt6 theme settings
├── qtengine/              # Qt theming engine rules
├── quickshell/            # QML-based OmniFormis desktop shell
├── scripts/               # Utility scripts and omniformis CLI daemon
├── shell.nix              # Nix development shell
├── spicetify/             # Dynamic Spotify theming
├── wezterm/               # Terminal emulator config
└── starship.toml          # Shell prompt configuration
```

## 📜 License
Distributed under the GNU General Public License v3.0 (GPLv3) (see individual sub-directories for specific licensing details where applicable).