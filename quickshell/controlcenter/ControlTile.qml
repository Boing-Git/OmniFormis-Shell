import QtQuick
import QtQuick.Shapes
import ".."
import "../primitive"
import "../variables.js" as Vars

// A tile on the control center's outer ring: the control's M3 shape with its icon.
// The selected tile grows, fills in, turns primary, wiggles and slowly spins its shape.
Item {
    id: root

    // set by the dial
    required property var controls

    // ControlCenterSettings
    required property var cfg
    required property var shapes
    required property size shapeScale

    // filled in by DialRing: which entry, this slot's angle, whether it's the selected one
    property int itemIndex
    property real ringDeg
    property bool selected
    property bool clicked

    readonly property var entry: controls[itemIndex]

    // ── dragging (ArrangeLayer) ── something held over this tile that it takes (a device
    // with an action here, or another tile while reordering): it "inhales", growing on a
    // spring; and this tile is the one lifted off (only a faint copy stays)
    property bool dropHot: false
    property bool lifted: false
    property real inhaleScale: 1.25
    property real liftedOpacity: 0.3
    SpringValue {
        id: inhale
        to: root.dropHot ? root.inhaleScale : 1
        stiffness: Vars.springs.expressive.fast.spatial.stiffness
        dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio
        epsilon: 0.002
        value: 1
    }
    scale: inhale.value

    // ── Edit ── every tile wiggles while arranging (not the one lifted off), each a little
    // out of step, like app icons on a phone
    property bool jiggling: false
    property real jiggleDeg: 4
    property real jiggleLift: 1
    property int jigglePeriod: 50
    property real jiggleAmount: jiggling && !lifted ? 1 : 0
    Behavior on jiggleAmount { NumberAnimation { duration: Vars.expressiveDefaultEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveDefaultEffects.bezier } }
    property real jigglePhase: 0
    NumberAnimation on jigglePhase {
        from: 0; to: Math.PI * 2
        duration: root.jigglePeriod
        loops: Animation.Infinite
        running: root.jiggleAmount > 0
    }
    opacity: lifted ? liftedOpacity : 1
    Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

    // the unselected tiles take turns through the container colours, or all wear one
    // (Prefs.ringColors): 0 primary, 1 secondary, 2 tertiary
    readonly property int tone: Prefs.ringColors === "three" ? itemIndex % 3
        : Math.max(0, ["primary", "secondary", "tertiary"].indexOf(Prefs.ringColors))
    readonly property color fill: selected ? Roles.primary
        : tone === 1 ? Roles.secondary_container
        : tone === 2 ? Roles.tertiary_container
        : Roles.primary_container
    readonly property color ink: selected ? Roles.on_primary
        : tone === 1 ? Roles.on_secondary_container
        : tone === 2 ? Roles.on_tertiary_container
        : Roles.on_primary_container

    // cancel the ring's tilt: the whole tile stays upright
    rotation: -(ringDeg + 90)

    // the tile itself: grows when selected, and wiggles (its own rotation, so the
    // upright-keeping rotation above is left alone)
    Item {
        id: tile
        anchors.fill: parent
        // grows when selected, on a spring: it keeps its speed when the selection moves on
        // mid-growth (a fast spin), where a fixed curve would start again from rest
        scale: grow.value
        SpringValue {
            id: grow
            to: root.selected ? root.cfg.selectedTileSize / root.cfg.tileSize : 1
            stiffness: Vars.springs.expressive.fast.spatial.stiffness
            dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio
            epsilon: 0.001
            Component.onCompleted: snap(to)
        }

        // the Edit wiggle: a tilt and a little hop, on top of `rotation` (which the
        // selection wiggle uses)
        transform: [
            Rotation {
                origin.x: tile.width / 2
                origin.y: tile.height / 2
                angle: root.jiggleDeg * root.jiggleAmount * Math.sin(root.jigglePhase + root.itemIndex * 2.1)
            },
            Translate {
                y: root.jiggleLift * root.jiggleAmount * Math.sin(root.jigglePhase * 2 + root.itemIndex * 2.1)
            }
        ]
        // a quick tilt and a bouncy settle once the ring rests on this tile (not on every tile a
        // fast spin passes: a row of wiggles is noise, and a tax on the 500th spin)
        SequentialAnimation {
            id: wiggle
            NumberAnimation { target: tile; property: "rotation"; to: -cfg.tileWiggleDeg; duration: cfg.tileWiggleIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.fastSpatial.bezier }
            NumberAnimation { target: tile; property: "rotation"; to: 0; duration: cfg.tileWiggleOut; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.fastSpatial.bezier }
        }
        Connections {
            target: root
            function onSelectedChanged() { if (root.selected) wiggleWait.restart(); else wiggleWait.stop() }
        }
        Timer {
            id: wiggleWait
            interval: Vars.expressiveFastEffects.duration

            // no wiggle with Bounce 0: it is a bounce
            onTriggered: if (root.selected && !Prefs.calm) wiggle.restart()
        }

        // the shape: spins slowly on the selected tile (the icon below stays upright)
        Shape {
            id: tileShape
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer

            RotationAnimation on rotation {
                from: 0; to: 360
                duration: Math.max(1, cfg.tileSpin)
                loops: Animation.Infinite
                running: selected && cfg.tileSpin > 0
            }

            // M3E FAB menu: items are container colours, the selected one primary
            ShapePath {
                fillColor: root.fill
                strokeColor: "transparent"
                scale: shapeScale
                PathSvg { path: shapes.getPath(selected ? entry.shapeSelected : entry.shape) }
                // colour on the effects curve: colours never bounce (a spatial curve overshoots
                // past the new colour and comes back, which shows as a flash)
                Behavior on fillColor {
                    ColorAnimation {
                        duration: Vars.expressiveFastEffects.duration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Vars.expressiveFastEffects.bezier
                    }
                }
            }
        }

        SymbolIcon {
            anchors.centerIn: parent
            z: 1
            text: entry.icon
            size: cfg.tileIconSize
            filled: selected
            color: root.ink
            Behavior on color {
                ColorAnimation {
                    duration: Vars.expressiveFastEffects.duration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Vars.expressiveFastEffects.bezier
                }
            }
        }
    }
}
