import QtQuick
import QtQuick.Effects
import ".."
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications as QNotif
import "../Variables/variables.js" as Vars

Item {
    id: root

    Layout.preferredWidth: 100
    Layout.preferredHeight: 40

    property bool expanded: false
    property var focusWindow: null
    property bool gameMode: false

    // Expose panel for TopPills Wayland mask tracking
    property alias panel: panel
    property alias panelMask: panelMask

    property var notifications: NotificationService.notifications
    property bool hasNotifications: notifications && notifications.length > 0

    onNotificationsChanged: {
        var count = notifications ? notifications.length : 0;
        console.log("NotificationPopup: notifications changed, count:", count);
        if (count > 0 && !expanded) {
            expanded = true;
        } else if (count === 0) {
            expanded = false;
        }
    }

    // Safety timer: collapse if notifications were dismissed externally
    Timer {
        interval: 500
        running: root.expanded
        repeat: true
        onTriggered: {
            if (!root.notifications || root.notifications.length === 0) {
                root.expanded = false;
            }
        }
    }

    Item {
        id: panelMask
        anchors.centerIn: panel
        width: panel.width + 40
        height: panel.height + 40
    }

    // The visual panel that morphs from clock pill
    Rectangle {
        id: panel
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: !root.gameMode; shadowBlur: 1.0; shadowColor: Qt.rgba(0,0,0,0.25); shadowVerticalOffset: 4; shadowHorizontalOffset: 0 }
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        width: root.expanded ? 380 : 100
        height: root.expanded ? contentColumn.implicitHeight + Vars.spacingMedium * 2 + 8 : 40

        color: Theme.primary
        radius: root.gameMode ? 0 : (root.expanded ? Vars.radiusLarge : height / 2)

        opacity: root.expanded || panel.width > 105 ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on radius { enabled: !root.gameMode; NumberAnimation { duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
        Behavior on width { enabled: !root.gameMode; NumberAnimation { duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
        Behavior on height { enabled: !root.gameMode; NumberAnimation { duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }

        // EXPANDED UI
        Item {
            anchors.fill: parent
            anchors.margins: Vars.spacingMedium

            opacity: root.expanded ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.expanded ? 200 : 0 } NumberAnimation { duration: root.expanded ? 200 : 100; easing.type: Easing.BezierSpline; easing.bezierCurve: root.expanded ? Vars.m3StandardDecelerate : Vars.m3StandardAccelerate } } }

            ColumnLayout {
                id: contentColumn
                anchors.fill: parent
                spacing: Vars.spacingSmall

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Vars.spacingSmall

                    Text {
                        text: "\ue7f4"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 18
                        color: Theme.on_primary
                    }

                    Text {
                        text: root.notifications ? root.notifications.length + " notification" + (root.notifications.length > 1 ? "s" : "") : ""
                        font.family: Vars.fontFamily
                        font.pixelSize: 13
                        font.weight: 500
                        color: Theme.on_primary
                        opacity: 0.7
                        Layout.fillWidth: true
                    }

                    // Close all button
                    Rectangle {
                        width: 28; height: 28; radius: 14
                        color: closeAllHover.containsMouse ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.12) : "transparent"
                        Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 16; color: Theme.on_primary; text: "\ue5cd" }
                        MouseArea {
                            id: closeAllHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                NotificationService.dismissAll();
                                root.expanded = false;
                            }
                        }
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                }

                // Show only the latest notification
                Repeater {
                    model: root.hasNotifications ? [root.notifications[0]] : []

                    NotificationCard {
                        Layout.fillWidth: true
                        isPopup: true
                        fontName: Vars.fontFamily
                    }
                }
            }
        }
    }
}
