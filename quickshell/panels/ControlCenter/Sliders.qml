import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Quickshell.Io
import "../../theme"
import "../.."
import "../../core/primitives" as Primitives

ColumnLayout {
    id: sliders
    Layout.fillWidth: true
    spacing: 8

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

    Primitives.Slider {
        id: volumeSlider
        Layout.fillWidth: true
        icon: audioNode && audioNode.audio.muted ? "" : ""
        value: currentVolume
        onMoved: {
            if (audioNode)
                audioNode.audio.volume = value;
        }
    }

    Primitives.Slider {
        id: brightnessSlider
        Layout.fillWidth: true
        icon: {
            let b = Vars.currentBrightness !== undefined ? Vars.currentBrightness : 1.0;
            if (b <= 0.0) return "brightness_1";
            if (b <= 0.16) return "brightness_2";
            if (b <= 0.33) return "brightness_3";
            if (b <= 0.50) return "brightness_4";
            if (b <= 0.66) return "brightness_5";
            if (b <= 0.83) return "brightness_6";
            return "brightness_7";
        }
        value: currentBrightness
        onMoved: {
            Vars.currentBrightness = value;
            ddcSetTimer.restart();
        }
    }
}
