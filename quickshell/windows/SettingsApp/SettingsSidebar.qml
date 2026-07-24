import QtQuick
import QtQuick.Layouts
import "../.."
import "../../theme/variables.js" as Vars

ColumnLayout {
    id: rootSidebar
    
    property string currentSection: "wifi"
    property string wifiIcon: "\ue1d8"
    property string bluetoothIcon: "\ue1a7"

    Layout.fillWidth: true
    spacing: 4

    FontLoader {
        id: filledIconFont
        source: "../../theme/assets/MaterialSymbolsRounded-Filled.ttf"
    }

    Repeater {
        model: [
            // Connections
            { id: "wifi", name: "Wi-Fi", subtitle: "Wi-Fi, ethernet", icon: rootSidebar.wifiIcon, section: "Connections", isFirst: true, isLast: false },
            { id: "bluetooth", name: "Bluetooth", subtitle: "Bluetooth, pairing", icon: rootSidebar.bluetoothIcon, section: "Connections", isFirst: false, isLast: true },
            
            // General and Appearance
            { id: "General", name: "General", subtitle: "System config, spacing, layout", icon: "\ue8b8", section: "General and Appearance", isFirst: true, isLast: false },
            { id: "Appearance", name: "Appearance", subtitle: "Theme, rounding, colors", icon: "\ue3b7", section: "General and Appearance", isFirst: false, isLast: false },
            { id: "Input", name: "Input", subtitle: "Keyboard, mouse, gestures", icon: "\ue312", section: "General and Appearance", isFirst: false, isLast: false },
            { id: "bezier", name: "Motion", subtitle: "Custom curve editor", icon: "\ue922", section: "General and Appearance", isFirst: false, isLast: true },
            
            // System
            { id: "taskmanager", name: "Task Manager", subtitle: "System resources, processes", icon: "\ue85c", section: "System", isFirst: true, isLast: false },
            { id: "about", name: "About", subtitle: "Omniformis Shell info", icon: "\ue88e", section: "System", isFirst: false, isLast: true }
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

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 72
                property bool isSelected: rootSidebar.currentSection === modelData.id
                
                // Determine target color (which may contain alpha)
                property color targetColor: isSelected ? (Vars.translucent ? Qt.rgba(Theme.secondary_container.r, Theme.secondary_container.g, Theme.secondary_container.b, 0.5) : Theme.secondary_container) : (navHover.containsMouse ? Qt.tint((Vars.translucent ? Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 0.5) : Theme.surface_container), Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : (Vars.translucent ? Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 0.5) : Theme.surface_container))
                Behavior on targetColor { ColorAnimation { duration: Vars.animationDuration } }

                Item {
                    anchors.fill: parent
                    layer.enabled: true
                    opacity: parent.targetColor.a

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.parent.isSelected ? height / 2 : 16
                        Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                        color: Qt.rgba(parent.parent.targetColor.r, parent.parent.targetColor.g, parent.parent.targetColor.b, 1.0)
                        
                        // Square-off top corners if not the first item
                        Rectangle {
                            width: parent.radius; height: parent.radius; color: parent.color
                            anchors.top: parent.top; anchors.left: parent.left
                            opacity: (!modelData.isFirst && !parent.parent.parent.isSelected) ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                        }
                        Rectangle {
                            width: parent.radius; height: parent.radius; color: parent.color
                            anchors.top: parent.top; anchors.right: parent.right
                            opacity: (!modelData.isFirst && !parent.parent.parent.isSelected) ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                        }
                        // Square-off bottom corners if not the last item
                        Rectangle {
                            width: parent.radius; height: parent.radius; color: parent.color
                            anchors.bottom: parent.bottom; anchors.left: parent.left
                            opacity: (!modelData.isLast && !parent.parent.parent.isSelected) ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                        }
                        Rectangle {
                            width: parent.radius; height: parent.radius; color: parent.color
                            anchors.bottom: parent.bottom; anchors.right: parent.right
                            opacity: (!modelData.isLast && !parent.parent.parent.isSelected) ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                        }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 16
                    
                    Text {
                        text: modelData.icon
                        font.family: parent.parent.isSelected ? filledIconFont.name : "Material Symbols Outlined"
                        font.pixelSize: 24
                        color: parent.parent.isSelected ? Theme.on_secondary_container : Theme.on_surface_variant
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        Text {
                            text: modelData.name
                            font.family: Vars.fontFamily
                            font.pixelSize: 16
                            font.weight: parent.parent.isSelected ? 500 : 400
                            color: parent.parent.isSelected ? Theme.on_secondary_container : Theme.on_surface
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignLeft
                        }
                        Text {
                            text: modelData.subtitle
                            font.family: Vars.fontFamily
                            font.pixelSize: 12
                            color: parent.parent.isSelected ? Theme.on_secondary_container : Theme.on_surface_variant
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
