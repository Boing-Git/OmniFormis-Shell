import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Shapes
import "primitive"
import "variables.js" as Vars

// The first-run tour: one card at a time, each pointing (an arrow and a pulsing marker)
// at the spot a dial lives on while that dial peeks out, so a new user learns that this
// is a dial system (not a bar), where each dial is and how it's used. Shown once
// (Hints "tour"); replay it any time with
//
//   qs -p <this folder> ipc call hints tour     (hints tourStep 3, hints tourEnd)
//
// It never takes the keyboard (it comes up by itself on the first run, maybe while you
// type): the buttons, or a click on the dimmed screen, move it on.
PanelWindow {
    id: win
    // the screen the shell lives on (Dials.screen): when the monitor goes away and comes
    // back (a DisplayPort monitor does as it sleeps) the window follows it back
    screen: Dials.screen

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    visible: shown || scrim.opacity > 0.01
    WlrLayershell.namespace: "dial-onboarding"
    WlrLayershell.layer: WlrLayer.Overlay
    mask: Region {
        width: win.shown ? win.width : 0
        height: win.shown ? win.height : 0
    }

    property bool shown: false
    property int step: 0

    Component.onCompleted: Dials.onboarding = win

    // the first run: once every dial has registered, if it was never shown
    Timer {
        interval: 2500
        running: true
        onTriggered: if (Hints.wants("tour")) win.begin()
    }

    // ── the steps ── a welcome, one per dial (in the spots they live on now), hands-on
    readonly property var dialWords: ({
        wallpaper: ["Wallpapers", "Scroll to browse, click the big one to apply; the colours of the whole shell follow it. Type to search by name, colour or number."],
        apps: ["Apps", "Type to search, Enter to launch. Scroll, or use the arrow keys, to browse."],
        center: ["Control center", "The outer ring picks a control, the inner ring shows what's inside it, and the two tick rings between them are volume and brightness. Dials → Edit lets you move every dial to another corner or edge."],
        power: ["Power", "Lock, log out, suspend, reboot or shut down: scroll to it, click."],
        volume: ["Volume", "Pops up here when the volume changes. Scroll it to adjust, click to mute."],
        brightness: ["Brightness", "Pops up here when the brightness changes. Scroll it to adjust."],
        workspaces: ["Workspaces", "Pops up here as you switch workspaces. Scroll to step through them, or click one to jump there."]
    })
    property var steps: []
    function buildSteps() {
        const list = [{
            title: "Welcome to your dials",
            body: "This isn't a bar or an island. Your tools are dials that live in the corners and on the edges of the screen. Move the mouse into a corner or an edge's middle to see one peek out; click it to open.",
            dial: ""
        }]
        const names = Dials.homes.concat(Dials.popups)
        for (let i = 0; i < names.length; i++) {
            const w = dialWords[names[i]]
            if (w && Dials.dials[names[i]]) list.push({ title: w[0], body: w[1], dial: names[i] })
        }
        list.push({
            title: "Hands on",
            body: "Every ring can be grabbed: hold and spin it, let go fast to throw it. Turning a knob, pull the hand further out for finer steps. Pull an app off the launcher's ring onto a workspace to open it there. In the control center, pull a device pill outwards: drop it on Media to play through it, or flick it away to dismiss it; a notification's pill flicks away the same way.\n\nReplay this tour any time:  Control center → Dials → Help",
            dial: ""
        })
        steps = list
    }

    function begin() {
        buildSteps()
        Hints.shown("tour")
        step = 0
        shown = true
    }
    function finish() { shown = false }
    function next() { if (step >= steps.length - 1) finish(); else step++ }
    function back() { if (step > 0) step-- }

    readonly property var current: steps[step] || ({ title: "", body: "", dial: "" })
    readonly property string spot: current.dial !== "" ? Dials.spotOf(current.dial) : ""

    // the spot's point on the screen (a corner, or the middle of an edge)
    readonly property point spotPoint: {
        const W = width, H = height
        switch (spot) {
        case "topLeft": return Qt.point(0, 0)
        case "top": return Qt.point(W / 2, 0)
        case "topRight": return Qt.point(W, 0)
        case "right": return Qt.point(W, H / 2)
        case "bottomRight": return Qt.point(W, H)
        case "bottom": return Qt.point(W / 2, H)
        case "bottomLeft": return Qt.point(0, H)
        case "left": return Qt.point(0, H / 2)
        default: return Qt.point(W / 2, H / 2)
        }
    }

    // the step's dial peeks out again and again while its card is up
    function peekCurrent() {
        const d = Dials.dials[current.dial]
        if (d && d.peek) d.peek(1100)
    }
    onStepChanged: if (shown) peekCurrent()
    onShownChanged: if (shown) peekCurrent()
    Timer {
        interval: 1600
        repeat: true
        running: win.shown && win.current.dial !== ""
        onTriggered: win.peekCurrent()
    }

    // ── sizes (M3E) ──
    readonly property real cardWidth: 440
    readonly property real cardPad: 28
    readonly property real cardRadius: 28
    readonly property real markerRadius: 84

    Item {
        id: content
        anchors.fill: parent

        // the scrim: the screen behind dims, so the card and the marker stand out
        Rectangle {
            id: scrim
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.45)
            opacity: win.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration * 2; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
            MouseArea { anchors.fill: parent; onClicked: win.next() }
        }

        // ── the marker ── a pulsing primary disc on the spot (the screen cuts it to a
        // quarter or a half, like the dial living there)
        Rectangle {
            id: marker
            width: win.markerRadius * 2
            height: width
            radius: width / 2
            x: win.spotPoint.x - width / 2
            y: win.spotPoint.y - height / 2
            color: Qt.rgba(Roles.primary.r, Roles.primary.g, Roles.primary.b, 0.18)
            border.width: 3
            border.color: Roles.primary
            antialiasing: true
            opacity: win.shown && win.spot !== "" ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
            Behavior on x { NumberAnimation { duration: Prefs.defaultSpatial.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.defaultSpatial.bezier } }
            Behavior on y { NumberAnimation { duration: Prefs.defaultSpatial.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.defaultSpatial.bezier } }
            SequentialAnimation on scale {
                loops: Animation.Infinite
                running: marker.visible
                NumberAnimation { to: 1.1; duration: Vars.expressiveSlowEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveSlowEffects.bezier }
                NumberAnimation { to: 1; duration: Vars.expressiveSlowEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveSlowEffects.bezier }
            }
        }

        // ── the arrow ── from the card's middle towards the marker, stopping at its edge
        Item {
            id: arrow
            readonly property real fromX: card.x + card.width / 2
            readonly property real fromY: card.y + card.height / 2
            readonly property real dx: win.spotPoint.x - fromX
            readonly property real dy: win.spotPoint.y - fromY
            readonly property real dist: Math.hypot(dx, dy)
            readonly property real angle: Math.atan2(dy, dx) * 180 / Math.PI

            // starts just outside the card, ends just outside the marker
            readonly property real startAt: Math.min(card.width, card.height) / 2 + 24
            readonly property real endAt: dist - win.markerRadius - 16
            readonly property real len: Math.max(0, endAt - startAt)
            x: fromX
            y: fromY
            rotation: angle
            transformOrigin: Item.TopLeft
            opacity: win.shown && win.spot !== "" && len > 30 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

            Rectangle {
                x: arrow.startAt
                y: -2
                width: arrow.len - 14
                height: 4
                radius: 2
                color: Roles.primary
                antialiasing: true
                Behavior on width { NumberAnimation { duration: Prefs.defaultSpatial.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.defaultSpatial.bezier } }
            }
            Shape {
                x: arrow.startAt + arrow.len - 18
                y: -11
                width: 18
                height: 22
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    fillColor: Roles.primary
                    strokeColor: "transparent"
                    startX: 0; startY: 0
                    PathLine { x: 18; y: 11 }
                    PathLine { x: 0; y: 22 }
                    PathLine { x: 0; y: 0 }
                }
            }
        }

        // ── the card ──
        Rectangle {
            id: card
            width: win.cardWidth
            height: column.height + win.cardPad * 2
            radius: win.cardRadius
            color: Roles.surface_container_high
            antialiasing: true

            // in the middle of the screen, nudged away from the spot so the arrow has room
            readonly property real nudge: 110
            readonly property real wantX: (win.width - width) / 2 - (win.spot !== "" ? Math.sign(win.spotPoint.x - win.width / 2) * nudge : 0)
            readonly property real wantY: (win.height - height) / 2 - (win.spot !== "" ? Math.sign(win.spotPoint.y - win.height / 2) * nudge : 0)
            x: wantX
            y: wantY
            Behavior on x { NumberAnimation { duration: Prefs.defaultSpatial.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.defaultSpatial.bezier } }
            Behavior on y { NumberAnimation { duration: Prefs.defaultSpatial.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.defaultSpatial.bezier } }
            opacity: win.shown ? 1 : 0
            scale: win.shown ? 1 : 0.9
            Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
            Behavior on scale { NumberAnimation { duration: Prefs.defaultSpatial.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.defaultSpatial.bezier } }

            Column {
                id: column
                x: win.cardPad
                y: win.cardPad
                width: parent.width - win.cardPad * 2
                spacing: 14

                // the step's shape and number (M3E: a cookie that morphs per step)
                Row {
                    spacing: 12
                    Item {
                        width: 40; height: 40
                        ShapeMorph {
                            anchors.fill: parent
                            shape: ["12SidedCookie", "4SidedCookie", "Sunny", "6SidedCookie", "Gem", "Puffy", "SoftBurst", "Flower", "Clamshell"][win.step % 9]
                            color: Roles.primary_container
                        }
                        SmoothText {
                            anchors.centerIn: parent
                            text: win.step + 1
                            font.pixelSize: 15
                            font.weight: 800
                            color: Roles.on_primary_container
                        }
                    }
                    SmoothText {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Step " + (win.step + 1) + " of " + win.steps.length
                        font.pixelSize: 12
                        font.weight: 600
                        color: Roles.on_surface_variant
                    }
                }

                SmoothText {
                    width: parent.width
                    text: win.current.title
                    font.pixelSize: 26            // M3 headlineSmall
                    font.weight: 800
                    color: Roles.on_surface
                    wrapMode: Text.WordWrap
                }
                SmoothText {
                    width: parent.width
                    text: win.current.body
                    font.pixelSize: 15            // M3 bodyLarge
                    lineHeight: 1.25
                    color: Roles.on_surface_variant
                    wrapMode: Text.WordWrap
                }

                // progress: a dot per step, the current one a pill (M3 carousel indicator)
                Row {
                    spacing: 6
                    Repeater {
                        model: win.steps.length
                        Rectangle {
                            required property int index
                            width: index === win.step ? 22 : 8
                            height: 8
                            radius: 4
                            color: index === win.step ? Roles.primary : index < win.step ? Roles.primary_container : Roles.outline_variant
                            Behavior on width { NumberAnimation { duration: Prefs.fastSpatial.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.fastSpatial.bezier } }
                        }
                    }
                }

                // the buttons: Skip (text), Back (outlined), Next / Done (filled)
                Item {
                    width: parent.width
                    height: 44

                    TourButton {
                        anchors.left: parent.left
                        label: "Skip"
                        kind: "text"
                        visible: win.step < win.steps.length - 1
                        onClicked: win.finish()
                    }
                    Row {
                        anchors.right: parent.right
                        spacing: 8
                        TourButton {
                            label: "Back"
                            kind: "outlined"
                            visible: win.step > 0
                            onClicked: win.back()
                        }
                        TourButton {
                            label: win.step >= win.steps.length - 1 ? "Done" : "Next"
                            kind: "filled"
                            onClicked: win.next()
                        }
                    }
                }
            }
        }
    }

    // an M3E button: a pill that squares up a little while pressed, with a state layer
    component TourButton: Item {
        id: btn
        property string label: ""
        property string kind: "filled"
        signal clicked()
        width: text.implicitWidth + 48
        height: 44

        Rectangle {
            anchors.fill: parent
            radius: area.pressed ? 12 : height / 2
            antialiasing: true
            color: btn.kind === "filled" ? Roles.primary : "transparent"
            border.width: btn.kind === "outlined" ? 1 : 0
            border.color: Roles.outline
            Behavior on radius { NumberAnimation { duration: Prefs.fastSpatial.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.fastSpatial.bezier } }

            // the state layer: hover 8%, pressed 12% of the text colour
            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: text.color
                opacity: area.pressed ? 0.12 : area.containsMouse ? 0.08 : 0
                Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
            }
        }
        SmoothText {
            id: text
            anchors.centerIn: parent
            text: btn.label
            font.pixelSize: 14
            font.weight: 700
            color: btn.kind === "filled" ? Roles.on_primary : Roles.primary
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }
}
