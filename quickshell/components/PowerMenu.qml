import QtQuick
import QtQuick.Effects
import ".."
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../Variables/variables.js" as Vars

Item {
    id: root
    
    // Fixed layout footprint - never animates, no parent relayout
    Layout.preferredWidth: 100
    Layout.preferredHeight: 40

    property bool expanded: false
    property var focusWindow: null
    property bool gameMode: false

    property alias panel: panel
    property alias panelMask: panelMask
    
    focus: true

    HyprlandFocusGrab {
        active: root.expanded && root.focusWindow !== null
        windows: root.focusWindow ? [root.focusWindow] : []
    }
    
    // Close on escape
    Keys.onEscapePressed: {
        root.expanded = false;
    }
    
    onExpandedChanged: {
        if (expanded) {
            currentIndex = 0;
            root.forceActiveFocus();
        }
    }

    property int currentIndex: 0

    Keys.onLeftPressed: {
        currentIndex = (currentIndex - 1 + 5) % 5;
        event.accepted = true;
    }
    
    Keys.onRightPressed: {
        currentIndex = (currentIndex + 1) % 5;
        event.accepted = true;
    }
    
    Keys.onReturnPressed: {
        triggerAction();
        event.accepted = true;
    }
    
    Keys.onSpacePressed: {
        triggerAction();
        event.accepted = true;
    }

    function triggerAction() {
        if (currentIndex === 0) { lockProcess.running = true; root.expanded = false; }
        else if (currentIndex === 1) { suspendProcess.running = true; root.expanded = false; }
        else if (currentIndex === 2) { logoutProcess.running = true; root.expanded = false; }
        else if (currentIndex === 3) { rebootProcess.running = true; root.expanded = false; }
        else if (currentIndex === 4) { shutdownProcess.running = true; root.expanded = false; }
    }

    Item {
        id: panelMask
        anchors.centerIn: panel
        width: panel.width + 40
        height: panel.height + 40
    }

    Rectangle {
        id: panel
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: !root.gameMode; shadowBlur: 1.0; shadowColor: Qt.rgba(0,0,0,0.25); shadowVerticalOffset: 4; shadowHorizontalOffset: 0 }
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter

        width: root.expanded ? 420 : 100
        height: root.expanded ? 84 : 40
        
        color: Theme.primary
        radius: root.gameMode ? 0 : (root.expanded ? 20 : height / 2)
        // clip removed for shadow

        opacity: root.expanded || panel.width > 105 ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on radius { enabled: !root.gameMode; NumberAnimation { duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
        Behavior on width { enabled: !root.gameMode; NumberAnimation { duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
        Behavior on height { enabled: !root.gameMode; NumberAnimation { duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }

        Rectangle {
            id: globalCursor
            color: Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.12)
            border.color: Theme.on_primary
            border.width: root.activeFocus ? 2 : 0
            radius: 16
            
            Behavior on border.width { NumberAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }

            property var currentItem: {
                if (root.currentIndex === 0) return btn0;
                if (root.currentIndex === 1) return btn1;
                if (root.currentIndex === 2) return btn2;
                if (root.currentIndex === 3) return btn3;
                if (root.currentIndex === 4) return btn4;
                return null;
            }
            property real _x: currentItem ? currentItem.x : 0
            property real _y: currentItem ? currentItem.y : 0
            property real _w: currentItem ? currentItem.width : 0
            property real _h: currentItem ? currentItem.height : 0
            
            x: rowLayout.x + _x
            y: rowLayout.y + _y
            width: _w
            height: _h
            opacity: root.expanded ? 1.0 : 0.0

            Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }
            Behavior on y { NumberAnimation { duration: 300; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }
            Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }
            Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }
            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
        }

        RowLayout {
            id: rowLayout
            anchors.fill: parent
            anchors.margins: 6
            spacing: 8
            
            opacity: root.expanded ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.expanded ? 200 : 0 } NumberAnimation { duration: root.expanded ? 200 : 100; easing.type: Easing.BezierSpline; easing.bezierCurve: root.expanded ? Vars.m3StandardDecelerate : Vars.m3StandardAccelerate } } }

            PowerMenuButton {
                id: btn0
                iconText: "\ue897" // lock
                labelText: "Lock"
                index: 0
                onClicked: { lockProcess.running = true; root.expanded = false; }
            }
            
            PowerMenuButton {
                id: btn1
                iconText: "\ue51c" // dark_mode / suspend
                labelText: "Suspend"
                index: 1
                onClicked: { suspendProcess.running = true; root.expanded = false; }
            }
            
            PowerMenuButton {
                id: btn2
                iconText: "\ue9ba" // logout
                labelText: "Log Out"
                index: 2
                onClicked: { logoutProcess.running = true; root.expanded = false; }
            }
            
            PowerMenuButton {
                id: btn3
                iconText: "\ue5d5" // restart_alt
                labelText: "Reboot"
                index: 3
                onClicked: { rebootProcess.running = true; root.expanded = false; }
            }
            
            PowerMenuButton {
                id: btn4
                iconText: "\ue8ac" // power_settings_new
                labelText: "Power Off"
                index: 4
                onClicked: { shutdownProcess.running = true; root.expanded = false; }
            }
        }
    }

    component PowerMenuButton: Rectangle {
        id: btn
        property string iconText: ""
        property string labelText: ""
        property int index: 0
        property color textColor: Theme.on_primary
        signal clicked
        
        Layout.preferredWidth: 72
        Layout.preferredHeight: 72
        radius: 16 // Reduced radius for buttons to match
        
        color: "transparent"
        
        scale: ma.pressed ? 0.92 : 1.0
        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2
            
            Text {
                text: btn.iconText
                font.family: "Material Symbols Outlined"
                font.pixelSize: 24
                color: btn.textColor
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: btn.labelText
                font.family: Vars.fontFamily
                font.pixelSize: 11
                font.weight: 500
                color: btn.textColor
                Layout.alignment: Qt.AlignHCenter
            }
        }

        MouseArea {
            id: ma
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: { root.currentIndex = btn.index; }
            onClicked: btn.clicked()
        }
    }

    Process { id: lockProcess; command: ["hyprlock"] }
    Process { id: shutdownProcess; command: ["systemctl", "poweroff"] }
    Process { id: rebootProcess; command: ["systemctl", "reboot"] }
    Process { id: suspendProcess; command: ["systemctl", "suspend"] }
    Process { id: logoutProcess; command: ["hyprctl", "dispatch", "exit"] }
}
