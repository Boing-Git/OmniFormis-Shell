import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import ".."
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../Variables/variables.js" as Vars

Item {
    id: mainContainer

    width: osdBackground.width
    height: osdBackground.height

    property int trackHeight: 40
    property int gap: 4
    property int handleWidth: 4

    property bool isVisible: false
    property bool preventShow: false
    property bool gameMode: false
    property real smoothVolume: Pipewire.defaultAudioSink?.audio?.volume ?? 0

    onPreventShowChanged: {
        if (preventShow) {
            isVisible = false;
            hideTimer.stop();
        }
    }

    property string volumeIcon: {
        let isMuted = Pipewire.defaultAudioSink?.audio?.muted ?? false;
        let vol = Pipewire.defaultAudioSink?.audio?.volume ?? 0;

        if (isMuted || vol <= 0.0)
            return "\uE04F";
        if (vol < 0.5)
            return "\uE04D";
        return "\uE050";
    }

    Behavior on smoothVolume {
        enabled: !mainContainer.gameMode
        NumberAnimation {
            duration: Vars.animationDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Vars.m3Standard
        }
    }

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    property real actualVolume: Pipewire.defaultAudioSink?.audio?.volume ?? 0
    property bool actualMuted: Pipewire.defaultAudioSink?.audio?.muted ?? false

    onActualVolumeChanged: triggerShow()
    onActualMutedChanged: triggerShow()

    function triggerShow() {
        if (!preventShow) {
            mainContainer.isVisible = true;
            if (!hoverArea.containsMouse && !bg.pressed) {
                hideTimer.restart();
            }
        }
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: {
            if (!hoverArea.containsMouse && !bg.pressed) {
                mainContainer.isVisible = false;
            }
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.NoButton

        onContainsMouseChanged: {
            if (containsMouse && isVisible) {
                hideTimer.stop();
            } else if (!containsMouse && isVisible && !bg.pressed) {
                hideTimer.restart();
            }
        }

        onWheel: wheel => {
            if (Pipewire.defaultAudioSink?.audio) {
                let delta = wheel.angleDelta.y > 0 ? 0.02 : -0.02;
                let newVol = Math.max(0.0, Math.min(1.0, Pipewire.defaultAudioSink.audio.volume + delta));
                Pipewire.defaultAudioSink.audio.volume = newVol;
            }
        }
    }

    Rectangle {
        id: osdBackground
        anchors.centerIn: parent
        width: mainContainer.isVisible ? 352 : 132 // 320 + 32 and 100 + 32 padding
        height: 80 // 48 + 32 padding
        radius: Vars.radiusLarge
        color: Theme.surface

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowBlur: 1.0
            shadowColor: Qt.rgba(0, 0, 0, 0.25)
            shadowVerticalOffset: 4
            shadowHorizontalOffset: 0
        }

        opacity: mainContainer.isVisible ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on width {
            enabled: !mainContainer.gameMode
            NumberAnimation {
                duration: Vars.animationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.m3ExpressiveSpatialFast
            }
        }
        Behavior on opacity {
            enabled: !mainContainer.gameMode
            NumberAnimation {
                duration: Vars.animationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.m3Standard
            }
        }
    }

    Slider {
        id: bg
        anchors.centerIn: parent

        width: mainContainer.isVisible ? 320 : 100
        height: 48 // Generous M3 geometry for Expressive styling
        padding: 0

        opacity: mainContainer.isVisible ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on width {
            enabled: !mainContainer.gameMode
            NumberAnimation {
                duration: Vars.animationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.m3ExpressiveSpatialFast
            }
        }
        Behavior on opacity {
            enabled: !mainContainer.gameMode
            NumberAnimation {
                duration: Vars.animationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.m3Standard
            }
        }

        value: mainContainer.actualVolume
        onMoved: {
            if (Pipewire.defaultAudioSink?.audio) {
                Pipewire.defaultAudioSink.audio.volume = value;
            }
        }

        background: Item {
            x: bg.leftPadding
            y: bg.topPadding + (bg.availableHeight - mainContainer.trackHeight) / 2
            width: bg.availableWidth
            height: mainContainer.trackHeight

            // 1. LEFT TRACK (Active Fill)
            Item {
                x: 0
                y: 0
                width: Math.max(0, (bg.visualPosition * (bg.availableWidth - mainContainer.handleWidth)) - mainContainer.gap)
                height: parent.height
                clip: true

                Rectangle {
                    width: bg.availableWidth
                    height: parent.height
                    radius: 12
                    color: Theme.primary

                    // Overlay Icon
                    Text {
                        x: 16 // Must match leftMargin
                        anchors.verticalCenter: parent.verticalCenter
                        text: mainContainer.volumeIcon
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 20
                        color: Theme.on_primary
                    }
                }
            }

            // 2. RIGHT TRACK (Inactive Base)
            Item {
                x: (bg.visualPosition * (bg.availableWidth - mainContainer.handleWidth)) + mainContainer.handleWidth + mainContainer.gap
                y: 0
                width: Math.max(0, bg.availableWidth - x)
                height: parent.height
                clip: true

                Rectangle {
                    x: -parent.x
                    width: bg.availableWidth
                    height: parent.height
                    radius: 12
                    color: Theme.surface_variant

                    // Base Icon
                    Text {
                        x: 16 // Must match leftMargin
                        anchors.verticalCenter: parent.verticalCenter
                        text: mainContainer.volumeIcon
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 20
                        color: Theme.on_surface_variant
                    }
                }
            }
        }

        // 3. THE HANDLE
        handle: Rectangle {
            x: bg.leftPadding + bg.visualPosition * (bg.availableWidth - width)
            y: bg.topPadding + (bg.availableHeight - height) / 2

            width: mainContainer.handleWidth
            height: 48 // Fixed to 48dp to ensure physical overhang and avoid implicitHeight collapse
            radius: width / 2
            color: Theme.primary
        }
    }
}
