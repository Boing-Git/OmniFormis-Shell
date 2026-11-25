// screenpilot's overlay: a Quickshell instance of its own, started and kept running by
// screenpilotd (qs -p <this folder>), so it works with whichever shell is up.
//   STOP          top-right of every screen while the AI thinks, acts or waits: red, large. A click
//                 runs `screenpilot stop` as a process, so it works even if the daemon is stuck
//   status line   under the word: thinking / acting / paused / halted
//   AI cursor     shared mode: a cyan arrow labelled AI that glides to where the AI will act
//   confirm box   Yes / No under STOP when an action needs your OK
//   prompt        the text box `screenpilot prompt ask|act` opens (the keybinds)
//   answer card   how the last run ended, under STOP for a while (click to dismiss)
// The daemon paints over the rects reported here in every screenshot it takes (and hides the AI
// cursor while it takes one), and refuses AI clicks inside them.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

ShellRoot {
    id: root

    property string phase: "idle"
    property string reason: ""
    property string answer: ""
    property bool answerIsError: false
    property var confirmReq: null
    property string promptMode: ""
    property bool cursorShown: false
    property real cursorX: 0
    property real cursorY: 0
    property int glideMs: 300
    property bool haltFlash: false
    readonly property bool active: phase === "thinking" || phase === "acting" || phase === "paused"
    readonly property string cli: Quickshell.env("SCREENPILOT_CLI") || "screenpilot"

    readonly property int margin: 16
    readonly property int stopW: 176
    readonly property int stopH: 68
    readonly property int cardW: 360
    readonly property int confirmH: 132

    function send(obj) {
        if (!sock.connected) return
        sock.write(JSON.stringify(obj) + "\n")
        sock.flush()
    }

    function handle(ev) {
        if (ev.type === "status" || ev.type === "state") {
            phase = ev.state
            reason = ev.reason || ""
            if (phase === "halted") {
                haltFlash = true
                haltTimer.restart()
                confirmReq = null
                cursorShown = false
                reportRects()
            }
            if (active) answer = ""
        } else if (ev.type === "cursor") {
            if (ev.hide) { cursorShown = false; return }
            glideMs = ev.ms || 0
            cursorX = ev.x
            cursorY = ev.y
            cursorShown = true
        } else if (ev.type === "confirm") {
            confirmReq = ev
            reportRects()
        } else if (ev.type === "prompt") {
            promptMode = ev.mode
        } else if (ev.type === "answer" || ev.type === "error") {
            answer = ev.text || ""
            answerIsError = ev.type === "error"
            answerTimer.restart()
        }
    }

    // where the AI may never click, in layout coordinates: STOP, and the confirm box while it shows
    function reportRects() {
        const rects = []
        for (const s of Quickshell.screens) {
            const w = confirmReq ? cardW : stopW
            const h = stopH + (confirmReq ? 8 + confirmH : 0)
            rects.push([s.x + s.width - margin - w, s.y + margin, w, h])
        }
        send({ cmd: "overlay", rects: rects })
    }

    function answerConfirm(yes) {
        if (!confirmReq) return
        send({ cmd: "confirm", id: confirmReq.id, yes: yes })
        confirmReq = null
        reportRects()
    }

    Socket {
        id: sock
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "") + "/screenpilot.sock"
        connected: true
        onConnectedChanged: if (connected) { root.send({ cmd: "subscribe" }); root.reportRects() }
        parser: SplitParser { onRead: line => { try { root.handle(JSON.parse(line)) } catch (e) {} } }
    }
    // the daemon restarts, or isn't listening yet: try again every second
    Timer { interval: 1000; repeat: true; running: !sock.connected; onTriggered: sock.connected = true }
    Connections { target: Quickshell; function onScreensChanged() { root.reportRects() } }

    Timer { id: haltTimer; interval: 4000; onTriggered: root.haltFlash = false }
    Timer { id: answerTimer; interval: 15000; onTriggered: root.answer = "" }

    // ── STOP, status, confirm, answer: top-right of each screen ──
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.active || root.haltFlash || root.confirmReq !== null || root.answer !== ""
            anchors { top: true; right: true }
            margins { top: root.margin; right: root.margin }
            implicitWidth: root.cardW
            implicitHeight: Math.max(1, column.implicitHeight)
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "screenpilot-stop"
            mask: Region { item: column }

            Column {
                id: column
                anchors.right: parent.right
                spacing: 8

                Rectangle {
                    anchors.right: parent.right
                    visible: root.active || root.haltFlash
                    width: root.stopW
                    height: root.stopH
                    radius: 20
                    color: !root.active ? "#455a64" : stopArea.pressed ? "#8e1b1b" : stopArea.containsMouse ? "#e53935" : "#c62828"
                    border.width: 2
                    border.color: "#ffffff"

                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.active ? "STOP" : "HALTED"
                            color: "white"
                            font.pixelSize: 24
                            font.bold: true
                            font.letterSpacing: 2
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.phase === "paused" ? "paused: you're using it"
                                : root.active ? root.phase + "…"
                                : "Super+Shift+Esc resumes"
                            color: "#ffe9e9"
                            font.pixelSize: 12
                        }
                    }
                    MouseArea {
                        id: stopArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: root.active
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Quickshell.execDetached([root.cli, "stop"])
                    }
                }

                Rectangle {
                    visible: root.confirmReq !== null
                    width: root.cardW
                    height: root.confirmH
                    radius: 18
                    color: "#212121"
                    border.width: 2
                    border.color: "#ffb300"

                    Text {
                        x: 16; y: 14
                        width: parent.width - 32
                        text: root.confirmReq ? root.confirmReq.question : ""
                        color: "white"
                        font.pixelSize: 15
                        wrapMode: Text.Wrap
                        maximumLineCount: 3
                        elide: Text.ElideRight
                    }
                    Row {
                        anchors { right: parent.right; bottom: parent.bottom; margins: 14 }
                        spacing: 10
                        Repeater {
                            model: [{ label: "No", yes: false, color: "#424242" }, { label: "Yes", yes: true, color: "#2e7d32" }]
                            Rectangle {
                                required property var modelData
                                width: 96; height: 40; radius: 12
                                color: modelData.color
                                Text { anchors.centerIn: parent; text: parent.modelData.label; color: "white"; font.pixelSize: 16; font.bold: true }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.answerConfirm(parent.modelData.yes) }
                            }
                        }
                    }
                }

                Rectangle {
                    visible: root.answer !== "" && !root.active
                    width: root.cardW
                    height: answerText.implicitHeight + 28
                    radius: 18
                    color: "#212121"
                    border.width: 1
                    border.color: root.answerIsError ? "#ef5350" : "#00e5ff"

                    Text {
                        id: answerText
                        x: 16; y: 14
                        width: parent.width - 32
                        text: root.answer
                        color: "white"
                        font.pixelSize: 14
                        wrapMode: Text.Wrap
                        maximumLineCount: 12
                        elide: Text.ElideRight
                    }
                    MouseArea { anchors.fill: parent; onClicked: root.answer = "" }
                }
            }
        }
    }

    // ── the AI's own cursor (shared mode): click-through, over everything ──
    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: cursorWin
            required property var modelData
            screen: modelData
            visible: root.cursorShown
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "screenpilot-cursor"
            mask: Region {}

            Item {
                // the arrow's tip is at (2, 2)
                x: root.cursorX - cursorWin.modelData.x - 2
                y: root.cursorY - cursorWin.modelData.y - 2
                Behavior on x { NumberAnimation { duration: root.glideMs; easing.type: Easing.InOutCubic } }
                Behavior on y { NumberAnimation { duration: root.glideMs; easing.type: Easing.InOutCubic } }

                Canvas {
                    width: 28; height: 34
                    onPaint: {
                        const c = getContext("2d")
                        c.reset()
                        c.beginPath()
                        c.moveTo(2, 2); c.lineTo(2, 28); c.lineTo(9, 21); c.lineTo(14, 32)
                        c.lineTo(19, 30); c.lineTo(14, 19); c.lineTo(24, 19); c.closePath()
                        c.fillStyle = "#00e5ff"
                        c.fill()
                        c.lineWidth = 2
                        c.strokeStyle = "#06121f"
                        c.stroke()
                    }
                }
                Rectangle {
                    x: 20; y: 26
                    width: aiLabel.implicitWidth + 12
                    height: 18
                    radius: 6
                    color: "#ff2bd6"
                    Text { id: aiLabel; anchors.centerIn: parent; text: "AI"; color: "white"; font.bold: true; font.pixelSize: 11 }
                }
            }
        }
    }

    // ── the prompt the keybinds open ──
    PanelWindow {
        visible: root.promptMode !== ""
        anchors.top: true
        margins.top: 160
        implicitWidth: 640
        implicitHeight: 64
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "screenpilot-prompt"
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
        onVisibleChanged: if (visible) promptInput.forceActiveFocus()

        Rectangle {
            anchors.fill: parent
            radius: 22
            color: "#1b1b21"
            border.width: 2
            border.color: root.promptMode === "act" ? "#ff2bd6" : "#00e5ff"

            Text {
                id: promptLabel
                anchors { left: parent.left; leftMargin: 20; verticalCenter: parent.verticalCenter }
                text: root.promptMode === "act" ? "Do" : "Ask"
                color: root.promptMode === "act" ? "#ff2bd6" : "#00e5ff"
                font.pixelSize: 18
                font.bold: true
            }
            TextInput {
                id: promptInput
                anchors { left: promptLabel.right; leftMargin: 14; right: parent.right; rightMargin: 20; verticalCenter: parent.verticalCenter }
                color: "white"
                font.pixelSize: 18
                clip: true
                onAccepted: {
                    const words = text.trim()
                    if (words) Quickshell.execDetached([root.cli, root.promptMode, words])
                    text = ""
                    root.promptMode = ""
                }
                Keys.onEscapePressed: { text = ""; root.promptMode = "" }
            }
        }
    }
}
