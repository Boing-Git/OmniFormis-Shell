import QtQuick
import QtQuick.Shapes
import ".."
import "../primitive"
import "../variables.js" as Vars

// A pill on the control center's inner ring: a device / network / action with its
// icon and name, and a badge on the selected one (number, spinner, check or link).
Item {
    id: root

    // set by the dial
    required property var dial
    required property var shapes

    // filled in by DialRing: which entry, this slot's angle, whether it's the selected one
    property int itemIndex
    property real ringDeg
    property bool selected
    property bool clicked

    // the settings (controlcenter/ControlCenterSettings.qml, inner ring section)
    readonly property var cfg: dial.settings

    readonly property var entry: dial.subItems[itemIndex]

    // "loading" | "connected" | "paired" | "none"
    readonly property string status: entry && entry.status ? entry.status : "none"

    // ── arranging (Edit in the Dials control) ──
    // the pill is lifted off the ring (being dragged): only a faint copy stays behind
    readonly property bool lifted: dial.liftedIndex === itemIndex

    // a pill that can be dragged wiggles while Edit is on, each a little out of step
    readonly property bool jiggling: !!dial.arranging && !!entry && !!entry.drag && !lifted
    property real jiggleAmount: jiggling ? 1 : 0
    Behavior on jiggleAmount { NumberAnimation { duration: Vars.expressiveDefaultEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveDefaultEffects.bezier } }
    property real jigglePhase: 0
    NumberAnimation on jigglePhase {
        from: 0; to: Math.PI * 2
        duration: dial.arrange.jigglePeriod
        loops: Animation.Infinite
        running: root.jiggleAmount > 0
    }
    readonly property real jiggleOffset: itemIndex * 2.1

    // the slot follows the ring, so the name runs along the arc; on corners where that
    // would read upside down, turn it half a turn more. Decided by the dial's corner, not
    // each pill's own angle, so every pill on the dial faces the same way (pills near the
    // screen edges used to flip on their own)
    rotation: {
        const a = ((dial.midDeg + 90) % 360 + 360) % 360
        return a > 90 && a < 270 ? 180 : 0
    }

    Rectangle {
        id: pill

        // as long as the icon and name need (plus a little room), as tall as the slot
        anchors.centerIn: parent
        width: content.width + cfg.pillPadding + (selected ? cfg.selectedPillGrowW : 0)
        height: parent.height + (selected ? cfg.selectedPillGrowH : 0)
        radius: height / 2
        antialiasing: true
        // grows when selected, on a spring: it keeps its speed when the selection moves on
        // mid-growth, where a fixed curve would start again from rest
        scale: grow.value
        SpringValue {
            id: grow
            to: root.selected ? root.cfg.selectedPillScale : Prefs.inactiveScale
            stiffness: Vars.springs.expressive.fast.spatial.stiffness
            dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio
            epsilon: 0.001
            Component.onCompleted: snap(to)
        }

        // the selected one is primary, loading ones tertiary, connected ones primary-container
        property color fill: selected ? Roles.primary
            : root.status === "loading" ? Roles.tertiary_container
            : entry && entry.on ? Roles.primary_container
            : Roles.surface_container_high

        // the text on top of `fill`
        property color ink: selected ? Roles.on_primary
            : root.status === "loading" ? Roles.on_tertiary_container
            : entry && entry.on ? Roles.on_primary_container
            : Roles.on_surface

        // the rectangle only draws when the M3 pill shape isn't used
        color: cfg.m3Pills ? "transparent" : fill

        // left behind faint while it's dragged
        opacity: root.lifted ? dial.arrange.liftedOpacity : 1
        Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

        // the wiggle while arranging: a tilt and a little bob (on top of `rotation`, which
        // the selection wiggle uses)
        transform: [
            Rotation {
                origin.x: pill.width / 2
                origin.y: pill.height / 2
                angle: dial.arrange.jiggleDeg * root.jiggleAmount * Math.sin(root.jigglePhase + root.jiggleOffset)
            },
            Translate {
                y: dial.arrange.jiggleLift * root.jiggleAmount * Math.sin(root.jigglePhase * 2 + root.jiggleOffset)
            }
        ]

        Behavior on fill {
            ColorAnimation {
                duration: Vars.expressiveFastEffects.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.expressiveFastEffects.bezier
            }
        }
        // a quick tilt and a bouncy settle once the ring rests on this pill (not on every pill
        // a fast turn passes)
        // (on `pill`, not `root`: root's rotation keeps the name from reading upside down)
        SequentialAnimation {
            id: wiggle
            NumberAnimation { target: pill; property: "rotation"; to: -cfg.pillWiggleDeg; duration: cfg.pillWiggleIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.fastSpatial.bezier }
            NumberAnimation { target: pill; property: "rotation"; to: 0; duration: cfg.pillWiggleOut; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.fastSpatial.bezier }
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

        // the M3 "Pill" at its own proportions (a square box, never stretched), sized so
        // the capsule (0.95 of its box) just covers the name, turned so it lies level
        Shape {
            id: m3Pill
            anchors.centerIn: parent
            width: Math.max(cfg.pillHeight, (content.width + cfg.pillPadding - 2) / 0.95)
            height: width
            rotation: 45
            visible: cfg.m3Pills
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: pill.fill
                strokeColor: "transparent"
                scale: root.shapes.fitScale(m3Pill)
                PathSvg { path: root.shapes.getPath("Pill") }
            }
        }

        // the badge on the top-right corner of the selected pill
        // (controls with `badges: false` don't get one)
        Shape {
            id: badge
            width: cfg.badgeSize
            height: cfg.badgeSize
            visible: selected && dial.badgesEnabled
            preferredRendererType: Shape.CurveRenderer
            anchors.horizontalCenter: parent.right
            anchors.verticalCenter: parent.top
            anchors.horizontalCenterOffset: -cfg.badgeInset
            anchors.verticalCenterOffset: cfg.badgeInset
            z: 2

            // twirls in when the pill is selected
            scale: selected ? 1 : 0
            rotation: selected ? 0 : -cfg.badgeSpinInDeg
            Behavior on scale { NumberAnimation { duration: cfg.badgePopDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.fastSpatial.bezier } }
            Behavior on rotation { NumberAnimation { duration: cfg.badgeSpinDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.fastSpatial.bezier } }

            ShapePath {
                fillColor: Roles.on_primary
                strokeColor: "transparent"
                scale: root.shapes.fitScale(badge)
                PathSvg { path: root.shapes.getPath(root.cfg.badgeShape) }
            }

            // loading: a spinner, only created while it's needed
            Loader {
                anchors.centerIn: parent
                z: 1
                active: root.status === "loading" && badge.visible
                sourceComponent: LoadingIndicator {
                    width: root.cfg.spinnerSize
                    height: root.cfg.spinnerSize
                    running: true
                    indicatorColor: Roles.primary
                    backgroundColor: "transparent"
                }
            }

            // number / check / link, or the entry's own `badgeIcon` (e.g. where a dial
            // lives): hidden while loading
            SymbolIcon {
                anchors.centerIn: parent
                z: 1
                visible: root.status !== "loading"
                readonly property string own: entry && entry.badgeIcon ? entry.badgeIcon : ""

                // an entry's own words for the badge (e.g. how many notifications an app has)
                readonly property string ownText: entry && entry.badgeText !== undefined ? String(entry.badgeText) : ""
                readonly property bool isIcon: own !== "" || (ownText === "" && (root.status === "connected" || root.status === "paired"))
                text: own !== "" ? own : ownText !== "" ? ownText
                    : root.status === "connected" ? "check" : root.status === "paired" ? "link" : root.itemIndex + 1

                // an entry's own icon (e.g. an arrow to where a dial lives) points the same way
                // on screen however the pill is turned: undo the ring's turn, the flip, the
                // selection wiggle and the badge's twirl
                rotation: own !== "" ? -(root.ringDeg + 90 + root.rotation + pill.rotation + badge.rotation) : 0
                family: isIcon ? "Material Symbols Rounded" : Prefs.fontFamily
                size: isIcon ? cfg.badgeIconSize : cfg.badgeNumberSize
                filled: selected
                color: Roles.primary
            }
        }

        // the icon and the name, side by side in the middle
        Row {
            id: content
            anchors.centerIn: parent
            spacing: cfg.pillIconSpacing

            // the icon on its own M3 shape, which swaps shape and spins on the selected pill
            Item {
                width: cfg.pillIconSize + cfg.pillIconShapePad
                height: width
                anchors.verticalCenter: parent.verticalCenter

                Shape {
                    id: iconShape
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer

                    // turned by pillIconShapeTurn (e.g. 45 lays the diagonal M3 "Pill" level)
                    rotation: cfg.pillIconShapeTurn
                    ShapePath {
                        fillColor: selected ? Roles.on_primary : Roles.tertiary_container
                        strokeColor: "transparent"
                        scale: root.shapes.fitScale(iconShape)
                        // an entry can wear its own shape (e.g. the app a notification came from)
                        PathSvg { path: root.shapes.getPath(entry && entry.iconShape ? entry.iconShape : selected ? cfg.selectedPillIconShape : cfg.pillIconShape) }
                    }
                    RotationAnimation on rotation {
                        from: cfg.pillIconShapeTurn; to: cfg.pillIconShapeTurn + 360
                        duration: Math.max(1, cfg.pillIconSpin)
                        loops: Animation.Infinite
                        running: selected && cfg.pillIconSpin > 0
                    }
                }

                SymbolIcon {
                    anchors.centerIn: parent
                    text: entry ? entry.icon : ""
                    size: cfg.pillIconSize
                    filled: selected
                    color: selected ? Roles.primary : Roles.on_tertiary_container
                }
            }

            // the pill grows to fit the name, up to labelMax; the rest becomes "…"
            SmoothText {
                anchors.verticalCenter: parent.verticalCenter
                text: entry ? entry.label : ""
                width: Math.min(implicitWidth, cfg.pillLabelMax)
                elide: Text.ElideRight
                font.pixelSize: cfg.pillLabelSize
                color: pill.ink
            }
        }
    }
}
