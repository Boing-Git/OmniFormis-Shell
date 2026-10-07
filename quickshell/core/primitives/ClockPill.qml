import QtQuick
import QtQuick.Effects
import "../.."
import Quickshell
import QtQuick.Layouts
import "../../theme"
import "." as Primitives

Item {
    id: root
    property bool isVertical: Vars.pillPosition === "Left" || Vars.pillPosition === "Right"
    onIsVerticalChanged: { if (timeTimer) timeTimer.triggered(); }
    width: isVertical ? Math.max(40, contentGrid.implicitWidth + 20) : (contentGrid.implicitWidth + 38)
    height: isVertical ? (contentGrid.implicitHeight + 38) : 40
    signal clicked
    signal rightClicked
    signal scrolled(int delta)
    property string timeString: ""
    property string dateString: ""
    property bool gameMode: Vars.gameMode !== undefined ? Vars.gameMode : false
    property alias panel: clockRect
    property bool isHovered: dragArea.containsMouse

    // No physics strings or translation properties needed

    Primitives.SquircleMask {
        id: clockRect
        width: parent.width
        height: parent.height
        property real targetRad: Math.min(root.width, root.height) / 2
        color: Vars.tColor(Theme.surface, Vars.panelOpacity)
        topLeftRadius: Vars.getTopLeftRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        topRightRadius: Vars.getTopRightRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        bottomLeftRadius: Vars.getBottomLeftRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        bottomRightRadius: Vars.getBottomRightRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        z: 1

        Rectangle {
            antialiasing: true
            anchors.fill: parent
            topLeftRadius: clockRect.topLeftRadius
            topRightRadius: clockRect.topRightRadius
            bottomLeftRadius: clockRect.bottomLeftRadius
            bottomRightRadius: clockRect.bottomRightRadius
            color: dragArea.pressed ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.12) : (dragArea.containsMouse ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.08) : "transparent")
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
            id: timeTimer
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
                
                var months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
                
                if (root.isVertical) {
                    root.timeString = h + "\n" + m;
                    root.dateString = months[d.getMonth()] + "\n" + d.getDate();
                } else {
                    root.timeString = h + ":" + m;
                    root.dateString = months[d.getMonth()] + " " + d.getDate();
                }
            }
            Component.onCompleted: triggered()
        }

        Grid {
            id: contentGrid
            anchors.centerIn: parent
            spacing: root.isVertical ? 6 : 8
            columns: root.isVertical ? 1 : 2
            rows: root.isVertical ? 2 : 1
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter

            QsText {
                id: clockText
                font.family: Vars.fontFamily
                font.pixelSize: 14
                setWeight: 600
                color: Theme.on_surface
                text: root.timeString
                horizontalAlignment: Text.AlignHCenter
                lineHeight: root.isVertical ? 0.9 : 1.0
            }

            QsText {
                id: dateText
                font.family: Vars.fontFamily
                font.pixelSize: 14
                setWeight: 600
                color: Theme.on_surface
                opacity: 0.7
                text: root.dateString
                horizontalAlignment: Text.AlignHCenter
                lineHeight: root.isVertical ? 0.9 : 1.0
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
