#!/usr/bin/env bash

THEMES_DIR="$HOME/.config/color-schemes"
CURRENT_DIR="$THEMES_DIR/current"

# Ensure the 'current' directory exists
mkdir -p "$CURRENT_DIR"

# Get available themes by scanning for folder names (excluding 'current')
available_themes=()
for d in "$THEMES_DIR"/*/; do
    theme_name=$(basename "$d")
    if [[ "$theme_name" != "current" && "$theme_name" != "*" ]]; then
        available_themes+=("$theme_name")
    fi
done

# If no theme provided or invalid usage, show available themes
if [ -z "$1" ]; then
    echo "Usage: $(basename "$0") <theme_name> [dark|light]"
    echo ""
    echo "Available themes:"
    for theme in "${available_themes[@]}"; do
        echo "  - $theme"
    done
    exit 1
fi

SELECTED_THEME="$1"
MODE="${2:-dark}"

if [[ "$MODE" != "dark" && "$MODE" != "light" ]]; then
    echo "Error: Mode must be 'dark' or 'light'."
    exit 1
fi

# Check if the selected theme exists
is_valid=false
for theme in "${available_themes[@]}"; do
    if [[ "$theme" == "$SELECTED_THEME" ]]; then
        is_valid=true
        break
    fi
done

if [[ "$is_valid" == false ]]; then
    echo "Error: Theme '$SELECTED_THEME' not found."
    echo "Available themes:"
    for theme in "${available_themes[@]}"; do
        echo "  - $theme"
    done
    exit 1
fi

echo "Applying theme: $SELECTED_THEME ($MODE mode)"

# Create/overwrite soft links for all files in the selected theme folder
for file in "$THEMES_DIR/$SELECTED_THEME/$MODE"/*; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        # -s for soft link, -f to force overwrite
        ln -sf "$file" "$CURRENT_DIR/$filename"
        echo "Linked: $filename -> $SELECTED_THEME/$MODE/$filename"
    fi
done

echo "Done! Theme is now set to '$SELECTED_THEME' in '$MODE' mode."

# Update VSCodium Matugen theme
# VSCodium reads this via workbench.colorCustomizations.import (vscodium.nix) instead of a
# theme extension: home-manager installs extensions read-only from the Nix store, so an
# extension that needs an external tool to overwrite one of its own files (the old
# haikalllp.matugen-theme approach) can never actually update under this setup.
VSCODIUM_THEME_FILE="$HOME/.config/vscodium/colors.json"
if [ -f "$CURRENT_DIR/vscodium-colors.json" ]; then
    mkdir -p "$(dirname "$VSCODIUM_THEME_FILE")"
    rm -f "$VSCODIUM_THEME_FILE"
    ln -sf "$CURRENT_DIR/vscodium-colors.json" "$VSCODIUM_THEME_FILE"
    echo "Linked vscodium-colors.json to $VSCODIUM_THEME_FILE"
fi

# Update Starship theme
STARSHIP_THEME_FILE="$HOME/.config/starship.toml"
if [ -f "$CURRENT_DIR/starship.toml" ]; then
    rm -f "$STARSHIP_THEME_FILE"
    ln -sf "$CURRENT_DIR/starship.toml" "$STARSHIP_THEME_FILE"
    echo "Linked starship.toml to ~/.config/starship.toml"
    
    # Send signal to reload Fish shell starship prompt if configured
    pkill -USR2 fish 2>/dev/null || true
fi

# Update Quickshell Theme.qml
QUICKSHELL_THEME_FILE="$HOME/.config/quickshell/Variables/Theme.qml"
if [ -f "$CURRENT_DIR/quickTheme.qml" ]; then
    rm -f "$QUICKSHELL_THEME_FILE"
    ln -sf "$CURRENT_DIR/quickTheme.qml" "$QUICKSHELL_THEME_FILE"
    echo "Linked quickTheme.qml to Quickshell Variables/Theme.qml"
fi

# Update VSCode Matugen themes
VSCODE_RAW_FILE="$HOME/.cache/matugen/vscode-colors"
if [ -f "$CURRENT_DIR/vscode-colors" ]; then
    mkdir -p "$(dirname "$VSCODE_RAW_FILE")"
    rm -f "$VSCODE_RAW_FILE"
    ln -sf "$CURRENT_DIR/vscode-colors" "$VSCODE_RAW_FILE"
    echo "Linked vscode-colors to ~/.cache/matugen/vscode-colors"
fi

VSCODE_JSON_FILE="$HOME/.cache/matugen/vscode-colors.json"
if [ -f "$CURRENT_DIR/vscode-colors.json" ]; then
    mkdir -p "$(dirname "$VSCODE_JSON_FILE")"
    rm -f "$VSCODE_JSON_FILE"
    ln -sf "$CURRENT_DIR/vscode-colors.json" "$VSCODE_JSON_FILE"
    echo "Linked vscode-colors.json to ~/.cache/matugen/vscode-colors.json"
fi

# Update OBS Theme
OBS_THEME_FILE="$HOME/.config/obs-studio/themes/matugen.obt"
if [ -f "$CURRENT_DIR/automatic.obt" ]; then
    mkdir -p "$(dirname "$OBS_THEME_FILE")"
    rm -f "$OBS_THEME_FILE"
    ln -sf "$CURRENT_DIR/automatic.obt" "$OBS_THEME_FILE"
    echo "Linked automatic.obt to OBS themes as matugen.obt"
fi

# Apply GTK and color scheme changes globally
if [[ "$MODE" == "light" ]]; then
    gsettings set org.gnome.desktop.interface color-scheme prefer-light 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme "" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-light" 2>/dev/null || true
else
    gsettings set org.gnome.desktop.interface color-scheme prefer-dark 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme "" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark" 2>/dev/null || true
fi

# Update Spicetify Theme
if [ -f "$CURRENT_DIR/spicetify.ini" ]; then
    for SPICETIFY_THEME in M3E; do
        SPICETIFY_THEME_FILE="$HOME/.config/spicetify/Themes/$SPICETIFY_THEME/color.ini"
        [ -d "$(dirname "$SPICETIFY_THEME_FILE")" ] || continue
        rm -f "$SPICETIFY_THEME_FILE"
        ln -sf "$CURRENT_DIR/spicetify.ini" "$SPICETIFY_THEME_FILE"
    done
    echo "Linked spicetify.ini into Spicetify themes"
    
    # Reload Spicetify quietly. Set current_theme explicitly: an old matugen post_hook
    # (from a pre-rebuild Nix-store copy) resets it to the removed "text" theme, and
    # `spicetify apply` then aborts with 'Theme "text" not found'.
    nohup bash -c "spicetify config current_theme M3E color_scheme MaterialYou && spicetify apply" >/tmp/spicetify-apply.log 2>&1 &
fi

# Update AdwSteamGtk Theme
STEAM_THEME_FILE="$HOME/.config/AdwSteamGtk/custom.css"
if [ -f "$CURRENT_DIR/steam.css" ]; then
    mkdir -p "$(dirname "$STEAM_THEME_FILE")"
    rm -f "$STEAM_THEME_FILE"
    ln -sf "$CURRENT_DIR/steam.css" "$STEAM_THEME_FILE"
    echo "Linked steam.css to AdwSteamGtk custom.css"
    
    # Reload Steam theme via adwaita-steam-gtk
    nohup adwaita-steam-gtk -i >/dev/null 2>&1 &
fi

# Update Vesktop (Vencord) Theme
VESKTOP_CSS_FILE="$HOME/.config/vesktop/themes/matugen.css"
if [ -f "$CURRENT_DIR/vesktop.css" ]; then
    mkdir -p "$(dirname "$VESKTOP_CSS_FILE")"
    rm -f "$VESKTOP_CSS_FILE"
    ln -sf "$CURRENT_DIR/vesktop.css" "$VESKTOP_CSS_FILE"
    echo "Linked vesktop.css to ~/.config/vesktop/themes/matugen.css"
fi

# Reload other apps
hyprctl reload 2>/dev/null || true
pkill -SIGUSR1 nvim 2>/dev/null || true
pkill -USR1 cava 2>/dev/null || true

# The dial shell reloads itself after a theme switch and comes back to where you were (its
# Settings control sets DIAL_SHELL_RELOADS=1), so it is not killed and relaunched from here.
if [ -n "$DIAL_SHELL_RELOADS" ]; then
    exit 0
fi

# Restart quickshell the same careful way scripts/reload.sh does: stop the watchdog and actually
# wait for it to exit before relaunching, and relaunch through qs-watchdog.sh with the explicit
# -p path rather than a bare `quickshell &`. A bare launch has no -p flag, so quickshell falls
# back to its default config search path — which on this machine resolves to a stale, read-only
# Nix-store copy of the whole shell under ~/.config/quickshell instead of the live
# ~/Dotfiles/quickshell tree, making every widget look like an old, pre-redesign version until a
# real reload fixed it. A bare launch also bypasses the watchdog, silently losing crash recovery
# after every theme switch.
pkill -TERM -f qs-watchdog.sh
for i in $(seq 1 50); do
    pgrep -f qs-watchdog.sh >/dev/null || break
    sleep 0.1
done
pkill -9 -f qs-watchdog.sh 2>/dev/null

pkill -9 quickshell 2>/dev/null || true
pkill -9 .quickshell-wra 2>/dev/null || true

nohup bash /home/boing/Dotfiles/quickshell/scripts/qs-watchdog.sh >/dev/null 2>&1 &
disown