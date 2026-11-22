#!/usr/bin/env bash
# Themes every app from a wallpaper through matugen: the one way all the shells do it.
#
#   theme-apply.sh <image> [scheme] [source]
#     scheme  a matugen type: scheme-tonal-spot (default), scheme-expressive, scheme-vibrant, ...
#     source  which of the image's colours: saturation (default), less-saturation, lightness,
#             darkness, value, or 0-3 (the most common colour first)
#
# Never prompts (matugen 4 stops to ask for a colour without --prefer or an index, and a
# shell has no terminal), never hangs (a timeout), one run at a time with the newest
# request winning (quick wallpaper changes collapse into the last one), uses the repo's
# config (~/.config/matugen can be a stale Nix store copy), and says so when it fails: a
# notification and the log in $XDG_STATE_HOME/theme-apply/log.
#   theme-apply.sh --preview <image> <source> <scheme>...
#     nothing is applied: prints "<scheme> #primary #secondary #tertiary" per scheme and
#     "source:<source> #colour" per source, in the desktop's current mode (Settings' dots)
set -u

# matugen's flags for a source
pick_for() { case $1 in [0-3]) echo "--source-color-index $1" ;; *) echo "--prefer $1" ;; esac; }

if [ "${1:-}" = --preview ]; then
    image=$2 source=$3
    shift 3
    case $(readlink -f "$HOME/.config/color-schemes/current/quickTheme.qml") in */light/*) mode=light ;; *) mode=dark ;; esac
    peek() { timeout 10 matugen image "$image" --dry-run -j hex "$@" </dev/null 2>/dev/null; }
    for t in "$@"; do
        # (an index past the image's colours falls back as theming does)
        { peek -t "$t" $(pick_for "$source") || peek -t "$t" --prefer saturation; } |
            jq -r --arg t "$t" --arg m "$mode" '"\($t) \(.colors.primary[$m].color) \(.colors.secondary[$m].color) \(.colors.tertiary[$m].color)"'
    done
    for s in 0 1 2 3 saturation less-saturation lightness darkness; do
        peek $(pick_for "$s") | jq -r --arg s "$s" '"source:\($s) \(.colors.source_color.default.color)"'
    done
    exit 0
fi

image=${1:?usage: theme-apply.sh <image> [scheme] [source]}
scheme=${2:-scheme-tonal-spot}
source=${3:-saturation}
config="$(dirname "$(readlink -f "$0")")/../matugen/config.toml"
state="${XDG_STATE_HOME:-$HOME/.local/state}/theme-apply"
mkdir -p "$state"
log="$state/log"

notify() {
    busctl --user call org.freedesktop.Notifications /org/freedesktop/Notifications \
        org.freedesktop.Notifications Notify susssasa{sv}i \
        "Theme" 0 "palette" "$1" "$2" 0 0 6000 >/dev/null 2>&1 || true
}

# the last ~200 runs are plenty
[ -f "$log" ] && [ "$(wc -l <"$log")" -gt 2000 ] && tail -n 1000 "$log" >"$log.tmp" && mv "$log.tmp" "$log"

# a request that failed last time is tried again, even if it's the same one
[ -f "$state/failed" ] && rm -f "$state/done" "$state/failed"
printf '%s\n%s\n%s\n' "$image" "$scheme" "$source" >"$state/request"

# Checked outside the lock, then again inside it: a request written while another run holds
# the lock is picked up by that run after it lets go, so none is ever lost
while :; do
    [ "$(cat "$state/request")" = "$(cat "$state/done" 2>/dev/null)" ] && exit 0
    exec 9>"$state/lock"
    flock -n 9 || exit 0
    req=$(cat "$state/request")
    mapfile -t r <<<"$req"
    case ${r[2]} in
        [0-3]) pick=(--source-color-index "${r[2]}") ;;
        *) pick=(--prefer "${r[2]}") ;;
    esac

    echo "$(date -Is) ${r[0]} ${r[1]} ${r[2]}" >>"$log"
    run() { timeout 60 matugen image "${r[0]}" -c "$config" -t "${r[1]}" "$@" </dev/null >>"$log" 2>&1; }

    # an index past the image's own colours fails ("Failed to get source color"): fall
    # back to the most vivid one instead of keeping the old colours
    if ! run "${pick[@]}" && { [ "${pick[0]}" != --source-color-index ] || ! run --prefer saturation; }; then
        echo "$(date -Is) FAILED" >>"$log"
        touch "$state/failed"
        notify "Colours not updated" "matugen failed for $(basename "${r[0]}"). Details: $log"
    fi
    printf '%s\n' "$req" >"$state/done"
    exec 9>&-
done
