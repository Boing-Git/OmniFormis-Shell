#!/usr/bin/env bash
# Builds the Dial-E boot animation (plymouth/dial-e) from the shell's own loading indicator:
# renders one morph cycle as frames (a small window opens for ~20 s), bakes the current
# theme's background and text colours into the script, and makes a preview GIF. Run it in the
# desktop session after changing the theme, then rebuild NixOS (docs/plymouth.md).
set -eu
here=$(cd "$(dirname "$(readlink -f "$0")")/.." && pwd)
out="$here/plymouth/dial-e"
theme="$HOME/.config/color-schemes/current/quickTheme.qml"

rm -f "$out"/frame-*.png
BOOT_FRAMES_DIR="$out" timeout 90 qs -p "$here/quickshell/render-boot-frames.qml" >/dev/null 2>&1 || true
frames=$(find "$out" -name 'frame-*.png' | wc -l)
[ "$frames" -gt 0 ] || { echo "no frames rendered (is a Wayland session running?)" >&2; exit 1; }

# "#131318" → "0.075, 0.075, 0.094" (Plymouth wants 0..1)
rgb() {
    local hex
    hex=$(grep -m1 "property color $1:" "$theme" | grep -o '#[0-9a-fA-F]\{6\}')
    awk -v h="${hex:1}" 'BEGIN { for (i = 0; i < 3; i++) { v = 0; for (j = 1; j <= 2; j++) { c = index("0123456789abcdef", tolower(substr(h, i * 2 + j, 1))) - 1; v = v * 16 + c } printf "%s%.3f", (i ? ", " : ""), v / 255 } }'
}
sed "s/@BG@/$(rgb surface)/; s/@FG@/$(rgb on_surface)/; s/@FRAMES@/$frames/" "$out/dial-e.script.in" >"$out/dial-e.script"

# a preview with the turn added (Plymouth turns it while it plays: 2.4 s a turn, 30 frames a second)
preview="$here/docs/plymouth-preview.gif"
args=()
for f in $(ls "$out"/frame-*.png | sort); do
    i=$(basename "$f" .png); i=$((10#${i#frame-}))
    args+=( \( "$f" -background "#$(grep -m1 'property color surface:' "$theme" | grep -o '[0-9a-fA-F]\{6\}')" -rotate "$(echo "$i * 360 / 72" | bc -l)" -gravity center -extent 240x240 \) )
done
magick -delay 3.3 -loop 0 "${args[@]}" -layers Optimize "$preview"
echo "$frames frames in $out ($(du -sh "$out" | cut -f1)), preview: $preview"
