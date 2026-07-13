import QtQuick
import QtQuick.Layouts
import "../.."
import "../../Variables/variables.js" as Vars

ColumnLayout {
    id: rootSidebar
    
    property string currentSection: "hyprland"
    property string wifiIcon: "\ue1d8"
    property string bluetoothIcon: "\ue1a7"

    Layout.fillWidth: true
    spacing: 4

    Repeater {
        model: [
            { id: "hyprland", name: "Hyprland", subtitle: "Configuration, appearance", icon: "\ue8b8" }, // settings
            { id: "wifi", name: "Wi-Fi", subtitle: "Wi-Fi, ethernet", icon: rootSidebar.wifiIcon },
            { id: "bluetooth", name: "Bluetooth", subtitle: "Bluetooth, pairing", icon: rootSidebar.bluetoothIcon }
        ]
        delegate: Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 72
            property bool isSelected: rootSidebar.currentSection === modelData.id
            radius: isSelected ? height / 2 : 16
            Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
            color: isSelected ? Theme.secondary_container : (navHover.containsMouse ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : Theme.surface_container)
            border.color: activeFocus ? Theme.on_surface : "transparent"
            border.width: activeFocus ? 2 : 0
            activeFocusOnTab: true
            Keys.onSpacePressed: rootSidebar.currentSection = modelData.id
            Keys.onReturnPressed: rootSidebar.currentSection = modelData.id
            Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
            
            // Square-off top corners if not the first item
            Rectangle {
                width: parent.radius; height: parent.radius; color: parent.color
                anchors.top: parent.top; anchors.left: parent.left
                opacity: (index > 0 && !parent.isSelected) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
            }
            Rectangle {
                width: parent.radius; height: parent.radius; color: parent.color
                anchors.top: parent.top; anchors.right: parent.right
                opacity: (index > 0 && !parent.isSelected) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
            }
            // Square-off bottom corners if not the last item
            Rectangle {
                width: parent.radius; height: parent.radius; color: parent.color
                anchors.bottom: parent.bottom; anchors.left: parent.left
                opacity: (index < 2 && !parent.isSelected) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
            }
            Rectangle {
                width: parent.radius; height: parent.radius; color: parent.color
                anchors.bottom: parent.bottom; anchors.right: parent.right
                opacity: (index < 2 && !parent.isSelected) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 16
                
                Text {
                    text: modelData.icon
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 24
                    color: parent.isSelected ? Theme.on_secondary_container : Theme.on_surface_variant
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: modelData.name
                        font.family: Vars.fontFamily
                        font.pixelSize: 16
                        font.weight: parent.isSelected ? 500 : 400
                        color: parent.isSelected ? Theme.on_secondary_container : Theme.on_surface
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                    }
                    Text {
                        text: modelData.subtitle
                        font.family: Vars.fontFamily
                        font.pixelSize: 12
                        color: parent.isSelected ? Theme.on_secondary_container : Theme.on_surface_variant
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                        opacity: 0.9
                    }
                }
            }
            
            MouseArea {
                id: navHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: rootSidebar.currentSection = modelData.id
            }
        }
    }
}
