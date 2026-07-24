import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Io
import "../.."
import "../../theme/variables.js" as Vars

ColumnLayout {
    id: rootPage
    
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Vars.spacingMedium

    // State Variables
    property string targetCurve: "customStandard"
    property string referenceCurve: "None"
    property var testAnimObj: null
    property var localEdits: ({}) // Stores unapplied edits mapping curveName -> [x1, y1, x2, y2]
    property real p1x: 0.2
    property real p1y: 0.0
    property real p2x: 0.0
    property real p2y: 1.0
    
    signal settingsChanged()
    
    // Auto-update values when target curve changes
    onTargetCurveChanged: {
        var arrStr = localEdits[targetCurve] ? localEdits[targetCurve] : Vars[targetCurve];
        if (arrStr && Array.isArray(arrStr)) {
            p1x = arrStr[0]; p1y = arrStr[1]; p2x = arrStr[2]; p2y = arrStr[3];
        }
    }
    
    onP1xChanged: localEdits[targetCurve] = [p1x, p1y, p2x, p2y]
    onP1yChanged: localEdits[targetCurve] = [p1x, p1y, p2x, p2y]
    onP2xChanged: localEdits[targetCurve] = [p1x, p1y, p2x, p2y]
    onP2yChanged: localEdits[targetCurve] = [p1x, p1y, p2x, p2y]
    
    Component.onCompleted: targetCurveChanged()

    function getFormattedArrayStr(arr) {
        return "[" + arr[0].toFixed(2) + ", " + arr[1].toFixed(2) + ", " + arr[2].toFixed(2) + ", " + arr[3].toFixed(2) + "]";
    }
    
    function getFormattedStr(arr) {
        return arr[0].toFixed(2) + ", " + arr[1].toFixed(2) + ", " + arr[2].toFixed(2) + ", " + arr[3].toFixed(2);
    }

    function applyCurve() {
        var arr = localEdits[targetCurve] || [p1x, p1y, p2x, p2y];
        var qsVal = getFormattedArrayStr(arr);
        var qsProc = Qt.createQmlObject('import Quickshell.Io; Process { command: ["omniformis", "qs", "set", "' + targetCurve + '", "' + qsVal + '"]; onExited: destroy() }', rootPage);
        qsProc.running = true;
        
        var hyprTarget = targetCurve.charAt(0).toUpperCase() + targetCurve.slice(1);
        var hyprVal = getFormattedStr(arr);
        var hyprProc = Qt.createQmlObject('import Quickshell.Io; Process { command: ["omniformis", "hypr", "--' + hyprTarget + '", "' + hyprVal + '"]; onExited: destroy() }', rootPage);
        hyprProc.running = true;
    }
    
    function applyToAll() {
        var curves = ["customStandard", "customStandardDecelerate", "customStandardAccelerate", "customEmphasizedDecelerate", "customEmphasizedAccelerate", "customExpressiveSpatialFast", "customExpressiveSpatialSlow"];
        for (var i = 0; i < curves.length; i++) {
            var c = curves[i];
            if (localEdits[c]) {
                var qsVal = getFormattedArrayStr(localEdits[c]);
                var hyprVal = getFormattedStr(localEdits[c]);
                var hc = c.charAt(0).toUpperCase() + c.slice(1);
                var p1 = Qt.createQmlObject('import Quickshell.Io; Process { command: ["omniformis", "qs", "set", "' + c + '", "' + qsVal + '"]; onExited: destroy() }', rootPage);
                var p2 = Qt.createQmlObject('import Quickshell.Io; Process { command: ["omniformis", "hypr", "--' + hc + '", "' + hyprVal + '"]; onExited: destroy() }', rootPage);
                p1.running = true; p2.running = true;
            }
        }
        var p3 = Qt.createQmlObject('import Quickshell.Io; Process { command: ["omniformis", "hypr", "--AnimateStyle", "Custom"]; onExited: destroy() }', rootPage);
        p3.running = true;
        
        rootPage.settingsChanged();
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        Text {
            text: "Motion Editor"
            font.family: Vars.fontFamily
            font.pixelSize: 16
            font.weight: 500
            color: Theme.on_surface
        }
        Text {
            text: "Design custom bezier curves for system animations"
            font.family: Vars.fontFamily
            font.pixelSize: 12
            color: Theme.on_surface_variant
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Vars.spacingLarge

        // Editor Canvas Container
        Rectangle {
            Layout.preferredWidth: 350
            Layout.preferredHeight: 350
            Layout.alignment: Qt.AlignVCenter
            color: Theme.surface_container_highest
            radius: Vars.radiusMedium
            border.color: Theme.outline_variant
            border.width: 1
            clip: true

            Item {
                id: graph
                width: 250
                height: 250
                anchors.centerIn: parent

                // Grid Lines
                Repeater {
                    model: 11
                    Rectangle {
                        y: index * (graph.height / 10)
                        width: graph.width
                        height: 1
                        color: index === 0 || index === 10 ? Theme.outline : Theme.surface_variant
                    }
                }
                Repeater {
                    model: 11
                    Rectangle {
                        x: index * (graph.width / 10)
                        width: 1
                        height: graph.height
                        color: index === 0 || index === 10 ? Theme.outline : Theme.surface_variant
                    }
                }

                // Bezier Curve
                Canvas {
                    id: curveCanvas
                    anchors.fill: parent
                    
                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        
                        // Reference Curve
                        if (rootPage.referenceCurve !== "None" && Vars[rootPage.referenceCurve]) {
                            var refArr = Vars[rootPage.referenceCurve];
                            ctx.strokeStyle = Theme.outline_variant;
                            ctx.lineWidth = 2;
                            ctx.setLineDash([4, 4]);
                            ctx.beginPath();
                            ctx.moveTo(0, height);
                            ctx.bezierCurveTo(
                                refArr[0] * width, height - refArr[1] * height,
                                refArr[2] * width, height - refArr[3] * height,
                                width, 0
                            );
                            ctx.stroke();
                        }
                        
                        // Handle lines
                        ctx.strokeStyle = Theme.outline;
                        ctx.lineWidth = 1;
                        ctx.setLineDash([5, 5]);
                        
                        ctx.beginPath();
                        ctx.moveTo(0, height);
                        ctx.lineTo(rootPage.p1x * width, height - rootPage.p1y * height);
                        ctx.stroke();
                        
                        ctx.beginPath();
                        ctx.moveTo(width, 0);
                        ctx.lineTo(rootPage.p2x * width, height - rootPage.p2y * height);
                        ctx.stroke();
                        
                        // Curve
                        ctx.strokeStyle = Theme.primary;
                        ctx.lineWidth = 3;
                        ctx.setLineDash([]);
                        
                        ctx.beginPath();
                        ctx.moveTo(0, height);
                        ctx.bezierCurveTo(
                            rootPage.p1x * width, height - rootPage.p1y * height,
                            rootPage.p2x * width, height - rootPage.p2y * height,
                            width, 0
                        );
                        ctx.stroke();
                    }
                }

                // Triggers repaint when variables change
                Connections {
                    target: rootPage
                    function onP1xChanged() { curveCanvas.requestPaint(); }
                    function onP1yChanged() { curveCanvas.requestPaint(); }
                    function onP2xChanged() { curveCanvas.requestPaint(); }
                    function onP2yChanged() { curveCanvas.requestPaint(); }
                }

                // P1 Handle
                Rectangle {
                    width: 16; height: 16; radius: 8
                    color: p1Mouse.pressed ? Theme.secondary : Theme.primary
                    x: rootPage.p1x * graph.width - width/2
                    y: graph.height - rootPage.p1y * graph.height - height/2
                    
                    MouseArea {
                        id: p1Mouse
                        anchors.fill: parent
                        drag.target: parent
                        drag.axis: Drag.XAndYAxis
                        drag.minimumX: -width/2
                        drag.maximumX: graph.width - width/2
                        drag.minimumY: -graph.height - height/2 // Allow dragging above 1.0 for bounce
                        drag.maximumY: graph.height * 2 // Allow dragging below 0.0
                        
                        onPositionChanged: {
                            if (drag.active) {
                                rootPage.p1x = Math.max(0, Math.min(1, (parent.x + parent.width/2) / graph.width));
                                rootPage.p1y = (graph.height - (parent.y + parent.height/2)) / graph.height;
                            }
                        }
                    }
                }
                
                // P2 Handle
                Rectangle {
                    width: 16; height: 16; radius: 8
                    color: p2Mouse.pressed ? Theme.tertiary : Theme.primary
                    x: rootPage.p2x * graph.width - width/2
                    y: graph.height - rootPage.p2y * graph.height - height/2
                    
                    MouseArea {
                        id: p2Mouse
                        anchors.fill: parent
                        drag.target: parent
                        drag.axis: Drag.XAndYAxis
                        drag.minimumX: -width/2
                        drag.maximumX: graph.width - width/2
                        drag.minimumY: -graph.height - height/2
                        drag.maximumY: graph.height * 2
                        
                        onPositionChanged: {
                            if (drag.active) {
                                rootPage.p2x = Math.max(0, Math.min(1, (parent.x + parent.width/2) / graph.width));
                                rootPage.p2y = (graph.height - (parent.y + parent.height/2)) / graph.height;
                            }
                        }
                    }
                }
            }
        }

        // Sidebar Settings for Editor
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
            spacing: Vars.spacingMedium

            Text {
                text: "Target Curve"
                font.family: Vars.fontFamily
                font.bold: true
                color: Theme.on_surface
            }

            ComboBox {
                Layout.fillWidth: true
                height: 40
                model: ["customStandard", "customStandardDecelerate", "customStandardAccelerate", "customEmphasizedDecelerate", "customEmphasizedAccelerate", "customExpressiveSpatialFast", "customExpressiveSpatialSlow"]
                onActivated: function(index) { rootPage.targetCurve = model[index]; }
                
                background: Rectangle { color: Theme.surface_container_highest; radius: Vars.radiusSmall }
                contentItem: Text { text: parent.displayText; font.family: Vars.fontFamily; color: Theme.on_surface; font.pixelSize: 14; verticalAlignment: Text.AlignVCenter; leftPadding: 10 }
            }

            Text {
                text: "Reference Curve"
                font.family: Vars.fontFamily
                font.bold: true
                color: Theme.on_surface
                topPadding: 4
            }

            ComboBox {
                Layout.fillWidth: true
                height: 40
                model: ["None", "m3Standard", "m3StandardDecelerate", "m3StandardAccelerate", "m3EmphasizedDecelerate", "m3EmphasizedAccelerate", "m3ExpressiveSpatialFast", "m3ExpressiveSpatialSlow"]
                onActivated: function(index) { rootPage.referenceCurve = model[index]; curveCanvas.requestPaint(); }
                
                background: Rectangle { color: Theme.surface_container_highest; radius: Vars.radiusSmall }
                contentItem: Text { text: parent.displayText; font.family: Vars.fontFamily; color: Theme.on_surface; font.pixelSize: 14; verticalAlignment: Text.AlignVCenter; leftPadding: 10 }
            }

            Text {
                text: "Parameters"
                font.family: Vars.fontFamily
                font.bold: true
                color: Theme.on_surface
                topPadding: 12
            }

            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: Theme.surface_container_high
                radius: Vars.radiusSmall
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    Text { text: "X1:"; color: Theme.on_surface; font.family: Vars.fontFamily; font.bold: true }
                    TextInput { 
                        id: p1xInput
                        text: rootPage.p1x.toFixed(2)
                        color: Theme.on_surface_variant
                        Layout.fillWidth: true
                        font.family: Vars.fontFamily
                        validator: DoubleValidator { bottom: 0.0; top: 1.0; decimals: 2 }
                        onEditingFinished: rootPage.p1x = parseFloat(text)
                        Connections { target: rootPage; function onP1xChanged() { if (!p1xInput.activeFocus) p1xInput.text = rootPage.p1x.toFixed(2); } }
                    }
                    Text { text: "Y1:"; color: Theme.on_surface; font.family: Vars.fontFamily; font.bold: true }
                    TextInput { 
                        id: p1yInput
                        text: rootPage.p1y.toFixed(2)
                        color: Theme.on_surface_variant
                        Layout.fillWidth: true
                        font.family: Vars.fontFamily
                        validator: DoubleValidator { decimals: 2 }
                        onEditingFinished: rootPage.p1y = parseFloat(text)
                        Connections { target: rootPage; function onP1yChanged() { if (!p1yInput.activeFocus) p1yInput.text = rootPage.p1y.toFixed(2); } }
                    }
                }
            }
            
            Rectangle {
                Layout.fillWidth: true
                height: 40
                color: Theme.surface_container_high
                radius: Vars.radiusSmall
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    Text { text: "X2:"; color: Theme.on_surface; font.family: Vars.fontFamily; font.bold: true }
                    TextInput { 
                        id: p2xInput
                        text: rootPage.p2x.toFixed(2)
                        color: Theme.on_surface_variant
                        Layout.fillWidth: true
                        font.family: Vars.fontFamily
                        validator: DoubleValidator { bottom: 0.0; top: 1.0; decimals: 2 }
                        onEditingFinished: rootPage.p2x = parseFloat(text)
                        Connections { target: rootPage; function onP2xChanged() { if (!p2xInput.activeFocus) p2xInput.text = rootPage.p2x.toFixed(2); } }
                    }
                    Text { text: "Y2:"; color: Theme.on_surface; font.family: Vars.fontFamily; font.bold: true }
                    TextInput { 
                        id: p2yInput
                        text: rootPage.p2y.toFixed(2)
                        color: Theme.on_surface_variant
                        Layout.fillWidth: true
                        font.family: Vars.fontFamily
                        validator: DoubleValidator { decimals: 2 }
                        onEditingFinished: rootPage.p2y = parseFloat(text)
                        Connections { target: rootPage; function onP2yChanged() { if (!p2yInput.activeFocus) p2yInput.text = rootPage.p2y.toFixed(2); } }
                    }
                }
            }

            Item { Layout.preferredHeight: 4 }

            // Live Preview
            Rectangle {
                Layout.fillWidth: true
                height: 80
                color: Theme.surface_container_high
                radius: Vars.radiusMedium
                clip: true

                Rectangle {
                    id: animBoxRef
                    width: 30; height: 30; radius: 6
                    color: Theme.outline_variant
                    anchors.bottom: animBox.top
                    anchors.bottomMargin: 4
                    x: 20
                    visible: rootPage.referenceCurve !== "None"
                }

                Rectangle {
                    id: animBox
                    width: 30; height: 30; radius: 6
                    color: Theme.primary
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 15
                    x: 20
                }

                Button {
                    anchors.bottom: parent.bottom; anchors.right: parent.right; anchors.margins: 8
                    width: 80; height: 32
                    background: Rectangle { color: Theme.surface_variant; radius: Vars.radiusSmall }
                    contentItem: Text { text: "Test"; font.family: Vars.fontFamily; font.bold: true; color: Theme.on_surface; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    onClicked: {
                        if (rootPage.testAnimObj) {
                            rootPage.testAnimObj.stop();
                            rootPage.testAnimObj.destroy();
                        }
                        
                        animBox.x = 20;
                        animBoxRef.x = 20;
                        
                        var c = [rootPage.p1x, rootPage.p1y, rootPage.p2x, rootPage.p2y];
                        var newCurveStr = "[" + c[0] + ", " + c[1] + ", " + c[2] + ", " + c[3] + "]";
                        var r = (rootPage.referenceCurve !== "None" && Vars[rootPage.referenceCurve]) ? Vars[rootPage.referenceCurve] : [0,0,1,1];
                        var refCurveStr = "[" + r[0] + ", " + r[1] + ", " + r[2] + ", " + r[3] + "]";
                        
                        var animQml = `
                            import QtQuick
                            SequentialAnimation {
                                ParallelAnimation {
                                    NumberAnimation { target: animBox; property: "x"; to: animBox.parent.width - animBox.width - 20; duration: 600; easing.type: Easing.BezierSpline; easing.bezierCurve: ${newCurveStr} }
                                    NumberAnimation { target: animBoxRef; property: "x"; to: animBoxRef.parent.width - animBoxRef.width - 20; duration: 600; easing.type: Easing.BezierSpline; easing.bezierCurve: ${refCurveStr} }
                                }
                                PauseAnimation { duration: 200 }
                                ParallelAnimation {
                                    NumberAnimation { target: animBox; property: "x"; to: 20; duration: 600; easing.type: Easing.BezierSpline; easing.bezierCurve: ${newCurveStr} }
                                    NumberAnimation { target: animBoxRef; property: "x"; to: 20; duration: 600; easing.type: Easing.BezierSpline; easing.bezierCurve: ${refCurveStr} }
                                }
                            }
                        `;
                        
                        rootPage.testAnimObj = Qt.createQmlObject(animQml, rootPage);
                        rootPage.testAnimObj.start();
                    }
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: Vars.spacingSmall
                Button {
                    Layout.fillWidth: true; height: 40
                    background: Rectangle { color: Theme.surface_container_highest; radius: Vars.radiusSmall }
                    contentItem: Text { text: "Apply Target"; font.family: Vars.fontFamily; font.bold: true; color: Theme.on_surface; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    onClicked: applyCurve()
                }
                Button {
                    Layout.fillWidth: true; height: 40
                    background: Rectangle { color: Theme.primary; radius: Vars.radiusSmall }
                    contentItem: Text { text: "Apply to All"; font.family: Vars.fontFamily; font.bold: true; color: Theme.on_primary; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    onClicked: applyToAll()
                }
            }
            
            Rectangle {
                Layout.fillWidth: true; height: 40
                color: Theme.surface_container_highest
                radius: Vars.radiusSmall
                border.color: savePresetBtn.activeFocus ? Theme.primary : "transparent"
                border.width: 1
                RowLayout {
                    anchors.fill: parent; anchors.margins: 4; spacing: 4
                    TextInput {
                        id: presetNameInput
                        Layout.fillWidth: true; Layout.fillHeight: true
                        verticalAlignment: Text.AlignVCenter; leftPadding: 8
                        color: Theme.on_surface; font.family: Vars.fontFamily; text: "MyPreset"
                    }
                    Button {
                        id: savePresetBtn
                        Layout.preferredWidth: 60; Layout.fillHeight: true
                        background: Rectangle { color: Theme.surface_variant; radius: Vars.radiusSmall }
                        contentItem: Text { text: "Save"; font.family: Vars.fontFamily; color: Theme.on_surface; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        onClicked: {
                            // Ensure the current curve is in localEdits
                            localEdits[targetCurve] = [p1x, p1y, p2x, p2y];
                            
                            // Construct the payload mapping
                            var payloadObj = {};
                            var curves = ["customStandard", "customStandardDecelerate", "customStandardAccelerate", "customEmphasizedDecelerate", "customEmphasizedAccelerate", "customExpressiveSpatialFast", "customExpressiveSpatialSlow"];
                            for (var i = 0; i < curves.length; i++) {
                                var c = curves[i];
                                if (localEdits[c]) {
                                    payloadObj[c] = getFormattedArrayStr(localEdits[c]);
                                } else {
                                    payloadObj[c] = getFormattedArrayStr(Vars[c]);
                                }
                            }
                            var payloadStr = JSON.stringify(payloadObj);
                            
                            var p = Qt.createQmlObject('import Quickshell.Io; Process { command: ["omniformis", "bezier", "save", "' + presetNameInput.text + '", "--payload", \'' + payloadStr + '\']; onExited: destroy() }', rootPage);
                            p.running = true;
                        }
                    }
                }
            }
        }
    }
}
