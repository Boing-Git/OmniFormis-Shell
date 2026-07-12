import Quickshell
import ".."
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import "../Variables/variables.js" as Vars

Item {
    id: rootCard
    required property var modelData
    property bool isPopup: false
    property string fontName: "Rubik"
    
    // We bind height to the card container's height so the list layout reacts properly
    width: parent ? parent.width : 360
    height: container.height

    // Animate height changes for smooth insertions/removals
    Behavior on height {
        NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutCubic }
    }

    // A state flag to indicate if we are dismissing so we can trigger animations
    property bool dismissing: false

    property color textColor: isPopup ? (modelData.urgency === NotificationUrgency.Critical ? Theme.on_error : Theme.on_surface) : (modelData.urgency === NotificationUrgency.Critical ? Theme.on_error_container : Theme.on_surface)

    // Drag-to-dismiss properties
    property real dragThreshold: width * 0.4

    // Actual visual card
    Rectangle {
        id: container
        layer.enabled: !isPopup
        layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 1.0; shadowColor: Qt.rgba(0,0,0,0.25); shadowVerticalOffset: 4; shadowHorizontalOffset: 0 }
        width: parent.width
        height: cardContent.implicitHeight + (Vars.spacingMedium * 2)
        
        // Drag logic transforms the container X
        x: 0
        
        radius: Vars.radiusLarge // Material 3 expressive rounded corners for all notifications
        color: isPopup ? (modelData.urgency === NotificationUrgency.Critical ? Theme.error : "transparent") : (modelData.urgency === NotificationUrgency.Critical ? Theme.error_container : Theme.surface_container_high)
        border.width: 0
        clip: true

        // Spring animation for X (when released)
        Behavior on x {
            SpringAnimation {
                spring: dismissing ? 1.5 : 3.0
                damping: dismissing ? 1.0 : 0.7
                epsilon: 0.1
            }
        }

        // Opacity animation for entry/exit
        opacity: dismissing ? 0.0 : 1.0
        Behavior on opacity {
            NumberAnimation { duration: dismissing ? Vars.animationDuration : Vars.animationDuration; easing.type: Easing.OutCubic }
        }

        // Entry animation (opacity from 0)
        Component.onCompleted: {
            if (isPopup) {
                opacity = 0;
                Qt.callLater(() => { opacity = 1.0; });
                Vars.pushNotification(rootCard.modelData);
            }
        }

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
            anchors.fill: parent
            drag.target: container
            drag.axis: Drag.XAxis
            
            // Limit drag depending on whether we want free drag
            drag.minimumX: -rootCard.width * 1.5
            drag.maximumX: rootCard.width * 1.5
            
            onReleased: {
                if (Math.abs(container.x) > rootCard.dragThreshold) {
                    // Passed threshold, dismiss
                    rootCard.dismissing = true;
                    // Push it off screen
                    container.x = container.x > 0 ? rootCard.width * 1.5 : -rootCard.width * 1.5;
                    
                    // Delay actual dismiss to let animation play
                    dismissTimer.start();
                } else {
                    // Snap back
                    container.x = 0;
                }
            }
            cursorShape: Qt.PointingHandCursor
            
            onClicked: (mouse) => {
                if (Math.abs(container.x) < 5) {
                    if (typeof modelData.dismiss === "function") {
                        modelData.dismiss();
                    }
                    if (isPopup) {
                        rootCard.dismissing = true;
                        dismissTimer.start();
                    }
                }
            }
        }

        Timer {
            id: dismissTimer
            interval: 250
            onTriggered: {
                if (typeof modelData.dismiss === "function") {
                    modelData.dismiss();
                }
            }
        }

        // Removed legacy vertical accent bar

        ColumnLayout {
            id: cardContent
            anchors.fill: parent
            anchors.leftMargin: Vars.spacingMedium
            anchors.rightMargin: Vars.spacingMedium
            anchors.topMargin: Vars.spacingMedium
            anchors.bottomMargin: Vars.spacingMedium
            spacing: Vars.spacingSmall

            // Header row
            RowLayout {
                Layout.fillWidth: true
                spacing: Vars.spacingSmall

                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: width / 2
                    Layout.alignment: Qt.AlignVCenter
                    color: modelData.urgency === NotificationUrgency.Critical ? Theme.error_container : Theme.primary_container

                    IconImage {
                        anchors.centerIn: parent
                        source: Quickshell.iconPath(modelData.appIcon || "", true)
                        implicitSize: 18
                        visible: modelData.appIcon !== "" && modelData.appIcon !== undefined
                        asynchronous: false
                    }

                    Text {
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

                Text {
                    text: modelData.appName || "Notification"
                    color: rootCard.textColor
                    font.pixelSize: 14
                    font.weight: 600
                    font.family: rootCard.fontName
                    Layout.alignment: Qt.AlignVCenter
                }

                Item { Layout.fillWidth: true }
                
                Rectangle {
                    width: 24
                    height: 24
                    radius: Math.floor(Vars.radiusMedium * 0.75)
                    color: closeHover.pressed ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : (closeHover.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.08) : "transparent")
                    Layout.alignment: Qt.AlignVCenter
                    
                    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }

                    Text {
                        anchors.centerIn: parent
                        text: "\ue5cd"
                        color: closeHover.containsMouse ? Theme.error : rootCard.textColor
                        font.pixelSize: 16
                        font.family: "Material Symbols Outlined"
                    }

                    MouseArea {
                        id: closeHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            rootCard.dismissing = true;
                            dismissTimer.start();
                        }
                    }
                }
            }

            // Summary (Title)
            Text {
                text: modelData.summary || ""
                color: rootCard.textColor
                font.pixelSize: 16
                font.family: rootCard.fontName
                font.weight: 600
                elide: Text.ElideRight
                Layout.fillWidth: true
                visible: text !== ""
            }

            // Body and Image
            RowLayout {
                Layout.fillWidth: true
                spacing: Vars.spacingSmall
                visible: (modelData.body !== "" && modelData.body !== undefined) || (modelData.image !== "" && modelData.image !== undefined)

                Text {
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
                        radius: height / 2 // Pill shape for M3 actions
                        color: actionHover.pressed ? Qt.rgba(rootCard.textColor.r, rootCard.textColor.g, rootCard.textColor.b, 0.12) : (actionHover.containsMouse ? Qt.rgba(rootCard.textColor.r, rootCard.textColor.g, rootCard.textColor.b, 0.08) : "transparent")
                        border.color: rootCard.textColor
                        border.width: 1

                        Behavior on color {
                            ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard }
                        }

                        Text {
                            id: actionText
                            anchors.centerIn: parent
                            text: actionBtn.modelData.text || ""
                            color: rootCard.textColor
                            font.pixelSize: 13
                            font.family: rootCard.fontName
                            font.weight: 600
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
                color: Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.2)
                Layout.topMargin: (Vars.spacingSmall / 2)
                visible: rootCard.modelData.urgency !== NotificationUrgency.Critical && isPopup

                Rectangle {
                    id: progressBar
                    height: parent.height
                    width: parent.width
                    radius: Math.floor(Vars.radiusSmall / 5)
                    color: rootCard.modelData.urgency === NotificationUrgency.Critical
                           ? Theme.error : Theme.on_surface
                    opacity: 0.8

                    SequentialAnimation {
                        running: rootCard.modelData.urgency !== NotificationUrgency.Critical && isPopup
                        paused: cardHover.hovered
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
