import QtQuick
import Quickshell
import Quickshell.Wayland
import "."

ShellRoot {
    id: root

    PanelWindow {
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        color: "transparent"

        // Layer shell overlay to sit above everything
        WlrLayershell.namespace: "quickshell"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Item {
            anchors.fill: parent

            // Background
            Rectangle {
                anchors.fill: parent

                // Deep warm-dark gradient matching the card aesthetic
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.surface_container_lowest }
                    GradientStop { position: 0.4; color: Theme.surface_container_high }
                    GradientStop { position: 1.0; color: Theme.surface_container_low }
                }
            }

            // Subtle radial glow behind the card
            Rectangle {
                width: 500; height: 500
                anchors.centerIn: parent
                radius: 250
                color: Theme.primary
                opacity: 0.03
            }

            // Main Login Card
            LoginCard {
                anchors.centerIn: parent
            }
        }
    }
}
