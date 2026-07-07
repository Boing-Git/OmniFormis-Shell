#!/usr/bin/env bash

THEMES_DIR="$HOME/.config/color-schemes"
CURRENT_DIR="$THEMES_DIR/current"

# Ensure the 'current' directory exists
mkdir -p "$CURRENT_DIR"

# Get available themes by scanning for folder names (excluding 'current')
available_themes=()
for d in "$THEMES_DIR"/*/; do
    theme_name=$(basename "$d")
    if [[ "$theme_name" != "current" && "$theme_name" != "currect" && "$theme_name" != "*" ]]; then
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
VSCODIUM_THEME_FILE="$HOME/.antigravity/extensions/haikalllp.matugen-theme-1.0.2-universal/themes/matugen.json"
if [ -f "$CURRENT_DIR/vscodium.json" ]; then
    mkdir -p "$(dirname "$VSCODIUM_THEME_FILE")"
    rm -f "$VSCODIUM_THEME_FILE"
    ln -sf "$CURRENT_DIR/vscodium.json" "$VSCODIUM_THEME_FILE"
    echo "Linked vscodium.json to VSCodium Matugen theme"
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

# Reload other apps
hyprctl reload 2>/dev/null || true
pkill -SIGUSR1 nvim 2>/dev/null || true
pkill -USR1 cava 2>/dev/null || true
pkill -9 quickshell 2>/dev/null || true
nohup quickshell >/dev/null 2>&1 &