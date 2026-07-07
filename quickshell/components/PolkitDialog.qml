import QtQuick
import QtQuick.Effects
import ".."
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Polkit
import Quickshell.Hyprland
import "../Variables/variables.js" as Vars

Item {
    id: root

    Layout.preferredWidth: 100
    Layout.preferredHeight: 40

    property alias panel: panel
    property alias panelMask: panelMask
    property bool expanded: flow !== null && !flow.isCompleted
    property var focusWindow: null
    property bool gameMode: false

    HyprlandFocusGrab {
        active: root.expanded && root.focusWindow !== null
        windows: root.focusWindow ? [root.focusWindow] : []
    }

    PolkitAgent {
        id: polkitAgent
    }

    property var flow: polkitAgent.flow

    // ── Error state ─────────────────────────────────────
    property bool authError: false
    property string errorMessage: ""

    // Reset error state after a delay
    Timer {
        id: errorResetTimer
        interval: 2500
        onTriggered: {
            root.authError = false;
            root.errorMessage = "";
        }
    }

    Connections {
        target: root.flow

        function onFailedChanged() {
            if (root.flow && root.flow.failed) {
                root.authError = true;
                root.errorMessage = "Authentication failed";
                shakeAnim.start();
                errorResetTimer.start();
                passwordInput.text = "";
            }
        }

        function onSupplementaryMessageChanged() {
            if (root.flow && root.flow.supplementaryMessage) {
                if (root.flow.supplementaryIsError) {
                    root.authError = true;
                    root.errorMessage = root.flow.supplementaryMessage;
                    shakeAnim.start();
                    errorResetTimer.start();
                } else {
                    root.errorMessage = root.flow.supplementaryMessage;
                }
            }
        }
    }

    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: passwordBox; property: "x"; to: passwordBox.restX - 12; duration: 50 }
        NumberAnimation { target: passwordBox; property: "x"; to: passwordBox.restX + 12; duration: 50 }
        NumberAnimation { target: passwordBox; property: "x"; to: passwordBox.restX - 8; duration: 50 }
        NumberAnimation { target: passwordBox; property: "x"; to: passwordBox.restX + 8; duration: 50 }
        NumberAnimation { target: passwordBox; property: "x"; to: passwordBox.restX; duration: 50 }
    }

    onFlowChanged: {
        if (flow) {
            passwordInput.text = "";
            root.authError = false;
            root.errorMessage = "";
            passwordInput.forceActiveFocus();
        }
    }

    Item {
        id: panelMask
        anchors.centerIn: panel
        width: panel.width + 40
        height: panel.height + 40
    }

    Rectangle {
        id: panel
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: !root.gameMode; shadowBlur: 1.0; shadowColor: Qt.rgba(0,0,0,0.25); shadowVerticalOffset: 4; shadowHorizontalOffset: 0 }
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        width: root.expanded ? 420 : 100
        height: root.expanded ? contentColumn.implicitHeight + 32 : 40

        opacity: root.expanded || panel.width > 105 ? 1.0 : 0.0
        visible: opacity > 0

        color: Theme.primary
        radius: root.gameMode ? 0 : (root.expanded ? Vars.radiusExtraLarge : height / 2)

        Behavior on radius { enabled: !root.gameMode; NumberAnimation { duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
        Behavior on width { enabled: !root.gameMode; NumberAnimation { duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
        Behavior on height { enabled: !root.gameMode; NumberAnimation { duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }

        // EXPANDED UI
        Item {
            anchors.fill: parent

            opacity: root.expanded ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.expanded ? 200 : 0 } NumberAnimation { duration: root.expanded ? 200 : 100; easing.type: Easing.BezierSpline; easing.bezierCurve: root.expanded ? Vars.m3StandardDecelerate : Vars.m3StandardAccelerate } } }

            ColumnLayout {
                id: contentColumn
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                    margins: 16
                }
                spacing: 8

                // Header
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 22
                        color: Theme.on_primary
                        text: "\ue897"
                    }

                    Text {
                        text: "Authentication Required"
                        font.family: Vars.fontFamily
                        font.pixelSize: 18
                        font.weight: 700
                        color: Theme.on_primary
                    }
                }

                // Message text
                Text {
                    Layout.fillWidth: true
                    text: root.flow ? root.flow.message : ""
                    font.family: Vars.fontFamily
                    font.pixelSize: 13
                    font.weight: 400
                    color: Theme.on_primary
                    wrapMode: Text.WordWrap
                    lineHeight: 1.4
                }

                // Action ID
                Text {
                    Layout.fillWidth: true
                    text: root.flow ? root.flow.actionId : ""
                    font.family: Vars.fontFamily
                    font.pixelSize: 11
                    font.weight: 400
                    color: Theme.on_primary
                    opacity: 0.7
                    visible: root.flow && root.flow.actionId !== ""
                }

                // Password Input
                Rectangle {
                    id: passwordBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    radius: 12
                    color: root.authError
                        ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.15)
                        : Theme.primary_container
                    border.color: passwordInput.activeFocus
                        ? Theme.on_primary_container
                        : (root.authError ? Theme.error : "transparent")
                    border.width: passwordInput.activeFocus ? 2 : 1

                    Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    property real restX: x
                    Component.onCompleted: restX = x

                    visible: !root.flow || root.flow.isResponseRequired

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 8

                        TextInput {
                            id: passwordInput
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Vars.fontFamily
                            font.pixelSize: 13
                            color: Theme.on_primary_container
                            echoMode: TextInput.Password
                            clip: true
                            focus: root.expanded

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: root.flow && root.flow.inputPrompt ? root.flow.inputPrompt : "Password:"
                                color: Theme.on_primary_container
                                opacity: 0.7
                                font.family: Vars.fontFamily
                                font.pixelSize: 13
                                visible: !passwordInput.text && !passwordInput.activeFocus
                            }

                            onAccepted: {
                                if (text.length > 0 && root.flow) {
                                    root.flow.submit(text);
                                    passwordInput.text = "";
                                }
                            }
                        }
                    }
                }

                // Error / Info message
                Text {
                    Layout.fillWidth: true
                    text: root.errorMessage
                    font.family: Vars.fontFamily
                    font.pixelSize: 11
                    color: root.authError ? Theme.error : Theme.on_primary
                    visible: root.errorMessage !== ""
                    opacity: visible ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 200 } }
                }

                // Buttons: Cancel | Authenticate
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    layoutDirection: Qt.RightToLeft

                    // Authenticate button
                    Rectangle {
                        Layout.preferredWidth: authenticateLabel.implicitWidth + 40
                        Layout.preferredHeight: 36
                        radius: 18
                        color: authenticateArea.containsMouse
                            ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.2)
                            : Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.1)

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            id: authenticateLabel
                            anchors.centerIn: parent
                            text: "Authenticate"
                            font.family: Vars.fontFamily
                            font.pixelSize: 13
                            font.weight: 600
                            color: Theme.on_primary
                        }

                        MouseArea {
                            id: authenticateArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (passwordInput.text.length > 0 && root.flow) {
                                    root.flow.submit(passwordInput.text);
                                    passwordInput.text = "";
                                }
                            }
                        }
                    }

                    // Cancel button
                    Rectangle {
                        Layout.preferredWidth: cancelLabel.implicitWidth + 32
                        Layout.preferredHeight: 36
                        radius: 18
                        color: cancelArea.containsMouse
                            ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.08)
                            : "transparent"

                        Behavior on color { ColorAnimation { duration: 150 } }

                        Text {
                            id: cancelLabel
                            anchors.centerIn: parent
                            text: "Cancel"
                            font.family: Vars.fontFamily
                            font.pixelSize: 13
                            font.weight: 600
                            color: Theme.on_primary
                        }

                        MouseArea {
                            id: cancelArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.flow) {
                                    root.flow.cancelAuthenticationRequest();
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }
    }
}
