#!/usr/bin/env bash

hyprctl reload;

# Stop the old watchdog loop first and actually wait for it to exit before starting a new one.
# A fixed sleep here used to race the old watchdog's own cleanup against the new watchdog below:
# on some toggles the old one's delayed SIGTERM cleanup (or its loop spawning another quickshell
# right before noticing the signal) landed *after* the new watchdog had already launched a fresh
# quickshell, killing the instance we just started — "the shell doesn't appear" after toggling
# game mode off and back on.
pkill -TERM -f qs-watchdog.sh
for i in $(seq 1 50); do
    pgrep -f qs-watchdog.sh >/dev/null || break
    sleep 0.1
done
pkill -9 -f qs-watchdog.sh 2>/dev/null

pkill -9 quickshell
pkill -9 .quickshell-wra

if command -v python3 >/dev/null 2>&1; then
    python3 /home/boing/Dotfiles/scripts/extract_steam_games.py
fi

nohup bash /home/boing/Dotfiles/quickshell/scripts/qs-watchdog.sh >/dev/null 2>&1 &
disown
