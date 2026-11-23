import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "primitive"
import "variables.js" as Vars

// About: the dotfiles' three shells as their mascots, side by side on a card of liquid glass.
// The one that runs (Dial-E, here) is full size, the others at Unpicked size, and all three
// watch the pointer. Click another one, then again, to switch to its shell (scripts/shell).
// Each mascot keeps a secret (the spoilers section at the end of quickshell/CLAUDE.md).
// Open: the About pill in the control center's Dials control, or qs ipc call about open.
PanelWindow {
    id: win
    screen: Dials.screen

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: shown || scrim.opacity > 0.01
    WlrLayershell.namespace: "dial-about"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    mask: Region {
        width: win.shown ? win.width : 0
        height: win.shown ? win.height : 0
    }

    property bool shown: false
    function open() {
        story = ""
        armed = ""
        taps = 0
        whoRuns.running = true
        shown = true
    }
    function close() { shown = false }
    Component.onCompleted: Dials.about = win

    // ── the shells ── as scripts/shell names them, each with its line and its secret's words
    readonly property var shells: [
        { name: "dial-e", title: "Dial-E", body: Roles.primary_container, ink: Roles.on_primary_container, accent: Roles.primary,
          line: "Dials that sleep in the corners and wake when you come close.",
          story: "Hi, I'm Dial-E! I'm round because everything here is: your tools are dials in the corners and on the edges, and they spin. Try flicking a ring, pulling an app off the launcher onto a workspace, or turning a knob with your hand further out for finer steps." },
        { name: "puffy", title: "Puffy", body: Roles.tertiary_container, ink: Roles.on_tertiary_container, accent: Roles.tertiary,
          line: "A bar, panels and a big settings app: everything in reach.",
          story: "Puff! I'm Puffy, the shell these dotfiles started as (OmniFormis). I puff up when you open things and calm down when you close them. Try my control center's quick toggles, the game library and the overview. Click me twice up here to switch, or run scripts/shell switch puffy." },
        { name: "droplet", title: "Droplet", body: Roles.secondary_container, ink: Roles.on_secondary_container, accent: Roles.secondary,
          line: "Nothing is clicked: drag one drop onto the next.",
          story: "Blup. I'm Droplet. In my shell you pull a drop out of the right edge and drag it onto circles, and the chain joins like water: Apps onto a workspace, Wi-Fi onto a network. Click me twice up here to switch, or run scripts/shell switch droplet." }
    ]

    // which one runs (scripts/shell current), asked each time it opens
    property string running: "dial-e"
    Process {
        id: whoRuns
        command: [Vars.shellSwitcher, "current"]
        stdout: StdioCollector { onStreamFinished: if (text.trim() !== "") win.running = text.trim() }
    }

    // the one clicked once (a second click switches to it), a secret found (its words), and
    // Dial-E's taps
    property string armed: ""
    property string story: ""
    property int taps: 0
    Timer { id: tapWindow; interval: 3000; onTriggered: win.taps = 0 }

    function switchTo(name) {
        Quickshell.execDetached([Vars.shellSwitcher, "switch", name])
        close()
    }

    // ── the scrim ──
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.45)
        opacity: win.shown ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration * 2; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
    }

    // the pointer, for the eyes; a click outside the card closes
    property point pointer: Qt.point(width / 2, height / 2)
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: mouse => win.pointer = Qt.point(mouse.x, mouse.y)
        onClicked: win.close()
    }
    Shortcut { sequence: "Escape"; enabled: win.shown; onActivated: win.close() }
    Item { focus: win.shown; Keys.onEscapePressed: win.close() }

    // what the card's glass sees, only while it's up
    LiquidBackdrop {
        id: aboutPictures
        awake: win.shown
        area: Qt.rect(card.x, card.y, card.width, card.height)
    }

    // ── the card ──
    Rectangle {
        id: card
        width: 760
        height: 440
        anchors.centerIn: parent
        radius: 36
        color: cardGlass.active ? "transparent" : Roles.surface_container_high
        opacity: win.shown ? 1 : 0
        scale: win.shown ? 1 : 0.92
        Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
        Behavior on scale { NumberAnimation { duration: Prefs.defaultSpatial.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.defaultSpatial.bezier } }

        LiquidGlass {
            id: cardGlass
            anchors.fill: parent
            anchors.margins: -shadowReach
            shape: "box"
            boxWidth: card.width
            boxHeight: card.height
            radius: card.radius
            backdrop: aboutPictures
            tint: Prefs.liquidBody(Roles.surface_container_high, "popup")
            under: Qt.rgba(0, 0, 0, 0.45 * scrim.opacity)
        }

        // (a click on the card stays on the card)
        MouseArea { anchors.fill: parent }

        SmoothText {
            x: 36
            y: 28
            text: "Your shells"
            font.pixelSize: 15
            font.weight: 700
            color: Roles.on_surface_variant
        }

        Row {
            id: row
            anchors.horizontalCenter: parent.horizontalCenter
            y: 62
            spacing: 24

            Repeater {
                model: win.shells
                Item {
                    id: slot
                    required property var modelData
                    readonly property bool runs: modelData.name === win.running
                    width: 210
                    height: 250

                    // the running one full size, the others at Unpicked size, on a spring
                    SpringValue {
                        id: grow
                        to: slot.runs || win.armed === slot.modelData.name ? 1 : Prefs.inactiveScale
                        stiffness: Vars.springs.expressive.fast.spatial.stiffness
                        dampingRatio: Prefs.calm ? 1 : Vars.springs.expressive.fast.spatial.dampingRatio
                        epsilon: 0.001
                        Component.onCompleted: snap(to)
                    }

                    Mascot {
                        id: mascot
                        kind: slot.modelData.name
                        width: 170
                        height: 170
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 0
                        scale: grow.value
                        body: slot.modelData.body
                        ink: slot.modelData.ink
                        accent: slot.modelData.accent
                        eyeWhite: Roles.primary_fixed
                        pupil: Roles.on_primary_fixed

                        // it looks at the pointer
                        look: {
                            const p = mapFromItem(null, win.pointer.x, win.pointer.y)
                            return Qt.point(Math.max(-1, Math.min(1, (p.x - width / 2) / 260)), Math.max(-1, Math.min(1, (p.y - height / 2) / 260)))
                        }
                    }

                    SmoothText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 182
                        text: slot.modelData.title
                        font.pixelSize: 20
                        font.weight: 800
                        color: slot.runs ? Roles.primary : Roles.on_surface
                    }
                    SmoothText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 212
                        text: slot.runs ? "running" : win.armed === slot.modelData.name ? "click again to switch" : ""
                        font.pixelSize: 12
                        font.weight: 600
                        color: slot.runs ? Roles.on_surface_variant : Roles.primary
                    }

                    // click: poke (a second click on another shell switches to it); hold
                    // Puffy until it's fully puffed, or pull Droplet down to pour it: its secret
                    MouseArea {
                        anchors.fill: mascot
                        property real pressedAt: 0
                        property point from: Qt.point(0, 0)
                        property bool secret: false
                        onPressed: mouse => {
                            pressedAt = Date.now()
                            from = Qt.point(mouse.x, mouse.y)
                            secret = false
                            if (slot.modelData.name === "puffy") { mascot.puffTo(1.2); holdTimer.restart() }
                        }
                        onPositionChanged: mouse => {
                            if (slot.modelData.name !== "droplet" || !pressed) return
                            const dy = mouse.y - from.y
                            if (dy > 90 && !secret) { secret = true; mascot.cheer(); win.story = slot.modelData.story }
                        }
                        onReleased: mouse => {
                            holdTimer.stop()
                            mascot.puffTo(0)
                            if (secret || Date.now() - pressedAt > 450 || Math.hypot(mouse.x - from.x, mouse.y - from.y) > 12) return
                            mascot.poke()
                            if (slot.runs && slot.modelData.name === "dial-e") {
                                win.taps++
                                tapWindow.restart()
                                if (win.taps >= 7) { win.taps = 0; mascot.cheer(); win.story = slot.modelData.story }
                                return
                            }
                            if (slot.runs) return
                            if (win.armed === slot.modelData.name) win.switchTo(slot.modelData.name)
                            else win.armed = slot.modelData.name
                        }
                        Timer {
                            id: holdTimer
                            interval: 1400
                            onTriggered: { parent.secret = true; mascot.cheer(); win.story = slot.modelData.story }
                        }
                    }
                }
            }
        }

        // the running one's line, or a secret's words
        SmoothText {
            id: caption
            anchors.horizontalCenter: parent.horizontalCenter
            y: 330
            width: card.width - 96
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            text: win.story !== "" ? win.story : (win.shells.find(s => s.name === win.running) || win.shells[0]).line
            font.pixelSize: win.story !== "" ? 14 : 16
            font.weight: win.story !== "" ? 500 : 600
            color: Roles.on_surface
        }
    }

    IpcHandler {
        target: "about"
        function open(): void { win.open() }
        function close(): void { win.close() }
    }
}
