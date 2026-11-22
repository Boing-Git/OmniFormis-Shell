#!/usr/bin/env bash
# After a resume (hypridle's after_sleep_cmd): once the screens and the shell have settled,
# keeps what Hyprland and the shell logged and which surfaces exist, in
# $XDG_STATE_HOME/resume-logs/<time>/. Their own logs live in /run and are gone after the
# reboot that a resume gone wrong usually ends in, so this is the evidence that survives.
#   resume-report.sh [seconds to wait, default 20]
sleep "${1:-20}"
dir="${XDG_STATE_HOME:-$HOME/.local/state}/resume-logs/$(date +%F_%H-%M-%S)"
mkdir -p "$dir"
hyprctl monitors -j >"$dir/monitors.json" 2>&1
hyprctl layers -j >"$dir/layers.json" 2>&1
hyprctl rollinglog >"$dir/hyprland.log" 2>&1
awww query >"$dir/awww.txt" 2>&1
for id in $(qs list --all 2>/dev/null | sed -n 's/^Instance \(.*\):$/\1/p'); do
    qs log -i "$id" 2>&1 | tail -n 400 >"$dir/qs-$id.log"
done
journalctl -b --since "-10 min" --no-pager >"$dir/journal.txt" 2>&1

# the last 5 resumes are plenty
ls -1dt "${dir%/*}"/*/ | tail -n +6 | xargs -r rm -rf
