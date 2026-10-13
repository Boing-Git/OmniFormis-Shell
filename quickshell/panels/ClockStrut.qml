import QtQuick
import Quickshell
import Quickshell.Wayland
import "../theme"

PanelWindow {
    id: strutWindow
    color: "transparent"
    WlrLayershell.namespace: "quickshell-strut"
    WlrLayershell.layer: WlrLayer.Top
    mask: Region {}

    property string pillPos: Vars.pillPosition || "Top"
    property bool isAlwaysVisible: Vars.clockPillMode === "Always Visible" || Vars.clockPillMode === "Always"

    property int strutThickness: {
        var margin = (Vars.panelStyle === "Flat" || Vars.panelStyle === "Attached") ? 0 : (Vars.spacingSmall !== undefined ? Vars.spacingSmall : 11);
        if (strutWindow.pillPos === "Left" || strutWindow.pillPos === "Right") {
            return 48 + margin;
        } else {
            return Vars.clockPillThickness + margin;
        }
    }

    anchors {
        top: strutWindow.pillPos === "Top"
        bottom: strutWindow.pillPos === "Bottom"
        left: strutWindow.pillPos === "Left" || strutWindow.pillPos === "Top" || strutWindow.pillPos === "Bottom"
        right: strutWindow.pillPos === "Right" || strutWindow.pillPos === "Top" || strutWindow.pillPos === "Bottom"
    }

    implicitWidth: (strutWindow.pillPos === "Left" || strutWindow.pillPos === "Right") ? strutThickness : 0
    implicitHeight: (strutWindow.pillPos === "Top" || strutWindow.pillPos === "Bottom") ? strutThickness : 0

    visible: isAlwaysVisible
    exclusionMode: isAlwaysVisible ? ExclusionMode.Normal : ExclusionMode.Ignore
    exclusiveZone: isAlwaysVisible ? strutThickness : 0
}
