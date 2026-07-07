import QtQuick
import QtQuick.Effects
import ".."
import Quickshell
import QtQuick.Layouts
import "../Variables/variables.js" as Vars

Item {
    id: root
    width: 100
    height: 40
    signal clicked
    signal rightClicked
    signal scrolled(int delta)
    property string timeString: ""
    property bool gameMode: false

    // No physics strings or translation properties needed

    Rectangle {
        id: clockRect
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: !root.gameMode
            shadowBlur: 1.0
            shadowColor: Qt.rgba(0, 0, 0, 0.25)
            shadowVerticalOffset: 4
            shadowHorizontalOffset: 0
        }
        width: parent.width
        height: parent.height
        color: Theme.primary
        radius: root.gameMode ? 0 : height / 2
        z: 1

        Rectangle {
            anchors.fill: parent
            radius: root.gameMode ? 0 : height / 2
            color: dragArea.pressed ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.12) : (dragArea.containsMouse ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.08) : "transparent")
            Behavior on color {
                enabled: !root.gameMode
                ColorAnimation {
                    duration: 250
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Vars.m3Standard
                }
            }
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                var d = new Date();
                var h = d.getHours();
                var m = d.getMinutes();
                h = h % 12;
                if (h === 0)
                    h = 12;
                if (h < 10)
                    h = "0" + h;
                if (m < 10)
                    m = "0" + m;
                root.timeString = h + ":" + m;
            }
            Component.onCompleted: triggered()
        }

        Text {
            id: clockText
            font.family: Vars.fontFamily
            font.pixelSize: 14
            font.weight: 600 // Slightly bolder to match the new crisp aesthetic
            color: Theme.on_primary
            anchors.centerIn: parent
            text: root.timeString
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton) {
                    root.rightClicked();
                } else {
                    root.clicked();
                }
            }
            onWheel: wheel => {
                root.scrolled(wheel.angleDelta.y);
            }
        }
    }
}
