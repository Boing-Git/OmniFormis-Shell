import QtQuick
import QtQuick.Effects
import ".."
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../theme"
import "../core/primitives" as Primitives
Item {
    id: root
    
    Layout.preferredWidth: 100
    Layout.preferredHeight: 40
    
    property bool expanded: false
    property var focusWindow: null
    property bool gameMode: Vars.gameMode !== undefined ? Vars.gameMode : false
    property alias panel: panel
    property alias panelMask: panelMask

    signal emojiSelected()

    property var emojiModel: []

    Process {
        id: emojiFetcher
        command: ["cat", Quickshell.env("HOME") + "/.config/quickshell/scripts/emojis.txt"]
        running: false
        
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.length > 0) {
                    var lines = this.text.split("\n");
                    var arr = [];
                    for (var i = 0; i < lines.length; i++) {
                        var line = lines[i].trim();
                        if (line.length > 0) {
                            var firstSpace = line.indexOf(" ");
                            var charVal = line;
                            var nameVal = line;
                            if (firstSpace !== -1) {
                                charVal = line.substring(0, firstSpace);
                                nameVal = line.substring(firstSpace + 1).trim();
                            }
                            
                            arr.push({
                                char: charVal,
                                name: nameVal
                            });
                        }
                    }
                    root.emojiModel = arr;
                }
            }
        }
    }

    Component.onCompleted: {
        emojiFetcher.running = true;
    }

    property bool vimKeysEnabled: false
    Process {
        id: vimKeysChecker
        command: ["bash", "-c", "grep -qi 'vimkeys[ \t]*=[ \t]*true' /home/boing/Dotfiles/hypr/modules/variables.lua && echo 'true' || echo 'false'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.vimKeysEnabled = (this.text.trim() === 'true');
            }
        }
    }

    property var filteredModel: {
        var filterText = searchBar.text.toLowerCase().trim();
        if (filterText === "") return root.emojiModel;
        
        return root.emojiModel.filter(item => Vars.fuzzyMatch(filterText, item.name));
    }

    
    onExpandedChanged: {
        if (!expanded) {
            MorphState.notifyClosed();
            searchBar.text = "";
        } else {
            MorphState.notifyOpened(500, 450, panel.targetRad, panel);
            innerUI.visible = true;
            searchBar.forceActiveFocus();
            innerUI.visible = Qt.binding(() => root.expanded || innerUI.opacity > 0);
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
        height: root.expanded ? 490 : 0
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
        
        width: root.expanded ? 500 : (MorphState.anyExpanded ? MorphState.targetWidth : 100)
        height: root.expanded ? 450 : (MorphState.anyExpanded ? MorphState.targetHeight : 40)
        
        opacity: isBackgroundActive || innerUI.opacity > 0 ? 1.0 : 0.0
        // visible: opacity > 0 // Removed to preserve Behavior when hidden
        
        color: Vars.tColorActive(isBackgroundActive, Theme.surface_container_high, Vars.panelOpacity)
        property real targetRad: root.expanded ? Vars.radiusExtraLarge : (MorphState.anyExpanded ? MorphState.targetRadius : height / 2)
        topLeftRadius: Vars.getTopLeftRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        topRightRadius: Vars.getTopRightRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        bottomLeftRadius: Vars.getBottomLeftRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        bottomRightRadius: Vars.getBottomRightRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        // clip removed for shadow

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
                id: mainLayout
                anchors.fill: parent
                spacing: Vars.spacingMedium

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Vars.spacingMedium
                    
                    Rectangle {
                        antialiasing: true
                        width: 40; height: 40; radius: Vars.radiusMedium
                        color: backHover.pressed ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.12) : (backHover.containsMouse ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.08) : "transparent")
                        QsText { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_primary; text: "\ue5cd" }
                        MouseArea { id: backHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.expanded = false }
                        Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                    }
                    QsText { text: "Emoji Picker"; font.family: Vars.fontFamily; font.pixelSize: 20; setWeight: 600; color: Theme.on_primary }
                }

                SearchBar {
                    id: searchBar
                    expanded: root.expanded
                    placeholderText: "Search emojis..."
                    defaultHeight: 44
                    containerPadding: Vars.spacingLarge
                    outerTopLeftRadius: panel.topLeftRadius
                    outerTopRightRadius: panel.topRightRadius
                    outerBottomLeftRadius: panel.bottomLeftRadius
                    outerBottomRightRadius: panel.bottomRightRadius

                    onDownPressed: {
                        if (emojiGridView.count > 0 && emojiGridView.currentIndex === -1) {
                            emojiGridView.currentIndex = 0;
                        }
                        emojiGridView.forceActiveFocus();
                    }
                    onEscapePressed: {
                        root.expanded = false;
                    }
                }

                GridView {
                    id: emojiGridView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    
                    cellWidth: 55
                    cellHeight: 55
                    
                    model: root.filteredModel
                    
                    focus: true
                    keyNavigationEnabled: true
                    highlightFollowsCurrentItem: false
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)
                    
                    Keys.onReturnPressed: (event) => { if (currentItem) currentItem.triggerSelection(); event.accepted = true; }
                    Keys.onSpacePressed: (event) => { if (currentItem) currentItem.triggerSelection(); event.accepted = true; }
                    Keys.onEscapePressed: (event) => { root.expanded = false; event.accepted = true; }
                    
                    Keys.onUpPressed: (event) => {
                        if (currentIndex < Math.floor(width / cellWidth)) {
                            innerUI.visible = true;
            searchBar.forceActiveFocus();
            innerUI.visible = Qt.binding(() => root.expanded || innerUI.opacity > 0);
                        } else {
                            moveCurrentIndexUp();
                        }
                        event.accepted = true;
                    }
                    
                    Keys.onPressed: (event) => {
                        if (root.vimKeysEnabled) {
                            if (event.key === Qt.Key_H || event.key === Qt.Key_A) {
                                moveCurrentIndexLeft();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_L || event.key === Qt.Key_F) {
                                moveCurrentIndexRight();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_K || event.key === Qt.Key_D) {
                                if (currentIndex < Math.floor(width / cellWidth)) {
                                    innerUI.visible = true;
            searchBar.forceActiveFocus();
            innerUI.visible = Qt.binding(() => root.expanded || innerUI.opacity > 0);
                                } else {
                                    moveCurrentIndexUp();
                                }
                                event.accepted = true;
                            } else if (event.key === Qt.Key_J || event.key === Qt.Key_S) {
                                moveCurrentIndexDown();
                                event.accepted = true;
                            }
                        }
                    }
                    
                    onModelChanged: {
                        if (count > 0 && currentIndex === -1) {
                            currentIndex = 0;
                        }
                    }

                    delegate: Item {
                        id: delegateItem
                        width: emojiGridView.cellWidth
                        height: emojiGridView.cellHeight

                        function triggerSelection() {
                            Quickshell.execDetached({
                                command: ["wl-copy", modelData.char]
                            });
                            root.emojiSelected();
                            root.expanded = false;
                        }

                        property bool isCurrent: delegateItem.GridView.isCurrentItem && emojiGridView.activeFocus
                        
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 4
                            color: itemMouseArea.containsMouse || isCurrent ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.08) : "transparent"
                            radius: Vars.radiusMedium
                            antialiasing: true
                            border.color: isCurrent ? Theme.on_primary : "transparent"
                            border.width: isCurrent ? 2 : 0

                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            
                            QsText {
                                anchors.centerIn: parent
                                text: modelData.char
                                font.pixelSize: 26
                                
                                ToolTip.text: modelData.name
                                ToolTip.visible: itemMouseArea.containsMouse
                                ToolTip.delay: 500
                            }
                        }

                        MouseArea {
                            id: itemMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onEntered: {
                                emojiGridView.currentIndex = index;
                            }

                            onClicked: {
                                emojiGridView.currentIndex = index;
                                delegateItem.triggerSelection();
                            }
                        }
                    }
                    
                    ScrollBar.vertical: ScrollBar {}
                }
            }
        }
    }
}
