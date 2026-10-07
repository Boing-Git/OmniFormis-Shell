#!/usr/bin/env bash

# Config
WALLPAPER="$1"
MODE="${2:-dark}"

# Ensure wallpaper image is provided
if [[ -z "$WALLPAPER" || ! -f "$WALLPAPER" ]]; then
    echo "Usage: $0 <path-to-wallpaper> [mode]"
    exit 1
fi

# 1. Extract HSL metrics (Values range from 0.0 to 1.0)
# mean.g    = Mean Saturation   (average color intensity across entire image)
# maxima.g  = Max Saturation    (peak saturation — detects even tiny neon highlights)
# median.g  = Median Saturation (the *typical* pixel's saturation — key for desaturated wallpapers)
# mean.b    = Mean Brightness
# maxima.b  = Max Brightness
# standard_deviation.r = Hue Variance
# standard_deviation.g = Saturation Variance
# standard_deviation.b = Contrast
METRICS=$(magick "$WALLPAPER" -colorspace HSL -format "%[fx:mean.g] %[fx:maxima.g] %[fx:median.g] %[fx:mean.b] %[fx:maxima.b] %[fx:standard_deviation.r] %[fx:standard_deviation.g] %[fx:standard_deviation.b]" info:)
read -r MEAN_SAT MAX_SAT MEDIAN_SAT MEAN_BRIGHT MAX_BRIGHT STD_HUE STD_SAT STD_BRIGHT <<< "$METRICS"

# 2. Extract vibrant accent color (crucial for dark/OLED/cyberpunk wallpapers)
# Filters out pure dark/near-black/muddy pixels (chroma > 40 and brightness > 80)
ACCENT_HEX=$(magick "$WALLPAPER" -resize 100x100 -depth 8 -colors 16 -format "%c\n" histogram:info: \
  | tr -s " " | sed "s/^ *//" | sort -nr \
  | awk '{
      match($0, /#[0-9A-Fa-f]{6}/);
      if (RSTART > 0) {
          hex = substr($0, RSTART, 7);
          r = strtonum("0x" substr(hex, 2, 2));
          g = strtonum("0x" substr(hex, 4, 2));
          b = strtonum("0x" substr(hex, 6, 2));
          max = (r > g) ? ((r > b) ? r : b) : ((g > b) ? g : b);
          min = (r < g) ? ((r < b) ? r : b) : ((g < b) ? g : b);
          chroma = max - min;
          brightness = (r + g + b) / 3;
          if (chroma > 40 && brightness > 80) {
              print hex;
              exit;
          }
      }
  }')

# 3. Decision Logic for Material You Color Scheme
#
# The critical insight: MEDIAN saturation tells you what the *typical* pixel looks like.
# A wallpaper that is 90% grayscale mecha with a tiny red stripe has:
#   MeanSat ~0.22, MaxSat ~1.0, but MedianSat ~0.19
# A truly vibrant wallpaper (neon city, colorful anime) has:
#   MeanSat ~0.55, MaxSat ~1.0, and MedianSat ~0.54
#
# MedianSat < 0.25 = the typical pixel is desaturated → monochrome/neutral territory
# MedianSat >= 0.25 = real pervasive color → vibrant/expressive schemes apply

export PATH="$HOME/.nix-profile/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:$PATH"

USE_ACCENT_COLOR=false

SCHEME=$(awk -v mean_sat="$MEAN_SAT" -v max_sat="$MAX_SAT" -v median_sat="$MEDIAN_SAT" -v mean_bright="$MEAN_BRIGHT" -v std_hue="$STD_HUE" -v std_bright="$STD_BRIGHT" '
BEGIN {
    # If variables are empty, they default to 0 in numeric context, which is safe
    if (mean_sat <= 0.04 || max_sat <= 0.15) {
        print "scheme-monochrome"
    } else if (median_sat <= 0.25) {
        if (mean_sat <= 0.10) print "scheme-monochrome"
        else if (mean_sat <= 0.20) print "scheme-neutral"
        else print "scheme-tonal-spot"
    } else if (mean_bright <= 0.40 && median_sat >= 0.35) {
        if (std_hue >= 0.10) print "scheme-expressive"
        else print "scheme-vibrant"
    } else if (mean_bright <= 0.35 && median_sat >= 0.25) {
        print "scheme-fidelity"
    } else if (mean_bright <= 0.15) {
        print "scheme-neutral"
    } else if (mean_sat <= 0.40 && mean_bright >= 0.75) {
        print "scheme-monochrome"
    } else if (median_sat >= 0.45) {
        if (std_hue >= 0.15) print "scheme-rainbow"
        else if (std_hue >= 0.05) print "scheme-fruit-salad"
        else print "scheme-expressive"
    } else if (std_bright >= 0.25 && std_hue <= 0.05) {
        print "scheme-fidelity"
    } else {
        if (std_hue >= 0.10) print "scheme-content"
        else print "scheme-tonal-spot"
    }
}')

if [[ "$SCHEME" == "scheme-expressive" || "$SCHEME" == "scheme-vibrant" || "$SCHEME" == "scheme-fidelity" ]]; then
    if [[ -n "$ACCENT_HEX" ]]; then
        USE_ACCENT_COLOR=true
    fi
fi

CONFIG_PATH="$HOME/Dotfiles/matugen/config.toml"
CONFIG_ARG=""
if [[ -f "$CONFIG_PATH" ]]; then
    CONFIG_ARG="-c $CONFIG_PATH"
fi

# 4. Apply the scheme using Matugen
echo "Wallpaper Metrics -> MeanSat: $MEAN_SAT | MaxSat: $MAX_SAT | MedianSat: $MEDIAN_SAT | MeanBright: $MEAN_BRIGHT | StdHue: $STD_HUE"
if [[ "$USE_ACCENT_COLOR" == true && -n "$ACCENT_HEX" ]]; then
    echo "Applying matugen color: $ACCENT_HEX with scheme: $SCHEME ($MODE mode)"
    matugen color hex "$ACCENT_HEX" -m "$MODE" -t "$SCHEME" $CONFIG_ARG
    
    # Fix wallpaper path references in generated files when using color hex
    for target in "$HOME/.config/color-schemes/material-you/$MODE/hypr-colors.lua" "$HOME/.config/color-schemes/material-you/$MODE/vscode-colors.json"; do
        if [[ -f "$target" ]]; then
            sed -i "s|image = \"Null\"|image = \"$WALLPAPER\"|g; s|\"wallpaper\": \"[^\"]*\"|\"wallpaper\": \"$WALLPAPER\"|g" "$target" 2>/dev/null || true
        fi
    done
else
    echo "Applying matugen scheme: $SCHEME on $WALLPAPER ($MODE mode)"
    matugen image "$WALLPAPER" -m "$MODE" -t "$SCHEME" --prefer saturation $CONFIG_ARG
fi


