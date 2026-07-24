import QtQuick
import ".."
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "../theme/variables.js" as Vars


PanelWindow {
    id: root
    
    HyprlandFocusGrab { active: root.visible; windows: [root] }
    
    required property bool visibleState
    visible: visibleState
    signal screenshotClosed
    signal openRequested
    property bool internalVisible: false
    property var m3Expressive: [0.05, 0.7, 0.1, 1.0]

    onVisibleChanged: {
        if (visible) {
            internalVisible = true;
            dimLayer.visible = true;
            dimLayer.opacity = 0.0; 
            frozenImage.visible = false;
            freezeProcess.command = ["grim", "/tmp/qs_freeze.png"];
            freezeProcess.running = true;
        } else {
            frozenImage.source = "";
        }
    }

    Process {
        id: freezeProcess
        onExited: {
            frozenImage.source = "file:///tmp/qs_freeze.png?" + Date.now();
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
        id: selectionBox
        // Blanket Style: A soft, translucent fill instead of a completely empty box
        color: Theme.surface_container_high
        opacity: 0.15 // The fill is highly transparent
        
        // A softer border to match the aesthetic
        border.color: Theme.primary
        border.width: 2
        radius: Vars.radiusSmall
        
        property bool isDragging: false
        visible: isDragging

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
            startX = mouse.x;
            startY = mouse.y;
            selectionBox.x = startX;
            selectionBox.y = startY;
            selectionBox.width = 0;
            selectionBox.height = 0;
            selectionBox.isDragging = true;
        }
        
        onPositionChanged: mouse => {
            selectionBox.x = Math.min(startX, mouse.x);
            selectionBox.y = Math.min(startY, mouse.y);
            selectionBox.width = Math.abs(mouse.x - startX);
            selectionBox.height = Math.abs(mouse.y - startY);
        }
        
        onReleased: {
            let x = Math.round(selectionBox.x);
            let y = Math.round(selectionBox.y);
            let w = Math.round(selectionBox.width);
            let h = Math.round(selectionBox.height);
            
            if (w < 10 || h < 10) {
                dimLayer.opacity = 0;
                frozenImage.visible = false;
                closeTimer.start();
                return;
            }
            
            selectionBox.isDragging = false; 
            dimLayer.visible = false; 
            
            captureTimer.geometry = `${x},${y} ${w}x${h}`;
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
        interval: 50 
        property string geometry: ""
        onTriggered: {
            captureProcess.command = ["sh", "-c", `grim -g "${geometry}" /tmp/qs_crop.png`];
            captureProcess.running = true;
        }
    }

    Process {
        id: captureProcess
        onExited: {
            sattyProcess.running = true;
            internalVisible = false;
            root.screenshotClosed();
        }
    }

    Process {
        id: sattyProcess
        command: ["sh", "-c", "satty --filename /tmp/qs_crop.png"]
    }
}