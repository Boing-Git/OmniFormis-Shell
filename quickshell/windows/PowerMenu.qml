import QtQuick
import QtQuick.Effects
import ".."
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../theme/variables.js" as Vars

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

        width: root.expanded ? 456 : 100
        height: root.expanded ? 84 : 40
        
        color: Theme.surface_container_high
        topLeftRadius: root.gameMode || Vars.panelStyle === "Attached" || Vars.panelStyle === "Framed" ? 0 : (root.expanded ? Vars.radiusExtraLarge : height / 2)
        topRightRadius: root.gameMode || Vars.panelStyle === "Attached" || Vars.panelStyle === "Framed" ? 0 : (root.expanded ? Vars.radiusExtraLarge : height / 2)
        bottomLeftRadius: root.gameMode ? 0 : (root.expanded ? Vars.radiusExtraLarge : height / 2)
        bottomRightRadius: root.gameMode ? 0 : (root.expanded ? Vars.radiusExtraLarge : height / 2)
        // clip removed for shadow

        opacity: root.expanded || panel.width > 105 ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on topLeftRadius { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on topRightRadius { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on bottomLeftRadius { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on bottomRightRadius { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on width { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on height { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

        RowLayout {
            id: rowLayout
            anchors.fill: parent
            anchors.leftMargin: 24
            anchors.rightMargin: 24
            anchors.topMargin: 6
            anchors.bottomMargin: 6
            spacing: 12
            
            opacity: root.expanded ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { SequentialAnimation { PauseAnimation { duration: root.expanded ? Vars.animationDuration : 0 } NumberAnimation { duration: root.expanded ? Vars.animationDuration : Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.expanded ? Vars.customEmphasizedDecelerate : Vars.customEmphasizedAccelerate } } }

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
        property bool isActive: root.currentIndex === index
        signal clicked
        
        Layout.preferredWidth: 72
        Layout.preferredHeight: 72
        radius: isActive ? height / 2 : 24 
        
        Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
        
        color: isActive ? Theme.primary : Theme.surface_container_highest
        Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
        
        scale: ma.pressed ? 0.92 : 1.0
        Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutQuad } }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 2
            
            Text {
                text: btn.iconText
                font.family: "Material Symbols Outlined"
                font.pixelSize: 24
                color: btn.isActive ? Theme.on_primary : Theme.on_surface
                Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                Layout.alignment: Qt.AlignHCenter
            }
            Text {
                text: btn.labelText
                font.family: Vars.fontFamily
                font.pixelSize: 11
                font.weight: 600
                color: btn.isActive ? Theme.on_primary : Theme.on_surface
                Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
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

    Process { id: lockProcess; command: ["sh", "/home/boing/Dotfiles/quickshell/scripts/lock.sh"] }
    Process { id: shutdownProcess; command: ["systemctl", "poweroff"] }
    Process { id: rebootProcess; command: ["systemctl", "reboot"] }
    Process { id: suspendProcess; command: ["systemctl", "suspend"] }
    Process { id: logoutProcess; command: ["hyprctl", "dispatch", "exit"] }
}
