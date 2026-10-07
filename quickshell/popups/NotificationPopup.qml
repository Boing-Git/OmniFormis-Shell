import QtQuick
import QtQuick.Effects
import ".."
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications as QNotif
import "../theme"
import "../core/primitives" as Primitives
Item {
    id: root

    Layout.preferredWidth: 100
    Layout.preferredHeight: 40

    property bool expanded: false
    property var focusWindow: null
    property bool gameMode: Vars.gameMode !== undefined ? Vars.gameMode : false

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

    onExpandedChanged: {
        if (expanded) MorphState.notifyOpened(380, panel.targetHeight, panel.targetRad, panel);
        else MorphState.notifyClosed();
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
        anchors.top: (!Vars.pillPosition || Vars.pillPosition === "Top") ? parent.top : undefined
        anchors.bottom: Vars.pillPosition === "Bottom" ? parent.bottom : undefined
        anchors.left: Vars.pillPosition === "Left" ? parent.left : undefined
        anchors.right: Vars.pillPosition === "Right" ? parent.right : undefined
        anchors.horizontalCenter: (Vars.pillPosition === "Left" || Vars.pillPosition === "Right") ? undefined : parent.horizontalCenter
        anchors.verticalCenter: (Vars.pillPosition === "Left" || Vars.pillPosition === "Right") ? parent.verticalCenter : undefined
        
        anchors.topMargin: root.expanded ? -20 : 0
        anchors.bottomMargin: root.expanded ? -20 : 0
        anchors.leftMargin: root.expanded ? -20 : 0
        anchors.rightMargin: root.expanded ? -20 : 0
        width: root.expanded ? 420 : 0
        height: root.expanded ? 440 : 0
    }

    // The visual panel that morphs from clock pill
    Primitives.SquircleMask {
        id: panel
        property bool isBackgroundActive: root.expanded || (MorphState.openCount === 0 && MorphState.activeItem === panel && panel.width > 105)
        layer.enabled: false
        layer.samples: Vars.layerSamples
        anchors.top: (!Vars.pillPosition || Vars.pillPosition === "Top") ? parent.top : undefined
        anchors.bottom: Vars.pillPosition === "Bottom" ? parent.bottom : undefined
        anchors.left: Vars.pillPosition === "Left" ? parent.left : undefined
        anchors.right: Vars.pillPosition === "Right" ? parent.right : undefined
        anchors.horizontalCenter: (Vars.pillPosition === "Left" || Vars.pillPosition === "Right") ? undefined : parent.horizontalCenter
        anchors.verticalCenter: (Vars.pillPosition === "Left" || Vars.pillPosition === "Right") ? parent.verticalCenter : undefined

        property real targetHeight: root.expanded ? contentColumn.implicitHeight + 24 : (MorphState.anyExpanded ? MorphState.targetHeight : 40)
        width: root.expanded ? 380 : (MorphState.anyExpanded ? MorphState.targetWidth : 100)
        height: targetHeight

        onTargetHeightChanged: {
            if (root.expanded) MorphState.updateDimensions(380, targetHeight, targetRad);
        }

        color: Vars.tColorActive(isBackgroundActive, Theme.surface, Vars.panelOpacity)
        property real targetRad: root.expanded ? Vars.radiusExtraLarge : (MorphState.anyExpanded ? MorphState.targetRadius : height / 2)
        topLeftRadius: Vars.getTopLeftRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        topRightRadius: Vars.getTopRightRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        bottomLeftRadius: Vars.getBottomLeftRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        bottomRightRadius: Vars.getBottomRightRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)

        opacity: isBackgroundActive || innerUI.opacity > 0 ? 1.0 : 0.0
        // visible: opacity > 0 // Removed to preserve Behavior when hidden

        Behavior on width {
            enabled: !root.gameMode
            NumberAnimation {
                duration: Vars.animationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customExpressiveSpatialSlow
            }
        }
        Behavior on height {
            enabled: !root.gameMode
            NumberAnimation {
                duration: Vars.animationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customExpressiveSpatialSlow
            }
        }

        // EXPANDED UI
        Item {
            id: innerUI
            // Content must never draw outside the morphing panel
            clip: true
            anchors.fill: parent
            anchors.margins: 12

            opacity: root.expanded ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Vars.animationDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.expanded ? Vars.customEmphasizedDecelerate : Vars.customEmphasizedAccelerate
                }
            }

            ColumnLayout {
                id: contentColumn
                anchors.fill: parent
                spacing: 8



                // Show only the latest notification
                Repeater {
                    model: root.hasNotifications ? 1 : 0

                    NotificationCard {
                        Layout.fillWidth: true
                        isPopup: true
                        fontName: Vars.fontFamily
                        modelData: root.hasNotifications ? root.notifications[0] : null
                        onPopupRightClicked: {
                            root.expanded = false;
                        }
                    }
                }
            }
        }
    }
}
