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

import "../theme"
import "../core/primitives" as Primitives
Item {
    id: root
    
    Layout.preferredWidth: 100
    Layout.preferredHeight: 40
    
    property bool expanded: false
    property bool forceHidePill: false
    property var focusWindow: null
    property bool gameMode: Vars.gameMode !== undefined ? Vars.gameMode : false
    property alias panel: panel
    property alias panelMask: panelMask

    opacity: forceHidePill ? 0.0 : 1.0
    visible: opacity > 0

    property string currentTheme: ""
    property string currentMode: "dark"

    signal closeRequested()


    
    onExpandedChanged: {
        if (!expanded) {
            MorphState.notifyClosed();
            controlBar.searchText = "";
        } else {
            MorphState.notifyOpened(900, 550, panel.targetRad, panel);
            innerUI.visible = true;
            controlBar.forceSearchFocus();
            innerUI.visible = Qt.binding(() => root.expanded || innerUI.opacity > 0);
            root.reloadThemes();
        }
    }

    Item {
        id: panelMask
        // x/y are computed as one atomic expression per axis instead of six independently
        // toggled anchor lines plus four bleed-margin lines, so a pillPosition change can't
        // leave this item part-anchored to the old edge while the other axis has already moved
        // to the new one (that mismatch is what made expanded popups fail to render their
        // content after a live position change).
        property real _bleed: root.expanded ? -20 : 0
        x: {
            if (Vars.pillPosition === "Left") return _bleed;
            if (Vars.pillPosition === "Right") return parent.width - width - _bleed;
            return (parent.width - width) / 2;
        }
        y: {
            if (Vars.pillPosition === "Bottom") return parent.height - height - _bleed;
            if (Vars.pillPosition === "Left" || Vars.pillPosition === "Right") return (parent.height - height) / 2;
            return _bleed;
        }
        width: root.expanded ? 440 : 0
        height: root.expanded ? 360 : 0
    }

    Primitives.SquircleMask {
        id: panel
        property bool isBackgroundActive: root.expanded || (MorphState.openCount === 0 && MorphState.activeItem === panel && panel.width > 105)
        layer.enabled: false
        layer.samples: Vars.layerSamples
        // x/y are computed as one atomic expression per axis instead of six independently
        // toggled anchor lines, so a pillPosition change can't leave this item part-anchored to
        // the old edge while the other axis has already moved to the new one (that mismatch is
        // what made expanded popups fail to render their content after a live position change).
        x: {
            if (Vars.pillPosition === "Left") return 0;
            if (Vars.pillPosition === "Right") return parent.width - width;
            return (parent.width - width) / 2;
        }
        y: {
            if (Vars.pillPosition === "Bottom") return parent.height - height;
            if (Vars.pillPosition === "Left" || Vars.pillPosition === "Right") return (parent.height - height) / 2;
            return 0;
        }
        
        width: root.expanded ? 900 : (MorphState.anyExpanded ? MorphState.targetWidth : 100)
        height: root.expanded ? 550 : (MorphState.anyExpanded ? MorphState.targetHeight : 40)
        
        color: Vars.tColorActive(isBackgroundActive, Theme.surface, Vars.panelOpacity)
        property real targetRad: root.expanded ? Vars.radiusExtraLarge : (MorphState.anyExpanded ? MorphState.targetRadius : height / 2)
        topLeftRadius: Vars.getTopLeftRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        topRightRadius: Vars.getTopRightRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        bottomLeftRadius: Vars.getBottomLeftRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        bottomRightRadius: Vars.getBottomRightRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        
        opacity: isBackgroundActive || innerUI.opacity > 0 ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on width { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on height { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

        Item {
            id: innerUI
            // Content must never draw outside the morphing panel
            clip: true
            anchors.fill: parent
            anchors.margins: Vars.spacingLarge
            
            opacity: root.expanded ? 1.0 : 0.0
            visible: root.expanded || opacity > 0
            Behavior on opacity { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.getFadeCurve(root.expanded) } }

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
                        loadThemesProc.running = false;
                        loadThemesProc.running = true;
                    }
                    onRefreshClicked: root.reloadThemes()
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

    function reloadThemes() {
        currentThemeProc.running = false;
        currentThemeProc.running = true;
    }

    function executeThemeChange(themeName) {
        console.log("[USER ACTION] Theme selected: " + themeName + " (" + root.currentMode + ")");
        root.currentTheme = themeName;
        // Arguments are passed positionally so a theme name can never be interpreted by the shell
        themeChangeProc.command = ["bash", "-c", "exec bash \"$HOME/.config/color-schemes/set-theme.sh\" \"$1\" \"$2\"", "set-theme", themeName, root.currentMode];
        themeChangeProc.running = true;
    }

    // The active scheme and mode are encoded in where current/quickTheme.qml points:
    // ~/.config/color-schemes/<name>/<mode>/quickTheme.qml
    Process {
        id: currentThemeProc
        command: ["bash", "-c", "readlink -f \"$HOME/.config/color-schemes/current/quickTheme.qml\" 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: {
                var m = this.text.trim().match(/color-schemes\/([^\/]+)\/(dark|light)\/quickTheme\.qml$/);
                if (m) {
                    root.currentTheme = m[1];
                    root.currentMode = m[2];
                }
                loadThemesProc.running = false;
                loadThemesProc.running = true;
            }
        }
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

        // Diff against the visible model instead of clearing it, so tiles that stay keep their
        // identity and the grid can animate the ones that come and go while typing.
        function updateVisualGrid() {
            var wanted = [];
            for (var i = 0; i < themeModel.count; i++) {
                var item = themeModel.get(i);
                if (Vars.fuzzyMatch(filterText, item.themeName))
                    wanted.push(item);
            }
            var names = {};
            for (var w = 0; w < wanted.length; w++)
                names[wanted[w].themeName] = true;

            for (var r = proxyModel.count - 1; r >= 0; r--) {
                if (!names[proxyModel.get(r).themeName])
                    proxyModel.remove(r);
            }
            for (var t = 0; t < wanted.length; t++) {
                var entry = wanted[t];
                var row = { "themeName": entry.themeName, "themePrimary": entry.themePrimary, "themeSecondary": entry.themeSecondary, "themeTertiary": entry.themeTertiary, "themeSurface": entry.themeSurface, "themeOnSurface": entry.themeOnSurface };
                if (t < proxyModel.count && proxyModel.get(t).themeName === entry.themeName) {
                    proxyModel.set(t, row);
                    continue;
                }
                var found = -1;
                for (var j = t + 1; j < proxyModel.count; j++) {
                    if (proxyModel.get(j).themeName === entry.themeName) { found = j; break; }
                }
                if (found >= 0) {
                    proxyModel.move(found, t, 1);
                    proxyModel.set(t, row);
                } else {
                    proxyModel.insert(t, row);
                }
            }
        }
        property ListModel proxyModel: ListModel {}
    }

    Process {
        id: loadThemesProc
        // One line per scheme: name|primary|secondary|tertiary|surface|on_surface for the active mode
        command: ["bash", "-c", "mode=\"$1\"; get() { grep -m1 \"readonly property color $1:\" \"$2\" 2>/dev/null | cut -d'\"' -f2; }; for d in \"$HOME\"/.config/color-schemes/*/; do name=$(basename \"$d\"); [ \"$name\" = current ] && continue; f=\"$d$mode/quickTheme.qml\"; [ -f \"$f\" ] || f=\"${d}dark/quickTheme.qml\"; [ -f \"$f\" ] || continue; echo \"$name|$(get primary \"$f\")|$(get secondary \"$f\")|$(get tertiary \"$f\")|$(get surface \"$f\")|$(get on_surface \"$f\")\"; done", "load-themes", root.currentMode]
        stdout: StdioCollector {
            onStreamFinished: {
                themeModel.clear();
                var lines = this.text.split("\n");
                var hex = /^#[0-9a-fA-F]{6,8}$/;
                var pick = function (v, fallback) { return (v && hex.test(v)) ? v : fallback; };
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.length === 0) continue;
                    var parts = line.split("|");
                    var primary = pick(parts[1], "#cccccc");
                    themeModel.append({
                        "themeName": parts[0],
                        "themePrimary": primary,
                        "themeSecondary": pick(parts[2], primary),
                        "themeTertiary": pick(parts[3], primary),
                        "themeSurface": pick(parts[4], "#1c1b1f"),
                        "themeOnSurface": pick(parts[5], "#e6e1e5")
                    });
                }
                sortFilterProxyModel.updateVisualGrid();
            }
        }
    }

    Component.onCompleted: root.reloadThemes()
}
