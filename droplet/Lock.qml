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
    Timer { id: dripTimer; interval: 700; onTriggered: { root.password = ""; root.wrong = false } }

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

            // ── the drops ── a row under the time, each joined to the one before it
            Item {
                id: row
                width: parent.width
                height: 120
                y: parent.height * 0.62
                readonly property real gap: 30
                readonly property real r: 10

                Repeater {
                    model: root.count
                    Goo {
                        required property int index
                        anchors.fill: parent
                        visible: index > 0 && !root.wrong
                        ax: row.width / 2 + (index - 1 - (root.count - 1) / 2) * row.gap * (root.opening ? 0 : 1)
                        ay: row.height / 2
                        ar: row.r
                        bx: row.width / 2 + (index - (root.count - 1) / 2) * row.gap * (root.opening ? 0 : 1)
                        by: row.height / 2
                        br: row.r
                        thread: 4
                        color: root.checking ? Colors.tertiary : Colors.primary
                    }
                }
                Repeater {
                    model: root.count
                    Rectangle {
                        id: drop
                        required property int index
                        width: row.r * 2
                        height: width
                        radius: width / 2
                        color: root.wrong ? Colors.error : root.checking ? Colors.tertiary : Colors.primary
                        x: row.width / 2 + (index - (root.count - 1) / 2) * row.gap * (root.opening ? 0 : 1) - width / 2
                        y: row.height / 2 - height / 2 + (root.wrong ? 260 + index * 18 : 0)
                        opacity: root.wrong ? 0 : 1
                        scale: 0
                        Component.onCompleted: scale = 1
                        Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 2.2 } }
                        Behavior on x { NumberAnimation { duration: 420; easing.type: Easing.InOutCubic } }
                        Behavior on y { NumberAnimation { duration: 650; easing.type: Easing.InQuad } }
                        Behavior on opacity { NumberAnimation { duration: 650; easing.type: Easing.InQuad } }
                        Behavior on color { ColorAnimation { duration: 160 } }

                        // while PAM checks, the drops breathe one after another
                        SequentialAnimation on scale {
                            running: root.checking
                            loops: Animation.Infinite
                            onRunningChanged: if (!running) drop.scale = 1
                            PauseAnimation { duration: drop.index * 60 }
                            NumberAnimation { to: 1.25; duration: 300; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 1; duration: 300; easing.type: Easing.InOutSine }
                        }
                    }
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
