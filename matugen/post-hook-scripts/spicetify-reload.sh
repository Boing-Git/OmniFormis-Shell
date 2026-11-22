#!/usr/bin/env bash
# Spotify takes the new color.ini (Themes/M3E/color.ini, a link to the generated one).
# The theme is named every time: an old hook switched it to the removed "text" theme, and
# `spicetify apply` / `refresh` then abort with 'Theme "text" not found'.
# Restarting Spotify is what shows the colours, so it only happens while Spotify is open
# and not playing: never mid-song, and never launching a closed Spotify (it takes the
# colours when it next starts).
spicetify -q config current_theme M3E color_scheme MaterialYou || exit 1
restart=-n
if playerctl -l 2>/dev/null | grep -q '^spotify' && [ "$(playerctl -p spotify status 2>/dev/null)" != Playing ]; then
    restart=
fi
exec timeout 60 spicetify -q $restart refresh
