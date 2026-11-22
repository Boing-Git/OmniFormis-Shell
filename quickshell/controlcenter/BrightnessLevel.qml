import QtQuick
import Quickshell.Io

Item {
    id: root

    property string backend: ""
    property int bus: -1
    property real maxRaw: 100

    readonly property bool available: backend !== ""
    // Default to 0.5 (50%) on startup for DDC since we can't read the real value
    property real value: 0.5
    property bool locked: false
    readonly property bool muted: false

    readonly property string icon: locked ? "lock"
        : value < 0.34 ? "brightness_low"
        : value < 0.67 ? "brightness_medium" : "brightness_high"

    Component.onCompleted: finder.running = true

    // ── the backlight's file (laptops) ── the kernel rewrites it on every change, ours
    // or anyone's (brightness keys, another tool): read it again then, so the level is
    // always the real one and a change from elsewhere shows up (the brightness OSD)
    property string device: ""
    readonly property string sysfsPath: device !== "" ? "/sys/class/backlight/" + device + "/actual_brightness" : ""
    FileView {
        path: root.sysfsPath
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            if (writer.running || root._pending) return      // our own write is in flight
            const now = parseInt(text().trim())
            if (isNaN(now) || now < 0) return
            const v = now / root.maxRaw
            if (Math.abs(v - root.value) > 0.5 / root.maxRaw) root.value = v
        }
    }

    Process {
        id: finder
        command: ["sh", "-c", "brightnessctl -m -c backlight info 2>/dev/null && exit 0; "
                            + "ddcutil detect --brief 2>/dev/null | grep -o '/dev/i2c-[0-9]*' | head -n 1 | sed 's/^/ddc /'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const t = this.text.trim()
                const m = t.match(/^ddc \/dev\/i2c-(\d+)/)
                if (m) {
                    root.bus = parseInt(m[1])
                    root.backend = "ddc"
                    // Do not call refresh() for DDC; Samsung G4 always reports 0
                    return
                }
                const f = t.split("\n")[0].split(",")
                if (f.length >= 5 && f[1] === "backlight") {
                    root.maxRaw = Math.max(1, parseInt(f[4]))
                    root.value = parseInt(f[2]) / root.maxRaw
                    root.device = f[0]
                    root.backend = "backlight"
                }
            }
        }
    }

    // ── reading (only used for laptop backlights now) ──
    property int _writes: 0

    function refresh() {
        if (backend === "ddc") return
        locked = false
        read(false)
    }

    function read(check) {
        if (backend !== "backlight" || writer.running || reader.running) return
        reader.command = ["brightnessctl", "-m", "-c", "backlight", "info"]
        reader.startedAt = _writes
        reader.check = check
        reader.running = true
    }

    Process {
        id: reader
        property int startedAt: 0
        property bool check: false
        stdout: StdioCollector {
            onStreamFinished: {
                if (writer.running || reader.startedAt !== root._writes) return
                const t = this.text.trim()
                const f = t.split(",")
                if (f.length < 5) return
                
                root.maxRaw = Math.max(1, parseInt(f[4]))
                const now = parseInt(f[2])
                if (now < 0) return

                if (reader.check) root.locked = Math.abs(now - Math.round(root._target * root.maxRaw)) > 1
                root.value = now / root.maxRaw
            }
        }
    }

    // ── writing ──
    property real _target: 0.5
    property bool _pending: false

    function set(v) {
        if (!available) return
        _target = Math.max(0, Math.min(1, v))
        _writes++
        value = _target
        if (writer.running) _pending = true
        else write()
    }

    function write() {
        _pending = false
        const raw = Math.round(_target * maxRaw)
        writer.command = backend === "ddc"
            ? ["ddcutil", "--bus", String(bus), "--noverify", "setvcp", "10", String(raw)]
            : ["brightnessctl", "-q", "-c", "backlight", "set", String(raw)]
        writer.running = true
    }

    Process {
        id: writer
        onExited: {
            if (root._pending) root.write()
            // Only verify after write if using a laptop backlight
            else if (root.backend === "backlight") checkTimer.restart()
        }
    }

    Timer {
        id: checkTimer
        interval: 400
        onTriggered: if (!writer.running) root.read(true)
    }
}
