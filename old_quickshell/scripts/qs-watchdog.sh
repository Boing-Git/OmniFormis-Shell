#!/usr/bin/env bash
# Quickshell watchdog - auto-restarts on crash (Qt6+NVIDIA scene graph bug)
# This handles the known derefWindow segfault during monitor hot-plug events.

QS_PID=""

cleanup() {
    echo "[qs-watchdog] Terminated. Killing Quickshell..."
    if [[ -n "$QS_PID" ]]; then
        kill "$QS_PID" 2>/dev/null
        wait "$QS_PID" 2>/dev/null
    fi
    pkill -x quickshell 2>/dev/null
    pkill -x .quickshell-wra 2>/dev/null
    exit 0
}

trap cleanup SIGTERM SIGINT SIGHUP

RESTART_DELAY=1
MAX_RAPID_RESTARTS=5
RAPID_WINDOW=10 # seconds

declare -a restart_times=()

while true; do
    # Clean up stale processes
    pkill -x quickshell 2>/dev/null
    pkill -x .quickshell-wra 2>/dev/null
    sleep 0.3

    # RAM Optimization (glibc Tuning) to reduce virtual memory footprint
    export MALLOC_ARENA_MAX=2
    export MALLOC_MMAP_THRESHOLD_=131072

    # Dynamic Hertz Detection & Syncing
    # Fetch primary monitor refresh rate (or first available)
    HZ=$(hyprctl monitors -j 2>/dev/null | grep -o '"refreshRate": [0-9.]*' | head -n 1 | awk '{print $2}')
    HZ=${HZ:-60} # default to 60 if failed
    HZ_ROUND=$(printf "%.0f" "$HZ")
    TICK=$(( 1000 / HZ_ROUND ))
    
    export QML_DEFAULT_ANIMATION_TICK=$TICK
    export QSG_RENDER_LOOP=wayland
    export QSG_IMAGE_CACHE_LIMIT=33554432 # Limit internal QML image caching to 32MB
    
    # VRR (Variable Refresh Rate / FreeSync / G-Sync) Compatibility
    # Disable OpenGL driver-level VSync blocking. This allows the Wayland compositor
    # to dynamically control the frame pacing (VRR) via frame callbacks without 
    # the GPU driver causing internal stuttering or locking the refresh rate.
    export vblank_mode=0
    export __GL_SYNC_TO_VBLANK=0

    echo "[qs-watchdog] Starting Quickshell at ${HZ_ROUND}Hz (Tick: ${TICK}ms, VRR: Enabled)..."

    quickshell -p /home/boing/Dotfiles/quickshell > /tmp/quickshell.log 2>&1 &
    QS_PID=$!

    # Wait for it to exit
    wait $QS_PID
    EXIT_CODE=$?
    QS_PID=""

    # Only restart on real crash signals:
    # 139 = SIGSEGV, 134 = SIGABRT, 133 = SIGTRAP, 135 = SIGBUS
    if [[ "$EXIT_CODE" != "139" && "$EXIT_CODE" != "134" && "$EXIT_CODE" != "133" && "$EXIT_CODE" != "135" ]]; then
        echo "[qs-watchdog] Quickshell exited with code $EXIT_CODE (not a crash). Stopping watchdog."
        break
    fi

    NOW=$(date +%s)

    # Track rapid restarts to avoid infinite crash loops
    restart_times+=("$NOW")
    new_times=()
    for t in "${restart_times[@]}"; do
        if (( NOW - t < RAPID_WINDOW )); then
            new_times+=("$t")
        fi
    done
    restart_times=("${new_times[@]}")

    if (( ${#restart_times[@]} >= MAX_RAPID_RESTARTS )); then
        echo "[qs-watchdog] Too many rapid crashes (${#restart_times[@]} in ${RAPID_WINDOW}s). Stopping."
        break
    fi

    echo "[qs-watchdog] Quickshell crashed (exit code $EXIT_CODE). Restarting in ${RESTART_DELAY}s..."
    sleep $RESTART_DELAY
done
