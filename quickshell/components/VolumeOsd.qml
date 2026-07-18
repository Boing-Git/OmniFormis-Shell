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

    property int trackHeight: 38
    property int gap: 2
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
            easing.bezierCurve: Vars.customStandard
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
        color: Vars.translucent ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.85) : Theme.surface

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
                easing.bezierCurve: Vars.customExpressiveSpatialSlow
            }
        }
        Behavior on opacity {
            enabled: !mainContainer.gameMode
            NumberAnimation {
                duration: Vars.animationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customStandard
            }
        }
    }

    Slider {
        id: bg
        anchors.centerIn: parent

        width: mainContainer.isVisible ? 320 : 100
        height: 44 // Generous M3 geometry for Expressive styling
        padding: 0

        opacity: mainContainer.isVisible ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on width {
            enabled: !mainContainer.gameMode
            NumberAnimation {
                duration: Vars.animationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customExpressiveSpatialSlow
            }
        }
        Behavior on opacity {
            enabled: !mainContainer.gameMode
            NumberAnimation {
                duration: Vars.animationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customStandard
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

            property real leftRadiusLarge: 12
            property real leftRadiusSmall: 4
            property real handlePos: bg.visualPosition * (width - mainContainer.handleWidth)

            // 1. LEFT TRACK (Colored fill — no icon, no dot for 0-to-+ sliders)
            Rectangle {
                id: osdLeftTrack
                x: 0
                y: 0
                width: Math.max(0, parent.handlePos - mainContainer.gap)
                height: parent.height
                color: Theme.primary

                topLeftRadius: Math.min(parent.leftRadiusLarge, width / 2)
                bottomLeftRadius: Math.min(parent.leftRadiusLarge, width / 2)
                topRightRadius: Math.min(parent.leftRadiusSmall, width / 2)
                bottomRightRadius: Math.min(parent.leftRadiusSmall, width / 2)
            }

            // 2. RIGHT TRACK (Inactive — icon + dot at right end)
            Rectangle {
                id: osdRightTrack
                x: parent.handlePos + mainContainer.handleWidth + mainContainer.gap
                y: 0
                width: Math.max(0, parent.width - x)
                height: parent.height
                color: Theme.surface_variant

                topLeftRadius: Math.min(parent.leftRadiusSmall, width / 2)
                bottomLeftRadius: Math.min(parent.leftRadiusSmall, width / 2)
                topRightRadius: Math.min(parent.leftRadiusLarge, width / 2)
                bottomRightRadius: Math.min(parent.leftRadiusLarge, width / 2)

                // Icon at right end
                Text {
                    x: parent.width - parent.parent.leftRadiusLarge - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    text: mainContainer.volumeIcon
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: Theme.on_surface_variant
                    opacity: osdRightTrack.width > parent.parent.leftRadiusLarge * 2.5 ? 0.6 : 0.0
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
            x: bg.leftPadding + bg.visualPosition * (bg.availableWidth - width)
            y: bg.topPadding + (bg.availableHeight - height) / 2

            width: mainContainer.handleWidth
            height: mainContainer.trackHeight + 8
            radius: width / 2
            color: Theme.primary
        }
    }
}
