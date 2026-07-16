import QtQuick
import QtQuick.Layouts
import "../.."
import "../../Variables/variables.js" as Vars

ColumnLayout {
    id: rootSidebar
    
    property string currentSection: "General"
    property string wifiIcon: "\ue1d8"
    property string bluetoothIcon: "\ue1a7"

    Layout.fillWidth: true
    spacing: 4

    Repeater {
        model: [
            { id: "General", name: "General", subtitle: "System config, spacing, layout", icon: "\ue8b8", section: "System", isFirst: true, isLast: false },
            { id: "Appearance", name: "Appearance", subtitle: "Theme, rounding, colors", icon: "\ue3b7", section: "System", isFirst: false, isLast: false },
            { id: "Input", name: "Input", subtitle: "Keyboard, mouse, gestures", icon: "\ue312", section: "System", isFirst: false, isLast: false },
            { id: "bezier", name: "Motion", subtitle: "Custom curve editor", icon: "\ue922", section: "System", isFirst: false, isLast: true },
            { id: "wifi", name: "Wi-Fi", subtitle: "Wi-Fi, ethernet", icon: rootSidebar.wifiIcon, section: "Connections", isFirst: true, isLast: false },
            { id: "bluetooth", name: "Bluetooth", subtitle: "Bluetooth, pairing", icon: rootSidebar.bluetoothIcon, section: "Connections", isFirst: false, isLast: true }
        ]
        delegate: ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

            Text {
                visible: modelData.isFirst
                text: modelData.section
                color: Theme.primary
                font.pixelSize: 14
                font.bold: true
                font.family: Vars.fontFamily
                Layout.topMargin: index === 0 ? 0 : 8
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 72
                property bool isSelected: rootSidebar.currentSection === modelData.id
                radius: isSelected ? height / 2 : 16
                Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
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
                    opacity: (!modelData.isFirst && !parent.isSelected) ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                }
                Rectangle {
                    width: parent.radius; height: parent.radius; color: parent.color
                    anchors.top: parent.top; anchors.right: parent.right
                    opacity: (!modelData.isFirst && !parent.isSelected) ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                }
                // Square-off bottom corners if not the last item
                Rectangle {
                    width: parent.radius; height: parent.radius; color: parent.color
                    anchors.bottom: parent.bottom; anchors.left: parent.left
                    opacity: (!modelData.isLast && !parent.isSelected) ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                }
                Rectangle {
                    width: parent.radius; height: parent.radius; color: parent.color
                    anchors.bottom: parent.bottom; anchors.right: parent.right
                    opacity: (!modelData.isLast && !parent.isSelected) ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
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
}
