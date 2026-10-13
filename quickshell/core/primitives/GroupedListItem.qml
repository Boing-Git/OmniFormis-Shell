import QtQuick
import "../../theme"

// A row in a "sidebar style" grouped list (Wi-Fi networks, Bluetooth devices, etc): rows next to
// another row keep a small edge radius, while a row at the start or end of the group — where
// there's nothing adjacent — gets the full radius, matching SettingsSidebar.qml's nav list.
Rectangle {
    id: root

    property bool isFirst: false
    property bool isLast: false
    property bool selected: false
    property real baseRadius: Vars.radiusLarge
    property real edgeRadius: 4

    signal clicked()

    antialiasing: true
    topLeftRadius: isFirst ? baseRadius : edgeRadius
    topRightRadius: isFirst ? baseRadius : edgeRadius
    bottomLeftRadius: isLast ? baseRadius : edgeRadius
    bottomRightRadius: isLast ? baseRadius : edgeRadius
    Behavior on topLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
    Behavior on topRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
    Behavior on bottomLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
    Behavior on bottomRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }

    color: selected ? (Vars.tColorSelected(Theme.secondary_container)) : (mouseArea.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (mouseArea.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : (Vars.tColor(Theme.surface_container_low, Vars.componentOpacity))))
    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
