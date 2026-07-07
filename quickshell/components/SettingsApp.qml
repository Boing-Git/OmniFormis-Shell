import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import "../Variables/variables.js" as Vars
import ".."

Item {
    id: root
    
    Layout.preferredWidth: 100
    Layout.preferredHeight: 40
    
    property bool expanded: false
    property bool forceHidePill: false
    property var focusWindow: null
    property bool gameMode: false
    property var allVars: []
    property alias panel: panel
    property alias panelMask: panelMask
    
    opacity: forceHidePill ? 0.0 : 1.0
    visible: opacity > 0
    signal closeRequested()

    HyprlandFocusGrab {
        active: root.expanded && root.focusWindow !== null
        windows: root.focusWindow ? [root.focusWindow] : []
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
        
        width: root.expanded ? 700 : 100
        height: root.expanded ? 600 : 40
        
        color: Theme.primary
        radius: root.gameMode ? 0 : (root.expanded ? Vars.radiusExtraLarge : height / 2)
        
        opacity: root.expanded || panel.width > 105 ? 1.0 : 0.0
        visible: opacity > 0

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

                    Text {
                        text: "settings"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 28
                        color: Theme.on_primary
                    }

                    ColumnLayout {
                        spacing: 4
                        Text {
                            text: "Hyprland Settings"
                            font.family: Vars.fontFamily
                            font.pixelSize: 22
                            font.bold: true
                            color: Theme.on_primary
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Button {
                        text: "Refresh"
                        onClicked: { loadSettings(); }
                        background: Rectangle {
                            color: refreshBtnHover.containsMouse ? Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.1) : "transparent"
                            radius: Vars.radiusMedium
                        }
                        contentItem: Text { text: "Refresh"; color: Theme.on_primary; font.family: Vars.fontFamily; font.bold: true }
                        MouseArea { id: refreshBtnHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: loadSettings() }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    color: Qt.rgba(Theme.surface_variant.r, Theme.surface_variant.g, Theme.surface_variant.b, 0.5)
                    radius: Vars.radiusMedium
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        Text {
                            text: "search"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 20
                            color: Theme.on_surface_variant
                        }
                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            color: Theme.on_surface
                            font.family: Vars.fontFamily
                            font.pixelSize: 16
                            verticalAlignment: TextInput.AlignVCenter
                            clip: true
                            onTextChanged: applyFilter()
                            KeyNavigation.down: settingsList
                            Keys.onDownPressed: {
                                settingsList.forceActiveFocus();
                            }
                        }
                    }
                }

                ListModel {
                    id: settingsModel
                    // Roles: key, type, help, enums, val, category
                }
                ListView {
                    id: settingsList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: Vars.spacingLarge
                    model: settingsModel
                    boundsBehavior: Flickable.StopAtBounds
                    focus: true
                    KeyNavigation.up: searchInput
                    
                    Keys.onReturnPressed: {
                        if (currentItem) {
                            currentItem.triggerAction();
                        }
                    }
                    Keys.onRightPressed: {
                        if (currentItem) currentItem.triggerAction();
                    }
                    
                    section.property: "category"
                    section.criteria: ViewSection.FullString
                    section.delegate: Rectangle {
                        width: ListView.view.width
                        height: 40
                        color: "transparent"
                        
                        Text {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 8
                            text: section
                            color: Theme.primary
                            font.pixelSize: 18
                            font.bold: true
                            font.family: Vars.fontFamily
                        }
                        
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 1
                            color: Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.2)
                        }
                    }
                    
                    delegate: Rectangle {
                        id: delegateRoot
                        property int delegateIndex: index
                        property string itemKey: model.key
                        property string itemType: model.type
                        property string itemHelp: model.help
                        property string itemEnums: model.enums
                        property string itemVal: model.val
                        
                        width: ListView.view.width
                        height: 80
                        color: Theme.primary_container
                        radius: Vars.radiusMedium
                        border.color: ListView.isCurrentItem ? Theme.primary : "transparent"
                        border.width: 1
                        
                        function triggerAction() {
                            if (itemType === "bool") {
                                var newVal = itemVal === "true" ? "false" : "true";
                                settingsModel.setProperty(delegateIndex, "val", newVal);
                                updateVariable(itemKey, newVal);
                            } else if (itemType === "string" || itemType === "number") {
                                tInput.forceActiveFocus();
                            } else if (itemType === "enum") {
                                combo.forceActiveFocus();
                                combo.popup.open();
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                settingsList.currentIndex = delegateRoot.delegateIndex;
                            }
                        }
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Vars.spacingLarge
                            spacing: Vars.spacingMedium
                            
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                Text {
                                    text: delegateRoot.itemKey
                                    font.family: Vars.fontFamily
                                    font.pixelSize: 16
                                    font.bold: true
                                    color: Theme.on_primary_container
                                }
                                Text {
                                    text: delegateRoot.itemHelp
                                    font.family: Vars.fontFamily
                                    font.pixelSize: 12
                                    color: Theme.on_primary_container
                                    opacity: 0.8
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                            
                            Rectangle {
                                visible: delegateRoot.itemType === "bool"
                                width: 50; height: 28; radius: 14
                                color: delegateRoot.itemVal === "true" ? Theme.on_primary_container : Qt.rgba(Theme.on_primary_container.r, Theme.on_primary_container.g, Theme.on_primary_container.b, 0.3)
                                Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                                
                                Rectangle {
                                    width: 24; height: 24; radius: 12
                                    y: 2
                                    x: delegateRoot.itemVal === "true" ? 24 : 2
                                    color: Theme.primary_container
                                    Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                                }
                                
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var newVal = delegateRoot.itemVal === "true" ? "false" : "true";
                                        settingsModel.setProperty(delegateRoot.delegateIndex, "val", newVal);
                                        updateVariable(delegateRoot.itemKey, newVal);
                                    }
                                }
                            }
                            
                            Rectangle {
                                visible: delegateRoot.itemType === "string" || delegateRoot.itemType === "number"
                                width: 150; height: 32; radius: Vars.radiusSmall
                                color: Qt.rgba(Theme.on_primary_container.r, Theme.on_primary_container.g, Theme.on_primary_container.b, 0.1)
                                border.color: tInput.activeFocus ? Theme.on_primary_container : "transparent"
                                border.width: 1
                                
                                TextInput {
                                    id: tInput
                                    anchors.fill: parent
                                    anchors.leftMargin: 8; anchors.rightMargin: 8
                                    verticalAlignment: Text.AlignVCenter
                                    text: delegateRoot.itemVal
                                    font.family: Vars.fontFamily
                                    font.pixelSize: 14
                                    color: Theme.on_primary_container
                                    selectByMouse: true
                                    onEditingFinished: {
                                        settingsModel.setProperty(delegateRoot.delegateIndex, "val", text);
                                        updateVariable(delegateRoot.itemKey, text);
                                        tInput.focus = false;
                                        settingsList.forceActiveFocus();
                                    }
                                    Keys.onEscapePressed: {
                                        tInput.focus = false;
                                        settingsList.forceActiveFocus();
                                    }
                                }
                            }
                            
                            ComboBox {
                                id: combo
                                visible: delegateRoot.itemType === "enum"
                                width: 180; height: 32
                                model: visible ? delegateRoot.itemEnums.split("|||") : []
                                currentIndex: Math.max(0, combo.model.indexOf(delegateRoot.itemVal))
                                
                                onActivated: function(comboIdx) {
                                    var newVal = combo.textAt(comboIdx);
                                    settingsModel.setProperty(delegateRoot.delegateIndex, "val", newVal);
                                    updateVariable(delegateRoot.itemKey, newVal);
                                    settingsList.forceActiveFocus();
                                }
                                Keys.onEscapePressed: {
                                    settingsList.forceActiveFocus();
                                }
                                
                                background: Rectangle {
                                    color: Qt.rgba(Theme.on_primary_container.r, Theme.on_primary_container.g, Theme.on_primary_container.b, 0.1)
                                    radius: Vars.radiusSmall
                                }
                                contentItem: Text {
                                    text: combo.displayText
                                    font.family: Vars.fontFamily
                                    color: Theme.on_primary_container
                                    font.pixelSize: 14
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 10
                                    rightPadding: 28
                                    elide: Text.ElideRight
                                }
                                indicator: Text {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "\ue5cf"
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 18
                                    color: Theme.on_primary_container
                                }
                                delegate: ItemDelegate {
                                    width: combo.popup.width - 16
                                    height: 36
                                    contentItem: Text {
                                        text: modelData
                                        font.family: Vars.fontFamily
                                        color: Theme.on_primary_container
                                        font.pixelSize: 14
                                        verticalAlignment: Text.AlignVCenter
                                        leftPadding: 8
                                    }
                                    highlighted: combo.highlightedIndex === index
                                    background: Rectangle {
                                        radius: Vars.radiusSmall
                                        color: parent.highlighted ? Qt.rgba(Theme.on_primary_container.r, Theme.on_primary_container.g, Theme.on_primary_container.b, 0.12) : (parent.hovered ? Qt.rgba(Theme.on_primary_container.r, Theme.on_primary_container.g, Theme.on_primary_container.b, 0.06) : "transparent")
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                    }
                                }
                                popup: Popup {
                                    y: combo.height + 4
                                    width: Math.max(combo.width, 200)
                                    implicitHeight: contentItem.implicitHeight + 16
                                    padding: 8

                                    background: Rectangle {
                                        color: Theme.primary_container
                                        radius: Vars.radiusMedium
                                        border.color: Qt.rgba(Theme.on_primary_container.r, Theme.on_primary_container.g, Theme.on_primary_container.b, 0.15)
                                        border.width: 1
                                        layer.enabled: true
                                        layer.effect: MultiEffect {
                                            shadowEnabled: true
                                            shadowBlur: 0.8
                                            shadowColor: Qt.rgba(0, 0, 0, 0.3)
                                            shadowVerticalOffset: 4
                                        }
                                    }

                                    contentItem: ListView {
                                        clip: true
                                        implicitHeight: contentHeight
                                        model: combo.popup.visible ? combo.delegateModel : null
                                        currentIndex: combo.highlightedIndex
                                        boundsBehavior: Flickable.StopAtBounds
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }


    
    function updateVariable(key, val) {
        var strVal = String(val);
        console.log("[SettingsApp] Updating " + key + " to " + strVal);
        Quickshell.execDetached({ command: ["python3", Quickshell.env("HOME") + "/dotfiles/hypr/manager.py", "--" + key, strVal] });
    }

    onExpandedChanged: {
        if (expanded) {
            loadSettings();
        }
    }
    
    function loadSettings() {
        hyprManagerProc.running = true;
    }

    Process {
        id: hyprManagerProc
        command: ["python3", Quickshell.env("HOME") + "/dotfiles/hypr/manager.py", "-l"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n");
                var newVars = [];
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.length === 0) continue;
                    
                    var openBracketIdx = line.indexOf("[");
                    var closeBracketIdx = line.indexOf("]", openBracketIdx);
                    if (openBracketIdx === -1 || closeBracketIdx === -1) continue;
                    
                    var leftPart = line.substring(0, openBracketIdx).trim();
                    var valPart = line.substring(openBracketIdx + 1, closeBracketIdx);
                    
                    var dashIdx = line.indexOf("- ", closeBracketIdx);
                    var rawHelp = dashIdx !== -1 ? line.substring(dashIdx + 2).trim() : "";
                    var category = "General";
                    var pipeIdx = rawHelp.indexOf(" | ");
                    var helpPart = rawHelp;
                    if (pipeIdx !== -1) {
                        category = rawHelp.substring(0, pipeIdx).trim();
                        category = category.replace(/^-+\s*/, "");
                        helpPart = rawHelp.substring(pipeIdx + 3).trim();
                    }
                    
                    var colonIdx = leftPart.indexOf(":");
                    var key = leftPart.substring(0, colonIdx).trim();
                    var typePart = leftPart.substring(colonIdx + 1).trim();
                    
                    var type = "string";
                    var enums = [];
                    if (typePart === "togglable bool") {
                        type = "bool";
                    } else if (typePart.startsWith("enum")) {
                        type = "enum";
                        var match = typePart.match(/\((.*)\)/);
                        if (match) {
                            enums = match[1].split(",").map(function(s) { return s.trim(); });
                        }
                    } else if (typePart === "number" || typePart === "int") {
                        type = "number";
                    }
                    
                    newVars.push({ key: key, type: type, help: helpPart, enums: enums.join("|||"), val: valPart, category: category });
                }
                
                root.allVars = newVars;
                applyFilter();
            }
        }
    }
    
    function applyFilter() {
        var term = searchInput.text.trim().toLowerCase();
        settingsModel.clear();
        for (var k = 0; k < root.allVars.length; k++) {
            var v = root.allVars[k];
            if (term === "" || v.key.toLowerCase().indexOf(term) !== -1 || v.help.toLowerCase().indexOf(term) !== -1 || v.category.toLowerCase().indexOf(term) !== -1) {
                settingsModel.append(v);
            }
        }
    }
}
