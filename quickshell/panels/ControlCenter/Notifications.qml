import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../theme/variables.js" as Vars
import "../.."

Item {
    id: notificationsRoot
    Layout.fillWidth: true
    implicitHeight: mainLayout.implicitHeight

    property var historyList: []

    Timer {
        interval: 200
        running: true
        repeat: true
        property int lastSync: -1
        onTriggered: {
            if (lastSync !== Vars.historyUpdated) {
                lastSync = Vars.historyUpdated;
                notificationsRoot.historyList = Vars.notificationHistory.slice();
            }
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 8

        // Empty State
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            Layout.topMargin: Vars.spacingSmall
            radius: Vars.radiusLarge
            color: Theme.surface_container_high
            visible: notificationsRoot.historyList.length === 0
            
            Text {
                text: "No new notifications"
                font.family: Vars.fontFamily; font.pixelSize: 14; color: Theme.on_surface_variant
                anchors.centerIn: parent
            }
        }

        Repeater {
            model: notificationsRoot.historyList

            NotificationCard {
                isPopup: false
                fontName: Vars.fontFamily
                Layout.fillWidth: true
            }
        }

        Item {
            Layout.preferredHeight: 80
            Layout.fillWidth: true
            visible: notificationsRoot.historyList.length > 0
        }
    }

    // Floating action bar
    Rectangle {
        width: parent.width
        height: 64
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.horizontalCenter: parent.horizontalCenter
        radius: 16
        color: Theme.surface_container_highest
        visible: notificationsRoot.historyList.length > 0
        z: 10
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 8
            
            // Clear all button
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: 16
                color: clearAllHover.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.16) : (clearAllHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08))
                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                
                Text {
                    anchors.centerIn: parent
                    text: "Clear all"
                    font.family: Vars.fontFamily
                    font.pixelSize: 14
                    font.weight: 600
                    color: Theme.on_surface
                }
                MouseArea {
                    id: clearAllHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Vars.clearNotifications()
                }
            }
        }
    }
}
