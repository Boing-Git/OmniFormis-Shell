import QtQuick
import "../../theme"

// The 56x32 pill switch with a sliding knob, used for the Wi-Fi/Bluetooth master toggles in
// Control Center's submenus.
Rectangle {
    id: root

    property bool checked: false
    signal toggled()

    width: 56
    height: 32
    radius: 16
    antialiasing: true
    color: checked ? (Vars.tColorSelected(Theme.primary)) : (Vars.tColor(Theme.surface_variant, Vars.componentOpacity))
    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }

    Rectangle {
        antialiasing: true
        width: 24
        height: 24
        radius: 12
        color: root.checked ? Theme.on_primary : Theme.on_surface_variant
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: root.checked ? 28 : 4
        Behavior on anchors.leftMargin { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
