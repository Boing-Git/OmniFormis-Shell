import QtQuick
import QtQuick.Effects
import ".."
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications
import "../theme/variables.js" as Vars

Item {
    id: root

    Layout.preferredWidth: 100
    Layout.preferredHeight: 40

    property var notifications: NotificationService.notifications
    property int currentIndex: 0
    property bool isPlaying: false
    property real currentHeight: 100
    property var currentNotification: (root.notifications && root.notifications.length > root.currentIndex) ? root.notifications[root.currentIndex] : null
    property color expandedColor: (currentNotification && currentNotification.urgency === NotificationUrgency.Critical) ? Theme.error_container : Theme.primary_container

    onNotificationsChanged: {
        if (notifications && notifications.length > 0) {
            if (!isPlaying) {
                isPlaying = true;
                currentIndex = 0;
                pillTimer.restart();
            } else if (currentIndex >= notifications.length) {
                currentIndex = notifications.length - 1;
            }
        } else {
            isPlaying = false;
            currentIndex = 0;
            pillTimer.stop();
        }
    }

    Timer {
        id: pillTimer
        interval: 3000 // 3 seconds to make it visible
        repeat: true
        running: root.isPlaying && (!hoverArea || !hoverArea.containsMouse)
        onTriggered: {
            if (!notifications || notifications.length === 0) {
                root.isPlaying = false;
                return;
            }

            if (notifications.length >= 4) {
                root.isPlaying = false;
            } else {
                currentIndex++;
                if (currentIndex >= notifications.length) {
                    root.isPlaying = false;
                    currentIndex = 0;
                }
            }
        }
    }

    property alias panel: panel
    property alias panelMask: panelMask
    property bool expanded: isPlaying
    property var focusWindow: null

    Item {
        id: panelMask
        anchors.centerIn: panel
        width: panel.width + 40
        height: panel.height + 40
    }

    Rectangle {
        id: panel
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 1.0; shadowColor: Qt.rgba(0,0,0,0.25); shadowVerticalOffset: 4; shadowHorizontalOffset: 0 }
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        width: root.expanded ? 380 : 100
        height: root.expanded ? Math.max(100, root.currentHeight + Vars.spacingLarge * 2) : 40

        color: Vars.translucent ? Qt.rgba((root.expanded ? root.expandedColor.r : Theme.primary.r), (root.expanded ? root.expandedColor.g : Theme.primary.g), (root.expanded ? root.expandedColor.b : Theme.primary.b), 0.85) : (root.expanded ? root.expandedColor : Theme.primary)
        Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        radius: root.expanded ? 24 : height / 2

        opacity: root.expanded ? 1.0 : 0.0
        visible: true
        Behavior on opacity { 
            SequentialAnimation { 
                PauseAnimation { duration: root.expanded ? 0 : Vars.animationDuration } 
                NumberAnimation { duration: 0 } 
            } 
        }

        Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on width { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on height { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
                root.isPlaying = false;
            }
        }

        // EXPANDED UI
        Item {
            anchors.fill: parent

            opacity: root.expanded ? 1.0 : 0.0
            visible: opacity > 0
            // REMOVED PauseAnimation so content appears instantly
            Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutCubic } }

            Item {
                id: notifContainer
                anchors.fill: parent
                anchors.margins: Vars.spacingLarge

                Repeater {
                    model: root.notifications

                    delegate: Item {
                        width: parent.width
                        height: nCard.height
                        anchors.centerIn: parent

                        required property int index
                        required property var modelData
                        
                        property bool isCurrent: index === root.currentIndex
                        
                        onIsCurrentChanged: {
                            if (isCurrent) {
                                root.currentHeight = nCard.height;
                            }
                        }

                        NotificationCard {
                            id: nCard
                            modelData: parent.modelData
                            anchors.centerIn: parent
                            width: parent.width
                            isPopup: true
                            fontName: Vars.fontFamily
                            
                            Component.onCompleted: {
                                if (parent.isCurrent) {
                                    root.currentHeight = nCard.height;
                                }
                            }
                            
                            opacity: parent.isCurrent ? 1.0 : 0.0
                            visible: opacity > 0 || parent.isCurrent
                            
                            Behavior on opacity { 
                                NumberAnimation { 
                                    duration: Vars.animationDuration; 
                                    easing.type: Easing.OutCubic 
                                } 
                            }
                        }
                    }
                }
            }
        }
    }
}
