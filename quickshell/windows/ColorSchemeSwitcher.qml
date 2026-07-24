import QtQuick
import QtQuick.Effects
import ".."
import "./ColorSchemeSwitcher" as CS
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtCore

import "../theme/variables.js" as Vars

Item {
    id: root
    
    Layout.preferredWidth: 100
    Layout.preferredHeight: 40
    
    property bool expanded: false
    property bool forceHidePill: false
    property var focusWindow: null
    property bool gameMode: false
    property alias panel: panel
    property alias panelMask: panelMask

    opacity: forceHidePill ? 0.0 : 1.0
    visible: opacity > 0

    property string currentTheme: ""
    property string currentMode: "dark"

    signal closeRequested()

    HyprlandFocusGrab {
        active: root.expanded && root.focusWindow !== null
        windows: root.focusWindow ? [root.focusWindow] : []
        onCleared: root.expanded = false
    }
    
    onExpandedChanged: {
        if (!expanded) {
            controlBar.searchText = "";
        } else {
            controlBar.forceSearchFocus();
            loadThemesProc.running = true;
        }
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
        
        width: root.expanded ? 900 : 100
        height: root.expanded ? 550 : 40
        
        color: Vars.translucent ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.85) : Theme.surface
        topLeftRadius: root.gameMode || Vars.panelStyle === "Attached" || Vars.panelStyle === "Framed" ? 0 : (root.expanded ? Vars.radiusExtraLarge : height / 2)
        topRightRadius: root.gameMode || Vars.panelStyle === "Attached" || Vars.panelStyle === "Framed" ? 0 : (root.expanded ? Vars.radiusExtraLarge : height / 2)
        bottomLeftRadius: root.gameMode || Vars.panelStyle === "Flat" ? 0 : (root.expanded ? Vars.radiusExtraLarge : height / 2)
        bottomRightRadius: root.gameMode || Vars.panelStyle === "Flat" ? 0 : (root.expanded ? Vars.radiusExtraLarge : height / 2)
        
        opacity: root.expanded || panel.width > 105 ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on topLeftRadius { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on topRightRadius { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on bottomLeftRadius { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on bottomRightRadius { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on width { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on height { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

        Item {
            anchors.fill: parent
            anchors.margins: Vars.spacingLarge
            
            opacity: root.expanded ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { enabled: !root.gameMode; SequentialAnimation { PauseAnimation { duration: root.expanded ? Vars.animationDuration : 0 } NumberAnimation { duration: root.expanded ? Vars.animationDuration : Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.expanded ? Vars.customEmphasizedDecelerate : Vars.customEmphasizedAccelerate } } }

            ColumnLayout {
                anchors.fill: parent
                spacing: Vars.spacingMedium

                CS.ControlBar {
                    id: controlBar
                    Layout.fillWidth: true
                    currentTheme: root.currentTheme
                    currentMode: root.currentMode

                    onEscapePressed: root.expanded = false
                    onSearchDownPressed: themeGrid.forceActiveFocus()
                    onModeToggled: {
                        root.currentMode = root.currentMode === "dark" ? "light" : "dark";
                        if (root.currentTheme !== "") {
                            root.executeThemeChange(root.currentTheme);
                        }
                    }
                    onRefreshClicked: loadThemesProc.running = true
                }

                CS.ThemeGrid {
                    id: themeGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: sortFilterProxyModel.proxyModel
                    currentTheme: root.currentTheme
                    searchInput: controlBar

                    onThemeSelected: (themeName) => {
                        root.executeThemeChange(themeName);
                        root.expanded = false;
                    }
                    onEscapePressed: root.expanded = false
                }
            }
        }
    }

    function executeThemeChange(themeName) {
        console.log("[USER ACTION] Theme selected: " + themeName + " (" + root.currentMode + ")");
        root.currentTheme = themeName;
        themeChangeProc.command = ["bash", "-c", "bash ~/.config/color-schemes/set-theme.sh '" + themeName + "' '" + root.currentMode + "'"];
        themeChangeProc.running = true;
    }

    Process {
        id: themeChangeProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    console.log("[THEME CHANGE STDOUT]\n" + this.text);
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    console.error("[THEME CHANGE STDERR]\n" + this.text);
            }
        }
    }

    ListModel { id: themeModel }

    QtObject {
        id: sortFilterProxyModel
        property string filterText: controlBar.searchText
        onFilterTextChanged: updateVisualGrid()
        function updateVisualGrid() {
            proxyModel.clear();
            for (var i = 0; i < themeModel.count; i++) {
                var item = themeModel.get(i);
                if (Vars.fuzzyMatch(filterText, item.themeName)) {
                    proxyModel.append({ "themeName": item.themeName, "themePrimary": item.themePrimary });
                }
            }
        }
        property ListModel proxyModel: ListModel {}
    }

    Process {
        id: loadThemesProc
        // Get directory names and their primary color from dark/quickTheme.qml
        command: ["bash", "-c", "for d in ~/.config/color-schemes/*/; do name=$(basename \"$d\"); if [ \"$name\" != \"current\" ] && [ \"$name\" != \"currect\" ]; then primary=$(grep 'readonly property color primary:' \"$d/dark/quickTheme.qml\" 2>/dev/null | cut -d'\"' -f2); echo \"$name|$primary\"; fi; done"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                themeModel.clear();
                var lines = this.text.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.length > 0) {
                        var parts = line.split("|");
                        var name = parts[0];
                        var primary = parts.length > 1 && parts[1] ? parts[1] : "#cccccc";
                        themeModel.append({ "themeName": name, "themePrimary": primary });
                    }
                }
                sortFilterProxyModel.updateVisualGrid();
            }
        }
    }
}
