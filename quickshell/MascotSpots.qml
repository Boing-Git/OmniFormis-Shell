pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "variables.js" as Vars

// Where you put the mascots: each dragged along the inside of its ring and left there. A
// spot is a share of the way along the dial's visible arc (0 its start, 1 its end), so it
// stays sensible when the dial moves to another corner. NaN: never moved (the default spot).
// Kept in Vars.mascotSpotsPath.
Singleton {
    id: root

    // name ("center", "lock") → share along the arc
    property var spots: ({})

    function spotOf(name) { const v = spots[name]; return typeof v === "number" ? v : NaN }

    function put(name, share) {
        const next = Object.assign({}, spots)
        next[name] = Math.max(0, Math.min(1, share))
        spots = next
        _writer.exec(["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s\\n" "$2" > "$1.tmp" && mv "$1.tmp" "$1"',
                      "sh", Vars.mascotSpotsPath, JSON.stringify(spots)])
    }

    property Process _writer: Process {}
    property FileView _file: FileView {
        path: Vars.mascotSpotsPath
        printErrors: false
        onLoaded: { try { const o = JSON.parse(text()); if (o && typeof o === "object") root.spots = o } catch (e) {} }
    }
}
