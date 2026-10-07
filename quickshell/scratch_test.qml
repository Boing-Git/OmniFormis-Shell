import QtQuick
import Quickshell
import Quickshell.Hyprland
Window {
    Component.onCompleted: {
        console.log("Monitors:", Hyprland.monitors.length);
        for (let i = 0; i < Hyprland.monitors.length; i++) {
            console.log(Hyprland.monitors[i].id, Hyprland.monitors[i].x, Hyprland.monitors[i].y);
        }
        Qt.quit();
    }
}
