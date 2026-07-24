import QtQuick
import ".."
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Polkit
import "../theme/variables.js" as Vars

Scope {
    id: root

    // ── Polkit Agent ────────────────────────────────────
    PolkitAgent {
        id: polkitAgent
    }

    property bool dialogVisible: polkitAgent.flow !== null && !polkitAgent.flow.isCompleted

    // ── Popup Window ────────────────────────────────────
    PopupWindow {
        id: polkitWindow
        visible: root.dialogVisible
        anchor.window: Quickshell.screens[0]

        // Fullscreen transparent overlay
        width: screen ? screen.width : 1920
        height: screen ? screen.height : 1080

        color: "transparent"

        HyprlandFocusGrab {
            active: root.dialogVisible
            windows: [polkitWindow]
        }

        // ── Scrim overlay ──
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.5)

            opacity: root.dialogVisible ? 1.0 : 0.0
            Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }

            // Click scrim to cancel
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    if (polkitAgent.flow) {
                        polkitAgent.flow.cancelAuthenticationRequest();
                    }
                }
            }
        }

        // ── Centered Dialog ──
        PolkitDialog {
            id: dialog
            anchors.centerIn: parent
            flow: polkitAgent.flow

            // Entry animation
            scale: root.dialogVisible ? 1.0 : 0.92
            opacity: root.dialogVisible ? 1.0 : 0.0
            Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3EmphasizedDecelerate } }
            Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
        }
    }
}
