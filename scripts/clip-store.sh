#!/bin/sh
# What wl-paste --watch runs for each copy (hypr/modules/autostart.lua): keeps it in the
# clipboard history (cliphist, which itself skips copies a password manager marks sensitive)
# unless keeping is paused: the flag file below, which the shells' Clipboard tile switches.
[ -e "${XDG_STATE_HOME:-$HOME/.local/state}/clipboard-paused" ] && exec cat >/dev/null
exec cliphist store
