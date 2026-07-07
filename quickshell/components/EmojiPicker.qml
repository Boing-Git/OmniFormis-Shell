import QtQuick
import QtQuick.Effects
import ".."
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../Variables/variables.js" as Vars

Item {
    id: root
    
    Layout.preferredWidth: 100
    Layout.preferredHeight: 40
    
    property bool expanded: false
    property var focusWindow: null
    property bool gameMode: false
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

    property var filteredModel: {
        var filterText = searchInput.text.toLowerCase().trim();
        if (filterText === "") return root.emojiModel;
        
        return root.emojiModel.filter(item => Vars.fuzzyMatch(filterText, item.name));
    }

    HyprlandFocusGrab {
        active: root.expanded && root.focusWindow !== null
        windows: root.focusWindow ? [root.focusWindow] : []
    }
    
    onExpandedChanged: {
        if (!expanded) {
            searchInput.text = "";
        } else {
            searchInput.forceActiveFocus();
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
        
        width: root.expanded ? 500 : 100
        height: root.expanded ? 450 : 40
        
        opacity: root.expanded || panel.width > 105 ? 1.0 : 0.0
        visible: opacity > 0
        
        color: Theme.primary
        radius: root.gameMode ? 0 : (root.expanded ? Vars.radiusExtraLarge : height / 2)
        // clip removed for shadow

        Behavior on radius { enabled: !root.gameMode; NumberAnimation { duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
        Behavior on width { enabled: !root.gameMode; NumberAnimation { duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
        Behavior on height { enabled: !root.gameMode; NumberAnimation { duration: 350; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }

        Item {
            anchors.fill: parent
            anchors.margins: Vars.spacingLarge
            
            opacity: root.expanded ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { enabled: !root.gameMode; SequentialAnimation { PauseAnimation { duration: root.expanded ? 200 : 0 } NumberAnimation { duration: root.expanded ? 200 : 100; easing.type: Easing.BezierSpline; easing.bezierCurve: root.expanded ? Vars.m3StandardDecelerate : Vars.m3StandardAccelerate } } }

            ColumnLayout {
                id: mainLayout
                anchors.fill: parent
                spacing: Vars.spacingMedium

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Vars.spacingMedium
                    
                    Rectangle {
                        width: 40; height: 40; radius: Vars.radiusMedium
                        color: backHover.pressed ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.12) : (backHover.containsMouse ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.08) : "transparent")
                        Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_primary; text: "\ue5cd" }
                        MouseArea { id: backHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.expanded = false }
                        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                    }
                    Text { text: "Emoji Picker"; font.family: Vars.fontFamily; font.pixelSize: 20; font.weight: 600; color: Theme.on_primary }
                }

                Rectangle {
                    id: searchBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    color: searchInput.activeFocus ? "transparent" : Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.08)
                    radius: Vars.radiusMedium

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Vars.spacingMedium
                        anchors.rightMargin: Vars.spacingMedium

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            font.family: Vars.fontFamily
                            font.pixelSize: 14
                            color: Theme.on_primary
                            focus: root.expanded
                            selectByMouse: true

                            Text {
                                text: "Search emojis..."
                                font.family: Vars.fontFamily
                                font.pixelSize: 14
                                color: Theme.on_primary
                                opacity: 0.6
                                visible: !searchInput.text && !searchInput.activeFocus
                            }

                            Keys.onDownPressed: (event) => {
                                if (emojiGridView.count > 0 && emojiGridView.currentIndex === -1) {
                                    emojiGridView.currentIndex = 0;
                                }
                                emojiGridView.forceActiveFocus();
                                event.accepted = true;
                            }
                            Keys.onEscapePressed: (event) => {
                                root.expanded = false;
                                event.accepted = true;
                            }
                        }

                        Text {
                            text: "✕"
                            font.pixelSize: 14
                            color: Theme.on_primary
                            visible: searchInput.text.length > 0
                            Layout.alignment: Qt.AlignVCenter
                            MouseArea {
                                anchors.fill: parent
                                onClicked: searchInput.text = ""
                            }
                        }
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
                            searchInput.forceActiveFocus();
                        } else {
                            moveCurrentIndexUp();
                        }
                        event.accepted = true;
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
                            border.color: isCurrent ? Theme.on_primary : "transparent"
                            border.width: isCurrent ? 2 : 0

                            Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                            
                            Text {
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
