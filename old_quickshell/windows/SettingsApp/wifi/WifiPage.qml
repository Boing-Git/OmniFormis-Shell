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
    id: rootWifiPage

    Layout.fillWidth: true
    Layout.fillHeight: true

    property var panelRef
    property var wifiDevice

    property string pageTitle: "Wi-Fi Settings"
    property string pageIcon: "\ue63e"
    property string pageShape: "Puffy"
    property color pageColor: Theme.tertiary
    property color pageOnColor: Theme.on_tertiary
    property string searchText: ""

    // Scan while the page is on screen so the list is fresh, and stop when leaving it
    function syncScanner() {
        if (rootWifiPage.wifiDevice && Networking.wifiEnabled)
            rootWifiPage.wifiDevice.scannerEnabled = rootWifiPage.visible;
    }
    onVisibleChanged: syncScanner()
    onWifiDeviceChanged: syncScanner()

    M3Shapes { id: m3Shapes }

    property bool authOverlayVisible: false
    property string pendingSsid: ""
    property bool authError: false
    property string selectedNetworkForInfo: ""
    property string selectedNetworkPassword: ""

    Process {
        id: nmcliPwdProcess
        property string targetSsid: ""
        command: ["nmcli", "-s", "-g", "802-11-wireless-security.psk", "connection", "show", "id", targetSsid]
        stdout: StdioCollector {
            onStreamFinished: {
                rootWifiPage.selectedNetworkPassword = this.text.trim();
            }
        }
    }

    // Confirms the user's sudo password before a saved Wi-Fi password is revealed. The password is
    // written to sudo's stdin so it never appears in a process's command line.
    Process {
        id: authProcess
        property string pwd: ""
        command: ["sudo", "-S", "-k", "-p", "", "true"]
        stdinEnabled: true
        onStarted: {
            write(pwd + "\n");
            pwd = "";
        }
        onExited: code => {
            if (code === 0) {
                // Success!
                rootWifiPage.selectedNetworkForInfo = rootWifiPage.pendingSsid;
                rootWifiPage.selectedNetworkPassword = "Fetching...";
                nmcliPwdProcess.targetSsid = rootWifiPage.pendingSsid;
                nmcliPwdProcess.running = true;

                rootWifiPage.authOverlayVisible = false;
                authPwdInput.text = "";
                rootWifiPage.authError = false;
            } else {
                rootWifiPage.authError = true;
                authPwdInput.selectAll();
                authPwdInput.forceActiveFocus();
            }
        }
    }

    function showPasswordFor(ssid) {
        rootWifiPage.pendingSsid = ssid;
        rootWifiPage.authOverlayVisible = true;
        rootWifiPage.authError = false;
        authPwdInput.text = "";
        authPwdInput.forceActiveFocus();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Vars.spacingMedium

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Item {
                width: 38
                height: 38

                Image {
                    anchors.fill: parent
                    sourceSize: Qt.size(width, height)
                    source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='" + m3Shapes.getPath(rootWifiPage.pageShape) + "' fill='" + String(rootWifiPage.pageColor || "#3b383e").replace("#", "%23") + "'/></svg>"
                    smooth: true
                    antialiasing: true
                }

                QsText {
                    anchors.centerIn: parent
                    text: rootWifiPage.pageIcon
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: rootWifiPage.pageOnColor
                }
            }

            QsText {
                Layout.fillWidth: true
                text: rootWifiPage.pageTitle
                font.family: Vars.fontFamily
                font.pixelSize: 18
                setWeight: 600
                color: Theme.on_surface
                elide: Text.ElideRight
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: wifiContent.implicitHeight
            clip: true
            bottomMargin: 112
            // boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: Vars.flickDeceleration
            maximumFlickVelocity: Vars.maximumFlickVelocity

            ColumnLayout {
                id: wifiContent
                width: parent.width
                spacing: Vars.spacingSmall

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    // Wi-Fi Header Card
                    Item {
                        id: wifiHeader
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80

                        property color targetColor: wifiHeaderMouse.containsMouse ? (Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)) : (Vars.tColor(Theme.surface_container_high, Vars.componentOpacity))
                        scale: wifiHeaderMouse.pressed ? 1.08 : 1.0
                        Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }
                        Behavior on targetColor {
                            ColorAnimation {
                                duration: Vars.animationDuration
                            }
                        }

                        Item {
                            anchors.fill: parent
                            opacity: parent.targetColor.a
                            Rectangle {
                                antialiasing: true
                                anchors.fill: parent
                                color: Qt.rgba(parent.parent.targetColor.r, parent.parent.targetColor.g, parent.parent.targetColor.b, 1.0)

                                topLeftRadius: Vars.radiusLarge
                                topRightRadius: Vars.radiusLarge
                                bottomLeftRadius: Networking.wifiEnabled ? 4 : Vars.radiusLarge
                                bottomRightRadius: Networking.wifiEnabled ? 4 : Vars.radiusLarge
                                
                                Behavior on bottomLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                                Behavior on bottomRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                            }
                        }

                        activeFocusOnTab: true
                        Keys.onSpacePressed: Networking.wifiEnabled = !Networking.wifiEnabled
                        Keys.onReturnPressed: Networking.wifiEnabled = !Networking.wifiEnabled

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Vars.spacingLarge
                            anchors.rightMargin: Vars.spacingLarge
                            QsText {
                                text: rootWifiPage.pageTitle
                                font.family: Vars.fontFamily
                                font.pixelSize: 16
                                setWeight: Vars.fontWeight
                                font.italic: Vars.fontItalic
                                color: Theme.on_surface
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                width: 52
                                height: 32
                                radius: 16
                                antialiasing: true
                                color: Networking.wifiEnabled ? Vars.tColorSelected(Theme.primary) : Vars.tColor(Theme.surface_variant, Vars.componentOpacity)
                                border.color: wifiHeader.activeFocus ? Theme.on_surface : "transparent"
                                border.width: wifiHeader.activeFocus ? 2 : 0
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Vars.animationDuration
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: Vars.customStandard
                                    }
                                }
                                Rectangle {
                                    width: 24
                                    height: 24
                                    radius: 12
                                    antialiasing: true
                                    color: Networking.wifiEnabled ? Theme.on_primary : Theme.on_surface_variant
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: Networking.wifiEnabled ? 24 : 4
                                    Behavior on anchors.leftMargin {
                                        NumberAnimation {
                                            duration: Vars.animationDuration
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: Vars.customStandard
                                        }
                                    }
                                    QsText {
                                        anchors.centerIn: parent
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 16
                                        color: Networking.wifiEnabled ? (Vars.tColorSelected(Theme.primary)) : (Vars.tColor(Theme.surface_variant, Vars.componentOpacity))
                                        text: Networking.wifiEnabled ? "\ue5ca" : "\ue5cd"
                                    }
                                }
                            }
                        }
                        MouseArea {
                            id: wifiHeaderMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                wifiHeader.forceActiveFocus();
                                Networking.wifiEnabled = !Networking.wifiEnabled;
                            }
                        }
                    }

                    // Empty state (only if enabled and no networks)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 120
                        visible: Networking.wifiEnabled && (!rootWifiPage.wifiDevice || rootWifiPage.wifiDevice.networks.values.length === 0)
                        radius: 4
                        antialiasing: true
                        color: Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)

                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 8
                            SettingsIcon {
                                size: 56
                                icon: "\ue63e"
                                Layout.alignment: Qt.AlignHCenter
                            } // Wifi off icon
                            QsText {
                                text: "No networks found"
                                font.family: Vars.fontFamily
                                font.pixelSize: 16
                                color: Theme.on_surface_variant
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }

                    // Wi-Fi List
                    Repeater {
                        model: rootWifiPage.wifiDevice && Networking.wifiEnabled ? rootWifiPage.wifiDevice.networks.values : []
                        delegate: WifiNetworkDelegate {
                            rootPage: rootWifiPage
                        }
                    }

                    // Scan for Networks Card
                    Item {
                        id: scanCard
                        Layout.fillWidth: true
                        Layout.preferredHeight: 80
                        visible: Networking.wifiEnabled

                        property color targetColor: scanMouse.containsMouse ? (Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)) : (Vars.tColor(Theme.surface_container_high, Vars.componentOpacity))
                        scale: scanMouse.pressed ? 1.08 : 1.0
                        Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }
                        Behavior on targetColor {
                            ColorAnimation {
                                duration: Vars.animationDuration
                            }
                        }

                        Item {
                            anchors.fill: parent
                            opacity: parent.targetColor.a
                            Rectangle {
                                antialiasing: true
                                anchors.fill: parent
                                color: Qt.rgba(parent.parent.targetColor.r, parent.parent.targetColor.g, parent.parent.targetColor.b, 1.0)

                                topLeftRadius: 4
                                topRightRadius: 4
                                bottomLeftRadius: Vars.radiusLarge
                                bottomRightRadius: Vars.radiusLarge
                                
                                Behavior on topLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                                Behavior on topRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                            }
                        }

                        activeFocusOnTab: true
                        Keys.onSpacePressed: {
                            if (rootWifiPage.wifiDevice)
                                rootWifiPage.wifiDevice.scannerEnabled = !rootWifiPage.wifiDevice.scannerEnabled;
                        }
                        Keys.onReturnPressed: {
                            if (rootWifiPage.wifiDevice)
                                rootWifiPage.wifiDevice.scannerEnabled = !rootWifiPage.wifiDevice.scannerEnabled;
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Vars.spacingLarge
                            anchors.rightMargin: Vars.spacingLarge
                            spacing: 16

                            Item {
                                width: 40
                                height: 40
                                Layout.alignment: Qt.AlignVCenter

                                Rectangle {
                                    anchors.fill: parent
                                    radius: width / 2
                                    antialiasing: true
                                    color: Theme.secondary
                                }

                                Item {
                                    id: scanLoadingIndicator
                                    anchors.fill: parent
                                    property bool running: rootWifiPage.wifiDevice ? rootWifiPage.wifiDevice.scannerEnabled : false

                                    Primitives.LoadingIndicator {
                                        anchors.fill: parent
                                        running: scanLoadingIndicator.running
                                    }
                                }

                                QsText {
                                    id: wifiScanIcon
                                    anchors.centerIn: parent
                                    text: "\ue863"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 22
                                    color: Theme.on_secondary
                                    opacity: scanLoadingIndicator.running ? 0.0 : 1.0
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 300
                                        }
                                    }
                                }
                            }

                            QsText {
                                text: (rootWifiPage.wifiDevice && rootWifiPage.wifiDevice.scannerEnabled) ? "Scanning..." : "Scan for Networks"
                                font.family: Vars.fontFamily
                                font.pixelSize: 16
                                setWeight: Vars.fontWeight
                                font.italic: Vars.fontItalic
                                color: Theme.on_surface
                                Layout.fillWidth: true
                            }
                        }
                        MouseArea {
                            id: scanMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                scanCard.forceActiveFocus();
                                if (rootWifiPage.wifiDevice)
                                    rootWifiPage.wifiDevice.scannerEnabled = !rootWifiPage.wifiDevice.scannerEnabled;
                            }
                        }
                    }
                }
            }
        }
    }

    // Password Info Page Overlay
    Rectangle {
        id: infoPageOverlay
        anchors.fill: parent
        color: Vars.tColor(Theme.surface_container_low, 0.85)
        visible: rootWifiPage.selectedNetworkForInfo !== ""
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: 250
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customExpressiveSpatialSlow
            }
        }
        z: 100

        // Intercept mouse events so they don't fall through to the list beneath
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Vars.spacingMedium

            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Rectangle {
                    width: 40
                    height: 40
                    radius: 20
                    antialiasing: true
                    color: backInfoHover.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (backInfoHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                    QsText {
                        anchors.centerIn: parent
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 20
                        color: Theme.on_surface
                        text: "\ue5c4"
                    }
                    MouseArea {
                        id: backInfoHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: { rootWifiPage.selectedNetworkForInfo = ""; rootWifiPage.selectedNetworkPassword = ""; }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: Vars.animationDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Vars.customStandard
                        }
                    }
                }

                QsText {
                    text: "Network Password"
                    font.family: Vars.fontFamily
                    font.pixelSize: 20
                    setWeight: 600
                    color: Theme.on_surface
                }
                Item {
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                radius: 16
                antialiasing: true
                color: Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)

                ColumnLayout {
                    anchors.centerIn: parent
                    QsText {
                        text: rootWifiPage.selectedNetworkForInfo
                        font.family: Vars.fontFamily
                        font.pixelSize: 18
                        setWeight: 500
                        color: Theme.on_surface
                        Layout.alignment: Qt.AlignHCenter
                    }
                    QsText {
                        text: "Saved Password"
                        font.family: Vars.fontFamily
                        font.pixelSize: 12
                        color: Theme.on_surface_variant
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 64
                radius: 16
                antialiasing: true
                color: Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16

                    QsText {
                        text: rootWifiPage.selectedNetworkPassword !== "" ? rootWifiPage.selectedNetworkPassword : "No password found"
                        font.family: Vars.fontFamily
                        font.pixelSize: 16
                        color: Theme.on_surface
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        width: 32
                        height: 32
                        radius: 16
                        antialiasing: true
                        color: copyHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent"
                        QsText {
                            anchors.centerIn: parent
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 20
                            color: Theme.on_surface_variant
                            text: "content_copy"
                        }
                        MouseArea {
                            id: copyHover
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onClicked: {
                                Quickshell.execDetached({
                                    command: ["wl-copy", rootWifiPage.selectedNetworkPassword]
                                });
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }

    // Password Auth Page Overlay
    Rectangle {
        id: authPageOverlay
        anchors.fill: parent
        color: Vars.tColor(Theme.surface_container_low, 0.85)
        visible: rootWifiPage.authOverlayVisible
        opacity: visible ? 1.0 : 0.0
        Behavior on opacity {
            NumberAnimation {
                duration: 250
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customExpressiveSpatialSlow
            }
        }
        z: 101 // Above info page overlay

        // Intercept mouse events so they don't fall through
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Vars.spacingMedium

            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                Rectangle {
                    width: 40
                    height: 40
                    radius: 20
                    antialiasing: true
                    color: backAuthHover.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (backAuthHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                    QsText {
                        anchors.centerIn: parent
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 20
                        color: Theme.on_surface
                        text: "\ue5c4"
                    }
                    MouseArea {
                        id: backAuthHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rootWifiPage.authOverlayVisible = false
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: Vars.animationDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Vars.customStandard
                        }
                    }
                }

                QsText {
                    text: "Authentication Required"
                    font.family: Vars.fontFamily
                    font.pixelSize: 20
                    setWeight: 600
                    color: Theme.on_surface
                }
                Item {
                    Layout.fillWidth: true
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 180
                radius: 16
                antialiasing: true
                color: Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 16

                    Rectangle {
                        Layout.preferredWidth: 320
                        Layout.preferredHeight: 56
                        Layout.alignment: Qt.AlignHCenter
                        radius: 8
                        antialiasing: true
                        color: "transparent"
                        border.color: rootWifiPage.authError ? Theme.error : (authPwdInput.activeFocus ? Theme.primary : Theme.outline)
                        border.width: authPwdInput.activeFocus ? 3 : 2
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        Rectangle {
                            color: Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 1.0)
                            height: ssidLabelText.height
                            width: ssidLabelText.width + 8
                            anchors.verticalCenter: parent.top
                            anchors.left: parent.left
                            anchors.leftMargin: 12

                            QsText {
                                id: ssidLabelText
                                anchors.centerIn: parent
                                text: rootWifiPage.pendingSsid
                                font.family: Vars.fontFamily
                                font.pixelSize: 12
                                setWeight: 800
                                color: rootWifiPage.authError ? Theme.error : (authPwdInput.activeFocus ? Theme.primary : Theme.on_surface_variant)
                                Behavior on color { ColorAnimation { duration: 150 } }
                            }
                        }

                        TextField {
                            id: authPwdInput
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            font.family: Vars.fontFamily
                            font.pixelSize: 16
                            color: rootWifiPage.authError ? Theme.error : Theme.on_surface
                            echoMode: TextInput.Password
                            clip: true
                            background: Item {}
                            padding: 0
                            leftPadding: 16
                            rightPadding: 16
                            MouseArea { anchors.fill: parent; cursorShape: Qt.IBeamCursor; onPressed: (mouse) => { parent.forceActiveFocus(); mouse.accepted = false; } }

                            Keys.onReturnPressed: {
                                authProcess.pwd = authPwdInput.text;
                                authProcess.running = true;
                            }
                        }
                    }

                    QsText {
                        text: "Enter system password to view Wi-Fi credentials."
                        font.family: Vars.fontFamily
                        font.pixelSize: 14
                        color: Theme.on_surface_variant
                        Layout.alignment: Qt.AlignHCenter
                    }

                    QsText {
                        text: "Incorrect password"
                        font.family: Vars.fontFamily
                        font.pixelSize: 12
                        color: Theme.error
                        visible: rootWifiPage.authError
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
