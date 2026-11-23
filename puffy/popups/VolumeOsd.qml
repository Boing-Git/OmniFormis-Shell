import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import ".."
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import "../theme"
import "../core/primitives" as Primitives
Item {
    id: mainContainer

    property bool isVertical: Vars.pillPosition === "Left" || Vars.pillPosition === "Right"
    width: osdBackground.width
    height: osdBackground.height

    property int trackHeight: 48
    property int gap: 4
    property int handleWidth: 4

    property bool isVisible: false
    property bool preventShow: false
    property bool gameMode: Vars.gameMode !== undefined ? Vars.gameMode : false
    property alias panel: osdBackground
    property alias panelMask: panelMask
    
    Item {
        id: panelMask
        anchors.centerIn: osdBackground
        width: isVisible ? (osdBackground.width + 40) : 0
        height: isVisible ? (osdBackground.height + 40) : 0
    }
    
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

    Primitives.SquircleMask {
        id: osdBackground
        anchors.centerIn: parent
        width: mainContainer.isVertical ? 80 : (mainContainer.isVisible ? 352 : 132)
        height: mainContainer.isVertical ? (mainContainer.isVisible ? 352 : 132) : 80
        property real targetRad: 20
        topLeftRadius: Vars.getTopLeftRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        topRightRadius: Vars.getTopRightRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        bottomLeftRadius: Vars.getBottomLeftRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        bottomRightRadius: Vars.getBottomRightRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        color: Theme.surface
        
        layer.enabled: false
        layer.samples: Vars.layerSamples

        opacity: mainContainer.isVisible ? (Vars.isTranslucent() ? Vars.panelOpacity : 1.0) : 0.0
        visible: opacity > 0

        Behavior on width {
            enabled: !mainContainer.gameMode
            NumberAnimation {
                duration: Vars.animationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customExpressiveSpatialSlow
            }
        }
        Behavior on height {
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

    Primitives.Slider {
        id: bg
        anchors.centerIn: parent

        orientation: mainContainer.isVertical ? Qt.Vertical : Qt.Horizontal
        width: mainContainer.isVertical ? 48 : (mainContainer.isVisible ? 320 : 100)
        height: mainContainer.isVertical ? (mainContainer.isVisible ? 320 : 100) : 48
        padding: 0

        trackHeight: mainContainer.trackHeight
        gap: mainContainer.gap
        handleWidth: mainContainer.handleWidth
        icon: mainContainer.volumeIcon

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
        Behavior on height {
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
    }

}
