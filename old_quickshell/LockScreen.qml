pragma Singleton
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import Quickshell.Widgets
import "theme/variables.js" as Vars
import "."
import "desktop/Widgets" as Widgets
import "core/primitives" as Primitives

Item {
    id: root

    property string activeUser: "boing"
    property string statusMessage: ""
    property bool authError: false

    IdleMonitor {
        id: idleMonitor
        timeout: 300000 
        onIsIdleChanged: {
            if (isIdle) sessionLock.locked = true;
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

    property string _bufferedPassword: ""

    PamContext {
        id: pamContext
        config: "system-auth" 
        user: root.activeUser

        onPamMessage: {
            if (pamContext.messageIsError) {
                root.statusMessage = pamContext.message || "Authentication failed";
                root.authError = true;
                root.shakeActive();
                errorResetTimer.start();
            } else if (pamContext.responseRequired && root._bufferedPassword !== "") {
                pamContext.respond(root._bufferedPassword);
                root._bufferedPassword = "";
            }
        }
        
        onCompleted: (result) => {
            if (result === PamResult.Success) {
                root._bufferedPassword = "";
                root.authError = false;
                root.statusMessage = "Welcome back!";
                root.successActive();
            } else {
                root.statusMessage = "Authentication failed";
                root.authError = true;
                root.shakeActive();
                errorResetTimer.start();
                
                pamContext.abort();
            }
        }

        onError: (error) => {
            root.statusMessage = "PAM error: " + error;
            root.authError = true;
        }
    }

    signal shakeActive()
    signal successActive()

    function lockScreen() {
        sessionLock.locked = true;
    }

    WlSessionLock {
        id: sessionLock
        locked: false 

        onLockedChanged: {
            if (locked && !pamContext.active) {
                pamContext.start();
            }
        }

        surface: Component {
            WlSessionLockSurface {
                color: {
                    var c = Vars.wallpaperMaskColor;
                    if (c === "background") return Theme.background;
                    if (c === "primary") return Theme.primary;
                    if (c === "secondary") return Theme.secondary;
                    if (c === "tertiary") return Theme.tertiary;
                    if (c === "surface_variant") return Theme.surface_variant;
                    if (c === "error") return Theme.error;
                    return Theme.surface_container_lowest;
                }

                Component.onCompleted: {
                    card.passwordInput.forceActiveFocus();
                }

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
                    property real entranceOpacity: 0
                    property real entranceScale: 0.95
                    property real shakeOffset: 0
                    
                    opacity: entranceOpacity
                    scale: entranceScale
                    
                    Component.onCompleted: entranceAnim.start()
                    
                    ParallelAnimation {
                        id: entranceAnim
                        NumberAnimation { target: card; property: "entranceOpacity"; to: 1; duration: Vars.animationDuration * 1.5; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customEmphasizedDecelerate }
                        NumberAnimation { target: card; property: "entranceScale"; to: 1; duration: Vars.animationDuration * 1.5; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customEmphasizedDecelerate }
                    }

                    ParallelAnimation {
                        id: exitAnim
                        NumberAnimation { target: card; property: "entranceOpacity"; to: 0; duration: Vars.animationDuration * 1.5; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customEmphasizedAccelerate }
                        NumberAnimation { target: card; property: "entranceScale"; to: 0.95; duration: Vars.animationDuration * 1.5; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customEmphasizedAccelerate }
                        onFinished: sessionLock.locked = false;
                    }

                    Connections {
                        target: root
                        function onShakeActive() {
                            shakeAnim.start();
                            passwordInput.text = "";
                        }
                        function onSuccessActive() {
                            exitAnim.start();
                        }
                    }
                    
                    SequentialAnimation {
                        id: shakeAnim
                        NumberAnimation { target: card; property: "shakeOffset"; to: -24; duration: 50; easing.type: Easing.OutSine }
                        NumberAnimation { target: card; property: "shakeOffset"; to: 24; duration: 100; easing.type: Easing.InOutSine }
                        NumberAnimation { target: card; property: "shakeOffset"; to: -20; duration: 100; easing.type: Easing.InOutSine }
                        NumberAnimation { target: card; property: "shakeOffset"; to: 20; duration: 100; easing.type: Easing.InOutSine }
                        NumberAnimation { target: card; property: "shakeOffset"; to: -12; duration: 100; easing.type: Easing.InOutSine }
                        NumberAnimation { target: card; property: "shakeOffset"; to: 12; duration: 100; easing.type: Easing.InOutSine }
                        NumberAnimation { target: card; property: "shakeOffset"; to: 0; duration: 50; easing.type: Easing.OutSine }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 48
                        
                        Item { Layout.fillHeight: true }

                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 300
                            Layout.preferredHeight: 300

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
                            transform: Translate { x: card.shakeOffset }
                            scale: passwordInput.activeFocus ? 1.04 : 1.0

                            Behavior on color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }
                            Behavior on border.color { ColorAnimation { duration: 250 } }
                            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.5 } }

                            TextInput {
                                id: passwordInput
                                anchors.fill: parent
                                opacity: 0
                                focus: true
                                echoMode: TextInput.Normal
                                onTextChanged: {
                                    if (text.length > 0 && root.authError) {
                                        root.authError = false;
                                        if (root.statusMessage === "Authentication failed" || root.statusMessage.startsWith("PAM error")) {
                                            root.statusMessage = "";
                                        }
                                    }
                                    let len = text.length;
                                    while (shapeModel.count < len) {
                                        shapeModel.append({});
                                    }
                                    while (shapeModel.count > len) {
                                        shapeModel.remove(shapeModel.count - 1);
                                    }
                                }
                                onAccepted: {
                                    if (text.length > 0) {
                                        root.authError = false;
                                        root.statusMessage = "Authenticating...";
                                        if (pamContext.active && pamContext.responseRequired) {
                                            pamContext.respond(text);
                                        } else {
                                            root._bufferedPassword = text;
                                            if (!pamContext.active) {
                                                pamContext.start();
                                            }
                                        }
                                        text = "";
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
                            
                            ListModel {
                                id: shapeModel
                            }
                            
                            ListView {
                                id: shapeList
                                anchors.fill: parent
                                anchors.margins: 20
                                orientation: ListView.Horizontal
                                spacing: 12
                                interactive: false
                                
                                onCountChanged: positionViewAtEnd()
                                
                                model: shapeModel
                                
                                add: Transition {
                                    ParallelAnimation {
                                        NumberAnimation { property: "scale"; from: 0; to: 1; duration: 400; easing.type: Easing.OutBack; easing.overshoot: 2.5 }
                                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 300 }
                                        NumberAnimation { property: "rotation"; from: -90; to: 0; duration: 400; easing.type: Easing.OutBack }
                                    }
                                }
                                remove: Transition {
                                    ParallelAnimation {
                                        NumberAnimation { property: "scale"; to: 0; duration: 200; easing.type: Easing.InBack }
                                        NumberAnimation { property: "opacity"; to: 0; duration: 200 }
                                    }
                                }
                                displaced: Transition {
                                    NumberAnimation { properties: "x,y"; duration: 300; easing.type: Easing.OutBack }
                                }
                                
                                delegate: Item {
                                    width: 24
                                    height: 24
                                    anchors.verticalCenter: parent.verticalCenter
                                    
                                    property var keys: Object.keys(m3.m3AbstractPaths)
                                    property string shapeName: keys[index % keys.length]
                                    property color c: root.authError ? Theme.error : Theme.primary
                                    
                                    Image {
                                        id: shapeImage
                                        anchors.fill: parent
                                        sourceSize: Qt.size(48, 48)
                                        source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='" + m3.getPath(parent.shapeName) + "' fill='" + parent.c + "'/></svg>"
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
