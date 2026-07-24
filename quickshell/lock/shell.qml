import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Widgets
import "../theme/variables.js" as Vars
import "../"

ShellRoot {
    id: root

    property string activeUser: "boing"
    property string statusMessage: ""
    property bool authError: false

    // Date/Time
    property string clockHours: Qt.formatTime(new Date(), "hh")
    property string clockMinutes: Qt.formatTime(new Date(), "mm")
    property string clockDate: Qt.formatDate(new Date(), "dddd • dd MMM").toUpperCase()

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            var now = new Date();
            root.clockHours   = Qt.formatTime(now, "hh");
            root.clockMinutes = Qt.formatTime(now, "mm");
            root.clockDate    = Qt.formatDate(now, "dddd • dd MMM").toUpperCase();
        }
    }

    // Reset error timer
    Timer {
        id: errorResetTimer
        interval: 2000
        onTriggered: {
            root.authError = false;
            root.statusMessage = "";
        }
    }

    Component.onCompleted: {
        console.log("[LOCKSCREEN] Lockscreen Component completed initializing!");
        console.log("[LOCKSCREEN] activeUser is:", root.activeUser);
    }

    PamContext {
        id: pam
        service: "system-auth" // Most standard linux systems use system-auth for login
        
        onAuthenticated: {
            console.log("[LOCKSCREEN] PAM Authentication SUCCESS! Unlocking...");
            sessionLock.locked = false;
            Qt.quit(); // Exit the quickshell process completely
        }

        onError: (error) => {
            console.log("[LOCKSCREEN] PAM Authentication ERROR:", error);
            root.statusMessage = error || "Authentication failed";
            root.authError = true;
            root.shakeActive();
            errorResetTimer.start();
        }
    }

    // Signal used by surfaces to trigger the shake animation on the LockCard
    signal shakeActive()

    WlSessionLock {
        id: sessionLock
        locked: true // Ensure it locks immediately

        onLockedChanged: {
            console.log("[LOCKSCREEN] WlSessionLock locked state changed to:", locked);
        }

        Instantiator {
            model: Quickshell.screens
            delegate: WlSessionLockSurface {
                screen: modelData

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(0, 0, 0, 0.6) // Dark overlay
                    
                    // The main lock card UI
                    LockCard {
                        id: card
                        anchors.centerIn: parent

                        Connections {
                            target: root
                            function onShakeActive() {
                                card.shakeAnim.start();
                                card.passwordInput.text = "";
                            }
                        }
                    }
                }
            }
        }
    }

    // Extracted LockCard component
    component LockCard: Rectangle {
        id: cardRoot
        width: 400
        height: 540
        radius: 24
        color: Theme.surface

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowOpacity: 0.15
            shadowBlur: 1.0
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 4
            shadowColor: Theme.shadow
        }
        
        property alias passwordInput: passwordInput
        property alias shakeAnim: shakeAnim

        SequentialAnimation {
            id: shakeAnim
            NumberAnimation { target: passwordBox; property: "anchors.horizontalCenterOffset"; to: -12; duration: Vars.animationDuration }
            NumberAnimation { target: passwordBox; property: "anchors.horizontalCenterOffset"; to: 12; duration: Vars.animationDuration }
            NumberAnimation { target: passwordBox; property: "anchors.horizontalCenterOffset"; to: -8; duration: Vars.animationDuration }
            NumberAnimation { target: passwordBox; property: "anchors.horizontalCenterOffset"; to: 8; duration: Vars.animationDuration }
            NumberAnimation { target: passwordBox; property: "anchors.horizontalCenterOffset"; to: 0; duration: Vars.animationDuration }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 36
            spacing: 16

            Item { Layout.fillHeight: true }

            // ── Clock ──
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.clockHours + ":" + root.clockMinutes
                font.family: Vars.fontFamily
                font.pixelSize: 72
                font.weight: 700
                color: Theme.on_surface
            }

            // ── Date ──
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.clockDate
                font.family: Vars.fontFamily
                font.pixelSize: 12
                font.weight: 600
                font.letterSpacing: 2.0
                color: Theme.on_surface_variant
            }

            Item { Layout.preferredHeight: 12 }

            // ── Profile Picture ──
            ClippingRectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 120
                height: 120
                radius: 60
                color: "transparent"
                border.color: Theme.outline_variant
                border.width: 2

                ClippingRectangle {
                    anchors.fill: parent
                    anchors.margins: 2
                    radius: width / 2
                    color: "transparent"

                    Image {
                        id: avatarImage
                        anchors.fill: parent
                        source: "file:///home/" + root.activeUser + "/.face"
                        fillMode: Image.PreserveAspectCrop
                        smooth: true
                        
                        onStatusChanged: {
                            fallbackIcon.visible = (status === Image.Error || status === Image.Null);
                        }
                    }

                    Text {
                        id: fallbackIcon
                        anchors.centerIn: parent
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 56
                        color: Theme.on_surface_variant
                        text: "\ue853" // account_circle
                        visible: avatarImage.status !== Image.Ready
                    }
                }
            }

            Item { Layout.preferredHeight: 4 }

            // ── User label ──
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.activeUser
                font.family: Vars.fontFamily
                font.pixelSize: 18
                font.weight: 700
                color: Theme.on_surface
            }

            Item { Layout.preferredHeight: 8 }

            // ── Password Input ──
            Rectangle {
                id: passwordBox
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                radius: 26
                color: root.authError ? Theme.error_container : Theme.surface_container_highest
                border.color: passwordInput.activeFocus ? Theme.primary : "transparent"
                border.width: 2
                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                Behavior on border.color { ColorAnimation { duration: Vars.animationDuration } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 8
                    spacing: 12

                    Text {
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 20
                        color: Theme.on_surface_variant
                        text: "\ue897" // lock icon
                    }

                    TextInput {
                        id: passwordInput
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        verticalAlignment: TextInput.AlignVCenter
                        leftPadding: 4
                        rightPadding: 4
                        font.family: Vars.fontFamily
                        font.pixelSize: 15
                        color: Theme.on_surface
                        echoMode: TextInput.Password
                        clip: true
                        focus: true // Grab focus automatically

                        Text {
                            anchors.fill: parent
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 4
                            text: "Enter your password"
                            color: Theme.on_surface_variant
                            font.family: Vars.fontFamily
                            font.pixelSize: 15
                            visible: !passwordInput.text && !passwordInput.activeFocus
                        }

                        onAccepted: {
                            if (text.length > 0) {
                                console.log("[LOCKSCREEN] Password submitted via Enter key. Attempting auth...");
                                // Assume PamContext has authenticate(username, password) or similar API
                                if (typeof pam.authenticate === "function") {
                                    console.log("[LOCKSCREEN] Using pam.authenticate()");
                                    pam.authenticate(root.activeUser, text);
                                } else if (typeof pam.respond === "function") {
                                    console.log("[LOCKSCREEN] Using pam.respond()");
                                    pam.respond(text);
                                } else {
                                    console.log("[LOCKSCREEN] ERROR: Unknown PamContext API. Available keys:", Object.keys(pam).join(", "));
                                }
                            }
                        }
                    }

                    // Submit arrow
                    Rectangle {
                        width: 36; height: 36; radius: 18
                        color: passwordInput.text.length > 0 ? Theme.primary : Theme.surface_container_high
                        Behavior on color { ColorAnimation { duration: Vars.animationDuration } }

                        Text {
                            anchors.centerIn: parent
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 18
                            color: passwordInput.text.length > 0 ? Theme.on_primary : Theme.on_surface_variant
                            text: "\ue5c8" // arrow_forward
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (passwordInput.text.length > 0) {
                                    console.log("[LOCKSCREEN] Password submitted via Submit Arrow. Attempting auth...");
                                    if (typeof pam.authenticate === "function") {
                                        console.log("[LOCKSCREEN] Using pam.authenticate()");
                                        pam.authenticate(root.activeUser, passwordInput.text);
                                    } else if (typeof pam.respond === "function") {
                                        console.log("[LOCKSCREEN] Using pam.respond()");
                                        pam.respond(passwordInput.text);
                                    } else {
                                        console.log("[LOCKSCREEN] ERROR: Unknown PamContext API. Available keys:", Object.keys(pam).join(", "));
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Status message ──
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.statusMessage
                font.family: Vars.fontFamily
                font.pixelSize: 12
                color: root.authError ? Theme.error : Theme.on_surface_variant
                visible: root.statusMessage !== ""
                opacity: visible ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration } }
            }
            
            Item { Layout.fillHeight: true }
        }
    }
}
