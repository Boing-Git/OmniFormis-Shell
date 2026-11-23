import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Networking
import "../../theme"
import "../.."
import "../../core/primitives" as Primitives

ColumnLayout {
    id: wifiMenu

    // Parent should set this to control visibility and animations
    property bool isActive: false
    signal backRequested()

    property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi)

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
            onClicked: wifiMenu.backRequested()
        }
        QsText { text: "Wi-Fi Networks"; font.family: Vars.fontFamily; font.pixelSize: 24; setWeight: Font.Bold; color: Theme.on_surface; Layout.fillWidth: true }

        Primitives.ToggleSwitch {
            checked: Networking.wifiEnabled
            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
        }
    }

    Flickable {
        id: wifiFlickable
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 450)
        contentHeight: wifiListContainer.implicitHeight; clip: true

        ColumnLayout {
            id: wifiListContainer
            width: wifiFlickable.width; spacing: Vars.spacingSmall

            Repeater {
                model: wifiMenu.wifiDevice ? wifiMenu.wifiDevice.networks.values : []
                delegate: Primitives.GroupedListItem {
                    Layout.fillWidth: true; Layout.preferredHeight: 64
                    isFirst: index === 0
                    isLast: index === (wifiMenu.wifiDevice ? wifiMenu.wifiDevice.networks.values.length - 1 : 0)
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
                                antialiasing: true
                                renderType: Text.QtRendering
                                font.hintingPreference: Font.PreferNoHinting
                                color: modelData.connected ? Theme.on_primary : Theme.on_surface_variant
                                text: {
                                    if (modelData.signalStrength === undefined) return "";
                                    let tier = Math.min(Math.floor(modelData.signalStrength / 25), 3);
                                    return ["", "", "", ""][tier] || "";
                                }
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            }
                        }

                        ColumnLayout {
                            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter; spacing: 0
                            QsText {
                                text: modelData.name; font.family: Vars.fontFamily; font.pixelSize: 14; setWeight: Font.Bold
                                color: modelData.connected ? Theme.on_surface : Theme.on_surface_variant
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            }
                            QsText {
                                text: modelData.connected ? "Connected" : "Available"; font.family: Vars.fontFamily; font.pixelSize: 12; opacity: 0.8
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
