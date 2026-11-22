pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "primitive"
import "variables.js" as Vars

// The colours on screen under the dials: one average colour per spot, measured from a tiny
// screenshot (grim) taken while no dial is open, so no dial is in it. Roles.qml paints the
// Glass colours from the spot of the dial that's open: its surfaces are the colour under
// it, and its ink and picked things turn dark over a light area and white over a dark one,
// as Apple's glass does. Taken again a moment after the windows change, and every few
// seconds while the dials are closed (the same pace as liquid glass's Snapshot).
QtObject {
    id: root

    // ── what Roles reads ── the colour under the open dial (or the last one opened), and
    // whether it's light
    readonly property color color: _colors[spot] ?? _fallback
    readonly property bool light: luminance(color) > Vars.design.underneath.lightAbove

    // the spot of the dial that's open; it stays on the last one while all are closed, so a
    // closing dial keeps its colours
    property string spot: "bottom"

    // until the first measure: dark, as the shell has always been
    readonly property color _fallback: Qt.rgba(0.1, 0.1, 0.1, 1)
    property var _colors: ({})

    function luminance(c) { return 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b }

    readonly property bool _on: Prefs.tileStyle === "glass"

    // which dial is open: any dial grown past its closed size
    readonly property string _openSpot: {
        Dials.revision
        for (const name in Dials.dials) {
            const d = Dials.dials[name]
            if (d && d.currentSize > d.collapsedSize + 0.5) return Dials.spotOf(name)
        }
        return ""
    }
    on_OpenSpotChanged: if (_openSpot !== "") spot = _openSpot

    // ── measuring ── the screen at a tenth of its size; around each spot, a square as wide
    // as a big dial (cut to the screen), averaged to one pixel
    function measure() {
        const s = Dials.screen
        if (!_on || !s || _openSpot !== "" || _measurer.running) return
        const k = Vars.design.underneath.scale, r = Vars.design.underneath.radius * k
        const w = Math.round(s.width * k), h = Math.round(s.height * k)
        const crops = []
        for (const spot of Dials.spots) {
            const p = Dials.spotPoint(spot, w, h)
            const x0 = Math.max(0, Math.round(p.x - r)), y0 = Math.max(0, Math.round(p.y - r))
            const x1 = Math.min(w, Math.round(p.x + r)), y1 = Math.min(h, Math.round(p.y + r))
            crops.push(spot + " " + (x1 - x0) + "x" + (y1 - y0) + "+" + x0 + "+" + y0)
        }
        _measurer.exec(["sh", "-c",
            'f=$(mktemp --suffix=.ppm) && grim -o "$1" -s "$2" -t ppm "$f" && shift 2 && '
            + 'while [ $# -gt 0 ]; do printf "%s " "$1"; magick "$f" -crop "$2" +repage -resize "1x1!" -format "%[hex:p{0,0}]\\n" info:; shift 2; done; rm -f "$f"',
            "sh", s.name, String(k)].concat(crops.join(" ").split(" ")))
    }
    property Process _measurer: Process {
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {}
                for (const line of text.split("\n")) {
                    const m = line.trim().match(/^(\w+) ([0-9A-Fa-f]{6})/)
                    if (m) out[m[1]] = "#" + m[2]
                }
                if (Object.keys(out).length > 0) root._colors = out
            }
        }
    }

    // when to measure: a moment after the windows change, every few seconds while all
    // dials are closed, and as Glass colours come on
    property Timer _settle: Timer {
        interval: Vars.liquid.windowsSettle
        onTriggered: root.measure()
    }
    property Timer _refresh: Timer {
        interval: Math.max(1000, Vars.liquid.windowsRefresh)
        running: root._on && root._openSpot === ""
        repeat: true
        triggeredOnStart: true
        onTriggered: root.measure()
    }
    property Connections _hypr: Connections {
        target: Hyprland
        enabled: root._on
        function onRawEvent(event) { if (Backdrop._windowEvents.indexOf(event.name) >= 0) root._settle.restart() }
    }
}
