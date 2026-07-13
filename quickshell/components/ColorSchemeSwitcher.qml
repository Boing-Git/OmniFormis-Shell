import QtQuick
import QtQuick.Effects
import ".."
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtCore

import "../Variables/variables.js" as Vars

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
            searchInput.text = "";
        } else {
            searchInput.forceActiveFocus();
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
        
        color: Theme.surface_container_high
        radius: root.gameMode ? 0 : (root.expanded ? Vars.radiusExtraLarge : height / 2)
        
        opacity: root.expanded || panel.width > 105 ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on radius { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
        Behavior on width { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
        Behavior on height { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }

        Item {
            anchors.fill: parent
            anchors.margins: Vars.spacingLarge
            
            opacity: root.expanded ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { enabled: !root.gameMode; SequentialAnimation { PauseAnimation { duration: root.expanded ? Vars.animationDuration : 0 } NumberAnimation { duration: root.expanded ? Vars.animationDuration : Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.expanded ? Vars.m3StandardDecelerate : Vars.m3StandardAccelerate } } }

            ColumnLayout {
                anchors.fill: parent
                spacing: Vars.spacingMedium

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Vars.spacingMedium

                    RowLayout {
                        spacing: Vars.spacingMedium



                        Text {
                            text: "palette"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 28
                            color: Theme.on_surface
                        }

                        ColumnLayout {
                            spacing: 4
                            Text {
                                text: "Color Schemes"
                                font.family: Vars.fontFamily
                                font.pixelSize: 22
                                font.bold: true
                                color: Theme.on_surface
                            }
                            Text {
                                text: root.currentTheme ? "Active: " + root.currentTheme : "Select a theme"
                                font.family: Vars.fontFamily
                                font.pixelSize: 12
                                color: Theme.on_surface_variant
                                opacity: 0.8
                                elide: Text.ElideMiddle
                                Layout.maximumWidth: 320
                            }
                        }
                    }

                    Rectangle {
                        id: searchBox
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        color: searchInput.activeFocus ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)
                        border.color: searchInput.activeFocus ? Theme.primary : Theme.outline
                        border.width: searchInput.activeFocus ? 2 : 1
                        radius: Vars.radiusMedium

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Vars.spacingMedium
                            anchors.rightMargin: Vars.spacingMedium

                            Text {
                                text: "search"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 20
                                color: Theme.on_surface
                                opacity: 0.7
                            }

                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                font.family: Vars.fontFamily
                                font.pixelSize: 14
                                color: Theme.on_surface
                                focus: true
                                selectByMouse: true

                                Text {
                                    text: "Search themes..."
                                    font.family: Vars.fontFamily
                                    font.pixelSize: 14
                                    color: Theme.on_surface_variant
                                    opacity: 0.6
                                    visible: !searchInput.text && !searchInput.activeFocus
                                }

                                Keys.onDownPressed: (event) => {
                                    gridView.forceActiveFocus();
                                    event.accepted = true;
                                }
                                Keys.onEscapePressed: root.expanded = false
                            }

                            Text {
                                text: "✕"
                                font.pixelSize: 14
                                color: Theme.on_surface
                                visible: searchInput.text.length > 0
                                Layout.alignment: Qt.AlignVCenter
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: searchInput.text = ""
                                }
                            }
                        }
                    }

                    Button {
                        id: modeToggleBtn
                        text: root.currentMode === "dark" ? "Dark Mode" : "Light Mode"
                        onClicked: {
                            root.currentMode = root.currentMode === "dark" ? "light" : "dark";
                            if (root.currentTheme !== "") {
                                root.executeThemeChange(root.currentTheme);
                            }
                        }

                        background: Rectangle {
                            color: modeToggleBtn.down ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (modeToggleBtn.hovered ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                            border.width: 1
                            border.color: Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.3)
                            radius: Vars.radiusMedium
                        }
                        contentItem: RowLayout {
                            spacing: Vars.spacingSmall
                            Text {
                                text: root.currentMode === "dark" ? "dark_mode" : "light_mode"
                                font.family: "Material Symbols Outlined"
                                color: Theme.on_surface
                                font.pixelSize: 18
                            }
                            Text {
                                text: modeToggleBtn.text
                                font.family: Vars.fontFamily
                                color: Theme.on_surface
                                font.bold: true
                                font.pixelSize: 14
                            }
                        }
                    }

                    Button {
                        id: refreshBtn
                        text: "Scan"
                        onClicked: loadThemesProc.running = true

                        background: Rectangle {
                            color: refreshBtn.down ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (refreshBtn.hovered ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                            border.width: 0
                            radius: Vars.radiusMedium
                        }
                        contentItem: RowLayout {
                            spacing: Vars.spacingSmall
                            Text {
                                text: "refresh"
                                font.family: "Material Symbols Outlined"
                                color: (refreshBtn.down || refreshBtn.hovered) ? Theme.primary : Theme.on_surface
                                font.pixelSize: 18
                            }
                            Text {
                                text: refreshBtn.text
                                font.family: Vars.fontFamily
                                color: (refreshBtn.down || refreshBtn.hovered) ? Theme.primary : Theme.on_surface
                                font.bold: true
                                font.pixelSize: 14
                            }
                        }
                    }
                }

                GridView {
                    id: gridView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    cellWidth: Math.floor(parent.width / 4)
                    cellHeight: cellWidth * 0.5625
                    model: sortFilterProxyModel.proxyModel
                    boundsBehavior: Flickable.StopAtBounds

                    focus: true
                    keyNavigationEnabled: true
                    highlightFollowsCurrentItem: false
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)
                    
                    highlight: Item {
                        x: gridView.currentItem ? gridView.currentItem.x : 0
                        y: gridView.currentItem ? gridView.currentItem.y : 0
                        width: gridView.cellWidth
                        height: gridView.cellHeight
                        z: -1

                        Behavior on x { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }
                        Behavior on y { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: Vars.spacingSmall
                            radius: Vars.radiusMedium
                            color: gridView.activeFocus ? Theme.primary_container : "transparent"
                            border.color: Theme.primary_container
                            border.width: gridView.activeFocus ? 2 : 0
                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                            Behavior on border.width { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                        }
                    }

                    Keys.onEscapePressed: root.expanded = false
                    Keys.onUpPressed: (event) => {
                        if (currentIndex < 4) {
                            searchInput.forceActiveFocus();
                        } else {
                            moveCurrentIndexUp();
                        }
                        event.accepted = true;
                    }
                    Keys.onDownPressed: (event) => {
                        moveCurrentIndexDown();
                        event.accepted = true;
                    }
                    Keys.onLeftPressed: (event) => {
                        moveCurrentIndexLeft();
                        event.accepted = true;
                    }
                    Keys.onRightPressed: (event) => {
                        moveCurrentIndexRight();
                        event.accepted = true;
                    }
                    Keys.onReturnPressed: (event) => {
                        if (currentItem) currentItem.triggerSelection();
                        event.accepted = true;
                    }

                    delegate: Item {
                        id: delegateItem
                        width: gridView.cellWidth
                        height: gridView.cellHeight

                        function triggerSelection() {
                            executeThemeChange(themeName);
                        }

                        property bool isCurrentFocus: delegateItem.GridView.isCurrentItem && gridView.activeFocus
                        
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: Vars.spacingSmall
                            radius: Vars.radiusMedium

                            color: root.currentTheme === themeName ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : (tileMouseArea.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                            border.color: Theme.primary
                            border.width: (root.currentTheme === themeName) ? 2 : 0
                            clip: true

                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: Vars.spacingSmall
                                spacing: Vars.spacingSmall

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.margins: isCurrentFocus ? 4 : 0
                                    clip: true
                                    
                                    Behavior on Layout.margins { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "palette"
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 48
                                        color: isCurrentFocus ? Theme.on_primary_container : (root.currentTheme === themeName ? Theme.primary : Theme.on_surface)
                                        opacity: 0.8
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: themeName
                                    font.family: Vars.fontFamily
                                    color: isCurrentFocus ? Theme.on_primary_container : (root.currentTheme === themeName ? Theme.primary : Theme.on_surface)
                                    font.pixelSize: 16
                                    font.weight: root.currentTheme === themeName ? Font.Bold : Font.Normal
                                    elide: Text.ElideRight
                                    horizontalAlignment: Text.AlignHCenter
                                    
                                    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }
                                }
                            }

                            MouseArea {
                                id: tileMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                preventStealing: false
                                onClicked: {
                                    gridView.currentIndex = index;
                                    delegateItem.triggerSelection();
                                    root.expanded = false;
                                }
                            }
                        }
                    }
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
        property string filterText: searchInput.text
        onFilterTextChanged: updateVisualGrid()
        function updateVisualGrid() {
            proxyModel.clear();
            for (var i = 0; i < themeModel.count; i++) {
                var item = themeModel.get(i);
                if (Vars.fuzzyMatch(filterText, item.themeName)) {
                    proxyModel.append({ "themeName": item.themeName });
                }
            }
        }
        property ListModel proxyModel: ListModel {}
    }

    Process {
        id: loadThemesProc
        // Only get directory names directly under color-schemes, excluding currect
        command: ["bash", "-c", "find ~/.config/color-schemes/ -maxdepth 1 -mindepth 1 -type d -not -name 'currect' -not -name 'current' -exec basename {} \\;"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                themeModel.clear();
                var lines = this.text.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var name = lines[i].trim();
                    if (name.length > 0) {
                        themeModel.append({ "themeName": name });
                    }
                }
                sortFilterProxyModel.updateVisualGrid();
            }
        }
    }
}
