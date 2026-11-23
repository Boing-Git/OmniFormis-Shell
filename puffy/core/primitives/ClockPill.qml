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
    // Same value as contentGrid's own spacing below, so the clock-to-icon gap and the two edge
    // margins read as one consistent rhythm instead of a cramped inner gap between two much
    // wider outer ones.
    property int contentGap: 5
    // Rounded up to an even number so (width - contentGrid.implicitWidth) always splits into two
    // equal integer-pixel margins instead of occasionally leaving left and right a pixel off.
    // Vertical mode's content (DateStatusIcon) already carries its own ~10px of built-in padding
    // around the ring/badges, so a full +24 here on top of that compounded into a visibly
    // oversized gap — +8 leaves a smaller margin budget that reads as deliberate spacing instead
    // of doubled-up padding.
    width: isVertical ? Math.max(48, contentGrid.implicitWidth + 8) : (Math.ceil((contentGrid.implicitWidth + contentGap * 2) / 2) * 2)
    height: isVertical ? (contentGrid.implicitHeight + 44) : Vars.clockPillThickness
    signal clicked
    signal rightClicked
    signal scrolled(int delta)
    property string timeString: ""
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

                if (root.isVertical) {
                    root.timeString = h + "\n" + m;
                } else {
                    root.timeString = h + ":" + m;
                }
            }
            Component.onCompleted: triggered()
        }

        Grid {
            id: contentGrid
            anchors.centerIn: parent
            spacing: root.isVertical ? 3 : root.contentGap
            columns: root.isVertical ? 1 : 2
            rows: root.isVertical ? 2 : 1
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter
            // Horizontal-only: in vertical mode (Left/Right panel position) this is a single
            // column, so a right-only pad with no matching left pad shifted anchors.centerIn's
            // padded bounding box without shifting the content inside it — the icon and time text
            // rendered visibly off-center in the pill instead of centered, i.e. the uneven margins.
            rightPadding: root.isVertical ? 0 : 20

            Primitives.DateStatusIcon {
                id: dateStatusIcon
            }   
            QsText {
                id: clockText
                font.family: Vars.fontFamily
                font.pixelSize: 21
                setWeight: 600
                color: Theme.on_surface
                text: root.timeString
                horizontalAlignment: Text.AlignHCenter
                lineHeight: root.isVertical ? 0.9 : 1.0
            }
        }

        MouseArea {
            id: dragArea
            anchors.fill: parent
            anchors.margins: -6
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
