import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Greetd
import Quickshell.Widgets
import Quickshell.Io
import QtQuick.Effects
import "theme/variables.js" as Vars
import "."

Rectangle {
    id: root
    width: 400
    height: 600
    radius: 24
    color: Theme.surface
    anchors.centerIn: parent

    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowOpacity: 0.15
        shadowBlur: 1.0
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 4
        shadowColor: Theme.shadow
    }

    // ── State ──────────────────────────────────────────────
    property var users: ["boing", "surinder"]
    property var sessions: [
        { name: "Hyprland",  cmd: ["Hyprland"] },
        { name: "Hyprland (uwsm)", cmd: ["uwsm", "start", "hyprland-uwsm.desktop"] },
        { name: "GNOME",    cmd: ["gnome-session"] },
        { name: "XFCE",     cmd: ["startxfce4"] },
        { name: "bash",     cmd: ["/bin/bash"] }
    ]

    property int currentUserIndex: 0
    property int currentSessionIndex: 0
    property string activeUser: users[currentUserIndex]
    property string activeSession: sessions[currentSessionIndex].name
    property var    activeCmd:     sessions[currentSessionIndex].cmd

    property bool showSwitcher: false
    property string statusMessage: ""
    property bool   authError: false
    property bool   isAuthenticating: false

    // ── Accent palette ─────────────────────────────────────
    readonly property color accentPrimary:   Theme.primary
    readonly property color accentDark:      Theme.on_primary
    readonly property color surfaceDim:      Theme.surface_variant
    readonly property color surfaceBright:   Theme.surface_container_lowest
    readonly property color textPrimary:     Theme.on_surface
    readonly property color textDim:         Theme.on_surface_variant

    // ── Clock timer ────────────────────────────────────────
    property string clockHours: Qt.formatTime(new Date(), "hh")
    property string clockMinutes: Qt.formatTime(new Date(), "mm")
    property string clockDate: Qt.formatDate(new Date(), "dddd • dd MMM").toUpperCase()

    Timer {
        interval: 1000; running: true; repeat: true
        onTriggered: {
            var now = new Date();
            clockHours   = Qt.formatTime(now, "hh");
            clockMinutes = Qt.formatTime(now, "mm");
            clockDate    = Qt.formatDate(now, "dddd • dd MMM").toUpperCase();
        }
    }

    // ── Greetd integration ─────────────────────────────────
    Component.onCompleted: {
        startSession();
    }

    function startSession() {
        isAuthenticating = true;
        statusMessage = "";
        authError = false;
        passwordInput.text = "";

        if (Greetd.state === GreetdState.Authenticating) {
            Greetd.cancelSession();
        }
        Greetd.createSession(activeUser);
    }

    Connections {
        target: Greetd

        onAuthMessage: (message, isError, responseRequired, echoResponse) => {
            if (isError) {
                statusMessage = message;
                authError = true;
                shakeAnim.start();
            }
        }

        onAuthFailure: (message) => {
            statusMessage = message || "Authentication failed";
            authError = true;
            passwordInput.text = "";
            shakeAnim.start();
            errorResetTimer.start();
            retryTimer.start();
        }

        onReadyToLaunch: () => {
            statusMessage = "Launching " + activeSession + "...";
            authError = false;
            Greetd.launch(activeCmd);
        }

        onError: (errorMsg) => {
            statusMessage = errorMsg;
            authError = true;
        }
    }

    Timer {
        id: errorResetTimer
        interval: 2000
        onTriggered: {
            authError = false;
            statusMessage = "";
        }
    }

    Timer {
        id: retryTimer
        interval: 800
        onTriggered: startSession()
    }

    // ── Shake animation for errors ─────────────────────────
    SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: passwordBox; property: "anchors.horizontalCenterOffset"; to: -12; duration: Vars.animationDuration }
        NumberAnimation { target: passwordBox; property: "anchors.horizontalCenterOffset"; to: 12; duration: Vars.animationDuration }
        NumberAnimation { target: passwordBox; property: "anchors.horizontalCenterOffset"; to: -8; duration: Vars.animationDuration }
        NumberAnimation { target: passwordBox; property: "anchors.horizontalCenterOffset"; to: 8; duration: Vars.animationDuration }
        NumberAnimation { target: passwordBox; property: "anchors.horizontalCenterOffset"; to: 0; duration: Vars.animationDuration }
    }

    // ── Main card content ──────────────────────────────────
    ColumnLayout {
        id: mainContent
        anchors.fill: parent
        anchors.margins: 36
        spacing: 16

        opacity: showSwitcher ? 0.0 : 1.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }

        // Spacer
        Item { Layout.fillHeight: true }

        // ── Clock ──
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: clockHours + ":" + clockMinutes
            font.family: Vars.fontFamily
            font.pixelSize: 72
            font.weight: 700
            color: root.textPrimary
        }

        // ── Date ──
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: clockDate
            font.family: Vars.fontFamily
            font.pixelSize: 12
            font.weight: 600
            font.letterSpacing: 2.0
            color: root.textDim
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
                    source: "file:///home/" + activeUser + "/.face"
                    fillMode: Image.PreserveAspectCrop
                    smooth: true

                    onStatusChanged: {
                        if (status === Image.Error || status === Image.Null) {
                            fallbackIcon.visible = true;
                        } else {
                            fallbackIcon.visible = false;
                        }
                    }
                }

                Text {
                    id: fallbackIcon
                    anchors.centerIn: parent
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 56
                    color: root.textDim
                    text: "\ue853"
                    visible: avatarImage.status !== Image.Ready
                }
            }
        }

        Item { Layout.preferredHeight: 4 }

        // ── User | Session label ──
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 6
            Text {
                text: activeUser
                font.family: Vars.fontFamily
                font.pixelSize: 18
                font.weight: 700
                color: root.textPrimary
            }
            Text {
                text: "|"
                font.family: Vars.fontFamily
                font.pixelSize: 16
                font.weight: 400
                color: Theme.outline_variant
            }
            Text {
                text: activeSession
                font.family: Vars.fontFamily
                font.pixelSize: 16
                font.weight: 500
                color: root.textDim
            }
        }

        Item { Layout.preferredHeight: 8 }

        // ── Password Input ──
        Rectangle {
            id: passwordBox
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            radius: 26
            color: authError ? Theme.error_container : Theme.surface_container_highest
            border.color: passwordInput.activeFocus ? root.accentPrimary : "transparent"
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
                    color: root.textDim
                    text: "\ue897"
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
                    color: root.textPrimary
                    echoMode: TextInput.Password
                    clip: true
                    focus: !showSwitcher

                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        leftPadding: 4
                        text: "Enter your password"
                        color: root.textDim
                        font.family: Vars.fontFamily
                        font.pixelSize: 15
                        visible: !passwordInput.text && !passwordInput.activeFocus
                    }

                    onAccepted: {
                        if (text.length > 0) {
                            Greetd.respond(text);
                        }
                    }
                }

                // Submit arrow
                Rectangle {
                    width: 36; height: 36; radius: 18
                    color: passwordInput.text.length > 0 ? root.accentPrimary : Theme.surface_container_high
                    Behavior on color { ColorAnimation { duration: Vars.animationDuration } }

                    Text {
                        anchors.centerIn: parent
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 18
                        color: passwordInput.text.length > 0 ? root.accentDark : root.textDim
                        text: "\ue5c8"
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (passwordInput.text.length > 0) {
                                Greetd.respond(passwordInput.text);
                            }
                        }
                    }
                }
            }
        }

        // ── Status message ──
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: statusMessage
            font.family: Vars.fontFamily
            font.pixelSize: 12
            color: authError ? Theme.error : root.textDim
            visible: statusMessage !== ""
            opacity: visible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: Vars.animationDuration } }
        }

        Item { Layout.preferredHeight: 4 }

        // ── Action Icons ──
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 24

            // Suspend (Water drop)
            Rectangle {
                width: 48; height: 48; radius: 24
                color: suspendMouse.containsMouse ? root.surfaceDim : "transparent"
                Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                
                Text {
                    anchors.centerIn: parent
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 24
                    color: root.textPrimary
                    text: "\ue798"
                }
                MouseArea {
                    id: suspendMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: suspendProcess.running = true
                }
            }

            // Reboot (Gear)
            Rectangle {
                width: 48; height: 48; radius: 24
                color: rebootMouse.containsMouse ? root.surfaceDim : "transparent"
                Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                
                Text {
                    anchors.centerIn: parent
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 24
                    color: root.textPrimary
                    text: "\ue8b8"
                }
                MouseArea {
                    id: rebootMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rebootProcess.running = true
                }
            }

            // Power
            Rectangle {
                width: 48; height: 48; radius: 24
                color: powerMouse.containsMouse ? root.surfaceDim : "transparent"
                Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                
                Text {
                    anchors.centerIn: parent
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 24
                    color: root.textPrimary
                    text: "\ue8ac"
                }
                MouseArea {
                    id: powerMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: powerProcess.running = true
                }
            }
        }

        Item { Layout.fillHeight: true }

        // ── Switch Session Text (toggle) ──
        MouseArea {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            cursorShape: Qt.PointingHandCursor
            onClicked: showSwitcher = true

            RowLayout {
                anchors.centerIn: parent
                spacing: 6

                Text {
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 14
                    color: root.textDim
                    text: "\ue5d2"
                }
                Text {
                    text: "Click to switch User and Session"
                    font.family: Vars.fontFamily
                    font.pixelSize: 12
                    color: root.textDim
                }
            }
        }
    }

    // ── Switcher overlay ───────────────────────────────────
    ColumnLayout {
        id: switcherContent
        anchors.fill: parent
        anchors.margins: 28
        spacing: 16

        opacity: showSwitcher ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }

        // ── Header with back button ──
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                width: 36; height: 36; radius: 18
                color: root.surfaceDim

                Text {
                    anchors.centerIn: parent
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: root.textPrimary
                    text: "\ue5c4"
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        showSwitcher = false;
                        startSession();
                    }
                }
            }

            Text {
                text: "Switch User & Session"
                font.family: Vars.fontFamily
                font.pixelSize: 18
                font.weight: 600
                color: root.textPrimary
                Layout.fillWidth: true
            }
        }

        // ── User selection ──
        Text {
            text: "USER"
            font.family: Vars.fontFamily
            font.pixelSize: 11
            font.weight: 700
            font.letterSpacing: 2
            color: root.textDim
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: root.users

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    radius: currentUserIndex === index ? 14 : 22
                    color: currentUserIndex === index ? root.accentPrimary : root.surfaceDim
                    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                    Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12

                        Text {
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 20
                            color: currentUserIndex === index ? root.accentDark : root.textDim
                            text: "\ue7fd"
                        }
                        Text {
                            text: modelData
                            font.family: Vars.fontFamily
                            font.pixelSize: 14
                            font.weight: 500
                            color: currentUserIndex === index ? root.accentDark : root.textPrimary
                            Layout.fillWidth: true
                        }
                        Text {
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 18
                            color: currentUserIndex === index ? root.accentDark : "transparent"
                            text: "\ue876"
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            currentUserIndex = index;
                        }
                    }
                }
            }
        }

        Item { Layout.preferredHeight: 8 }

        // ── Session selection ──
        Text {
            text: "SESSION"
            font.family: Vars.fontFamily
            font.pixelSize: 11
            font.weight: 700
            font.letterSpacing: 2
            color: root.textDim
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: sessionCol.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            ColumnLayout {
                id: sessionCol
                width: parent.width
                spacing: 6

                Repeater {
                    model: root.sessions

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        radius: currentSessionIndex === index ? 14 : 22
                        color: currentSessionIndex === index ? root.accentPrimary : root.surfaceDim
                        Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                        Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 12

                            Text {
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 20
                                color: currentSessionIndex === index ? root.accentDark : root.textDim
                                text: "\ue30b"
                            }
                            Text {
                                text: modelData.name
                                font.family: Vars.fontFamily
                                font.pixelSize: 14
                                font.weight: 500
                                color: currentSessionIndex === index ? root.accentDark : root.textPrimary
                                Layout.fillWidth: true
                            }
                            Text {
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 18
                                color: currentSessionIndex === index ? root.accentDark : "transparent"
                                text: "\ue876"
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                currentSessionIndex = index;
                            }
                        }
                    }
                }
            }
        }

        // ── Confirm button ──
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            radius: 24
            color: root.accentPrimary

            Text {
                anchors.centerIn: parent
                text: "Confirm"
                font.family: Vars.fontFamily
                font.pixelSize: 15
                font.weight: 600
                color: root.accentDark
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    showSwitcher = false;
                    startSession();
                }
            }
        }
    }

    // ── Power / Reboot processes ───────────────────────────
    Process {
        id: powerProcess
        command: ["systemctl", "poweroff"]
    }

    Process {
        id: rebootProcess
        command: ["systemctl", "reboot"]
    }

    Process {
        id: suspendProcess
        command: ["systemctl", "suspend"]
    }
}
