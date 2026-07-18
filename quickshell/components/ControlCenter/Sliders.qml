import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Io
import "../../Variables/variables.js" as Vars
import "../.."

ColumnLayout {
    id: sliders
    Layout.fillWidth: true
    spacing: 8

    property int trackHeight: 40
    property int gap: 2
    property int handleWidth: 4
    property real leftRadiusLarge: 12
    property real leftRadiusSmall: 4
    property real dotSize: 6

    property var audioNode: Pipewire.defaultAudioSink
    property real currentVolume: audioNode && audioNode.audio ? audioNode.audio.volume : 0.0
    property real currentBrightness: 1 // Default fallback

    Component.onCompleted: {
        ddcQueryProcess.running = true;
    }

    Process {
        id: ddcQueryProcess
        command: ["ddcutil", "getvcp", "10", "-t"]
        stdout: StdioCollector {
            onStreamFinished: {
                let parts = this.text.trim().split(" ");
                if (parts.length >= 4) {
                    let b = parseInt(parts[3]);
                    if (!isNaN(b)) {
                        currentBrightness = b / 100.0;
                    }
                }
            }
        }
    }

    Timer {
        id: ddcSetTimer
        interval: 100 // Debounce to avoid overloading the I2C bus
        onTriggered: {
            let b = Math.round(currentBrightness * 100);
            ddcSetProcess.command = ["ddcutil", "setvcp", "10", b.toString()];
            ddcSetProcess.running = true;
        }
    }

    Process {
        id: ddcSetProcess
    }

    Slider {
        id: volumeSlider
        Layout.fillWidth: true
        implicitWidth: 320
        implicitHeight: 48 // Strict M3 48dp minimum touch target bounding box
        padding: 0

        value: currentVolume
        onMoved: {
            if (audioNode)
                audioNode.audio.volume = value;
        }

        background: Item {
            x: volumeSlider.leftPadding
            y: volumeSlider.topPadding + (volumeSlider.availableHeight - sliders.trackHeight) / 2
            width: volumeSlider.availableWidth
            height: sliders.trackHeight

            property real handlePos: volumeSlider.visualPosition * (width - sliders.handleWidth)

            // 1. LEFT TRACK (Colored fill — no icon, no dot for 0-to-+ sliders)
            Rectangle {
                id: volLeftTrack
                x: 0
                y: 0
                width: Math.max(0, parent.handlePos - sliders.gap)
                height: parent.height
                color: Theme.primary

                topLeftRadius: Math.min(sliders.leftRadiusLarge, width / 2)
                bottomLeftRadius: Math.min(sliders.leftRadiusLarge, width / 2)
                topRightRadius: Math.min(sliders.leftRadiusSmall, width / 2)
                bottomRightRadius: Math.min(sliders.leftRadiusSmall, width / 2)
            }

            // 2. RIGHT TRACK (Inactive — icon + dot at right end)
            Rectangle {
                id: volRightTrack
                x: parent.handlePos + sliders.handleWidth + sliders.gap
                y: 0
                width: Math.max(0, parent.width - x)
                height: parent.height
                color: Theme.surface_variant

                topLeftRadius: Math.min(sliders.leftRadiusSmall, width / 2)
                bottomLeftRadius: Math.min(sliders.leftRadiusSmall, width / 2)
                topRightRadius: Math.min(sliders.leftRadiusLarge, width / 2)
                bottomRightRadius: Math.min(sliders.leftRadiusLarge, width / 2)

                // Icon at right end
                Text {
                    x: parent.width - sliders.leftRadiusLarge - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    text: audioNode && audioNode.audio.muted ? "\ue04f" : "\ue050"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: Theme.on_surface_variant
                    opacity: volRightTrack.width > sliders.leftRadiusLarge * 2.5 ? 0.6 : 0.0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }
                }
            }
        }

        // 3. THE HANDLE
        handle: Rectangle {
            x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
            y: volumeSlider.topPadding + (volumeSlider.availableHeight - height) / 2

            width: sliders.handleWidth
            height: sliders.trackHeight + 8
            radius: width / 2
            color: Theme.primary
        }
    }

    Slider {
        id: brightnessSlider
        Layout.fillWidth: true
        implicitWidth: 320
        implicitHeight: 48 // Strict M3 48dp minimum touch target bounding box
        padding: 0

        value: currentBrightness
        onMoved: {
            currentBrightness = value;
            ddcSetTimer.restart();
        }

        background: Item {
            x: brightnessSlider.leftPadding
            y: brightnessSlider.topPadding + (brightnessSlider.availableHeight - sliders.trackHeight) / 2
            width: brightnessSlider.availableWidth
            height: sliders.trackHeight

            property real handlePos: brightnessSlider.visualPosition * (width - sliders.handleWidth)

            // 1. LEFT TRACK (Colored fill — no icon, no dot for 0-to-+ sliders)
            Rectangle {
                id: brightLeftTrack
                x: 0
                y: 0
                width: Math.max(0, parent.handlePos - sliders.gap)
                height: parent.height
                color: Theme.primary

                topLeftRadius: Math.min(sliders.leftRadiusLarge, width / 2)
                bottomLeftRadius: Math.min(sliders.leftRadiusLarge, width / 2)
                topRightRadius: Math.min(sliders.leftRadiusSmall, width / 2)
                bottomRightRadius: Math.min(sliders.leftRadiusSmall, width / 2)
            }

            // 2. RIGHT TRACK (Inactive — icon + dot at right end)
            Rectangle {
                id: brightRightTrack
                x: parent.handlePos + sliders.handleWidth + sliders.gap
                y: 0
                width: Math.max(0, parent.width - x)
                height: parent.height
                color: Theme.surface_variant

                topLeftRadius: Math.min(sliders.leftRadiusSmall, width / 2)
                bottomLeftRadius: Math.min(sliders.leftRadiusSmall, width / 2)
                topRightRadius: Math.min(sliders.leftRadiusLarge, width / 2)
                bottomRightRadius: Math.min(sliders.leftRadiusLarge, width / 2)

                // Icon at right end
                Text {
                    x: parent.width - sliders.leftRadiusLarge - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\ue518"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: Theme.on_surface_variant
                    opacity: brightRightTrack.width > sliders.leftRadiusLarge * 2.5 ? 0.6 : 0.0
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 150
                        }
                    }
                }
            }
        }

        // 3. THE HANDLE
        handle: Rectangle {
            x: brightnessSlider.leftPadding + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
            y: brightnessSlider.topPadding + (brightnessSlider.availableHeight - height) / 2

            width: sliders.handleWidth
            height: sliders.trackHeight + 8
            radius: width / 2
            color: Theme.primary
        }
    }
}
