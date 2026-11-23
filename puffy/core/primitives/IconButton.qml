import QtQuick
import "../../theme"

// Circular icon button (back buttons, close buttons, etc). Used throughout the Control Center
// submenus (WifiMenu, BluetoothMenu, DiskMenu, DisplayMenu) and anywhere else that needs the
// same hover/press-tinted circle.
Rectangle {
    id: root

    property string icon: ""
    property int size: 40
    property int iconSize: 20
    property color iconColor: Theme.on_surface

    signal clicked()

    width: size
    height: size
    radius: size / 2
    antialiasing: true
    color: mouseArea.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (mouseArea.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }

    QsText {
        anchors.centerIn: parent
        font.family: "Material Symbols Outlined"
        font.pixelSize: root.iconSize
        antialiasing: true
        renderType: Text.QtRendering
        font.hintingPreference: Font.PreferNoHinting
        color: root.iconColor
        text: root.icon
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
