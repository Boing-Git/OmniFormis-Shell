pragma Singleton
import QtQuick
import Quickshell
import "../theme"

// Applies a setting the cheapest way that still takes effect, instead of restarting the shell
// for every change. Nothing here is a per-variable list, the decision is derived at runtime:
//
//   Quickshell variable exposed as a property of Vars  -> live: set on Vars right away
//                                                         (components bind to Vars, so they update)
//   Quickshell variable Vars does not expose           -> nothing binds to it live, so the shell
//                                                         must be reloaded to pick it up
//   Hyprland variable                                  -> `hyprctl reload`, the shell keeps running
//
// Every change is also persisted through the omniformis CLI. Writes are debounced and sent as a
// single ordered batch, so dragging a slider doesn't spawn a process per pixel.
QtObject {
    id: root

    property int debounceMs: 250

    // Quickshell variables that are live in Vars (no shell reload needed) but that Hyprland's own
    // Lua config *also* reads straight out of quickshell/theme/variables.js — e.g. deco.lua's
    // isFramed() check on panelStyle (zeroes window rounding in "Framed" style) and animations.lua's
    // pillPosition check (picks the slide direction). Without this, those keys looked fully live
    // from the Quickshell side and never got a `hyprctl reload`, so Hyprland's half stayed stale
    // until something else happened to trigger one. Add a key here whenever a new Hyprland Lua
    // module starts reading variables.js for it.
    property var hyprDependentKeys: ({ "panelStyle": true, "pillPosition": true })

    // "<source>:<key>" -> { source, key, value, needsShell }; the latest value per key wins
    property var _pending: ({})

    function _source(source) {
        var s = String(source || "").toLowerCase();
        return (s === "qs" || s === "quickshell") ? "qs" : "hypr";
    }

    // A Quickshell variable is live when the running shell exposes it on Vars.
    function isLive(key) {
        var value;
        try {
            value = Vars[key];
        } catch (e) {
            return false;
        }
        if (typeof value === "function")
            return false;
        if (value !== undefined)
            return true;
        // A property that currently holds undefined still exists on the object
        try {
            return key in Vars;
        } catch (e) {
            return false;
        }
    }

    // Coerce to the type the live property already has, so "1" stays a string for a string property
    // and "true" becomes a real boolean for a bool one.
    function _typed(key, value) {
        var current = Vars[key];
        switch (typeof current) {
        case "boolean":
            return value === true || String(value) === "true";
        case "number":
            var n = Number(value);
            return isNaN(n) ? current : n;
        case "string":
            return String(value);
        default:
            if (typeof value === "string") {
                try { return JSON.parse(value); } catch (e) {}
            }
            return value;
        }
    }

    // source: "qs" | "quickshell" | "hypr" (anything else counts as Hyprland)
    function set(source, key, value) {
        var src = _source(source);
        var live = false;
        if (src === "qs" && isLive(key)) {
            try {
                Vars.setLive(key, _typed(key, value));
                live = true;
            } catch (e) {
                console.warn("SettingsApply: live update of " + key + " failed: " + e);
            }
        }
        var pending = root._pending;
        pending[src + ":" + key] = {
            source: src,
            key: key,
            value: String(value),
            needsShell: src === "qs" && !live,
            needsHypr: src === "qs" && !!root.hyprDependentKeys[key]
        };
        root._pending = pending;
        flushTimer.restart();
    }

    function flush() {
        var args = [];
        var needsShell = false;
        var needsHypr = false;
        for (var id in root._pending) {
            var p = root._pending[id];
            args.push(p.source, p.key, p.value);
            needsShell = needsShell || p.needsShell;
            needsHypr = needsHypr || p.source === "hypr" || p.needsHypr;
        }
        root._pending = ({});
        if (args.length === 0)
            return;

        // reload.sh already reloads Hyprland, so a shell reload covers a Hyprland one
        var mode = needsShell ? "shell" : (needsHypr ? "hypr" : "none");
        var script = 'mode="$1"; shift; ' +
            'bin="$HOME/.local/bin/omniformis"; [ -x "$bin" ] || bin=omniformis; ' +
            'while [ "$#" -ge 3 ]; do "$bin" "$1" set "$2" "$3" >/dev/null 2>&1; shift 3; done; ' +
            'case "$mode" in ' +
            'hypr) hyprctl reload >/dev/null 2>&1 ;; ' +
            'shell) nohup bash "$HOME/Dotfiles/scripts/reload.sh" >/dev/null 2>&1 & ;; ' +
            'esac';
        Quickshell.execDetached({ command: ["bash", "-c", script, "omniformis-apply", mode].concat(args) });
    }

    property Timer flushTimer: Timer {
        interval: root.debounceMs
        repeat: false
        onTriggered: root.flush()
    }
}
