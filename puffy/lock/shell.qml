import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Widgets
import "../theme"
import "../"
import "../desktop/Widgets" as Widgets
import "../core/primitives" as Primitives

ShellRoot {
    id: root

    property string activeUser: "boing"
    property string statusMessage: ""
    property bool authError: false

    IdleMonitor {
        timeout: 300000 
        onIdle: {
            sessionLock.locked = true;
        }
    }

    Timer {
        id: errorResetTimer
        interval: 2000
        onTriggered: {
            root.authError = false;
            root.statusMessage = "";
        }
    }

    PamContext {
        id: pamContext
        service: "system-auth" 
        
        onAuthenticated: {
            sessionLock.locked = false;
            Qt.quit();
        }
        onError: (error) => {
            root.statusMessage = error || "Authentication failed";
            root.authError = true;
            root.shakeActive();
            errorResetTimer.start();
        }
    }

    signal shakeActive()

    WlSessionLock {
        id: sessionLock
        locked: true 

        onLockedChanged: {
            if (locked && !pamContext.active) {
                pamContext.start();
            } else if (!locked && pamContext.active) {
                pamContext.abort();
            }
        }

        Instantiator {
            model: Quickshell.screens
            delegate: WlSessionLockSurface {
                screen: modelData
                color: Theme.surface_container_lowest 

                MouseArea {
                    anchors.fill: parent
                    onClicked: card.passwordInput.forceActiveFocus()
                }

                Item {
                    id: card
                    anchors.centerIn: parent
                    width: 400
                    height: 600
                    
                    property alias passwordInput: passwordInput
                    property real entranceOffset: -100
                    property real entranceOpacity: 0
                    
                    Component.onCompleted: entranceAnim.start()
                    
                    ParallelAnimation {
                        id: entranceAnim
                        NumberAnimation { target: card; property: "entranceOffset"; to: 0; duration: 1000; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                        NumberAnimation { target: card; property: "entranceOpacity"; to: 1; duration: 800; easing.type: Easing.InOutQuad }
                    }

                    Connections {
                        target: root
                        function onShakeActive() {
                            shakeAnim.start();
                            passwordInput.text = "";
                        }
                    }
                    
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
                        spacing: 48
                        
                        Item { Layout.fillHeight: true }

                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 300
                            Layout.preferredHeight: 300
                            transform: Translate { y: card.entranceOffset }
                            opacity: card.entranceOpacity

                            Widgets.AnalogClock {
                                anchors.centerIn: parent
                                width: 300
                                height: 300
                            }
                        }

                        Rectangle {
                            id: passwordBox
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 320
                            Layout.preferredHeight: 64
                            radius: 32
                            antialiasing: true
                            color: root.authError ? Theme.error_container : Theme.surface_container_highest
                            border.color: passwordInput.activeFocus ? Theme.primary : "transparent"
                            border.width: 2
                            clip: true
                            transform: Translate { y: card.entranceOffset * 0.5 }
                            opacity: card.entranceOpacity

                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                            Behavior on border.color { ColorAnimation { duration: Vars.animationDuration } }

                            TextInput {
                                id: passwordInput
                                anchors.fill: parent
                                opacity: 0
                                focus: true
                                echoMode: TextInput.Normal
                                onAccepted: {
                                    if (text.length > 0) {
                                        if (typeof pamContext.authenticate === "function") {
                                            pamContext.authenticate(root.activeUser, text);
                                        } else if (typeof pamContext.respond === "function") {
                                            pamContext.respond(text);
                                        }
                                    }
                                }
                            }

                            Primitives.M3Shapes { id: m3 }
                            
                            QsText {
                                text: "Enter password"
                                color: Theme.on_surface_variant
                                font.family: Vars.fontFamily
                                font.pixelSize: 16
                                anchors.centerIn: parent
                                visible: passwordInput.text.length === 0 && !passwordInput.activeFocus
                            }
                            
                            ListView {
                                id: shapeList
                                anchors.fill: parent
                                anchors.margins: 20
                                orientation: ListView.Horizontal
                                spacing: 12
                                interactive: false
                                
                                onCountChanged: positionViewAtEnd()
                                
                                model: passwordInput.text.length
                                delegate: Item {
                                    width: 24
                                    height: 24
                                    anchors.verticalCenter: parent.verticalCenter
                                    
                                    property var keys: Object.keys(m3.m3AbstractPaths)
                                    property string shapeName: keys[index % keys.length]
                                    property color c: root.authError ? Theme.error : Theme.primary
                                    
                                    Image {
                                        anchors.fill: parent
                                        sourceSize: Qt.size(48, 48)
                                        source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='" + m3.getPath(parent.shapeName) + "' fill='" + parent.c + "'/></svg>"
                                        
                                        scale: 0.01
                                        Component.onCompleted: popAnim.start()
                                        NumberAnimation on scale {
                                            id: popAnim
                                            to: 1.0
                                            duration: 350
                                            easing.type: Easing.OutBack
                                        }
                                    }
                                }
                            }
                        }

                        QsText {
                            Layout.alignment: Qt.AlignHCenter
                            text: root.statusMessage
                            font.family: Vars.fontFamily
                            font.pixelSize: 14
                            color: root.authError ? Theme.error : Theme.on_surface_variant
                            visible: root.statusMessage !== ""
                            opacity: visible ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: Vars.animationDuration } }
                            transform: Translate { y: card.entranceOffset * 0.25 }
                        }
                        
                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }
}
