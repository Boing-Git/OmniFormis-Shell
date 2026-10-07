import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Io
import "../../theme"
import "../.."

ColumnLayout {
    id: sliders
    Layout.fillWidth: true
    spacing: 8

    property int trackHeight: 40
    property int gap: 4
    property int handleWidth: 4
    property real leftRadiusLarge: 6
    property real leftRadiusSmall: 2
    property real dotSize: 6

    property var audioNode: Pipewire.defaultAudioSink
    property real currentVolume: audioNode && audioNode.audio ? audioNode.audio.volume : 0.0
    property real currentBrightness: Vars.currentBrightness !== undefined ? Vars.currentBrightness : 1

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
                        Vars.currentBrightness = b / 100.0;
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

            QsText {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: audioNode && audioNode.audio.muted ? "\ue04f" : "\ue050"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 20
                color: Theme.on_surface_variant
                opacity: 0.8
                renderType: Text.QtRendering
                font.hintingPreference: Font.PreferNoHinting
            }

            // 1. LEFT TRACK (Colored fill — no icon, no dot for 0-to-+ sliders)
            Rectangle {
                antialiasing: true
                id: volLeftTrack
                x: 0
                y: 0
                width: Math.max(0, parent.handlePos - sliders.gap)
                height: parent.height
                color: Theme.primary
                clip: true

                topLeftRadius: Math.min(sliders.leftRadiusLarge, width / 2)
                bottomLeftRadius: Math.min(sliders.leftRadiusLarge, width / 2)
                topRightRadius: Math.min(sliders.leftRadiusSmall, width / 2)
                bottomRightRadius: Math.min(sliders.leftRadiusSmall, width / 2)

                QsText {
                    x: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: audioNode && audioNode.audio.muted ? "\ue04f" : "\ue050"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: Theme.on_primary
                    renderType: Text.QtRendering
                    font.hintingPreference: Font.PreferNoHinting
                }
            }

            // 2. RIGHT TRACK (Inactive)
            Rectangle {
                antialiasing: true
                id: volRightTrack
                x: parent.handlePos + sliders.handleWidth + sliders.gap
                y: 0
                width: Math.max(0, parent.width - x)
                height: parent.height
                color: Vars.tColor(Theme.surface_variant, Vars.componentOpacity)

                topLeftRadius: Math.min(sliders.leftRadiusSmall, width / 2)
                bottomLeftRadius: Math.min(sliders.leftRadiusSmall, width / 2)
                topRightRadius: Math.min(sliders.leftRadiusLarge, width / 2)
                bottomRightRadius: Math.min(sliders.leftRadiusLarge, width / 2)
            }
        }

        // 3. THE HANDLE
        handle: Rectangle {
            x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
            y: volumeSlider.topPadding + (volumeSlider.availableHeight - height) / 2

            width: sliders.handleWidth
            height: sliders.trackHeight + 8
            radius: width / 2
            antialiasing: true
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
            Vars.currentBrightness = value;
            ddcSetTimer.restart();
        }

        property string brightnessIcon: {
            let b = Vars.currentBrightness !== undefined ? Vars.currentBrightness : 1.0;
            if (b <= 0.0) return "brightness_1";
            if (b <= 0.16) return "brightness_2";
            if (b <= 0.33) return "brightness_3";
            if (b <= 0.50) return "brightness_4";
            if (b <= 0.66) return "brightness_5";
            if (b <= 0.83) return "brightness_6";
            return "brightness_7";
        }

        background: Item {
            x: brightnessSlider.leftPadding
            y: brightnessSlider.topPadding + (brightnessSlider.availableHeight - sliders.trackHeight) / 2
            width: brightnessSlider.availableWidth
            height: sliders.trackHeight

            property real handlePos: brightnessSlider.visualPosition * (width - sliders.handleWidth)

            QsText {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: brightnessSlider.brightnessIcon
                font.family: "Material Symbols Outlined"
                font.pixelSize: 20
                color: Theme.on_surface_variant
                opacity: 0.8
                renderType: Text.QtRendering
                font.hintingPreference: Font.PreferNoHinting
            }

            // 1. LEFT TRACK (Colored fill — no icon, no dot for 0-to-+ sliders)
            Rectangle {
                antialiasing: true
                id: brightLeftTrack
                x: 0
                y: 0
                width: Math.max(0, parent.handlePos - sliders.gap)
                height: parent.height
                color: Theme.primary
                clip: true

                topLeftRadius: Math.min(sliders.leftRadiusLarge, width / 2)
                bottomLeftRadius: Math.min(sliders.leftRadiusLarge, width / 2)
                topRightRadius: Math.min(sliders.leftRadiusSmall, width / 2)
                bottomRightRadius: Math.min(sliders.leftRadiusSmall, width / 2)

                QsText {
                    x: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: brightnessSlider.brightnessIcon
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: Theme.on_primary
                    renderType: Text.QtRendering
                    font.hintingPreference: Font.PreferNoHinting
                }
            }

            // 2. RIGHT TRACK (Inactive)
            Rectangle {
                antialiasing: true
                id: brightRightTrack
                x: parent.handlePos + sliders.handleWidth + sliders.gap
                y: 0
                width: Math.max(0, parent.width - x)
                height: parent.height
                color: Vars.tColor(Theme.surface_variant, Vars.componentOpacity)

                topLeftRadius: Math.min(sliders.leftRadiusSmall, width / 2)
                bottomLeftRadius: Math.min(sliders.leftRadiusSmall, width / 2)
                topRightRadius: Math.min(sliders.leftRadiusLarge, width / 2)
                bottomRightRadius: Math.min(sliders.leftRadiusLarge, width / 2)
            }
        }

        // 3. THE HANDLE
        handle: Rectangle {
            x: brightnessSlider.leftPadding + brightnessSlider.visualPosition * (brightnessSlider.availableWidth - width)
            y: brightnessSlider.topPadding + (brightnessSlider.availableHeight - height) / 2

            width: sliders.handleWidth
            height: sliders.trackHeight + 8
            radius: width / 2
            antialiasing: true
            color: Theme.primary
        }
    }
}
