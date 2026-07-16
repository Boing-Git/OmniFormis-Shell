import QtQuick
import QtQuick.Effects
import ".."
import Quickshell
import QtQuick.Layouts
import "../Variables/variables.js" as Vars

Item {
    id: root
    width: contentRow.implicitWidth + 38 // Dynamic width to fit both time and date
    height: 40
    signal clicked
    signal rightClicked
    signal scrolled(int delta)
    property string timeString: ""
    property string dateString: "" // New property for the date
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
        color: Vars.translucent ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.85) : Theme.surface
        radius: root.gameMode ? 0 : height / 2
        z: 1

        Rectangle {
            anchors.fill: parent
            radius: root.gameMode ? 0 : height / 2
            color: dragArea.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (dragArea.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
            Behavior on color {
                enabled: !root.gameMode
                ColorAnimation {
                    duration: Vars.animationDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Vars.customStandard
                }
            }
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                var d = new Date();

                // Time Logic
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

                // Date Logic
                var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                root.dateString = months[d.getMonth()] + " " + d.getDate();
            }
            Component.onCompleted: triggered()
        }

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: 8

            Text {
                id: clockText
                font.family: Vars.fontFamily
                font.pixelSize: 14
                font.weight: 600 // Slightly bolder to match the new crisp aesthetic
                color: Theme.on_surface
                text: root.timeString
            }

            Text {
                id: dateText
                font.family: Vars.fontFamily
                font.pixelSize: 14
                font.weight: 600
                color: Theme.on_surface
                opacity: 0.7 // Slightly faded to establish visual hierarchy
                text: root.dateString
            }
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
