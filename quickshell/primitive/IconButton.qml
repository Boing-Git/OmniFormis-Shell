import QtQuick
import "../variables.js" as Vars

// An M3 Expressive icon button: a container that is round at rest and squares up while
// pressed (the expressive shape morph, on an M3E spring), with the M3 state layer (a
// wash of the content colour) on hover and press. Primitives never pick a colour: pass
// them all in ("transparent" container for a standard icon button).
//
//   IconButton {
//       icon: "save"
//       containerColor: "transparent"; contentColor: Roles.on_surface_variant
//       onClicked: ...
//   }
//
// Sizes follow "Design language/src/tokens/defaults/icon-button.ts" (small: 40 px, icon
// 24, pressed corner 8; medium: 56 px, pressed corner 12).
Item {
    id: root

    // the Material Symbols icon, and whether it's drawn filled
    property string icon: ""
    property bool filled: false

    // the container (square) and the icon
    property real size: 40
    property real iconSize: 24

    // corner radius at rest (round by default) and while pressed (squarer)
    property real radius: size / 2
    property real pressedRadius: 8

    required property color containerColor
    required property color contentColor

    // M3 state layer opacities (Design language/src/tokens/defaults/state.ts)
    property real hoverOpacity: 0.08
    property real pressedOpacity: 0.1

    // a short name for it (e.g. for a tooltip)
    property string label: ""

    readonly property bool hovered: mouse.containsMouse
    readonly property bool pressed: mouse.pressed

    signal clicked()

    implicitWidth: size
    implicitHeight: size

    // the corner on an M3E fast spatial spring, so a quick press still overshoots a little
    SpringValue {
        id: corner
        to: root.pressed ? root.pressedRadius : root.radius
        stiffness: Vars.springs.expressive.fast.spatial.stiffness
        dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio
        epsilon: 0.05
        Component.onCompleted: snap(to)
    }

    Rectangle {
        anchors.fill: parent
        radius: Math.max(0, Math.min(Math.min(width, height) / 2, corner.value))
        color: root.containerColor
        antialiasing: true
        Behavior on color { ColorAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

        // the state layer
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            antialiasing: true
            color: root.contentColor
            opacity: root.pressed ? root.pressedOpacity : root.hovered ? root.hoverOpacity : 0
            Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
        }
    }

    SymbolIcon {
        anchors.centerIn: parent
        text: root.icon
        size: root.iconSize
        filled: root.filled
        color: root.contentColor
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
