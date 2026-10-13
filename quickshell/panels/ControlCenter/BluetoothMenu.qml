import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import "../../theme"
import "../.."
import "../../core/primitives" as Primitives

ColumnLayout {
    id: bluetoothMenu

    // Parent should set this to control visibility and animations
    property bool isActive: false
    signal backRequested()

    property var adapter: Bluetooth.defaultAdapter
    property bool adapterState: adapter ? adapter.enabled : false
    // Pre-filtered so the Repeater's index lines up with visual position (needed for the grouped
    // list's isFirst/isLast), instead of including hidden devices and giving them a 0-height row.
    property var pairedDevices: adapterState && adapter ? adapter.devices.values.filter(d => d.paired || d.connected) : []

    // Remove anchors.fill to allow dynamic implicit height
    anchors.margins: Vars.spacingLarge
    spacing: Vars.spacingMedium

    FontLoader {
        id: filledIconFont
        source: "../../theme/assets/MaterialSymbolsRounded-Filled.ttf"
    }

    opacity: isActive ? 1.0 : 0.0
    visible: opacity > 0
    transform: Translate {
        x: isActive ? 0 : 40
        Behavior on x { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
    }
    Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: isActive ? Vars.customEmphasizedDecelerate : Vars.customEmphasizedAccelerate } }

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: Vars.spacingMedium

        Primitives.IconButton {
            icon: ""
            onClicked: bluetoothMenu.backRequested()
        }
        QsText { text: "Bluetooth Devices"; font.family: Vars.fontFamily; font.pixelSize: 24; setWeight: Font.Bold; color: Theme.on_surface; Layout.fillWidth: true }

        Primitives.ToggleSwitch {
            checked: bluetoothMenu.adapterState
            onToggled: if (bluetoothMenu.adapter) bluetoothMenu.adapter.enabled = !bluetoothMenu.adapter.enabled
        }
    }

    Flickable {
        id: bluetoothFlickable
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 450)
        contentHeight: bluetoothListContainer.implicitHeight; clip: true

        ColumnLayout {
            id: bluetoothListContainer
            width: bluetoothFlickable.width; spacing: Vars.spacingSmall

            Repeater {
                model: bluetoothMenu.pairedDevices
                delegate: Primitives.GroupedListItem {
                    Layout.fillWidth: true; Layout.preferredHeight: 64
                    isFirst: index === 0
                    isLast: index === bluetoothMenu.pairedDevices.length - 1
                    selected: modelData.connected
                    onClicked: {
                        if (modelData.connected) {
                            modelData.disconnect();
                        } else {
                            modelData.connect();
                        }
                    }

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 16; spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 40; Layout.preferredHeight: 40
                            radius: modelData.connected ? 12 : 20
                            antialiasing: true
                            Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            color: modelData.connected ? Theme.primary : Theme.surface_variant
                            QsText {
                                anchors.centerIn: parent
                                font.family: modelData.connected ? filledIconFont.name : "Material Symbols Outlined"
                                font.pixelSize: 22
                                color: modelData.connected ? Theme.on_primary : Theme.on_surface_variant
                                text: ""
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            }
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter; spacing: 0
                            QsText {
                                text: modelData.name ? modelData.name : "Unknown Device"; font.family: Vars.fontFamily; font.pixelSize: 14; setWeight: Font.Bold
                                color: modelData.connected ? Theme.on_surface : Theme.on_surface_variant
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            }
                            QsText {
                                text: modelData.connected ? "Connected" : "Paired"; font.family: Vars.fontFamily; font.pixelSize: 12; opacity: 0.8
                                color: Theme.on_surface_variant
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            }
                        }

                        Item { Layout.fillWidth: true } // Spacer pushes everything to the left
                    }
                }
            }
        }
    }
}
