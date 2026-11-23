import QtQuick
import ".."
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "../theme"


PanelWindow {
    id: root
    
    HyprlandFocusGrab { active: root.visible; windows: [root] }
    
    required property bool visibleState
    property bool isLensMode: false
    visible: visibleState
    signal screenshotClosed
    signal openRequested
    property bool internalVisible: false
    property var m3Expressive: [0.05, 0.7, 0.1, 1.0]
    
    property int layoutX: 0
    property int layoutY: 0

    Process {
        id: monitorPosProcess
        command: ["sh", "-c", "hyprctl monitors -j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let monitors = JSON.parse(this.text);
                    let scrName = root.screen ? root.screen.name : "";
                    for (let m of monitors) {
                        if (m.name === scrName) {
                            root.layoutX = m.x;
                            root.layoutY = m.y;
                            break;
                        }
                    }
                } catch(e) {
                    console.log("[ScreenShot] Failed to parse hyprctl output");
                }
            }
        }
    }

    onVisibleChanged: {
        if (visible) {
            internalVisible = true;
            dimLayer.visible = true;
            dimLayer.opacity = 0.0; 
            frozenImage.visible = false;
            let scrName = root.screen ? root.screen.name : "";
            freezeProcess.command = ["grim", "-o", scrName, "/tmp/qs_freeze_" + scrName + ".png"];
            freezeProcess.running = true;
        } else {
            frozenImage.source = "";
        }
    }

    Process {
        id: freezeProcess
        onExited: {
            let scrName = root.screen ? root.screen.name : "";
            frozenImage.source = "file:///tmp/qs_freeze_" + scrName + ".png?" + Date.now();
            frozenImage.visible = true;
            dimLayer.opacity = 0.15; 
        }
    }

    exclusionMode: ExclusionMode.Ignore
    aboveWindows: true
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"

    Image {
        id: frozenImage
        anchors.fill: parent
        visible: false
        cache: false 
        asynchronous: false 
    }


    Rectangle {
        id: dimLayer
        anchors.fill: parent
        color: Theme.scrim // Unified scrim color
        opacity: 0.0
        Behavior on opacity {
            NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard }
        }
    }

    Rectangle {
        id: lensOverlay
        anchors.fill: parent
        color: Qt.rgba(0.25, 0.1, 0.5, 0.25) 
        opacity: root.isLensMode ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }
    }
    
    Item {
        id: lensBrackets
        opacity: 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        
        property real animScale: 1.2
        scale: animScale
        Behavior on scale { 
            NumberAnimation { 
                duration: 400
                easing.type: Easing.OutBack
                easing.overshoot: 1.3
            } 
        }
        
        Canvas {
            id: lensBracketsCanvas
            anchors.fill: parent
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.strokeStyle = "white";
                ctx.lineWidth = 14;
                ctx.lineCap = "round";
                ctx.lineJoin = "round";
                
                var len = Math.max(30, Math.min(width, height) * 0.15); 
                var r = 32; 
                
                ctx.beginPath();
                ctx.moveTo(0, len); ctx.arcTo(0, 0, r, 0, r); ctx.lineTo(len, 0);
                ctx.moveTo(width - len, 0); ctx.arcTo(width, 0, width, r, r); ctx.lineTo(width, len);
                ctx.moveTo(width, height - len); ctx.arcTo(width, height, width - r, height, r); ctx.lineTo(width - len, height);
                ctx.moveTo(len, height); ctx.arcTo(0, height, 0, height - r, r); ctx.lineTo(0, height - len);
                ctx.stroke();
            }
        }
    }

    Rectangle {
        id: selectionBox
        // Blanket Style: A soft, translucent fill instead of a completely empty box
        color: Vars.tColor(Theme.surface_container_high, Vars.panelOpacity)
        opacity: 0.15 // The fill is highly transparent
        
        // A softer border to match the aesthetic
        border.color: Theme.primary
        border.width: 2
        radius: Vars.radiusSmall
        antialiasing: true
        
        property bool isDragging: false
        visible: isDragging && !root.isLensMode

    }

    Canvas {
        id: drawCanvas
        anchors.fill: parent
        visible: root.isLensMode
        renderTarget: Canvas.FramebufferObject
        renderStrategy: Canvas.Threaded
        antialiasing: true
        smooth: true
        property var pathPoints: []
        property bool isDrawing: false
        property var currentMousePos: null
        
        onPaint: {
            var ctx = getContext("2d");
            if (!isDrawing) {
                ctx.clearRect(0, 0, width, height);
                return;
            }
            ctx.clearRect(0, 0, width, height);
            
            var pts = pathPoints.slice();
            if (currentMousePos) pts.push(currentMousePos);
            
            if (pts.length < 1) return;
            var lastPt = pts[pts.length - 1];
            

            
            // Draw the white line
            if (pathPoints.length >= 2) {
                ctx.strokeStyle = "white";
                ctx.lineWidth = 8;
                ctx.lineJoin = "round";
                ctx.lineCap = "round";
                // Disable shadow on the main line to prevent QML Canvas jaggedness artifacts
                ctx.shadowColor = "transparent";
                ctx.shadowBlur = 0;
                
                ctx.beginPath();
                ctx.moveTo(pts[0].x, pts[0].y);
                
                var getPt = function(idx) {
                    return pts[Math.max(0, Math.min(pts.length - 1, idx))];
                };
                
                for (var i = 0; i < pts.length; i++) {
                    var p0 = getPt(i - 1);
                    var p1 = getPt(i);
                    var p2 = getPt(i + 1);
                    var p3 = getPt(i + 2);
                    
                    var dist = Math.sqrt(Math.pow(p2.x - p1.x, 2) + Math.pow(p2.y - p1.y, 2));
                    if (dist < 1 && i > 0 && i < pts.length - 1) continue;
                    
                    var segments = Math.max(5, Math.floor(dist / 2));
                    for (var s = 1; s <= segments; s++) {
                        var t = s / segments;
                        var mt = 1.0 - t;
                        var b0 = (mt * mt * mt) / 6.0;
                        var b1 = (3.0 * t * t * t - 6.0 * t * t + 4.0) / 6.0;
                        var b2 = (-3.0 * t * t * t + 3.0 * t * t + 3.0 * t + 1.0) / 6.0;
                        var b3 = (t * t * t) / 6.0;
                        
                        var bx = b0*p0.x + b1*p1.x + b2*p2.x + b3*p3.x;
                        var by = b0*p0.y + b1*p1.y + b2*p2.y + b3*p3.y;
                        ctx.lineTo(bx, by);
                    }
                }
                ctx.lineTo(lastPt.x, lastPt.y);
                ctx.stroke();
            }
            

        }
        function clear() {
            pathPoints = [];
            currentMousePos = null;
            isDrawing = false;
            requestPaint();
        }
    }

    Item {
        id: lensCursor
        width: 40
        height: 40
        visible: root.isLensMode && drawCanvas.isDrawing && drawCanvas.currentMousePos !== null
        x: (drawCanvas.currentMousePos ? drawCanvas.currentMousePos.x : 0) - 20
        y: (drawCanvas.currentMousePos ? drawCanvas.currentMousePos.y : 0) - 20
        
        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                var cx = width / 2;
                var cy = height / 2;
                
                var colors = ["#4285F4", "#EA4335", "#FBBC05", "#34A853"];
                ctx.lineCap = "round";
                ctx.lineWidth = 12;
                for (var j = 0; j < 4; j++) {
                    ctx.beginPath();
                    var startAngle = j * (Math.PI / 2) - (Math.PI / 4);
                    var endAngle = (j + 1) * (Math.PI / 2) - (Math.PI / 4);
                    ctx.arc(cx, cy, 8, startAngle, endAngle);
                    ctx.strokeStyle = colors[j];
                    ctx.shadowColor = colors[j];
                    ctx.shadowBlur = 12;
                    ctx.stroke();
                }
                
                ctx.shadowColor = "transparent";
                ctx.shadowBlur = 0;
                ctx.beginPath();
                ctx.arc(cx, cy, 10, 0, 2 * Math.PI);
                ctx.fillStyle = "white";
                ctx.fill();
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.CrossCursor
        focus: true
        Keys.onEscapePressed: {
            dimLayer.opacity = 0;
            frozenImage.visible = false;
            closeTimer.start();
        }
        property int startX: 0
        property int startY: 0
        
        onPressed: mouse => {
            if (root.isLensMode) {
                lensBrackets.opacity = 0;
                drawCanvas.isDrawing = true;
                drawCanvas.pathPoints = [{x: mouse.x, y: mouse.y}];
                drawCanvas.currentMousePos = null;
                drawCanvas.requestPaint();
            } else {
                startX = mouse.x;
                startY = mouse.y;
                selectionBox.x = startX;
                selectionBox.y = startY;
                selectionBox.width = 0;
                selectionBox.height = 0;
                selectionBox.isDragging = true;
            }
        }
        
        onPositionChanged: mouse => {
            if (root.isLensMode) {
                drawCanvas.currentMousePos = {x: mouse.x, y: mouse.y};
                var pts = drawCanvas.pathPoints;
                if (pts.length > 0) {
                    var last = pts[pts.length - 1];
                    var dx = mouse.x - last.x;
                    var dy = mouse.y - last.y;
                    if (dx*dx + dy*dy >= 36) {
                        pts.push({x: mouse.x, y: mouse.y});
                    }
                }
                drawCanvas.requestPaint();
            } else {
                selectionBox.x = Math.min(startX, mouse.x);
                selectionBox.y = Math.min(startY, mouse.y);
                selectionBox.width = Math.abs(mouse.x - startX);
                selectionBox.height = Math.abs(mouse.y - startY);
            }
        }
        
        onReleased: {
            let x, y, w, h;
            if (root.isLensMode) {
                if (drawCanvas.pathPoints.length < 2) {
                    dimLayer.opacity = 0;
                    frozenImage.visible = false;
                    closeTimer.start();
                    return;
                }
                let minX = drawCanvas.pathPoints[0].x;
                let maxX = drawCanvas.pathPoints[0].x;
                let minY = drawCanvas.pathPoints[0].y;
                let maxY = drawCanvas.pathPoints[0].y;
                for (var i = 1; i < drawCanvas.pathPoints.length; i++) {
                    if (drawCanvas.pathPoints[i].x < minX) minX = drawCanvas.pathPoints[i].x;
                    if (drawCanvas.pathPoints[i].x > maxX) maxX = drawCanvas.pathPoints[i].x;
                    if (drawCanvas.pathPoints[i].y < minY) minY = drawCanvas.pathPoints[i].y;
                    if (drawCanvas.pathPoints[i].y > maxY) maxY = drawCanvas.pathPoints[i].y;
                }
                let padding = 15;
                x = Math.max(0, Math.round(minX) - padding);
                y = Math.max(0, Math.round(minY) - padding);
                w = Math.min(root.width - x, Math.round(maxX - minX) + (padding * 2));
                h = Math.min(root.height - y, Math.round(maxY - minY) + (padding * 2));
                console.log(`[Lens Debug] Circle drawn. MinXY: ${minX},${minY}, MaxXY: ${maxX},${maxY}`);
                console.log(`[Lens Debug] Computed Bounding Box: x=${x}, y=${y}, w=${w}, h=${h}`);
            } else {
                x = Math.round(selectionBox.x);
                y = Math.round(selectionBox.y);
                w = Math.round(selectionBox.width);
                h = Math.round(selectionBox.height);
            }
            
            if (w < 10 || h < 10) {
                dimLayer.opacity = 0;
                frozenImage.visible = false;
                closeTimer.start();
                return;
            }
            
            let absX = Math.round(x + root.layoutX);
            let absY = Math.round(y + root.layoutY);
            
            captureTimer.geometry = `${absX},${absY} ${w}x${h}`;
            
            if (root.isLensMode) {
                lensBrackets.x = x;
                lensBrackets.y = y;
                lensBrackets.width = w;
                lensBrackets.height = h;
                drawCanvas.clear();
                lensBrackets.opacity = 1;
                lensBrackets.animScale = 1.0;
                lensBracketsCanvas.requestPaint();
                lensAnimationTimer.start();
            } else {
                selectionBox.isDragging = false; 
                dimLayer.visible = false; 
                console.log(`[Lens Debug] Passing geometry string to grim: ${captureTimer.geometry}`);
                captureTimer.start();
            }
        }
    }

    Timer {
        id: lensAnimationTimer
        interval: 650
        onTriggered: {
            dimLayer.visible = false;
            lensOverlay.visible = false;
            lensBrackets.visible = false;
            frozenImage.visible = false;
            console.log(`[Lens Debug] Passing geometry string to grim: ${captureTimer.geometry}`);
            captureTimer.start();
        }
    }

    Timer {
        id: closeTimer
        interval: 400
        onTriggered: {
            internalVisible = false;
            root.screenshotClosed();
        }
    }

    Timer {
        id: captureTimer
        interval: 150 
        property string geometry: ""
        onTriggered: {
            let scrName = root.screen ? root.screen.name : "";
            let target = root.isLensMode ? `/tmp/qs_lens_${scrName}.png` : `/tmp/qs_crop_${scrName}.png`;
            captureProcess.command = ["grim", "-g", geometry, target];
            console.log(`[Lens Debug] Triggering capture command: ${captureProcess.command.join(" ")}`);
            captureProcess.running = true;
        }
    }

    Process {
        id: captureProcess
        onExited: {
            console.log(`[Lens Debug] Capture process exited. isLensMode: ${root.isLensMode}`);
            if (root.isLensMode) {
                console.log(`[Lens Debug] Starting lens script...`);
                lensProcess.running = true;
            } else {
                sattyProcess.running = true;
            }
            internalVisible = false;
            root.screenshotClosed();
        }
    }

    Process {
        id: sattyProcess
        property string scrName: root.screen ? root.screen.name : ""
        command: ["satty", "--filename", `/tmp/qs_crop_${scrName}.png`]
    }

    Process {
        id: lensProcess
        property string scrName: root.screen ? root.screen.name : ""
        command: ["bash", "/home/boing/Dotfiles/scripts/lens.sh", scrName]
    }
}