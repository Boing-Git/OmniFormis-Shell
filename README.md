<div align="center">

# OmniFormis Shell

A deeply modular, dynamic, and hardware-accelerated desktop environment built for **NixOS** and **Arch Linux**, leveraging **Hyprland** and **Quickshell**.

![NixOS](https://img.shields.io/badge/OS-NixOS-5277C3?style=for-the-badge&logo=nixos&logoColor=white)
![Arch Linux](https://img.shields.io/badge/OS-Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)
![Hyprland](https://img.shields.io/badge/WM-Hyprland-00A489?style=for-the-badge&logo=hyprland&logoColor=white)
![Quickshell](https://img.shields.io/badge/UI-Quickshell-8B5CF6?style=for-the-badge&logo=qt&logoColor=white)

</div>

---

## ✨ Overview

Welcome to OmniFormis Shell! This repository represents my fully customized, aesthetic, and automated desktop setup, featuring a unified environment that seamlessly supports both **NixOS** and **Arch Linux**. 

The entire system is glued together by a unified theming engine based on **Material 3 Expressive**, leveraging Pywal/Matugen methodologies to dynamically theme the OS based on the current wallpaper and color scheme.

## 🚀 Key Technologies & Stack

* **Window Manager**: [Hyprland](https://hyprland.org/) (configured entirely in **Lua** for maximum programmability and modularity)
* **Desktop Shell**: [Quickshell](https://outfoxxed.me/quickshell/) (QtQuick/QML-based, replacing traditional Waybar/Eww setups with fluid animations)
* **Terminal Emulator**: [WezTerm](https://wezfurlong.org/wezterm/)
* **Shell & Prompt**: [Fish](https://fishshell.com/) with [Starship](https://starship.rs/)
* **Editor**: [Neovim](https://neovim.io/) / [VS Codium](https://vscodium.com/)
* **Launcher**: [Quickshell App Launcher](quickshell/) (replacing Fuzzel/Rofi)
* **Audio Visualizer**: [Cava](https://github.com/karlstav/cava)
* **System Monitoring**: Btop, Htop, Nvtop
* **Theming & Color**: [Matugen](https://github.com/InioX/matugen) + Custom Rust cli tool + Bash Scripts (`color-schemes/set-theme.sh`)

## 🛠️ Installation

OmniFormis Shell features a unified installer that automatically detects your operating system and executes the appropriate setup logic for both NixOS and Arch Linux.

```bash
git clone [https://github.com/Boing-Git/My-Dotfiles](https://github.com/Boing-Git/My-Dotfiles) ~/Dotfiles
cd ~/Dotfiles
chmod +x scripts/install.sh
./scripts/install.sh
```

## 🎨 Architecture & Modules

This repository avoids monolithic configuration files. Every component is meticulously split into clean, logical modules:

### [Hyprland (Lua Config)](hypr/)
Instead of a static `hyprland.conf`, the WM is configured via `hyprland.lua`. 
* **Modular Layouts**: Dwindle, Master, Scrolling.
* **Dynamic Manager**: A custom `omniformis` Rust CLI tool lets you swap themes, change animations (15+ profiles like *Springy*, *Jelly*, *Cinematic*), and layouts on the fly.
* **Native Keybinds**: Deeply programmable workspace loops and window manipulation using Lua scripting.

### [Quickshell UI (OmniFormis Core)](quickshell/)
A custom-built, hardware-accelerated QML shell powering the core user interface.
* **Full Shell Experience**: Includes top panels, volume OSDs, notification daemons, an M3-styled Control Center, and Hyprland workspace trackers.
* **Built-in Settings App**: A unified, responsive GUI (`SettingsApp/UnifiedSettingsPage.qml`) that parses your `variables.lua` and Hyprland config dynamically. You can toggle special workspace rules, adjust window gaps via sliders, and customize layouts—all without touching a text editor!
* **Dynamic Widgets & Interactions**: Features an analog desktop clock, segmented pill headers, and precise hover-zone transitions.
* **Material You Theming**: Colors are extracted directly from the system scheme via the Rust CLI and injected as QML Singletons for real-time UI updates.

### 🌈 Dynamic Color Engine
The `color-schemes/` directory acts as the brain for system-wide color coordination. Using `set-theme.sh` and the Rust CLI, changing a scheme instantly updates:
* OmniFormis Shell / Quickshell UI
* Hyprland Borders & Animations
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
├── hypr/                  # Lua-based Hyprland config
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