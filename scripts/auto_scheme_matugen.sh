#!/usr/bin/env bash

# Config
WALLPAPER="$1"
MODE="${2:-dark}"
MATUGEN_CMD="matugen image -m $MODE --source-color-index 0 -t"

# Ensure an image is provided
if [[ -z "$WALLPAPER" ]]; then
    echo "Usage: $0 <path-to-wallpaper> [mode]"
    exit 1
fi

# Extract HSL metrics (Values range from 0.0 to 1.0)
# mean.g = Saturation, mean.b = Brightness/Lightness
# standard_deviation.r = Hue Variance, standard_deviation.g = Saturation Variance, standard_deviation.b = Brightness Variance (Contrast)
METRICS=$(convert "$WALLPAPER" -colorspace HSL -format "%[fx:mean.g] %[fx:mean.b] %[fx:standard_deviation.r] %[fx:standard_deviation.g] %[fx:standard_deviation.b]" info:)
SATURATION=$(echo "$METRICS" | awk '{print $1}')
BRIGHTNESS=$(echo "$METRICS" | awk '{print $2}')
STD_HUE=$(echo "$METRICS" | awk '{print $3}')
STD_BRIGHT=$(echo "$METRICS" | awk '{print $5}')

# Decision Logic
if (( $(echo "$SATURATION <= 0.05" | bc -l) )); then
    # Completely devoid of color (Grayscale)
    SCHEME="scheme-monochrome"

elif (( $(echo "$SATURATION <= 0.25" | bc -l) )); then
    # Very low color, muted, foggy (e.g. foggy forest)
    SCHEME="scheme-neutral"

elif (( $(echo "$SATURATION <= 0.40" | bc -l) && $(echo "$BRIGHTNESS >= 0.75" | bc -l) )); then
    # Very bright with low-to-mid saturation (e.g. snowy landscapes, pale skies)
    SCHEME="scheme-monochrome"

elif (( $(echo "$BRIGHTNESS <= 0.35" | bc -l) && $(echo "$SATURATION <= 0.50" | bc -l) )); then
    # Very dark wallpapers with some accents (e.g. dark mecha with a red stripe)
    SCHEME="scheme-tonal-spot"

elif (( $(echo "$SATURATION >= 0.65" | bc -l) )); then
    # High saturation
    if (( $(echo "$STD_HUE >= 0.15" | bc -l) )); then
        # Many different vibrant colors across the spectrum
        SCHEME="scheme-rainbow"
    elif (( $(echo "$STD_HUE >= 0.05" | bc -l) )); then
        # Moderately varied vibrant colors
        SCHEME="scheme-fruit-salad"
    else
        # Very saturated but mostly one cohesive color tone
        SCHEME="scheme-expressive"
    fi

elif (( $(echo "$STD_BRIGHT >= 0.25" | bc -l) && $(echo "$STD_HUE <= 0.05" | bc -l) )); then
    # High contrast (dramatic lighting) but low color variance (mostly one color family)
    SCHEME="scheme-fidelity"

else
    # Mid-range, detailed, balanced wallpapers (e.g. anime scenery)
    if (( $(echo "$STD_HUE >= 0.10" | bc -l) )); then
        # Lots of distinct colors in a mid-saturation image
        SCHEME="scheme-content"
    else
        # Standard balanced image
        SCHEME="scheme-tonal-spot"
    fi
fi

# Apply the scheme
echo "Wallpaper Metrics -> Saturation: $SATURATION | Brightness: $BRIGHTNESS"
echo "Applying matugen scheme: $SCHEME"
$MATUGEN_CMD "$SCHEME" "$WALLPAPER"

