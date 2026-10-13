import QtQuick
import QtQuick.Effects
import ".."
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Polkit
import Quickshell.Hyprland
import "../theme"
import "../core/primitives" as Primitives
Item {
    id: root

    Layout.preferredWidth: 100
    Layout.preferredHeight: 40

    property alias panel: panel
    property alias panelMask: panelMask
    property bool expanded: flow !== null && !flow.isCompleted
    property var focusWindow: null
    property bool gameMode: Vars.gameMode !== undefined ? Vars.gameMode : false



    onExpandedChanged: {
        if (expanded) {
            MorphState.notifyOpened(420, panel.targetHeight, panel.targetRad, panel);
            passwordInput.forceActiveFocus();
        } else {
            MorphState.notifyClosed();
        }
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
                passwordInput.forceActiveFocus();
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
        NumberAnimation { target: passwordBox; property: "x"; to: passwordBox.restX - 12; duration: Vars.animationDuration }
        NumberAnimation { target: passwordBox; property: "x"; to: passwordBox.restX + 12; duration: Vars.animationDuration }
        NumberAnimation { target: passwordBox; property: "x"; to: passwordBox.restX - 8; duration: Vars.animationDuration }
        NumberAnimation { target: passwordBox; property: "x"; to: passwordBox.restX + 8; duration: Vars.animationDuration }
        NumberAnimation { target: passwordBox; property: "x"; to: passwordBox.restX; duration: Vars.animationDuration }
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
        // x/y are computed as one atomic expression per axis instead of six independently
        // toggled anchor lines plus four bleed-margin lines, so a pillPosition change can't
        // leave this item part-anchored to the old edge while the other axis has already moved
        // to the new one (that mismatch is what made expanded popups fail to render their
        // content after a live position change).
        property real _bleed: root.expanded ? -20 : 0
        x: {
            if (Vars.pillPosition === "Left") return _bleed;
            if (Vars.pillPosition === "Right") return parent.width - width - _bleed;
            return (parent.width - width) / 2;
        }
        y: {
            if (Vars.pillPosition === "Bottom") return parent.height - height - _bleed;
            if (Vars.pillPosition === "Left" || Vars.pillPosition === "Right") return (parent.height - height) / 2;
            return _bleed;
        }
        width: root.expanded ? 460 : 0
        height: root.expanded ? 400 : 0
    }

    Primitives.SquircleMask {
        id: panel
        property bool isBackgroundActive: root.expanded || (MorphState.openCount === 0 && MorphState.activeItem === panel && panel.width > 105)
        layer.enabled: false
        layer.samples: Vars.layerSamples
        // x/y are computed as one atomic expression per axis instead of six independently
        // toggled anchor lines, so a pillPosition change can't leave this item part-anchored to
        // the old edge while the other axis has already moved to the new one (that mismatch is
        // what made expanded popups fail to render their content after a live position change).
        x: {
            if (Vars.pillPosition === "Left") return 0;
            if (Vars.pillPosition === "Right") return parent.width - width;
            return (parent.width - width) / 2;
        }
        y: {
            if (Vars.pillPosition === "Bottom") return parent.height - height;
            if (Vars.pillPosition === "Left" || Vars.pillPosition === "Right") return (parent.height - height) / 2;
            return 0;
        }

        property real targetHeight: root.expanded ? contentColumn.implicitHeight + 32 : (MorphState.anyExpanded ? MorphState.targetHeight : 40)
        width: root.expanded ? 420 : (MorphState.anyExpanded ? MorphState.targetWidth : 100)
        height: targetHeight

        onTargetHeightChanged: {
            if (root.expanded) MorphState.updateDimensions(420, targetHeight, targetRad);
        }

        opacity: isBackgroundActive || innerUI.opacity > 0 ? 1.0 : 0.0
        // visible: opacity > 0 // Removed to preserve Behavior when hidden

        color: Vars.tColorActive(isBackgroundActive, Theme.surface_container, Vars.panelOpacity)
        property real targetRad: root.expanded ? Vars.radiusExtraLarge : (MorphState.anyExpanded ? MorphState.targetRadius : height / 2)
        topLeftRadius: Vars.getTopLeftRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        topRightRadius: Vars.getTopRightRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        bottomLeftRadius: Vars.getBottomLeftRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        bottomRightRadius: Vars.getBottomRightRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)

        Behavior on width { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on height { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            hoverEnabled: true
            enabled: panel.opacity > 0
            onWheel: (wheel) => wheel.accepted = true
        }

        // EXPANDED UI
        Item {
            id: innerUI
            // Content must never draw outside the morphing panel
            clip: true
            anchors.fill: parent

            opacity: root.expanded ? 1.0 : 0.0
            visible: root.expanded || opacity > 0 || root.expanded
            Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.expanded ? Vars.customEmphasizedDecelerate : Vars.customEmphasizedAccelerate } }

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
                    spacing: 16

                    Rectangle {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        radius: 22
                        antialiasing: true
                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                        
                        QsText {
                            anchors.centerIn: parent
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 24
                            color: Theme.primary
                            text: "lock"
                        }
                    }

                    QsText {
                        text: "Authentication Required"
                        font.family: Vars.fontFamily
                        font.pixelSize: 20
                        setWeight: 700
                        color: Theme.on_surface
                    }
                }

                // Message text
                QsText {
                    Layout.fillWidth: true
                    text: root.flow ? root.flow.message : ""
                    font.family: Vars.fontFamily
                    font.pixelSize: 14
                    setWeight: 400
                    color: Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.9)
                    wrapMode: Text.WordWrap
                    lineHeight: 1.4
                    Layout.topMargin: 4
                }

                // Action ID
                QsText {
                    Layout.fillWidth: true
                    text: root.flow ? root.flow.actionId : ""
                    font.family: Vars.fontFamily
                    font.pixelSize: 12
                    setWeight: 400
                    color: Theme.on_surface_variant
                    opacity: 0.6
                    visible: root.flow && root.flow.actionId !== ""
                    Layout.bottomMargin: 8
                }

                // Password Input
                Rectangle {
                    id: passwordBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    radius: Vars.radiusLarge
                    antialiasing: true
                    color: root.authError
                        ? Theme.error_container
                        : (passwordInput.activeFocus ? Theme.surface_container_highest : Qt.rgba(Theme.surface_container_highest.r, Theme.surface_container_highest.g, Theme.surface_container_highest.b, 0.5))
                    border.color: passwordInput.activeFocus
                        ? Theme.primary
                        : (root.authError ? Theme.error : "transparent")
                    border.width: passwordInput.activeFocus ? 2 : 0

                    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                    Behavior on border.color { ColorAnimation { duration: Vars.animationDuration } }

                    property real restX: x
                    Component.onCompleted: restX = x

                    visible: !root.flow || root.flow.isResponseRequired

                    onVisibleChanged: {
                        if (visible && root.expanded) {
                            passwordInput.forceActiveFocus();
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.IBeamCursor
                        onClicked: passwordInput.forceActiveFocus()
                    }



                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12

                        QsText {
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 20
                            color: passwordInput.activeFocus ? Theme.primary : Theme.on_surface_variant
                            text: "key"
                            Layout.alignment: Qt.AlignVCenter
                        }

                        TextInput {
                            id: passwordInput
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Vars.fontFamily
                            font.pixelSize: 14
                            color: Theme.on_surface
                            echoMode: TextInput.Password
                            clip: true
                            focus: root.expanded

                            QsText {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: root.flow && root.flow.inputPrompt ? root.flow.inputPrompt : "Password:"
                                color: Theme.on_surface_variant
                                opacity: 0.8
                                font.family: Vars.fontFamily
                                font.pixelSize: 14
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
                QsText {
                    Layout.fillWidth: true
                    text: root.errorMessage
                    font.family: Vars.fontFamily
                    font.pixelSize: 11
                    color: root.authError ? Theme.error : Theme.on_surface_variant
                    visible: root.errorMessage !== ""
                    opacity: visible ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: Vars.animationDuration } }
                }

                // Buttons: Cancel | Authenticate
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    layoutDirection: Qt.RightToLeft
                    Layout.topMargin: 4

                    // Authenticate button
                    Rectangle {
                        Layout.preferredWidth: authenticateLabel.implicitWidth + 48
                        Layout.preferredHeight: 40
                        radius: 20
                        antialiasing: true
                        color: authenticateArea.containsMouse
                            ? Qt.lighter(Theme.primary, 1.08)
                            : Theme.primary

                        Behavior on color { ColorAnimation { duration: Vars.animationDuration } }

                        QsText {
                            id: authenticateLabel
                            anchors.centerIn: parent
                            text: "Authenticate"
                            font.family: Vars.fontFamily
                            font.pixelSize: 14
                            setWeight: 600
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
                        Layout.preferredHeight: 40
                        radius: 20
                        antialiasing: true
                        color: cancelArea.containsMouse
                            ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)
                            : "transparent"

                        Behavior on color { ColorAnimation { duration: Vars.animationDuration } }

                        QsText {
                            id: cancelLabel
                            anchors.centerIn: parent
                            text: "Cancel"
                            font.family: Vars.fontFamily
                            font.pixelSize: 14
                            setWeight: 600
                            color: Theme.on_surface_variant
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
