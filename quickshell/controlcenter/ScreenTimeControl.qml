import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../primitive"
import "../variables.js" as Vars

// The Screen time control of the control center: how long each app had you today, from the
// tracker every shell shares (../scripts/screentime.py). The inner ring has a pill per app,
// longest first (a click opens it); the card in the middle says the one at the mark: today
// and the last seven days, or the day in all when none is. The tile reads the numbers again;
// Settings → Extras → Screen time stops the counting (every shell's switch) and hides this.
// ControlCenter.qml uses `control`.
Item {
    id: st

    required property var dial

    // ★ the card's and the dial's sizes while this is selected: controlcenter/ReaderSettings.qml ★
    readonly property var cfg: ReaderSettings { liveSize: st.dial.expandedSize; sweepDeg: st.dial.sweepDeg }

    readonly property bool active: dial.open && !!dial.currentControl && dial.currentControl.key === "screentime"
    onActiveChanged: if (active) _reader.running = true

    // { on, days: [{ date, apps: { class: seconds } }] }, today first
    property var usage: ({ on: true, days: [] })
    property Process _reader: Process {
        command: [Quickshell.shellDir + "/../scripts/screentime.py", "json", "7"]
        stdout: StdioCollector { onStreamFinished: { try { st.usage = JSON.parse(text) } catch (e) {} } }
    }

    readonly property var today: usage.days.length > 0 ? usage.days[0].apps : ({})
    readonly property var apps: Object.keys(today).sort((a, b) => today[b] - today[a])
    function week(cls) { return usage.days.reduce((a, d) => a + (d.apps[cls] || 0), 0) }
    readonly property real total: Object.values(today).reduce((a, b) => a + b, 0)

    // a window class as the app it belongs to (its name and icon)
    function entryOf(cls) { return DesktopEntries.heuristicLookup(cls) }
    function nameOf(cls) { const e = entryOf(cls); return e ? e.name : cls }
    function pretty(s) {
        const m = Math.floor(s / 60)
        return m >= 60 ? Math.floor(m / 60) + " h " + (m % 60) + " min" : m >= 1 ? m + " min" : "< 1 min"
    }

    readonly property string atMark: active ? (apps[dial.innerIndex] || "") : ""

    property Component corner: Component {
        ReaderCard {
            dial: st.dial
            cfg: st.cfg
            readonly property string cls: st.atMark
            readonly property var e: cls !== "" ? st.entryOf(cls) : null
            shape: cls !== "" ? Apps.shapeFor(e ? e.id : cls) : "Circle"
            fill: cls !== "" ? Roles.secondary_container : Roles.surface_container_high
            ink: cls !== "" ? Roles.on_secondary_container : Roles.on_surface_variant
            image: e && e.icon ? Quickshell.iconPath(e.icon, true) : ""
            symbol: cls !== "" ? "apps" : st.usage.on ? "hourglass_top" : "hourglass_disabled"
            note: cls !== "" ? "Today" : st.usage.on ? "Today, in all" : "Not counting"
            title: cls !== "" ? st.nameOf(cls) + "  ·  " + st.pretty(st.today[cls]) : st.pretty(st.total)
            body: cls !== "" ? st.pretty(st.week(cls)) + " in the last 7 days. Click it to open it."
                : st.apps.length === 0 ? (st.usage.on ? "Nothing yet today." : "Settings → Extras → Screen time starts it again.")
                : st.apps.slice(0, 4).map(c => st.nameOf(c) + "  " + st.pretty(st.today[c])).join("\n")
        }
    }

    readonly property var control: ({
        key: "screentime",
        label: "Screen time",
        icon: st.usage.on ? "hourglass_top" : "hourglass_disabled",
        shape: "Pill",
        shapeSelected: "SoftBurst",

        // on = counting; the tile reads the numbers again
        on: st.usage.on,
        toggle: () => { st._reader.running = true },
        size: st.cfg.dialSize,
        dateIcon: false,
        corner: st.corner,
        settings: st.cfg.controlCenter,

        // a pill per app used today, longest first
        devices: () => st.apps.slice(0, 16).map(c => ({
            label: st.nameOf(c) + "  " + st.pretty(st.today[c]),
            icon: "apps",
            shape: "Circle",
            on: false,
            status: "none",
            activate: () => { const e = st.entryOf(c); if (e) e.execute() }
        }))
    })
}
