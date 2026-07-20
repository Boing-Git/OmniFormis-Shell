# OmniFormis Shell Release Notes

## 🚀 The Release

### ⚙️ `omniformis` CLI Rewritten in rust
The `omniformis` CLI tool has been completely rewritten and migrated to **rust**!
- Powered by the Clap framework.
- Drastically faster execution, static binary distribution, and no more Python environment dependency issues.
- Integrated reload triggers to specifically target "general appearance" settings changes on the fly.

### 🎨 Material 3 & UI Polish Pass
Extensive aesthetic updates and UX refinements across the entire shell:
- **New Shape Selectors**: Replaced basic text-based radio buttons with M3-compliant interactive segmented controls featuring high-quality anti-aliased renderings.
- **Enhanced Task Manager**: Added fuzzy search functionality for top processes. Optimized performance by restricting system info queries (`nvidia-smi`, `top`, `free`) to execute only when the module is actively visible.
- **Refined Settings App**: Introduced a standardized, accessible interface for copying and pasting slider values. Added snap-to-tick behavior for integer-based sliders.
- **UI Consistency**: Unified geometry, fixed layout gaps, and standardized slider handle-to-track height ratios across the Control Center, Settings, and Volume OSD.
- **Notification Fixes**: Eliminated structural padding issues in notification components.
- **Wallpaper Mask**: Enabled enhanced anti-aliasing on the wallpaper mask for smoother edges.
- **Widgets**: Introduced a shape-customization toggle for the Analog Clock widget.

### 🐧 NixOS & Unified Installer Improvements
- **Unified Installer Architecture**: `install.sh` now intelligently detects existing repositories to avoid redundant cloning, and directly downloads pre-built `omniformis` binaries from GitHub Releases for lighting-fast setup.
- **NixOS Parity**: Migrated NixOS dotfiles installation to utilize the same consolidated `~/Dotfiles` structure as Arch Linux, removing the dependency on fragmented repos.
- Fixed Spicetify installation issues on NixOS by resolving path and permission constraints on the read-only Nix store.
- Resolved system configuration build errors ("not of type package") in `packages.nix`.
- Ensured `marketplace` and custom extensions integrate seamlessly on NixOS.

---

## 🛠️ Upgrading
To upgrade to the latest OmniFormis Shell version, simply pull the latest changes and run the unified installer:
```bash
cd ~/Dotfiles
git pull origin main
./install.sh
```
