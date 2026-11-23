#!/usr/bin/env bash
# What liquid glass costs: the running shell's CPU and GPU, and Hyprland's GPU, at rest and
# with the control center open, so a change to the glass is measured, not guessed.
#   glass-bench.sh [seconds per phase, default 10]      (opens and closes the control center)
set -u
secs=${1:-10}
id=$(qs list --all | sed -n 's/^Instance \(.*\):$/\1/p' | head -1)
pid=$(qs list --all | sed -n 's/^ *Process ID: //p' | head -1)
hz=$(getconf CLK_TCK)
cpu() { awk '{print $14 + $15}' "/proc/$pid/stat"; }

phase() {
    local t0 t1 gpu
    t0=$(cpu)
    # one sample a second: sm is the share of the GPU's cores, fb its memory
    gpu=$(nvidia-smi pmon -c "$secs" -s um 2>/dev/null | awk -v p="$pid" '
        $2 == p { sm += ($4 == "-" ? 0 : $4); fb = $10; n++ }
        $NF == "Hyprland" { hs += ($4 == "-" ? 0 : $4); hn++ }
        END { printf "qs gpu %4.1f%% (%s MB) | Hyprland gpu %4.1f%%", n ? sm / n : 0, fb, hn ? hs / hn : 0 }')
    t1=$(cpu)
    printf "%-6s qs cpu %5.1f%% | %s\n" "$1" "$(echo "($t1 - $t0) * 100 / $hz / $secs" | bc -l)" "$gpu"
}

echo "Sees: $(qs ipc -i "$id" call prefs get liquidSees), glass: $(qs ipc -i "$id" call prefs get liquidGlass)"
phase rest
qs ipc -i "$id" call center open >/dev/null
sleep 1
phase open
qs ipc -i "$id" call center close >/dev/null
