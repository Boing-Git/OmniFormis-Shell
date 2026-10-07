import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import "../../.."
import "../../../theme"
import "../../../core/primitives" as Primitives
import ".."

Item {
    id: wifiDelegate
    property var rootPage

    Layout.fillWidth: true

    property bool isPasswordMode: false
    onIsPasswordModeChanged: { if (!isPasswordMode) wifiPwdInput.text = ""; }
    Layout.preferredHeight: 80
    Behavior on Layout.preferredHeight {
        NumberAnimation {
            duration: Vars.animationDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Vars.customExpressiveSpatialSlow
        }
    }

    property bool isSelected: modelData.connected || isPasswordMode
    property bool showForget: false

    property color targetColor: modelData.connected ? (Vars.tColorSelected(Theme.primary_container)) : (isSelected ? (Vars.tColorSelected(Theme.primary_container, 0.75)) : (wifiMouse.containsMouse ? (Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)) : (Vars.tColor(Theme.surface_container_high, Vars.componentOpacity))))
    scale: wifiMouse.pressed ? 1.08 : 1.0
    Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }
    Behavior on targetColor {
        ColorAnimation {
            duration: Vars.animationDuration
        }
    }

    // Set when the last connection attempt failed, cleared on the next attempt
    property bool connectFailed: false
    readonly property bool isOpenNetwork: modelData.security === WifiSecurityType.Open

    Connections {
        target: modelData
        function onConnectionFailed(reason) {
            wifiDelegate.connectFailed = true;
            // A bad or missing password: let the user type it again
            if (reason === ConnectionFailReason.NoSecrets || reason === ConnectionFailReason.WifiAuthTimeout || reason === ConnectionFailReason.WifiClientFailed)
                wifiDelegate.isPasswordMode = true;
        }
        function onConnectedChanged() {
            if (modelData.connected)
                wifiDelegate.connectFailed = false;
        }
    }

    // Known and open networks connect straight away, new secured ones ask for a password first
    function connectNetwork() {
        wifiDelegate.connectFailed = false;
        if (modelData.known || wifiDelegate.isOpenNetwork)
            modelData.connect();
        else
            wifiDelegate.isPasswordMode = true;
    }

    // The password goes straight to NetworkManager through Quickshell instead of being passed to
    // nmcli on the command line, where any process could read it.
    function submitPassword() {
        var pwd = wifiPwdInput.text;
        wifiDelegate.connectFailed = false;
        if (pwd.length > 0) {
            modelData.connectWithPsk(pwd);
        } else if (modelData.known || wifiDelegate.isOpenNetwork) {
            modelData.connect();
        } else {
            wifiPwdInput.forceActiveFocus();
            return;
        }
        wifiPwdInput.text = "";
        wifiDelegate.isPasswordMode = false;
    }

    Item {
        anchors.fill: parent
        opacity: parent.targetColor.a
        Rectangle {
            antialiasing: true
            anchors.fill: parent
            color: Qt.rgba(parent.parent.targetColor.r, parent.parent.targetColor.g, parent.parent.targetColor.b, 1.0)
            
            property bool isFirst: index === 0
            property bool isLast: rootPage.wifiDevice && rootPage.wifiDevice.networks && rootPage.wifiDevice.networks.values ? index === rootPage.wifiDevice.networks.values.length - 1 : true
            property real baseRadius: Vars.radiusLarge
            property real edgeRadius: 4
            
            
            topLeftRadius: parent.parent.isSelected ? height / 2 : edgeRadius
            topRightRadius: parent.parent.isSelected ? height / 2 : edgeRadius
            bottomLeftRadius: parent.parent.isSelected ? height / 2 : edgeRadius
            bottomRightRadius: parent.parent.isSelected ? height / 2 : edgeRadius

            Behavior on topLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
            Behavior on topRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
            Behavior on bottomLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
            Behavior on bottomRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        }
    }

    Item {
        anchors.fill: parent

        Item {
            anchors.fill: parent
            opacity: wifiDelegate.isPasswordMode ? 0.0 : 1.0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.InOutCubic
                }
            }
            RowLayout {
                z: 1
                anchors.fill: parent
                anchors.leftMargin: Vars.spacingLarge
                anchors.rightMargin: Vars.spacingLarge
                spacing: 16

                SettingsIcon {
                    size: 40
                    Layout.alignment: Qt.AlignVCenter
                    selected: wifiDelegate.isSelected
                    filled: modelData.connected
                    icon: {
                        if (modelData.signalStrength === undefined)
                            return "\ue63e";
                        let tier = Math.min(Math.floor(modelData.signalStrength / 25), 3);
                        return ["\ue1ba", "\uebe4", "\uebd6", "\uebe1"][tier] || "\ue63e";
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0
                    Layout.fillWidth: true

                    // Placeholder for the animated floating SSID text
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 18
                    }

                    QsText {
                        text: {
                            if (wifiDelegate.connectFailed)
                                return "Couldn't connect";
                            if (modelData.state === ConnectionState.Connecting)
                                return "Connecting…";
                            if (modelData.state === ConnectionState.Disconnecting)
                                return "Disconnecting…";
                            if (modelData.connected)
                                return "Connected";
                            return modelData.known ? "Saved" : "Available";
                        }
                        font.family: Vars.fontFamily
                        font.pixelSize: 11
                        setWeight: 500
                        color: wifiDelegate.connectFailed ? Theme.error : (modelData.connected ? Theme.on_primary_container : Theme.on_surface_variant)
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignLeft
                    }
                }
                Item {
                    width: 40
                    height: 40
                    Layout.alignment: Qt.AlignVCenter

                    Item {
                        id: m3LoadingIndicator
                        anchors.fill: parent
                        property bool running: modelData.stateChanging

                        Primitives.LoadingIndicator {
                            anchors.fill: parent
                            running: m3LoadingIndicator.running
                        }
                    }

                    Rectangle {
                        width: 32
                        height: 32
                        anchors.centerIn: parent
                        radius: 16
                        antialiasing: true
                        color: infoHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent"
                        visible: (modelData.known || modelData.connected) && !m3LoadingIndicator.running
                        QsText {
                            anchors.centerIn: parent
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 20
                            color: Theme.on_surface_variant
                            text: "info"
                        }
                        MouseArea {
                            id: infoHover
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: rootPage.showPasswordFor(modelData.name)
                        }
                    }
                }
            }
            MouseArea {
                id: wifiMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: mouse => {
                    wifiDelegate.forceActiveFocus();
                    if (mouse.button === Qt.RightButton) {
                        wifiDelegate.showForget = true;
                    } else {
                        if (modelData.connected)
                            modelData.disconnect();
                        else
                            wifiDelegate.connectNetwork();
                    }
                }
            }
        }

        Item {
            anchors.fill: parent
            opacity: wifiDelegate.isPasswordMode ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.InOutCubic
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Vars.spacingLarge
                anchors.rightMargin: Vars.spacingLarge
                spacing: 4

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    Layout.alignment: Qt.AlignVCenter

                    Rectangle {
                        antialiasing: true
                        anchors.fill: parent
                        color: "transparent"
                        border.color: wifiPwdInput.activeFocus ? Theme.primary : Theme.outline
                        border.width: wifiPwdInput.activeFocus ? 3 : 2
                        topLeftRadius: 24
                        bottomLeftRadius: 24
                        topRightRadius: 4
                        bottomRightRadius: 4
                        Behavior on border.color {
                            ColorAnimation {
                                duration: 150
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 4
                            spacing: 4

                            QsText {
                                text: "\ue897"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 20
                                color: wifiPwdInput.activeFocus ? Theme.primary : Theme.on_surface_variant
                            }

                            TextInput {
                                id: wifiPwdInput
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                verticalAlignment: Text.AlignVCenter
                                font.family: Vars.fontFamily
                                font.pixelSize: 16
                                color: Theme.on_surface
                                echoMode: pwdToggle.showPwd ? TextInput.Normal : TextInput.Password
                                selectByMouse: true
                                clip: true
                                MouseArea { anchors.fill: parent; cursorShape: Qt.IBeamCursor; onPressed: (mouse) => { parent.forceActiveFocus(); mouse.accepted = false; } }
                                Keys.onReturnPressed: wifiDelegate.submitPassword()
                                onVisibleChanged: {
                                    if (visible && wifiDelegate.isPasswordMode) {
                                        text = "";
                                        pwdToggle.showPwd = false;
                                        forceActiveFocus();
                                    }
                                }
                            }

                            Rectangle {
                                id: pwdToggle
                                property bool showPwd: false
                                width: 32
                                height: 32
                                radius: 16
                                antialiasing: true
                                color: pwdToggleHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent"
                                QsText {
                                    anchors.centerIn: parent
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 20
                                    color: Theme.on_surface_variant
                                    text: pwdToggle.showPwd ? "\ue8f4" : "\ue8f5"
                                }
                                MouseArea {
                                    id: pwdToggleHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: pwdToggle.showPwd = !pwdToggle.showPwd
                                }
                            }

                            Rectangle {
                                width: 32
                                height: 32
                                radius: 16
                                antialiasing: true
                                color: closeHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent"
                                QsText {
                                    anchors.centerIn: parent
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 20
                                    color: Theme.on_surface_variant
                                    text: "\ue5cd"
                                }
                                MouseArea {
                                    id: closeHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: wifiDelegate.isPasswordMode = false
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    antialiasing: true
                    Layout.preferredWidth: connectBtnTxt.implicitWidth + 32
                    Layout.preferredHeight: 48
                    Layout.alignment: Qt.AlignVCenter
                    topLeftRadius: 4
                    bottomLeftRadius: 4
                    topRightRadius: 24
                    bottomRightRadius: 24
                    color: connectHover.containsMouse ? Qt.tint(Theme.primary, Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.08)) : Theme.primary
                    QsText {
                        id: connectBtnTxt
                        anchors.centerIn: parent
                        text: "Connect"
                        color: Theme.on_primary
                        font.family: Vars.fontFamily
                        font.pixelSize: 14
                        setWeight: 500
                    }
                    MouseArea {
                        id: connectHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: wifiDelegate.submitPassword()
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: Vars.animationDuration
                        }
                    }
                }
            }
        }
    }

    // Dynamic Floating SSID Label and Background Cutout
    Rectangle {
        z: 9
        x: 36
        y: 4
        width: animatedSsidLabel.implicitWidth + 8
        height: animatedSsidLabel.implicitHeight
        color: Theme.surface_container_high
        opacity: wifiDelegate.isPasswordMode ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutCubic
            }
        }
    }

    QsText {
        id: animatedSsidLabel
        z: 10
        text: modelData.name
        font.family: Vars.fontFamily
        font.pixelSize: wifiDelegate.isPasswordMode ? 12 : 16
        setWeight: wifiDelegate.isPasswordMode ? 800 : 400
        color: wifiDelegate.isPasswordMode ? (wifiPwdInput.activeFocus ? Theme.primary : Theme.on_surface_variant) : (modelData.connected ? Theme.on_primary_container : Theme.on_surface)

        x: wifiDelegate.isPasswordMode ? 40 : 76
        y: wifiDelegate.isPasswordMode ? 4 : 20

        Behavior on x {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutCubic
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: 300
                easing.type: Easing.InOutCubic
            }
        }
        Behavior on color {
            ColorAnimation {
                duration: 150
            }
        }
    }

    // Forget Overlay
    Rectangle {
        antialiasing: true
        anchors.fill: parent
        color: Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)
        visible: wifiDelegate.showForget
        opacity: wifiDelegate.showForget ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: Vars.animationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customExpressiveSpatialSlow
            }
        }
        
        property bool isLast: rootPage.wifiDevice && rootPage.wifiDevice.networks && rootPage.wifiDevice.networks.values ? index === rootPage.wifiDevice.networks.values.length - 1 : true
        property real baseRadius: Vars.radiusLarge
        property real edgeRadius: 4
        
        
        topLeftRadius: wifiDelegate.isSelected ? height / 2 : edgeRadius
        topRightRadius: wifiDelegate.isSelected ? height / 2 : edgeRadius
        bottomLeftRadius: wifiDelegate.isSelected ? height / 2 : edgeRadius
        bottomRightRadius: wifiDelegate.isSelected ? height / 2 : edgeRadius

        Behavior on topLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on topRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on bottomLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on bottomRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 16
            QsText {
                text: "Forget " + (modelData.name || "Network") + "?"
                font.family: Vars.fontFamily
                font.pixelSize: 16
                color: Theme.on_surface
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            Rectangle {
                width: 80
                height: 32
                radius: 16
                antialiasing: true
                color: "transparent"
                border.color: Theme.outline
                border.width: 1
                QsText {
                    anchors.centerIn: parent
                    text: "Cancel"
                    color: Theme.on_surface
                    font.family: Vars.fontFamily
                    font.pixelSize: 14
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: wifiDelegate.showForget = false
                }
            }
            Rectangle {
                width: 80
                height: 32
                radius: 16
                antialiasing: true
                color: Theme.error ? Theme.error : "#ffb4ab"
                QsText {
                    anchors.centerIn: parent
                    text: "Forget"
                    color: Theme.on_error ? Theme.on_error : "#690005"
                    font.family: Vars.fontFamily
                    font.pixelSize: 14
                    setWeight: 500
                }
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (modelData.forget)
                            modelData.forget();
                        wifiDelegate.showForget = false;
                    }
                }
            }
        }
    }
}
