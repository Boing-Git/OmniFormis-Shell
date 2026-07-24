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
* **Terminal Emulator**: [WezTerm](https://wezfurlong.org/wezterm/)
* **Shell & Prompt**: [Fish](https://fishshell.com/) with [Starship](https://starship.rs/)
* **Editor**: [Neovim](https://neovim.io/) / [VS Codium](https://vscodium.com/)
* **Launcher**: [Quickshell App Launcher](quickshell/) (replacing Fuzzel/Rofi)
* **Audio Visualizer**: [Cava](https://github.com/karlstav/cava)
* **System Monitoring**: Custom system monitoring implemented directly in Quickshell (replacing Btop), Htop, Nvtop
* **Theming & Color**: [Matugen](https://github.com/InioX/matugen) + Custom Rust cli tool + Bash Scripts (`color-schemes/set-theme.sh`)

## 🛠️ Installation

OmniFormis Shell features a unified installer that automatically detects your operating system and executes the appropriate setup logic for both NixOS and Arch Linux.

```bash
git clone https://github.com/Boing-Git/My-Dotfiles ~/Dotfiles
cd ~/Dotfiles
chmod +x scripts/install.sh
./scripts/install.sh
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
├── matugen/               # Material color generation
├── nvim/                  # Neovim configuration
├── nvtop/                 # GPU usage monitor
├── nwg-look/              # GTK settings
├── qt5ct/                 # Qt5 theme settings
├── qt6ct/                 # Qt6 theme settings
├── qtengine/              # Qt theming engine rules
├── quickshell/            # QML-based OmniFormis desktop shell
├── scripts/               # Utility scripts and omniformis CLI
├── spicetify/             # Dynamic Spotify theming
├── wezterm/               # Terminal emulator config
└── starship.toml          # Shell prompt configuration
```

## 📜 License
Distributed under the GNU General Public License v3.0 (GPLv3) (see individual sub-directories for specific licensing details where applicable).