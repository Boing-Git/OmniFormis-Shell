#!/usr/bin/env bash

hyprctl reload; 

pkill -9 quickshell
pkill -9 .quickshell-wra
pkill -f qs-watchdog

if command -v python3 >/dev/null 2>&1; then
    python3 /home/boing/Dotfiles/scripts/extract_steam_games.py
fi

sleep 0.5
nohup bash /home/boing/Dotfiles/quickshell/scripts/qs-watchdog.sh >/dev/null 2>&1 &
disown