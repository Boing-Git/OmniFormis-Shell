import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import ".."
import "../primitive"
import "../controlcenter"
import "../variables.js" as Vars

// One screen of the lock (LockScreen.qml makes one per screen; they all draw the same
// state). A sheet grows out of the power dial's spot over the whole screen: the wallpaper,
// softened, and in the middle the lock's dial, the shell's one whole circle: the clock and
// the date at its centre (the centre is "now", as on every dial), and round them the ring
// the password turns, with the mark at the top.
WlSessionLockSurface {
    id: surface

    // the LockScreen: its state, its settings, where the keys go
    required property var lock
    readonly property LockSettings cfg: lock.cfg

    // See-through only while the sheet grows or goes back (the desktop shows round it,
    // with Hyprland's misc:session_lock_xray), solid once it covers the screen, so nothing
    // under the lock can show while it waits for the password
    color: lock.covered ? Roles.surface : "transparent"

    // ── the sheet ── a circle out of the spot, filled with everything on the lock
    readonly property point originPoint: Dials.spotPoint(lock.origin, width, height)

    // far enough to reach the furthest corner (a little past it, so the spring's small dip
    // back after its overshoot never uncovers a corner)
    readonly property real fullRadius: Math.max(
        Math.hypot(originPoint.x, originPoint.y),
        Math.hypot(width - originPoint.x, originPoint.y),
        Math.hypot(originPoint.x, height - originPoint.y),
        Math.hypot(width - originPoint.x, height - originPoint.y)) * 1.03 + 4
    readonly property real sheetRadius: Math.max(0, lock.sheetRadius(fullRadius))

    // The dial on the sheet shows once the sheet has nearly covered the screen, and goes
    // before it shrinks back (as every dial's content does: closing is opening backwards)
    readonly property bool faceShown: lock.phase === "covered" || (lock.phase === "in" && lock.cover >= 0.9)

    // Lock face: Eclipse (EclipseBeads.qml) in place of the clock and the ring's beads
    readonly property bool eclipse: Prefs.lockFace === "eclipse"

    // where the pointer is (Eclipse's beads lean towards it)
    property point pointer: Qt.point(width / 2, height / 2)

    // ── effects that follow the state ── (the effects curve: they never bounce)
    // 1 while the password is wrong (beads and mark in the error colour)
    property real alarm: lock.wrong ? 1 : 0
    Behavior on alarm { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

    // 1 once the password was right (every bead turns primary)
    property real done: lock.unlocking ? 1 : 0
    Behavior on done { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, a.a + (b.a - a.a) * t)
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    M3Shapes { id: shapes }

    // ── the sheet ── one circle out of the spot, three layers: the surface (all there is
    // until the picture loads), the wallpaper softened (lock.picture, blurred ahead of time),
    // and the scrim with the rim every dial has: while the sheet grows and goes back it is a
    // dial too, the biggest one
    Shape {
        id: sheet
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            fillColor: Roles.surface_container_lowest
            PathAngleArc {
                centerX: surface.originPoint.x; centerY: surface.originPoint.y
                radiusX: surface.sheetRadius; radiusY: surface.sheetRadius
                startAngle: 0; sweepAngle: 360
            }
        }

        // the picture covers the screen, centred, never stretched (as ShapeImage does it)
        ShapePath {
            strokeColor: "transparent"
            fillColor: "transparent"
            // (Lock sheet: Liquid glass draws the picture itself, through the glass below)
            fillItem: wall.status === Image.Ready && !sheetGlass.active ? wall : null
            readonly property real tw: Math.max(1, wall.implicitWidth)
            readonly property real th: Math.max(1, wall.implicitHeight)
            readonly property real fit: Math.max(sheet.width / tw, sheet.height / th)
            fillTransform: PlanarTransform.fromAffineMatrix(fit, 0, 0, fit, (sheet.width - tw * fit) / 2, (sheet.height - th * fit) / 2)
            PathAngleArc {
                centerX: surface.originPoint.x; centerY: surface.originPoint.y
                radiusX: surface.sheetRadius; radiusY: surface.sheetRadius
                startAngle: 0; sweepAngle: 360
            }
        }

        ShapePath {
            strokeColor: sheetGlass.active ? "transparent" : Roles.outline_variant
            strokeWidth: surface.cfg.borderWidth
            fillColor: sheetGlass.active ? "transparent" : Qt.rgba(Roles.surface.r, Roles.surface.g, Roles.surface.b, surface.scrim)
            PathAngleArc {
                centerX: surface.originPoint.x; centerY: surface.originPoint.y
                radiusX: surface.sheetRadius; radiusY: surface.sheetRadius
                startAngle: 0; sweepAngle: 360
            }
        }
    }

    // the picture, used only as the sheet's fill (not drawn by itself). LockScreen keeps the
    // same one loaded, so this finds it ready: not asynchronous, so the first frame has it
    Image {
        id: wall
        source: surface.lock.pictureUrl
        sourceSize.width: 1280
        asynchronous: false
        smooth: true
        visible: false
    }

    // Lock sheet: Liquid glass. The sheet is a pane of liquid glass over the picture, with the
    // scrim under it: it bends the picture at its rim as it sweeps out of the spot and back,
    // and its rim catches the light where the flat sheet has its outline
    LiquidGlass {
        id: sheetGlass
        anchors.fill: parent
        shape: "disc"
        cx: surface.originPoint.x
        cy: surface.originPoint.y
        radius: surface.sheetRadius
        backdrop: lockPictures
        force: true
        allowed: Prefs.lockBackground === "glass"
        under: surface.scrimColor
    }

    // what the lock's liquid glass sees (Settings → Liquid glass): the same picture (Qt
    // shares one loaded at the same url and size), softened already, so blurred and sharp
    // are the one picture; the scrim over it goes in as each glass's `under`
    LiquidBackdrop {
        id: lockPictures
        source: Prefs.liquidOn || Prefs.lockBackground === "glass" ? surface.lock.pictureUrl : ""
        blurSource: ""
        live: false
        sourceSize: Qt.size(1280, -1)
        crop: false
        asynchronous: false
    }
    readonly property color scrimColor: Qt.rgba(Roles.surface.r, Roles.surface.g, Roles.surface.b, scrim)

    // How much the scrim hides the picture: a little at rest, more while the ring is out
    // (the world steps back while you unlock), and more on a picture that isn't blurred yet
    property real scrim: (lock.pictureBlurred ? 0 : cfg.sharpScrimExtra)
        + (lock.awake ? cfg.awakeScrim : cfg.restScrim)
    Behavior on scrim { NumberAnimation { duration: Vars.expressiveDefaultEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveDefaultEffects.bezier } }

    // ── the dial ── a square round the middle of the screen; everything on it is placed
    // round its centre (cx, cy)
    Item {
        id: face
        width: surface.cfg.dialRadius * 2 + 16
        height: width
        anchors.centerIn: parent
        readonly property real cx: width / 2
        readonly property real cy: height / 2

        opacity: surface.faceShown ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

        // where an angle (degrees, 0 = right, 90 = down) at radius r lands on the face
        function px(r, deg) { return face.cx + r * Math.cos(deg * Math.PI / 180) }
        function py(r, deg) { return face.cy + r * Math.sin(deg * Math.PI / 180) }

        // ── the disc ── grows out of the middle when the ring comes out, like any dial
        // out of its spot (Prefs.openSpring: the Bounce and Speed settings), and goes
        // once the ring has faded (closing is opening backwards)
        SpringValue {
            id: open
            to: surface.lock.awake || ring.opacity > 0.01 ? 1 : 0
            stiffness: Prefs.openSpring.stiffness
            dampingRatio: Prefs.openSpring.dampingRatio
            epsilon: 0.002
        }

        Rectangle {
            width: surface.cfg.dialRadius * 2 * Math.max(0, open.value)
            height: width
            radius: width / 2
            x: face.cx - width / 2
            y: face.cy - height / 2
            visible: width > 1
            antialiasing: true

            // glass when the shell is translucent (Prefs.glass): here it shows the
            // softened wallpaper on the sheet. The rim stays solid. Liquid glass draws
            // both itself (below)
            color: discGlass.active ? "transparent" : Prefs.glass(Roles.surface_container, "lock")
            border.width: discGlass.active ? 0 : surface.cfg.borderWidth
            border.color: Roles.outline_variant

            // liquid glass in the disc's place (Settings → Liquid glass): it bends the
            // softened wallpaper under the scrim
            LiquidGlass {
                id: discGlass
                anchors.fill: parent
                anchors.margins: -shadowReach
                radius: parent.width / 2
                backdrop: lockPictures
                tint: Prefs.liquidBody(Roles.surface_container, "lock")
                under: surface.scrimColor
            }
        }

        // ── the ring ── fades in over the last of the disc's growing, out before it shrinks
        Item {
            id: ring
            anchors.fill: parent
            opacity: surface.lock.awake && open.value >= 0.9 ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

            // liquid glass in the band's place (Settings → Liquid glass): it sees the
            // softened wallpaper through the scrim and the disc under it
            LiquidGlass {
                id: bandGlass
                anchors.fill: parent
                shape: "arc"
                cx: face.cx
                cy: face.cy
                radius: surface.cfg.ringRadius
                thickness: surface.cfg.bandWidth
                startDeg: 0
                sweepDeg: 360
                backdrop: lockPictures
                tint: Prefs.liquidBody(Roles.surface_container_high, "ring")
                under: over(surface.scrimColor, Prefs.liquidBody(Roles.surface_container, "lock"))
            }

            // the band and its tick marks: the ticks sit between the beads and turn
            // with them, like the graduations on a safe's dial
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer

                // the band, a surface step up from the dial (glass too when translucent;
                // liquid glass draws it itself, above)
                ShapePath {
                    strokeColor: bandGlass.active ? "transparent" : Prefs.glass(Roles.surface_container_high, "ring")
                    strokeWidth: surface.cfg.bandWidth
                    fillColor: "transparent"
                    PathAngleArc {
                        centerX: face.cx; centerY: face.cy
                        radiusX: surface.cfg.ringRadius; radiusY: surface.cfg.ringRadius
                        startAngle: 0; sweepAngle: 360
                    }
                }

                // the inner and outer row of ticks
                TickRow {
                    radius: surface.cfg.tickInner
                    cx: face.cx; cy: face.cy
                    stepDeg: surface.cfg.stepDeg; startDeg: surface.cfg.markDeg; turn: surface.lock.turn
                    strokeWidth: surface.cfg.tickSize
                    strokeColor: Roles.outline_variant
                }
                TickRow {
                    radius: surface.cfg.tickOuter
                    cx: face.cx; cy: face.cy
                    stepDeg: surface.cfg.stepDeg; startDeg: surface.cfg.markDeg; turn: surface.lock.turn
                    strokeWidth: surface.cfg.tickSize
                    strokeColor: Roles.outline_variant
                }
            }

            // ── the beads ── one per typed letter: the newest at the mark (bigger,
            // primary), the older ones secondary, further round to the left
            Repeater {
                model: surface.eclipse ? 0 : surface.lock.peak

                Item {
                    id: bead
                    required property int index

                    // still in the password (false: on its way out)
                    readonly property bool alive: index < surface.lock.count

                    // its angle on the ring, and how far round from the mark that is
                    // (0 at the mark, growing for older beads)
                    readonly property real deg: surface.cfg.markDeg + index * surface.cfg.stepDeg + surface.lock.turn
                    readonly property real along: surface.cfg.markDeg - deg

                    // 1 at the mark .. 0 one notch away: size and colour follow it, so a
                    // bead turning onto the mark grows into "selected" instead of popping
                    readonly property real near: Math.max(0, 1 - Math.abs(along) / surface.cfg.stepDeg)

                    // far round the ring it fades, before it could reach the mark again
                    readonly property real fade: along <= surface.cfg.beadFadeFrom ? 1
                        : Math.max(0, 1 - (along - surface.cfg.beadFadeFrom) / (surface.cfg.beadFadeTo - surface.cfg.beadFadeFrom))

                    readonly property color fill: surface.mix(surface.mix(surface.mix(Roles.secondary, Roles.primary, near),
                                                                          Roles.primary, surface.done),
                                                              Roles.error, surface.alarm)

                    width: surface.cfg.beadSize
                    height: width
                    x: face.px(surface.cfg.ringRadius, deg) - width / 2
                    y: face.py(surface.cfg.ringRadius, deg) - height / 2

                    // it turns with the ring (its top faces out)
                    rotation: deg + 90
                    scale: Math.max(0, life.value) * (1 + (surface.cfg.beadSelectedScale - 1) * near)
                    opacity: Math.min(1, Math.max(0, life.value)) * fade

                    // 0 .. 1: pops in on the expressive fast spring (a little past 1, back),
                    // and out the same way
                    SpringValue {
                        id: life
                        to: 0
                        stiffness: Vars.springs.expressive.fast.spatial.stiffness
                        dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio
                        epsilon: 0.002
                    }
                    Component.onCompleted: if (alive) life.to = 1

                    // deleted: goes at once; cleared: the newest goes first, the rest
                    // one by one after it
                    onAliveChanged: {
                        if (alive) { leave.stop(); life.to = 1; return }
                        const from = surface.lock.clearedFrom
                        leave.interval = from > index ? Math.max(1, (from - 1 - index) * surface.cfg.beadStagger) : 1
                        leave.restart()
                    }
                    Timer {
                        id: leave
                        onTriggered: life.to = 0
                    }

                    Shape {
                        id: beadShape
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer

                        ShapePath {
                            strokeColor: "transparent"
                            fillColor: bead.fill
                            scale: shapes.fitScale(beadShape)
                            PathSvg { path: shapes.getPath(surface.cfg.beadShapes[bead.index % surface.cfg.beadShapes.length]) }
                        }
                    }
                }
            }

            // ── the mark ── the fixed point the ring turns to: a gem with the lock in it.
            // While PAM checks it turns into the M3E loading indicator; a wrong password
            // bursts it into the error colour; the right one opens the lock
            Item {
                id: mark
                width: surface.cfg.markSize
                height: width
                x: face.px(surface.cfg.markRadius, surface.cfg.markDeg) - width / 2
                y: face.py(surface.cfg.markRadius, surface.cfg.markDeg) - height / 2

                Item {
                    anchors.fill: parent
                    opacity: surface.lock.checking ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

                    ShapeMorph {
                        anchors.fill: parent
                        shape: surface.lock.wrong ? "SoftBoom" : surface.lock.unlocking ? "Circle" : "Gem"
                        color: surface.mix(Roles.primary, Roles.error, surface.alarm)
                    }
                    SymbolIcon {
                        anchors.centerIn: parent
                        text: surface.lock.unlocking ? "lock_open" : "lock"
                        size: surface.cfg.markIconSize
                        filled: true
                        color: surface.mix(Roles.on_primary, Roles.on_error, surface.alarm)
                    }
                }

                LoadingIndicator {
                    anchors.fill: parent
                    running: surface.lock.checking
                    indicatorColor: Roles.primary
                    backgroundColor: "transparent"
                }
            }

            // what the lock has to say, along the top of the inside of the ring
            CurvedText {
                anchors.fill: parent
                cx: face.cx
                cy: face.cy
                radius: surface.cfg.textRadius
                centerDeg: -90
                maxDeg: surface.cfg.textMaxDeg
                text: surface.lock.statusText
                font.pixelSize: surface.cfg.statusFontSize
                font.weight: 600
                color: surface.lock.statusTone === "error" ? Roles.error
                    : surface.lock.statusTone === "warn" ? Roles.tertiary
                    : Roles.on_surface_variant
            }
        }

        // ── Dial-E, keeping watch ── (Settings → Extras → Mascots) small, on the dial's rim at
        // the bottom: asleep until you come back, its eyes on the pointer
        Mascot {
            id: keeper
            width: 30
            height: 30
            x: face.px(surface.cfg.dialRadius - 4, 90) - width / 2
            y: face.py(surface.cfg.dialRadius - 4, 90) - height / 2
            kind: "dial-e"
            calm: Prefs.calm
            body: Roles.primary_container
            ink: Roles.on_primary_container
            eyeWhite: Roles.primary_fixed
            pupil: Roles.on_primary_fixed
            accent: Roles.primary
            visible: Prefs.mascots
            asleep: !surface.lock.awake
            look: {
                const dx = surface.pointer.x - (face.x + x + width / 2), dy = surface.pointer.y - (face.y + y + height / 2)
                const d = Math.max(1, Math.hypot(dx, dy))
                return Qt.point(dx / d, dy / d)
            }
            // a bob per letter, a flinch per deletion; it cries at a wrong password, and is glad at
            // the right one
            property int lastCount: 0
            Connections {
                target: surface.lock
                function onCountChanged() {
                    if (!surface.lock.wrong && !surface.lock.unlocking)
                        keeper.react(surface.lock.count > keeper.lastCount ? "type" : "delete")
                    keeper.lastCount = surface.lock.count
                }
                function onWrongChanged() { if (surface.lock.wrong) keeper.react("wrong") }
                function onUnlockingChanged() { if (surface.lock.unlocking) keeper.react("right") }
            }
        }

        // ── the centre: now ── the clock (the control center's, bigger), and the date
        // along the bottom of the inside of the ring. They stay put while the ring comes
        // and goes round them
        Row {
            anchors.centerIn: parent
            spacing: surface.cfg.clockGap
            visible: !surface.eclipse

            ClockFace { cfg: surface.cfg; part: "hours"; anchors.verticalCenter: parent.verticalCenter }
            ClockFace { cfg: surface.cfg; part: "minutes"; anchors.verticalCenter: parent.verticalCenter }
            ClockFace {
                cfg: surface.cfg
                part: "ampm"
                anchors.verticalCenter: parent.verticalCenter
                visible: surface.cfg.clockFormat === "12hAmPm"
            }
        }

        CurvedText {
            anchors.fill: parent
            cx: face.cx
            cy: face.cy
            radius: surface.cfg.textRadius
            centerDeg: 90
            maxDeg: surface.cfg.textMaxDeg
            text: Qt.formatDate(clock.date, "dddd d MMMM")
            font.pixelSize: surface.cfg.dateFontSize
            font.weight: 600
            color: Roles.on_surface
        }
    }

    // ── Eclipse ── over the dial, and not faded with it as the lock opens: its beads fly
    // off to the dials while the sheet goes back
    Loader {
        anchors.fill: parent
        active: surface.eclipse
        opacity: surface.faceShown || surface.lock.unlocking ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
        sourceComponent: EclipseBeads {
            host: surface
            cx: surface.width / 2
            cy: surface.height / 2
            pointer: surface.pointer
        }
    }

    // One row of ticks round the ring: short dashes on a thin circle, one between each two
    // beads, sliding round as the ring turns. The circle starts at `startDeg` (the mark);
    // `turn` is how far the ring has turned, degrees
    component TickRow: ShapePath {
        id: row
        required property real radius
        required property real cx
        required property real cy
        required property real stepDeg
        required property real startDeg
        required property real turn

        // px from one tick to the next, and how long a tick is along the ring
        readonly property real period: stepDeg * Math.PI / 180 * radius
        readonly property real tickLength: 2

        strokeStyle: ShapePath.DashLine
        capStyle: ShapePath.FlatCap
        fillColor: "transparent"

        // dashes are measured in stroke widths
        dashPattern: [tickLength / strokeWidth, (period - tickLength) / strokeWidth]

        // each tick's middle half a notch past a bead's place
        dashOffset: (tickLength / 2 - radius * (0.5 * stepDeg + turn) * Math.PI / 180) / strokeWidth

        PathAngleArc {
            centerX: row.cx; centerY: row.cy
            radiusX: row.radius; radiusY: row.radius
            startAngle: row.startDeg; sweepAngle: 360
        }
    }

    // ── the hand ── every key is the lock's; a move, a click or the wheel wakes the ring
    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => { event.accepted = surface.lock.key(event) }
        Component.onCompleted: forceActiveFocus()
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onPositionChanged: mouse => { surface.pointer = Qt.point(mouse.x, mouse.y); surface.lock.moved() }
        onPressed: { surface.lock.poke(); keys.forceActiveFocus() }
        onWheel: surface.lock.poke()
    }
}
