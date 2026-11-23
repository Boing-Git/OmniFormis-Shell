import Quickshell
import ".."
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../theme"
import "../core/primitives" as Primitives
Item {
    id: rootCard
    required property var modelData
    property bool isPopup: false
    property string fontName: Vars.fontFamily
    
    // We bind height to the card container's height so the list layout reacts properly
    width: parent ? parent.width : 360
    // Popups are sized by their morphing panel, so only list cards collapse / animate their height
    height: (rootCard.dismissing && !isPopup) ? 0 : container.height

    // Animate height changes for smooth insertions/removals
    Behavior on height {
        enabled: !isPopup
        NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard }
    }

    // A state flag to indicate if we are dismissing so we can trigger animations
    property bool dismissing: false

    onModelDataChanged: {
        // We removed the opacity flash here because the parent NotificationPopup 
        // handles the global fade-in, and resetting opacity on every incoming 
        // message in a burst causes a terrible strobe effect.
    }

    property color textColor: isPopup ? (modelData.urgency === NotificationUrgency.Critical ? Theme.on_error : Theme.on_surface) : (modelData.urgency === NotificationUrgency.Critical ? Theme.on_error_container : Theme.on_surface)

    // Drag-to-dismiss properties
    property real dragThreshold: width * 0.4

    property int listIndex: -1
    property int listCount: 1
    
    // Drag coordination
    property int activeDragIndex: -1
    property real activeDragX: 0
    signal dragStarted(int idx)
    signal dragMoved(int idx, real dx)
    signal dragEnded(int idx)
    signal popupRightClicked()

    property bool isEffectivelyFirst: isPopup || listIndex === 0 || 
        (activeDragIndex === listIndex - 1 && Math.abs(activeDragX) > dragThreshold * 0.3) ||
        (activeDragIndex === listIndex && Math.abs(activeDragX) > dragThreshold * 0.3)
        
    property bool isEffectivelyLast: isPopup || listIndex === listCount - 1 || 
        (activeDragIndex === listIndex + 1 && Math.abs(activeDragX) > dragThreshold * 0.3) ||
        (activeDragIndex === listIndex && Math.abs(activeDragX) > dragThreshold * 0.3)

    property real adjacentDragShift: {
        if (activeDragIndex === -1 || activeDragIndex === listIndex) return 0;
        
        let dist = Math.abs(listIndex - activeDragIndex);
        if (dist >= 1) {
            // Formula: base factor 0.24 divided by 2^dist
            // dist=1: 0.12, dist=2: 0.06, dist=3: 0.03, etc.
            let factor = 0.24 / Math.pow(2, dist);
            
            // To ensure the effect doesn't get too microscopic, we can cap it at 4 items
            if (dist <= 4) {
                return activeDragX * factor;
            }
        }
        return 0;
    }

    // Actual visual card
    Primitives.SquircleMask {
        id: container
        width: parent.width
        height: cardContent.implicitHeight + 24
        
        // Drag logic transforms the container X
        x: 0
        
        onXChanged: {
            if (activeDragIndex === listIndex || dragArea.drag.active) {
                rootCard.dragMoved(listIndex, x);
                if (!dragArea.drag.active && !rootCard.dismissing && Math.abs(x) < 0.1) {
                    rootCard.dragEnded(listIndex);
                }
            }
        }
        
        transform: Translate {
            x: rootCard.adjacentDragShift
        }
        
        topLeftRadius: isEffectivelyFirst ? Vars.radiusLarge : 4
        topRightRadius: isEffectivelyFirst ? Vars.radiusLarge : 4
        bottomLeftRadius: isEffectivelyLast ? Vars.radiusLarge : 4
        bottomRightRadius: isEffectivelyLast ? Vars.radiusLarge : 4
        
        color: isPopup ? (modelData.urgency === NotificationUrgency.Critical ? Theme.error : "transparent") : (modelData.urgency === NotificationUrgency.Critical ? Theme.error_container : (Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)))
        clip: true

        // Spring animation for X (when released)
        Behavior on x {
            enabled: !dragArea.drag.active
            SpringAnimation {
                spring: dismissing ? 1.5 : 3.0
                damping: dismissing ? 1.0 : 0.7
                epsilon: 0.1
            }
        }

        // Opacity animation for entry/exit
        opacity: dismissing ? 0.0 : 1.0
        Behavior on opacity {
            NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard }
        }

        // Entry animation (opacity from 0)
        // Handled by parent.

        Accessible.role: Accessible.StaticText
        Accessible.name: (modelData.urgency === NotificationUrgency.Critical ? "[Critical] " :
                         modelData.urgency === NotificationUrgency.Low       ? "[Low] "      : "") +
                         (modelData.appName || "Notification") + ": " + (modelData.summary || "")

        HoverHandler {
            id: cardHover
            onHoveredChanged: {
                if (modelData.hovered !== undefined) {
                    modelData.hovered = hovered
                }
            }
        }

        // Drag handling
        MouseArea {
            id: dragArea
            anchors.fill: parent
            drag.target: container
            drag.axis: Drag.XAxis
            preventStealing: true
            
            // Limit drag depending on whether we want free drag
            drag.minimumX: -rootCard.width * 1.5
            drag.maximumX: rootCard.width * 1.5
            
            onPressed: rootCard.dragStarted(listIndex)
            
            onReleased: {
                if (Math.abs(container.x) > rootCard.dragThreshold) {
                    // Passed threshold, dismiss
                    rootCard.dismissing = true;
                    // Push it off screen
                    container.x = container.x > 0 ? rootCard.width * 1.5 : -rootCard.width * 1.5;
                    
                    // Delay actual dismiss to let animation play
                    dismissTimer.start();
                } else {
                    if (Math.abs(container.x) < 0.1) {
                        rootCard.dragEnded(listIndex);
                    } else {
                        // Snap back (dragEnded will be called when x reaches 0)
                        container.x = 0;
                    }
                }
            }
            cursorShape: Qt.PointingHandCursor
            
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
                if (Math.abs(container.x) < 5) {
                    if (mouse.button === Qt.RightButton) {
                        if (isPopup) {
                            rootCard.popupRightClicked();
                        }
                    } else {
                        if (isPopup) {
                            rootCard.dismissing = true;
                            dismissTimer.start();
                        } else {
                            // Same collapse-then-remove path as a swipe so the row animates out
                            rootCard.dismissing = true;
                            dismissTimer.start();
                        }
                    }
                }
            }
        }

        Timer {
            id: dismissTimer
            interval: 250
            onTriggered: {
                // Read the index first, dismissing removes the card and its properties with it
                var index = listIndex;
                if (isPopup) {
                    NotificationService.clearPopups();
                } else {
                    if (typeof modelData.dismiss === "function") {
                        modelData.dismiss();
                    }
                }
                rootCard.dragEnded(index);
            }
        }

        // Removed legacy vertical accent bar

        ColumnLayout {
            id: cardContent
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            spacing: 6

            // Header row
            RowLayout {
                Layout.fillWidth: true
                spacing: Vars.spacingSmall

                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: width / 2
                    antialiasing: true
                    Layout.alignment: Qt.AlignVCenter
                    color: modelData.urgency === NotificationUrgency.Critical ? Theme.error_container : Theme.primary_container

                    IconImage {
                        anchors.centerIn: parent
                        source: Quickshell.iconPath(modelData.appIcon || "", true)
                        implicitSize: 18
                        visible: modelData.appIcon !== "" && modelData.appIcon !== undefined
                        asynchronous: false
                    }

                    QsText {
                        anchors.centerIn: parent
                        visible: modelData.appIcon === "" || modelData.appIcon === undefined
                        text: {
                            const name = (modelData.appName || "").toLowerCase();
                            if (modelData.urgency === NotificationUrgency.Critical) return "\ue000"; // error icon
                            if (name.includes("discord"))  return "\ue0b7"; // chat icon fallback
                            if (name.includes("firefox") || name.includes("chrome")) return "\ue894"; // public / web
                            if (name.includes("telegram")) return "\ue163"; // send
                            if (name.includes("spotify"))  return "\ue030"; // music
                            if (name.includes("terminal") || name.includes("kitty") || name.includes("alacritty")) return "\ue320"; // terminal
                            return "\ue7f4"; // notifications icon
                        }
                        color: rootCard.textColor
                        font.pixelSize: 18
                        font.family: "Material Symbols Outlined"
                    }
                }

                // Summary (Title) moved to header
                QsText {
                    text: modelData.summary || ""
                    color: rootCard.textColor
                    font.pixelSize: 16
                    font.family: rootCard.fontName
                    setWeight: 600
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    visible: text !== ""
                }
            }

            // Body and Image
            RowLayout {
                Layout.fillWidth: true
                spacing: Vars.spacingSmall
                visible: (modelData.body !== "" && modelData.body !== undefined) || (modelData.image !== "" && modelData.image !== undefined)

                QsText {
                    text: modelData.body || ""
                    color: rootCard.textColor
                    opacity: 0.8
                    font.pixelSize: 14
                    font.family: rootCard.fontName
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    visible: text !== ""
                    textFormat: Text.PlainText
                }

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: Vars.radiusSmall
                    antialiasing: true
                    color: Theme.primary_container
                    clip: true
                    visible: modelData.image !== "" && modelData.image !== undefined

                    Image {
                        anchors.fill: parent
                        source: modelData.image || ""
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: 40
                        sourceSize.height: 40
                    }
                }
            }

            // Actions
            RowLayout {
                Layout.fillWidth: true
                spacing: Vars.spacingSmall
                visible: modelData.actions !== undefined && modelData.actions.length > 0

                Repeater {
                    model: modelData.actions || []

                    Rectangle {
                        id: actionBtn
                        required property var modelData

                        Layout.preferredHeight: 36
                        Layout.preferredWidth: actionText.width + 32
                        radius: Vars.radiusSmall // Styled to match r2 = r1 - p spacing
                        antialiasing: true
                        color: actionHover.pressed ? Qt.rgba(rootCard.textColor.r, rootCard.textColor.g, rootCard.textColor.b, 0.12) : (actionHover.containsMouse ? Qt.rgba(rootCard.textColor.r, rootCard.textColor.g, rootCard.textColor.b, 0.08) : "transparent")
                        border.color: rootCard.textColor
                        border.width: 1

                        Behavior on color {
                            ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard }
                        }

                        QsText {
                            id: actionText
                            anchors.centerIn: parent
                            text: actionBtn.modelData.text || ""
                            color: rootCard.textColor
                            font.pixelSize: 13
                            font.family: rootCard.fontName
                            setWeight: 600
                        }

                        MouseArea {
                            id: actionHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (typeof rootCard.modelData.invokeAction === "function") {
                                    rootCard.modelData.invokeAction(actionBtn.modelData.identifier);
                                }
                            }
                        }
                    }
                }
            }

            // Progress bar (Timeout)
            Rectangle {
                Layout.fillWidth: true
                height: 3
                radius: Math.floor(Vars.radiusSmall / 5)
                antialiasing: true
                color: Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.2)
                Layout.topMargin: 2
                visible: rootCard.modelData.urgency !== NotificationUrgency.Critical && isPopup

                Rectangle {
                    id: progressBar
                    height: parent.height
                    width: parent.width
                    radius: Math.floor(Vars.radiusSmall / 5)
                    antialiasing: true
                    color: rootCard.modelData.urgency === NotificationUrgency.Critical
                           ? Theme.error : Theme.on_surface
                    opacity: 0.8

                    SequentialAnimation {
                        running: rootCard.modelData.urgency !== NotificationUrgency.Critical && isPopup
                        paused: running && cardHover.hovered
                        PauseAnimation { duration: Vars.animationDuration }
                        NumberAnimation {
                            target: progressBar
                            property: "width"
                            to: 0
                            duration: rootCard.modelData.expireTimeout > 0
                                      ? rootCard.modelData.expireTimeout
                                      : (rootCard.modelData.defaultTimeout || 5000)
                        }
                        onFinished: {
                            if (isPopup) {
                                rootCard.dismissing = true;
                                dismissTimer.start();
                            }
                        }
                    }
                }
            }
        }
    }
}
