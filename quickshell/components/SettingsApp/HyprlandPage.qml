import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../.."
import "../../Variables/variables.js" as Vars

ColumnLayout {
    id: rootPage
    
    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Vars.spacingMedium

    property var allVars: []

    function updateVariable(key, val) {
        var proc = Qt.createQmlObject('import Quickshell.Io; Process { command: ["hypr-manager", "set", "' + key + '", "' + val + '"]; onExited: destroy() }', rootPage);
        proc.running = true;
    }

    function loadSettings() {
        hyprManagerProc.running = true;
    }

    Component.onCompleted: {
        loadSettings();
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        Text {
            text: "Hyprland Configuration"
            font.family: Vars.fontFamily
            font.pixelSize: 16
            font.weight: 500
            color: Theme.on_surface
        }
        Text {
            text: "Configuration, appearance, and window behavior"
            font.family: Vars.fontFamily
            font.pixelSize: 12
            color: Theme.on_surface
            opacity: 0.7
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 72
        color: Theme.surface_container
        radius: 16
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 16
            Text {
                text: "search"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 24
                color: Theme.on_surface
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
            Button {
                onClicked: loadSettings()
                background: Rectangle {
                    color: refreshBtnHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.1) : "transparent"
                    radius: 16
                }
                contentItem: Text { text: "Refresh"; color: Theme.on_surface; font.family: Vars.fontFamily; font.bold: true }
                MouseArea { id: refreshBtnHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: loadSettings() }
            }
        }
    }

    ListModel {
        id: settingsModel
    }

    ListView {
        id: settingsList
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 4
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
        section.labelPositioning: ViewSection.InlineLabels
        section.delegate: Item {
            width: ListView.view.width
            height: 50
            z: 2
            
            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: section
                color: Theme.primary
                font.pixelSize: 14
                font.bold: true
                font.family: Vars.fontFamily
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
            property bool isSelected: false
            radius: 16
            color: delegateMouse.containsMouse ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : Theme.surface_container
            Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
            
            Rectangle {
                width: parent.radius; height: parent.radius; color: parent.color
                anchors.top: parent.top; anchors.left: parent.left
                opacity: (index > 0 && settingsModel.get(index).category === settingsModel.get(index - 1).category) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
            }
            Rectangle {
                width: parent.radius; height: parent.radius; color: parent.color
                anchors.top: parent.top; anchors.right: parent.right
                opacity: (index > 0 && settingsModel.get(index).category === settingsModel.get(index - 1).category) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
            }
            Rectangle {
                width: parent.radius; height: parent.radius; color: parent.color
                anchors.bottom: parent.bottom; anchors.left: parent.left
                opacity: (index < settingsModel.count - 1 && settingsModel.get(index).category === settingsModel.get(index + 1).category) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
            }
            Rectangle {
                width: parent.radius; height: parent.radius; color: parent.color
                anchors.bottom: parent.bottom; anchors.right: parent.right
                opacity: (index < settingsModel.count - 1 && settingsModel.get(index).category === settingsModel.get(index + 1).category) ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
            }
            
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
                id: delegateMouse
                anchors.fill: parent
                hoverEnabled: true
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
                        color: Theme.on_surface
                    }
                    Text {
                        text: delegateRoot.itemHelp
                        font.family: Vars.fontFamily
                        font.pixelSize: 12
                        color: Theme.on_surface_variant
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
                
                Rectangle {
                    visible: delegateRoot.itemType === "bool"
                    width: 52; height: 32; radius: 16
                    color: delegateRoot.itemVal === "true" ? Theme.primary : Theme.surface_variant
                    border.color: delegateRoot.activeFocus ? Theme.on_surface : "transparent"; border.width: delegateRoot.activeFocus ? 2 : 0
                    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                    
                    Rectangle {
                        width: 24; height: 24; radius: 12
                        color: delegateRoot.itemVal === "true" ? Theme.on_primary : Theme.on_surface_variant
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left; anchors.leftMargin: delegateRoot.itemVal === "true" ? 24 : 4
                        Behavior on anchors.leftMargin { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                        
                        Text {
                            anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 16
                            color: delegateRoot.itemVal === "true" ? Theme.primary : Theme.surface_variant
                            text: delegateRoot.itemVal === "true" ? "\ue5ca" : "\ue5cd"
                        }
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
                    color: Theme.surface_container_highest
                    border.color: tInput.activeFocus ? Theme.primary : "transparent"
                    border.width: 1
                    
                    TextInput {
                        id: tInput
                        anchors.fill: parent
                        anchors.leftMargin: 8; anchors.rightMargin: 8
                        verticalAlignment: Text.AlignVCenter
                        text: delegateRoot.itemVal
                        font.family: Vars.fontFamily
                        font.pixelSize: 14
                        color: Theme.on_surface
                        selectByMouse: true
                        onAccepted: {
                            tInput.focus = false;
                            settingsList.forceActiveFocus();
                        }
                        onEditingFinished: {
                            if (text !== delegateRoot.itemVal) {
                                settingsModel.setProperty(delegateRoot.delegateIndex, "val", text);
                                updateVariable(delegateRoot.itemKey, text);
                            }
                        }
                        Keys.onEscapePressed: {
                            text = delegateRoot.itemVal;
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
                        color: Theme.surface_container_highest
                        radius: Vars.radiusSmall
                    }
                    contentItem: Text {
                        text: combo.displayText
                        font.family: Vars.fontFamily
                        color: Theme.on_surface
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
                        color: Theme.on_surface
                    }
                    delegate: ItemDelegate {
                        width: combo.popup.width - 16
                        height: 36
                        contentItem: Text {
                            text: modelData
                            font.family: Vars.fontFamily
                            color: Theme.on_surface
                            font.pixelSize: 14
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 8
                        }
                        highlighted: combo.highlightedIndex === index
                        background: Rectangle {
                            radius: Vars.radiusSmall
                            color: parent.highlighted ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (parent.hovered ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.06) : "transparent")
                            Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                        }
                    }
                    popup: Popup {
                        y: combo.height + 4
                        width: Math.max(combo.width, 200)
                        implicitHeight: contentItem.implicitHeight + 16
                        padding: 8

                        background: Rectangle {
                            color: Theme.surface_container_high
                            radius: Vars.radiusMedium
                            border.color: Theme.outline_variant
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

    Process {
        id: hyprManagerProc
        command: ["hypr-manager", "-l"]
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
                
                rootPage.allVars = newVars;
                applyFilter();
            }
        }
    }
    
    function applyFilter() {
        var term = searchInput.text.trim();
        settingsModel.clear();
        for (var k = 0; k < rootPage.allVars.length; k++) {
            var v = rootPage.allVars[k];
            if (term === "" || Vars.fuzzyMatch(term, v.key) || Vars.fuzzyMatch(term, v.help) || Vars.fuzzyMatch(term, v.category)) {
                settingsModel.append(v);
            }
        }
    }
}
