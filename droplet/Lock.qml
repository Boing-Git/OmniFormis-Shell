import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam

// Droplet's lock screen: the time, and under it a string of drops, one per letter typed,
// joined like water (Goo). A wrong password makes them drip away; the right one runs them
// together into one drop in the middle, and the lock opens.
//
// It locks from hypridle and the Lock circle (scripts/shell lock -> `qs ipc call lock lock`),
// and again at once if Droplet is started after a crash while this Hyprland session was
// locked (a note in ~/.local/state/droplet/locked carries the session's signature). There is
// no unlock call: only the password opens it.
Scope {
    id: root

    property bool locked: false
    property string password: ""
    readonly property int count: Array.from(password).length
    // the most drops shown since the row was last empty: deleted ones stay a moment, to go
    // back into the one before them
    property int peak: 0
    onCountChanged: { if (count > peak) peak = count; else if (count === 0) peakReset.restart() }
    Timer { id: peakReset; interval: 900; onTriggered: if (root.count === 0) root.peak = 0 }
    property bool checking: false
    property bool wrong: false      // the drops are dripping away
    property bool opening: false    // right: the drops run together, then it opens
    property string note: ""

    // PAM's own files; DROPLET_PAM_DIR lets a test session use a test password
    readonly property string pamDir: Quickshell.env("DROPLET_PAM_DIR") || "/etc/pam.d"
    readonly property string session: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || ""
    readonly property string notePath: Quickshell.env("HOME") + "/.local/state/droplet/locked"

    function lock() {
        if (locked) return
        password = ""; checking = false; wrong = false; opening = false; note = ""
        locked = true
        remember(true)
    }

    function key(event) {
        if (checking || opening) return
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { submit(); return }
        if (event.key === Qt.Key_Escape || (event.key === Qt.Key_U && (event.modifiers & Qt.ControlModifier))) { password = ""; return }
        if (event.key === Qt.Key_Backspace) { password = Array.from(password).slice(0, -1).join(""); return }
        if (event.text !== "" && event.text.charCodeAt(0) >= 32) { wrong = false; note = ""; password += event.text }
    }

    property string _answer: ""
    function submit() {
        if (count === 0 || checking) return
        _answer = password
        checking = true
        pam.start()
    }
    PamContext {
        id: pam
        config: "system-auth"
        configDirectory: root.pamDir
        // the only question asked is the password
        onPamMessage: { if (pam.responseRequired) { pam.respond(root._answer); root._answer = "" } }
        onCompleted: result => {
            root.checking = false
            if (result === PamResult.Success) {
                root.opening = true
                openTimer.restart()
            } else {
                root.note = result === PamResult.MaxTries ? "Too many tries, wait a moment" : "Wrong password"
                root.wrong = true
                dripTimer.restart()
            }
        }
        onError: { root.checking = false; root.note = "Couldn't check the password: try again" }
    }

    // the drops drip away, then the row is empty for the next try
    Timer { id: dripTimer; interval: 900; onTriggered: { root.password = ""; root.wrong = false } }

    // the drops have run together: open
    Timer {
        id: openTimer
        interval: 520
        onTriggered: { root.locked = false; root.password = ""; root.opening = false; root.remember(false) }
    }

    // the note for a Droplet started after a crash
    Process { id: noter }
    function remember(on) {
        if (on && session !== "")
            noter.exec(["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"', "sh", notePath, session])
        else noter.exec(["rm", "-f", notePath])
    }
    FileView {
        path: root.notePath
        printErrors: false
        onLoaded: if (root.session !== "" && text().trim() === root.session) root.lock()
    }

    IpcHandler {
        target: "lock"
        function lock(): void { root.lock() }
        function isLocked(): bool { return root.locked }
    }

    WlSessionLock {
        locked: root.locked

        WlSessionLockSurface {
            id: surface
            color: Colors.surface

            SystemClock { id: clock; precision: SystemClock.Minutes }

            Text {
                id: time
                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.32
                text: Qt.formatTime(clock.date, "h:mm")
                font.pixelSize: 132
                font.weight: 300
                color: Colors.on_surface
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: time.bottom
                text: Qt.formatDate(clock.date, "dddd d MMMM")
                font.pixelSize: 22
                color: Colors.on_surface_variant
            }

            // ── the drops ── a row under the time. A new one buds out of the drop before it
            // (Goo: the neck stretches and pinches off as it reaches its place); a deleted one
            // springs back into it; a wrong password drips them away one by one; the right
            // one runs them together into one drop
            Item {
                id: row
                width: parent.width
                height: 120
                y: parent.height * 0.62
                readonly property real gap: 30
                readonly property real r: 10
                property color fill: root.wrong ? Colors.error : root.checking ? Colors.tertiary : Colors.primary
                Behavior on fill { ColorAnimation { duration: 160 } }

                // where the newest drop rests (the mascot follows it)
                readonly property real endX: width / 2 + (root.opening ? 0 : (root.count - 1) / 2 * gap)

                Repeater {
                    id: drops
                    model: root.peak

                    Item {
                        id: drop
                        required property int index
                        anchors.fill: parent

                        // still in the password (false: going back into the one before it)
                        readonly property bool alive: index < root.count
                        // its place: in the row, centred; all in the middle while it opens
                        readonly property real homeX: row.width / 2 + (root.opening ? 0 : (index - (root.count - 1) / 2) * row.gap)
                        // the one before it: it buds out of that one and goes back into it
                        property Item prev: null
                        readonly property real cx: px.value
                        readonly property real cy: row.height / 2 + fall.y
                        readonly property real r: row.r * Math.max(0, grow.value) * pulse.k

                        SpringValue {
                            id: px
                            to: drop.alive ? drop.homeX : (drop.prev ? drop.prev.cx : row.width / 2)
                            stiffness: 300
                            dampingRatio: 0.62
                            epsilon: 0.05
                        }
                        SpringValue { id: grow; to: drop.alive ? 1 : 0; stiffness: 420; dampingRatio: 0.55; epsilon: 0.002 }
                        Component.onCompleted: {
                            prev = index > 0 ? drops.itemAt(index - 1) : null
                            px.snap(prev ? prev.cx : row.width / 2)
                            grow.snap(prev ? 0.6 : 0)
                            // (a snap stops a spring; its target hasn't changed, so set it off)
                            px.start()
                            grow.start()
                        }
                        onAliveChanged: if (alive) { fall.y = 0; if (prev) { px.snap(prev.cx); px.start() } }

                        // wrong: it drips down, a little after the one before it
                        QtObject { id: fall; property real y: 0 }
                        SequentialAnimation {
                            id: drip
                            PauseAnimation { duration: drop.index * 45 }
                            NumberAnimation { target: fall; property: "y"; to: 240; duration: 520; easing.type: Easing.InQuad }
                        }
                        Connections {
                            target: root
                            function onWrongChanged() { if (root.wrong && drop.alive) drip.restart() }
                        }

                        // while PAM checks, the drops breathe one after another
                        QtObject { id: pulse; property real k: 1 }
                        SequentialAnimation {
                            running: root.checking
                            loops: Animation.Infinite
                            onRunningChanged: if (!running) pulse.k = 1
                            PauseAnimation { duration: drop.index * 60 }
                            NumberAnimation { target: pulse; property: "k"; to: 1.25; duration: 300; easing.type: Easing.InOutSine }
                            NumberAnimation { target: pulse; property: "k"; to: 1; duration: 300; easing.type: Easing.InOutSine }
                        }

                        // the neck to the one before it: only while they are close (budding,
                        // going back, running together), so at rest they are drops apart
                        Goo {
                            anchors.fill: parent
                            visible: !!drop.prev && fall.y < 2 && drop.r > 1 && drop.prev.r > 1
                            ax: drop.prev ? drop.prev.cx : 0
                            ay: drop.prev ? drop.prev.cy : 0
                            ar: drop.prev ? drop.prev.r : 0
                            bx: drop.cx
                            by: drop.cy
                            br: drop.r
                            color: row.fill
                            spread: 0.6
                            snapAt: 1.3
                        }
                        Rectangle {
                            width: drop.r * 2 * (fall.y > 2 ? 0.85 : 1)
                            height: drop.r * 2 * (fall.y > 2 ? 1.3 : 1)
                            radius: width / 2
                            x: drop.cx - width / 2
                            y: drop.cy - height / 2
                            visible: drop.r > 0.5
                            color: row.fill
                            opacity: 1 - Math.min(1, fall.y / 240)
                        }
                    }
                }
            }

            // ── Droplet itself ── (Settings: Mascot) riding behind the newest drop: it looks at
            // you, and looks away while the password is typed; a bob per letter, a flinch per
            // deletion; a wrong password makes it cry, the right one makes it hop with joy. 15 s
            // with nothing typed, it dozes off
            Mascot {
                id: keeper
                width: 56
                height: 56
                SpringValue { id: keeperX; to: root.count > 0 ? row.endX + row.gap + 12 : surface.width / 2 - 28; stiffness: 260; dampingRatio: 0.6; epsilon: 0.1 }
                SpringValue { id: keeperY; to: row.y + row.height / 2 - 28 - (root.count > 0 ? 0 : 54); stiffness: 260; dampingRatio: 0.6; epsilon: 0.1 }
                Component.onCompleted: { keeperX.snap(keeperX.to); keeperY.snap(keeperY.to) }
                x: keeperX.value
                y: keeperY.value
                kind: "droplet"
                body: Colors.primary_container
                ink: Colors.on_primary_container
                eyeWhite: Colors.primary_fixed
                pupil: Colors.on_primary_fixed
                accent: Colors.primary
                visible: Settings.mascot
                asleep: idle && root.count === 0 && root.note === "" && mood === ""
                look: Qt.point(0, -0.35)
                shy: root.count > 0 && !root.wrong && !root.opening
                shySide: 1
                property bool idle: false
                Timer { id: idleClock; interval: 15000; running: root.locked; onTriggered: keeper.idle = true }
                property int lastCount: 0
                Connections {
                    target: root
                    function onCountChanged() {
                        keeper.idle = false
                        idleClock.restart()
                        if (!root.wrong && !root.opening) keeper.react(root.count > keeper.lastCount ? "type" : "delete")
                        keeper.lastCount = root.count
                    }
                    function onWrongChanged() { if (root.wrong) keeper.react("wrong") }
                    function onOpeningChanged() { if (root.opening) keeper.react("right") }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: row.y + row.height + 12
                text: root.note !== "" ? root.note : root.count === 0 ? "Type your password" : root.checking ? "Checking…" : ""
                font.pixelSize: 16
                color: root.note !== "" ? Colors.error : Colors.on_surface_variant
            }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onPressed: event => { root.key(event); event.accepted = true }
                Component.onCompleted: forceActiveFocus()
            }
        }
    }
}
