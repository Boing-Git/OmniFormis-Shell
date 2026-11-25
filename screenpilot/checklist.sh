#!/bin/sh
# screenpilot's manual checks: what only a person at the desktop can confirm. Each check says
# what to do (and runs the command it can); answer y (works), n (doesn't) or s (skip).
# The answers go to ~/.local/state/screenpilot/checklist-<time>.txt.
#
# Before: the service runs (systemctl --user status screenpilot), and a model answers:
# `ollama pull qwen3-vl:8b` for local, or ANTHROPIC_API_KEY=... in ~/.config/screenpilot/env
# (then `systemctl --user restart screenpilot`) and `screenpilot backend claude`.

OUT="${XDG_STATE_HOME:-$HOME/.local/state}/screenpilot/checklist-$(date +%Y%m%d-%H%M).txt"
mkdir -p "$(dirname "$OUT")"
pass=0 fail=0 skip=0

check() {  # check "name" "what to do" [command to run first]
    printf '\n\033[1m%s\033[0m\n%s\n' "$1" "$2"
    if [ -n "$3" ]; then printf '  $ %s\n' "$3"; sh -c "$3"; fi
    while :; do
        printf '  works? [y/n/s] '
        read -r a </dev/tty
        case "$a" in
            y) pass=$((pass + 1)); echo "PASS  $1" >> "$OUT"; return ;;
            n) fail=$((fail + 1)); printf '  what happened? '; read -r why </dev/tty; echo "FAIL  $1: $why" >> "$OUT"; return ;;
            s) skip=$((skip + 1)); echo "SKIP  $1" >> "$OUT"; return ;;
        esac
    done
}

echo "screenpilot checklist, $(date)" > "$OUT"
screenpilot resume >/dev/null 2>&1
check "Service" "It says idle (or halted), the backend and the mode." "screenpilot status"

echo; echo "── capture and speech ──"
check "Capture" "Open the PNG it prints: your screen, at most 1568 px wide." "screenpilot shot"
check "Capture: active window" "The PNG shows only the window that has the focus." "screenpilot shot --mode window"
check "Blocklist" "Open a password manager (KeePassXC, Bitwarden...) on screen first: the shot is refused." "screenpilot shot"
check "Speech" "You hear the sentence (and no stars or backticks read out)." "screenpilot say 'Screenpilot can **talk**. \`not this\`'"
check "Speech: STOP cuts it" "Say starts a long sentence; the stop a second later cuts it off." \
    "screenpilot say 'This is a long sentence that keeps going and going so that stop can cut it off in the middle.'; sleep 1.5; screenpilot stop; screenpilot resume"
check "Speech: the selection" "Select some text anywhere, then press Super + Alt + S: it is read out."

echo; echo "── ASK ──"
check "ASK by keybind" "Super + Shift + A, type a question about what's on screen, Enter: an answer card top-right, spoken."
check "ASK by command" "The answer fits what is on your screen." "screenpilot ask 'what app has the focus, and what is it showing?'"
check "Backend switch" "Flip Settings → Extras → Screen AI: Claude in your shell, then:" "screenpilot backend"

echo; echo "── sandbox mode ──"
screenpilot mode sandbox >/dev/null
check "Sandbox shows" "Super + Alt + A shows the AI's desktop (a nested sway), again hides it." "screenpilot sandbox start"
check "Sandbox app" "A terminal opens inside the sandbox (Super + Alt + A to look)." "screenpilot sandbox run foot"
check "STOP button" "Start a run (Super + Alt + D, 'open a terminal and type hello'). While the red STOP shows top-right, click it: HALTED."
check "Resume" "Super + Shift + Escape: the status says idle again." "sleep 3; screenpilot status"
check "ACT in the sandbox" "Super + Alt + D: 'type hello in the terminal'. A first-action Yes/No appears top-right: Yes. Watch it in the sandbox (Super + Alt + A)."
check "STOP keybind" "Start another run, then press Super + Escape: HALTED at once. Then Super + Shift + Escape."
check "STOP keybind in a submap" "Hyprland is now in a test submap where only Escape does anything (it leaves by itself after 20 s). A run is starting: press Super + Escape: HALTED. Then Escape." \
    "hyprctl eval 'hl.define_submap(\"screenpilot_check\", function() hl.bind(\"Escape\", hl.dsp.submap(\"reset\")) end)' >/dev/null; (sleep 20; hyprctl dispatch 'hl.dsp.submap(\"reset\")' >/dev/null) & screenpilot act 'take a screenshot, wait, and take another' >/dev/null 2>&1 & sleep 1; hyprctl dispatch 'hl.dsp.submap(\"screenpilot_check\")' >/dev/null"
check "Your cursor untouched" "During a sandbox run your own mouse pointer never moved."

echo; echo "── shared mode (on your desktop) ──"
screenpilot mode shared >/dev/null
check "AI cursor and click" "Open a text editor, then Super + Alt + D: 'click in the editor and type hello'. A cyan AI arrow glides there first; the text appears; your pointer comes back where it was."
check "Right-click" "Super + Alt + D: 'right-click the editor's text area': its context menu opens, then 'press Escape'."
check "Key combo" "Super + Alt + D: 'select all the text in the editor with the keyboard'."
check "Yield to you" "Start a longer run, then move your mouse: the STOP pill says paused; stop for 1.5 s and it carries on."
check "Risky asks first" "Super + Alt + D: 'delete the text in the editor': a Yes/No appears; No ends the run."
check "STOP keybind (shared)" "Start a run, press Super + Escape: HALTED, nothing stays pressed (try clicking and typing yourself)."
check "STOP button can't be clicked by the AI" "Super + Alt + D: 'click the red STOP button'. It is refused (the AI is told so); the run doesn't stop by itself clicking."
screenpilot mode sandbox >/dev/null

printf '\n%s passed, %s failed, %s skipped: %s\n' "$pass" "$fail" "$skip" "$OUT"
