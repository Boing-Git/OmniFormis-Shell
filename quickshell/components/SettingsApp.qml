import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
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
    
    property string currentSection: "hyprland" // "hyprland", "wifi", "bluetooth"
    
    // Wi-Fi
    property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
    property var activeNet: wifiDevice ? wifiDevice.networks.values.find(n => n.connected) : null
    property var wifiSignal: activeNet ? activeNet.signalStrength : 0

    readonly property string wifiIcon: {
        if (!Networking.wifiEnabled) return "\ue1da"; 
        if (!activeNet) return "\uf067"; 
        let tier = Math.min(Math.floor(wifiSignal / 25), 3);
        let icons = ["\ue1ba", "\uebe4", "\uebd6", "\uebe1"];
        return icons[tier];
    }
    
    // Bluetooth
    property var adapter: Bluetooth.defaultAdapter
    property bool adapterState: adapter ? adapter.enabled : false
    property var connectDevice: adapter ? adapter.devices.values.find(d => d.connected) : null

    readonly property string bluetoothIcon: {
        if (!adapterState) return "\ue1a9"; 
        if (!connectDevice) return "\ue1a7"; 
        return "\ue1a8"; 
    }
    
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
        
        width: root.expanded ? 900 : 100
        height: root.expanded ? 650 : 40
        
        color: Theme.surface_container_low
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

            RowLayout {
                anchors.fill: parent
                spacing: Vars.spacingLarge

                // Sidebar
                ColumnLayout {
                    Layout.preferredWidth: 280
                    Layout.maximumWidth: 280
                    Layout.fillHeight: true
                    spacing: Vars.spacingMedium

                    // Header
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Vars.spacingMedium

                        Rectangle {
                            width: 48; height: 48; radius: Vars.radiusMedium
                            color: backHover.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (backHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                            Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: Theme.on_surface; text: "\ue5cd" }
                            MouseArea { id: backHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.expanded = false }
                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                        }
                        
                        Text {
                            text: "Settings"
                            font.family: Vars.fontFamily
                            font.pixelSize: 24
                            font.weight: 700
                            color: Theme.on_surface
                        }
                    }

                    Item { Layout.preferredHeight: Vars.spacingSmall }

                    // Navigation Items
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Repeater {
                            model: [
                                { id: "hyprland", name: "Hyprland", subtitle: "Configuration, appearance", icon: "\ue8b8" }, // settings
                                { id: "wifi", name: "Wi-Fi", subtitle: "Wi-Fi, ethernet", icon: root.wifiIcon },
                                { id: "bluetooth", name: "Bluetooth", subtitle: "Bluetooth, pairing", icon: root.bluetoothIcon }
                            ]
                            delegate: Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 72
                                property bool isSelected: root.currentSection === modelData.id
                                radius: isSelected ? height / 2 : 16
                                Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                color: isSelected ? Theme.secondary_container : (navHover.containsMouse ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : Theme.surface_container)
                                border.color: activeFocus ? Theme.on_surface : "transparent"
                                border.width: activeFocus ? 2 : 0
                                activeFocusOnTab: true
                                Keys.onSpacePressed: root.currentSection = modelData.id
                                Keys.onReturnPressed: root.currentSection = modelData.id
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                                
                                // Square-off top corners if not the first item
                                Rectangle {
                                    width: parent.radius; height: parent.radius; color: parent.color
                                    anchors.top: parent.top; anchors.left: parent.left
                                    opacity: (index > 0 && !parent.isSelected) ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                }
                                Rectangle {
                                    width: parent.radius; height: parent.radius; color: parent.color
                                    anchors.top: parent.top; anchors.right: parent.right
                                    opacity: (index > 0 && !parent.isSelected) ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                }
                                // Square-off bottom corners if not the last item
                                Rectangle {
                                    width: parent.radius; height: parent.radius; color: parent.color
                                    anchors.bottom: parent.bottom; anchors.left: parent.left
                                    opacity: (index < 2 && !parent.isSelected) ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                }
                                Rectangle {
                                    width: parent.radius; height: parent.radius; color: parent.color
                                    anchors.bottom: parent.bottom; anchors.right: parent.right
                                    opacity: (index < 2 && !parent.isSelected) ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 20
                                    anchors.rightMargin: 20
                                    spacing: 16
                                    
                                    Text {
                                        text: modelData.icon
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 24
                                        color: parent.isSelected ? Theme.on_secondary_container : Theme.on_surface_variant
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text {
                                            text: modelData.name
                                            font.family: Vars.fontFamily
                                            font.pixelSize: 16
                                            font.weight: parent.isSelected ? 500 : 400
                                            color: parent.isSelected ? Theme.on_secondary_container : Theme.on_surface
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignLeft
                                        }
                                        Text {
                                            text: modelData.subtitle
                                            font.family: Vars.fontFamily
                                            font.pixelSize: 12
                                            color: parent.isSelected ? Theme.on_secondary_container : Theme.on_surface_variant
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignLeft
                                            opacity: 0.9
                                        }
                                    }
                                }
                                
                                MouseArea {
                                    id: navHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.currentSection = modelData.id
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }

                // Vertical Divider
                Rectangle {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 1
                    color: Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.2)
                }

                // Content Area
                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: root.currentSection === "hyprland" ? 0 : (root.currentSection === "wifi" ? 1 : 2)

                    // 0: Hyprland Settings
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: Vars.spacingMedium

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
                            // Roles: key, type, help, enums, val, category
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
                        
                        // Square-off top corners if not the first in section
                        Rectangle {
                            width: parent.radius; height: parent.radius; color: parent.color
                            anchors.top: parent.top; anchors.left: parent.left
                            opacity: (index > 0 && settingsModel.get(index).category === settingsModel.get(index - 1).category) && !delegateMouse.containsMouse ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                        }
                        Rectangle {
                            width: parent.radius; height: parent.radius; color: parent.color
                            anchors.top: parent.top; anchors.right: parent.right
                            opacity: (index > 0 && settingsModel.get(index).category === settingsModel.get(index - 1).category) && !delegateMouse.containsMouse ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                        }
                        // Square-off bottom corners if not the last in section
                        Rectangle {
                            width: parent.radius; height: parent.radius; color: parent.color
                            anchors.bottom: parent.bottom; anchors.left: parent.left
                            opacity: (index < settingsModel.count - 1 && settingsModel.get(index).category === settingsModel.get(index + 1).category) && !delegateMouse.containsMouse ? 1.0 : 0.0
                            Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                        }
                        Rectangle {
                            width: parent.radius; height: parent.radius; color: parent.color
                            anchors.bottom: parent.bottom; anchors.right: parent.right
                            opacity: (index < settingsModel.count - 1 && settingsModel.get(index).category === settingsModel.get(index + 1).category) && !delegateMouse.containsMouse ? 1.0 : 0.0
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
                                        text = delegateRoot.itemVal; // Restore original text
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
                    }

                    // 1: Wi-Fi Settings
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: Vars.spacingMedium

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Wi-Fi Networks"
                                font.family: Vars.fontFamily
                                font.pixelSize: 16
                                font.weight: 500
                                color: Theme.on_surface
                            }
                            Text {
                                text: "Network connection and internet availability"
                                font.family: Vars.fontFamily
                                font.pixelSize: 12
                                color: Theme.on_surface
                                opacity: 0.7
                            }
                        }

                        Flickable {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            contentHeight: wifiContent.childrenRect.height; clip: true

                            ColumnLayout {
                                id: wifiContent
                                width: parent.width; spacing: Vars.spacingSmall

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    // Wi-Fi Header Card
                                    Rectangle {
                                        id: wifiHeader
                                        Layout.fillWidth: true; Layout.preferredHeight: 72
                                        radius: 16; color: wifiHeaderMouse.containsMouse ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : Theme.surface_container
                                        Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                                        
                                        // Square bottom corners if enabled
                                        Rectangle { width: 16; height: 16; color: parent.color; anchors.bottom: parent.bottom; anchors.left: parent.left; visible: Networking.wifiEnabled; opacity: wifiHeaderMouse.containsMouse ? 0.0 : 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } } }
                                        Rectangle { width: 16; height: 16; color: parent.color; anchors.bottom: parent.bottom; anchors.right: parent.right; visible: Networking.wifiEnabled; opacity: wifiHeaderMouse.containsMouse ? 0.0 : 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } } }
                                        
                                        activeFocusOnTab: true
                                        Keys.onSpacePressed: Networking.wifiEnabled = !Networking.wifiEnabled
                                        Keys.onReturnPressed: Networking.wifiEnabled = !Networking.wifiEnabled
                                        
                                        RowLayout {
                                            anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20
                                            Text { text: "Wi-Fi"; font.family: Vars.fontFamily; font.pixelSize: 16; font.weight: 500; color: Theme.on_surface; Layout.fillWidth: true }
                                            
                                            // Master Toggle
                                            Rectangle {
                                                width: 52; height: 32; radius: 16
                                                color: Networking.wifiEnabled ? Theme.primary : Theme.surface_variant
                                                border.color: wifiHeader.activeFocus ? Theme.on_surface : "transparent"
                                                border.width: wifiHeader.activeFocus ? 2 : 0
                                                Rectangle {
                                                    width: 24; height: 24; radius: 12
                                                    color: Networking.wifiEnabled ? Theme.on_primary : Theme.on_surface_variant
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    anchors.left: parent.left; anchors.leftMargin: Networking.wifiEnabled ? 24 : 4
                                                    Behavior on anchors.leftMargin { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                                                    Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 16; color: Networking.wifiEnabled ? Theme.primary : Theme.surface_variant; text: Networking.wifiEnabled ? "\ue5ca" : "\ue5cd" }
                                                }
                                            }
                                        }
                                        MouseArea { id: wifiHeaderMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: { wifiHeader.forceActiveFocus(); Networking.wifiEnabled = !Networking.wifiEnabled; } }
                                    }

                                    // Empty state (only if enabled and no networks)
                                    Rectangle {
                                        Layout.fillWidth: true; Layout.preferredHeight: 120
                                        visible: Networking.wifiEnabled && (!wifiDevice || wifiDevice.networks.values.length === 0)
                                        radius: 16; color: Theme.surface_container
                                        
                                        Rectangle { width: 16; height: 16; color: parent.color; anchors.top: parent.top; anchors.left: parent.left }
                                        Rectangle { width: 16; height: 16; color: parent.color; anchors.top: parent.top; anchors.right: parent.right }
                                        Rectangle { width: 16; height: 16; color: parent.color; anchors.bottom: parent.bottom; anchors.left: parent.left }
                                        Rectangle { width: 16; height: 16; color: parent.color; anchors.bottom: parent.bottom; anchors.right: parent.right }
                                        
                                        ColumnLayout {
                                            anchors.centerIn: parent; spacing: 8
                                            Text { text: "\ue63e"; font.family: "Material Symbols Outlined"; font.pixelSize: 32; color: Theme.on_surface_variant; Layout.alignment: Qt.AlignHCenter } // Wifi off icon
                                            Text { text: "No networks found"; font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface_variant; Layout.alignment: Qt.AlignHCenter }
                                        }
                                    }

                                    // Wi-Fi List
                                    Repeater {
                                        model: wifiDevice && Networking.wifiEnabled ? wifiDevice.networks.values : []
                                        delegate: Rectangle {
                                            id: wifiDelegate
                                            Layout.fillWidth: true; Layout.preferredHeight: 72
                                            property bool isSelected: modelData.connected
                                            property bool showForget: false
                                            radius: isSelected ? height / 2 : 16
                                            Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                            color: isSelected ? Theme.secondary_container : (wifiMouse.containsMouse ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : Theme.surface_container)
                                            Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                                            
                                            Rectangle {
                                                width: parent.radius; height: parent.radius; color: parent.color
                                                anchors.top: parent.top; anchors.left: parent.left
                                                opacity: parent.isSelected || wifiMouse.containsMouse ? 0.0 : 1.0
                                                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                            }
                                            Rectangle {
                                                width: parent.radius; height: parent.radius; color: parent.color
                                                anchors.top: parent.top; anchors.right: parent.right
                                                opacity: parent.isSelected || wifiMouse.containsMouse ? 0.0 : 1.0
                                                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                            }
                                            Rectangle {
                                                width: parent.radius; height: parent.radius; color: parent.color
                                                anchors.bottom: parent.bottom; anchors.left: parent.left
                                                opacity: parent.isSelected || wifiMouse.containsMouse ? 0.0 : 1.0
                                                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                            }
                                            Rectangle {
                                                width: parent.radius; height: parent.radius; color: parent.color
                                                anchors.bottom: parent.bottom; anchors.right: parent.right
                                                opacity: parent.isSelected || wifiMouse.containsMouse ? 0.0 : 1.0
                                                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                            }
                                            
                                            RowLayout {
                                                anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 16
                                                
                                                Text {
                                                    font.family: "Material Symbols Outlined"; font.pixelSize: 24
                                                    color: modelData.connected ? Theme.primary : Theme.on_surface_variant
                                                    text: {
                                                        if (modelData.signalStrength === undefined) return "\ue63e";
                                                        let tier = Math.min(Math.floor(modelData.signalStrength / 25), 3);
                                                        return ["\ue1ba", "\uebe4", "\uebd6", "\uebe1"][tier] || "\ue63e";
                                                    }
                                                }
                                                
                                                ColumnLayout {
                                                    Layout.alignment: Qt.AlignVCenter; spacing: 0; Layout.fillWidth: true
                                                    Text { 
                                                        text: modelData.name; font.family: Vars.fontFamily; font.pixelSize: 16
                                                        color: Theme.on_surface
                                                        Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft
                                                    }
                                                    Text { 
                                                        text: modelData.connected ? "Connected" : "Available"
                                                        font.family: Vars.fontFamily; font.pixelSize: 11; font.weight: 500
                                                        color: Theme.on_surface_variant
                                                        Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft
                                                    }
                                                }
                                            }
                                            MouseArea {
                                                id: wifiMouse
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                onClicked: (mouse) => {
                                                    wifiDelegate.forceActiveFocus();
                                                    if (mouse.button === Qt.RightButton) {
                                                        wifiDelegate.showForget = true;
                                                    } else {
                                                        if (modelData.connected) {
                                                            modelData.disconnect();
                                                        } else {
                                                            if (modelData.saved || modelData.known || modelData.security === "none" || modelData.security === 0) {
                                                                modelData.connect();
                                                            } else {
                                                                wifiPasswordPopup.targetNetwork = modelData;
                                                                wifiPasswordPopup.open();
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            // Forget Overlay
                                            Rectangle {
                                                anchors.fill: parent
                                                radius: parent.radius
                                                color: Theme.surface_container_highest
                                                visible: wifiDelegate.showForget
                                                opacity: wifiDelegate.showForget ? 1.0 : 0.0
                                                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                                
                                                RowLayout {
                                                    anchors.fill: parent; anchors.margins: 16; spacing: 16
                                                    Text {
                                                        text: "Forget " + (modelData.name || "Network") + "?"
                                                        font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface; Layout.fillWidth: true; elide: Text.ElideRight
                                                    }
                                                    Rectangle {
                                                        width: 80; height: 32; radius: 16; color: "transparent"
                                                        border.color: Theme.outline; border.width: 1
                                                        Text { anchors.centerIn: parent; text: "Cancel"; color: Theme.on_surface; font.family: Vars.fontFamily; font.pixelSize: 14 }
                                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: wifiDelegate.showForget = false }
                                                    }
                                                    Rectangle {
                                                        width: 80; height: 32; radius: 16; color: Theme.error ? Theme.error : "#ffb4ab"
                                                        Text { anchors.centerIn: parent; text: "Forget"; color: Theme.on_error ? Theme.on_error : "#690005"; font.family: Vars.fontFamily; font.pixelSize: 14; font.weight: 500 }
                                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (modelData.forget) modelData.forget(); wifiDelegate.showForget = false; } }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Scan for Networks Card
                                    Rectangle {
                                        id: scanCard
                                        Layout.fillWidth: true; Layout.preferredHeight: 72
                                        visible: Networking.wifiEnabled
                                        radius: 16; color: scanMouse.containsMouse ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : Theme.surface_container
                                        Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                                        
                                        Rectangle { 
                                            width: 16; height: 16; color: parent.color; anchors.top: parent.top; anchors.left: parent.left 
                                            opacity: scanMouse.containsMouse ? 0.0 : 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                        }
                                        Rectangle { 
                                            width: 16; height: 16; color: parent.color; anchors.top: parent.top; anchors.right: parent.right 
                                            opacity: scanMouse.containsMouse ? 0.0 : 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                        }
                                        
                                        activeFocusOnTab: true
                                        Keys.onSpacePressed: { if(wifiDevice) wifiDevice.scannerEnabled = !wifiDevice.scannerEnabled }
                                        Keys.onReturnPressed: { if(wifiDevice) wifiDevice.scannerEnabled = !wifiDevice.scannerEnabled }
                                        
                                        RowLayout {
                                            anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 16
                                            Text { 
                                                id: wifiScanIcon
                                                text: "\ue863"; font.family: "Material Symbols Outlined"; font.pixelSize: 24; 
                                                color: wifiDevice && wifiDevice.scannerEnabled ? Theme.primary : Theme.on_surface 
                                                RotationAnimation {
                                                    target: wifiScanIcon; property: "rotation"
                                                    loops: Animation.Infinite; from: 0; to: 360; duration: 2000; running: wifiDevice && wifiDevice.scannerEnabled
                                                    onRunningChanged: if (!running) wifiScanIcon.rotation = 0
                                                }
                                            }
                                            Text { text: (wifiDevice && wifiDevice.scannerEnabled) ? "Scanning..." : "Scan for Networks"; font.family: Vars.fontFamily; font.pixelSize: 16; font.weight: 500; color: Theme.on_surface; Layout.fillWidth: true }
                                        }
                                        MouseArea { id: scanMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { scanCard.forceActiveFocus(); if(wifiDevice) wifiDevice.scannerEnabled = !wifiDevice.scannerEnabled; } }
                                    }
                                }
                            }
                        }
                    }

                    // 2: Bluetooth Settings
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: Vars.spacingMedium

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "Bluetooth"
                                font.family: Vars.fontFamily
                                font.pixelSize: 16
                                font.weight: 500
                                color: Theme.on_surface
                            }
                            Text {
                                text: "Manage devices and discoverability"
                                font.family: Vars.fontFamily
                                font.pixelSize: 12
                                color: Theme.on_surface
                                opacity: 0.7
                            }
                        }

                        Flickable {
                            Layout.fillWidth: true; Layout.fillHeight: true
                            contentHeight: btContent.childrenRect.height; clip: true

                            ColumnLayout {
                                id: btContent
                                width: parent.width; spacing: Vars.spacingSmall
                                property bool isPairingMode: false

                                // --- MAIN BLUETOOTH VIEW ---
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: Vars.spacingSmall
                                    visible: !btContent.isPairingMode

                                    // Main Bluetooth Group
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    // Bluetooth Header Card
                                    Rectangle {
                                        id: btHeader
                                        Layout.fillWidth: true; Layout.preferredHeight: 72
                                        radius: 16; 
                                        color: btHeaderMouse.containsMouse ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : Theme.surface_container
                                        Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                                        
                                        property bool hasDeviceBelow: {
                                            if (!adapter || !adapter.devices.values) return false;
                                            for (let i = 0; i < adapter.devices.values.length; ++i) {
                                                let d = adapter.devices.values[i];
                                                if (d && (d.paired || d.connected)) return true;
                                            }
                                            return false;
                                        }
                                        
                                        // Square bottom corners if there are paired devices below
                                        Rectangle { width: 16; height: 16; color: parent.color; anchors.bottom: parent.bottom; anchors.left: parent.left; visible: adapterState && parent.hasDeviceBelow; opacity: btHeaderMouse.containsMouse ? 0.0 : 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } } }
                                        Rectangle { width: 16; height: 16; color: parent.color; anchors.bottom: parent.bottom; anchors.right: parent.right; visible: adapterState && parent.hasDeviceBelow; opacity: btHeaderMouse.containsMouse ? 0.0 : 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } } }
                                        
                                        activeFocusOnTab: true
                                        Keys.onSpacePressed: if(adapter) adapter.enabled = !adapter.enabled
                                        Keys.onReturnPressed: if(adapter) adapter.enabled = !adapter.enabled
                                        
                                        RowLayout {
                                            anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20
                                            Text { text: "Bluetooth"; font.family: Vars.fontFamily; font.pixelSize: 16; font.weight: 500; color: Theme.on_surface; Layout.fillWidth: true }
                                            
                                            // Master Toggle
                                            Rectangle {
                                                width: 52; height: 32; radius: 16
                                                color: adapterState ? Theme.primary : Theme.surface_variant
                                                border.color: btHeader.activeFocus ? Theme.on_surface : "transparent"
                                                border.width: btHeader.activeFocus ? 2 : 0
                                                Rectangle {
                                                    width: 24; height: 24; radius: 12
                                                    color: adapterState ? Theme.on_primary : Theme.on_surface_variant
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    anchors.left: parent.left; anchors.leftMargin: adapterState ? 24 : 4
                                                    Behavior on anchors.leftMargin { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                                                    Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 16; color: adapterState ? Theme.primary : Theme.surface_variant; text: adapterState ? "\ue5ca" : "\ue5cd" }
                                                }
                                            }
                                        }
                                        MouseArea { id: btHeaderMouse; anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true; onClicked: { btHeader.forceActiveFocus(); if(adapter) adapter.enabled = !adapter.enabled; } }
                                    }

                                    // Empty state (only if enabled and no devices)
                                    Rectangle {
                                        Layout.fillWidth: true; Layout.preferredHeight: 120
                                        visible: adapterState && (!adapter || adapter.devices.values.length === 0)
                                        radius: 16; color: Theme.surface_container
                                        
                                        Rectangle { width: 16; height: 16; color: parent.color; anchors.top: parent.top; anchors.left: parent.left }
                                        Rectangle { width: 16; height: 16; color: parent.color; anchors.top: parent.top; anchors.right: parent.right }
                                        Rectangle { width: 16; height: 16; color: parent.color; anchors.bottom: parent.bottom; anchors.left: parent.left }
                                        Rectangle { width: 16; height: 16; color: parent.color; anchors.bottom: parent.bottom; anchors.right: parent.right }
                                        
                                        ColumnLayout {
                                            anchors.centerIn: parent; spacing: 8
                                            Text { text: "\ue322"; font.family: "Material Symbols Outlined"; font.pixelSize: 32; color: Theme.on_surface_variant; Layout.alignment: Qt.AlignHCenter } // Devices icon
                                            Text { text: "No saved devices"; font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface_variant; Layout.alignment: Qt.AlignHCenter }
                                        }
                                    }

                                    // Device List
                                    Repeater {
                                        model: adapter && adapterState ? adapter.devices.values : []
                                        delegate: Rectangle {
                                            id: btDelegate
                                            Layout.fillWidth: true; Layout.preferredHeight: visible ? 72 : 0
                                            visible: modelData.paired || modelData.connected
                                            property bool isSelected: modelData.connected
                                            property bool showForget: false
                                            radius: isSelected ? height / 2 : 16
                                            Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                            color: isSelected ? Theme.secondary_container : (btMouse.containsMouse ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : Theme.surface_container)
                                            Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                                            
                                            Rectangle {
                                                width: parent.radius; height: parent.radius; color: parent.color
                                                anchors.top: parent.top; anchors.left: parent.left
                                                opacity: parent.isSelected || btMouse.containsMouse ? 0.0 : 1.0
                                                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                            }
                                            property bool hasDeviceBelow: {
                                                if (!adapter || !adapter.devices.values) return false;
                                                for (let i = index + 1; i < adapter.devices.values.length; ++i) {
                                                    let d = adapter.devices.values[i];
                                                    if (d && (d.paired || d.connected)) return true;
                                                }
                                                return false;
                                            }
                                            
                                            Rectangle {
                                                width: parent.radius; height: parent.radius; color: parent.color
                                                anchors.bottom: parent.bottom; anchors.left: parent.left
                                                visible: parent.hasDeviceBelow
                                                opacity: parent.isSelected || btMouse.containsMouse ? 0.0 : 1.0
                                                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                            }
                                            Rectangle {
                                                width: parent.radius; height: parent.radius; color: parent.color
                                                anchors.bottom: parent.bottom; anchors.right: parent.right
                                                visible: parent.hasDeviceBelow
                                                opacity: parent.isSelected || btMouse.containsMouse ? 0.0 : 1.0
                                                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                            }


                                            activeFocusOnTab: true
                                            Keys.onSpacePressed: { if (modelData.connected) modelData.disconnect(); else modelData.connect(); }
                                            Keys.onReturnPressed: { if (modelData.connected) modelData.disconnect(); else modelData.connect(); }
                                            
                                            RowLayout {
                                                anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 16
                                                Text { text: modelData.connected ? "\ue1a8" : "\ue1a7"; font.family: "Material Symbols Outlined"; font.pixelSize: 24; color: modelData.connected ? Theme.primary : Theme.on_surface_variant }
                                                ColumnLayout {
                                                    Layout.alignment: Qt.AlignVCenter; spacing: 0; Layout.fillWidth: true
                                                    Text { text: modelData.name ? modelData.name : "Unknown Device"; font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface; Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft }
                                                    Text { text: modelData.connected ? "Connected" : "Available"; font.family: Vars.fontFamily; font.pixelSize: 11; font.weight: 500; color: Theme.on_surface_variant; visible: text !== ""; Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft }
                                                }
                                            }
                                            MouseArea {
                                                id: btMouse
                                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor; hoverEnabled: true
                                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                onClicked: (mouse) => {
                                                    parent.forceActiveFocus();
                                                    if (mouse.button === Qt.RightButton) {
                                                        btDelegate.showForget = true;
                                                    } else {
                                                        if (modelData.connected) modelData.disconnect(); else modelData.connect();
                                                    }
                                                }
                                            }
                                            
                                            // Forget Overlay
                                            Rectangle {
                                                anchors.fill: parent
                                                radius: parent.radius
                                                color: Theme.surface_container_highest
                                                visible: btDelegate.showForget
                                                opacity: btDelegate.showForget ? 1.0 : 0.0
                                                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                                
                                                RowLayout {
                                                    anchors.fill: parent; anchors.margins: 16; spacing: 16
                                                    Text {
                                                        text: "Forget " + (modelData.name || "Device") + "?"
                                                        font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface; Layout.fillWidth: true; elide: Text.ElideRight
                                                    }
                                                    Rectangle {
                                                        width: 80; height: 32; radius: 16; color: "transparent"
                                                        border.color: Theme.outline; border.width: 1
                                                        Text { anchors.centerIn: parent; text: "Cancel"; color: Theme.on_surface; font.family: Vars.fontFamily; font.pixelSize: 14 }
                                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: btDelegate.showForget = false }
                                                    }
                                                    Rectangle {
                                                        width: 80; height: 32; radius: 16; color: Theme.error ? Theme.error : "#ffb4ab"
                                                        Text { anchors.centerIn: parent; text: "Forget"; color: Theme.on_error ? Theme.on_error : "#690005"; font.family: Vars.fontFamily; font.pixelSize: 14; font.weight: 500 }
                                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (modelData.forget) modelData.forget(); btDelegate.showForget = false; } }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Pair new device
                                    Rectangle {
                                        Layout.fillWidth: true; Layout.preferredHeight: 72
                                        visible: adapterState
                                        radius: 16; color: btPairMouse.containsMouse ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : Theme.surface_container
                                        Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                                        
                                        Rectangle { 
                                            width: 16; height: 16; color: parent.color; anchors.top: parent.top; anchors.left: parent.left 
                                            opacity: btPairMouse.containsMouse ? 0.0 : 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                        }
                                        Rectangle { 
                                            width: 16; height: 16; color: parent.color; anchors.top: parent.top; anchors.right: parent.right 
                                            opacity: btPairMouse.containsMouse ? 0.0 : 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                        }
                                        
                                        activeFocusOnTab: true
                                        Keys.onSpacePressed: parent.forceActiveFocus()
                                        Keys.onReturnPressed: parent.forceActiveFocus()
                                        
                                        RowLayout {
                                            anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 16
                                            Text { text: "\ue145"; font.family: "Material Symbols Outlined"; font.pixelSize: 24; color: Theme.on_surface }
                                            Text { text: "Pair new device"; font.family: Vars.fontFamily; font.pixelSize: 16; font.weight: 500; color: Theme.on_surface; Layout.fillWidth: true }
                                        }
                                        MouseArea { id: btPairMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { parent.forceActiveFocus(); btContent.isPairingMode = true; } }
                                    }
                                }

                                Item { Layout.preferredHeight: Vars.spacingSmall }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    // Discoverable Card
                                    Rectangle {
                                        id: discCard
                                        Layout.fillWidth: true; Layout.preferredHeight: 72; radius: 16; color: discMouse.containsMouse ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : Theme.surface_container
                                        Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                                        visible: adapterState
                                        
                                        Rectangle { 
                                            width: 16; height: 16; color: parent.color; anchors.bottom: parent.bottom; anchors.left: parent.left 
                                            opacity: discMouse.containsMouse ? 0.0 : 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                        }
                                        Rectangle { 
                                            width: 16; height: 16; color: parent.color; anchors.bottom: parent.bottom; anchors.right: parent.right 
                                            opacity: discMouse.containsMouse ? 0.0 : 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                        }
                                        
                                        activeFocusOnTab: true
                                        Keys.onSpacePressed: if(adapter) adapter.discoverable = !adapter.discoverable
                                        Keys.onReturnPressed: if(adapter) adapter.discoverable = !adapter.discoverable
                                        
                                        RowLayout {
                                            anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 16
                                            ColumnLayout {
                                                Layout.fillWidth: true; spacing: 2
                                                Text { text: "Discoverable"; font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface; Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft }
                                                Text { text: "Allow nearby devices to find this one"; font.family: Vars.fontFamily; font.pixelSize: 13; color: Theme.on_surface_variant; Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft }
                                            }
                                            Rectangle {
                                                width: 52; height: 32; radius: 16; color: adapter && adapter.discoverable ? Theme.primary : Theme.surface_variant
                                                border.color: discCard.activeFocus ? Theme.on_surface : "transparent"; border.width: discCard.activeFocus ? 2 : 0
                                                Rectangle {
                                                    width: 24; height: 24; radius: 12; color: adapter && adapter.discoverable ? Theme.on_primary : Theme.on_surface_variant
                                                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: adapter && adapter.discoverable ? 24 : 4
                                                    Behavior on anchors.leftMargin { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                                                    Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 16; color: adapter && adapter.discoverable ? Theme.primary : Theme.surface_variant; text: adapter && adapter.discoverable ? "\ue5ca" : "\ue5cd" }
                                                }
                                            }
                                        }
                                        MouseArea { id: discMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { discCard.forceActiveFocus(); if(adapter) adapter.discoverable = !adapter.discoverable } }
                                    }

                                    // Pairable Card
                                    Rectangle {
                                        id: pairCard
                                        Layout.fillWidth: true; Layout.preferredHeight: 72; radius: 16; color: pairMouse.containsMouse ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : Theme.surface_container
                                        Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                                        visible: adapterState
                                        
                                        Rectangle { 
                                            width: 16; height: 16; color: parent.color; anchors.top: parent.top; anchors.left: parent.left 
                                            opacity: pairMouse.containsMouse ? 0.0 : 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                        }
                                        Rectangle { 
                                            width: 16; height: 16; color: parent.color; anchors.top: parent.top; anchors.right: parent.right 
                                            opacity: pairMouse.containsMouse ? 0.0 : 1.0; Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                        }
                                        
                                        activeFocusOnTab: true
                                        Keys.onSpacePressed: if(adapter) adapter.pairable = !adapter.pairable
                                        Keys.onReturnPressed: if(adapter) adapter.pairable = !adapter.pairable
                                        
                                        RowLayout {
                                            anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 16
                                            ColumnLayout {
                                                Layout.fillWidth: true; spacing: 2
                                                Text { text: "Pairable"; font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface; Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft }
                                                Text { text: "Allow nearby devices to pair with this one"; font.family: Vars.fontFamily; font.pixelSize: 13; color: Theme.on_surface_variant; Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft }
                                            }
                                            Rectangle {
                                                width: 52; height: 32; radius: 16; color: adapter && adapter.pairable ? Theme.primary : Theme.surface_variant
                                                border.color: pairCard.activeFocus ? Theme.on_surface : "transparent"; border.width: pairCard.activeFocus ? 2 : 0
                                                Rectangle {
                                                    width: 24; height: 24; radius: 12; color: adapter && adapter.pairable ? Theme.on_primary : Theme.on_surface_variant
                                                    anchors.verticalCenter: parent.verticalCenter; anchors.left: parent.left; anchors.leftMargin: adapter && adapter.pairable ? 24 : 4
                                                    Behavior on anchors.leftMargin { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                                                    Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 16; color: adapter && adapter.pairable ? Theme.primary : Theme.surface_variant; text: adapter && adapter.pairable ? "\ue5ca" : "\ue5cd" }
                                                }
                                            }
                                        }
                                        MouseArea { id: pairMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { pairCard.forceActiveFocus(); if(adapter) adapter.pairable = !adapter.pairable } }
                                    }
                                }
                                }

                                // --- PAIRING VIEW ---
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    visible: btContent.isPairingMode

                                    // Pairing Header Card
                                    Rectangle {
                                        Layout.fillWidth: true; Layout.preferredHeight: 72
                                        radius: 16; 
                                        color: Theme.surface_container
                                        
                                        property bool hasDeviceBelow: {
                                            if (!adapter || !adapter.devices.values) return false;
                                            for (let i = 0; i < adapter.devices.values.length; ++i) {
                                                let d = adapter.devices.values[i];
                                                if (d && !(d.paired || d.connected)) return true;
                                            }
                                            return false;
                                        }
                                        
                                        // Square bottom corners for contiguous list
                                        Rectangle { width: 16; height: 16; color: parent.color; anchors.bottom: parent.bottom; anchors.left: parent.left; visible: parent.hasDeviceBelow }
                                        Rectangle { width: 16; height: 16; color: parent.color; anchors.bottom: parent.bottom; anchors.right: parent.right; visible: parent.hasDeviceBelow }
                                        
                                        RowLayout {
                                            anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 16
                                            
                                            // Back button
                                            Rectangle {
                                                width: 40; height: 40; radius: 20; color: backMouse.containsMouse ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12)) : "transparent"
                                                Text { anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 24; color: Theme.on_surface; text: "\ue5c4" }
                                                MouseArea { id: backMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: btContent.isPairingMode = false }
                                            }

                                            Text { text: "Pair new device"; font.family: Vars.fontFamily; font.pixelSize: 16; font.weight: 500; color: Theme.on_surface; Layout.fillWidth: true }
                                            
                                            // Discovering Toggle
                                            Rectangle {
                                                width: 52; height: 32; radius: 16
                                                property bool isDiscovering: adapter && adapter.discovering
                                                color: isDiscovering ? Theme.primary : Theme.surface_variant
                                                Rectangle {
                                                    width: 24; height: 24; radius: 12
                                                    color: parent.isDiscovering ? Theme.on_primary : Theme.on_surface_variant
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    anchors.left: parent.left; anchors.leftMargin: parent.isDiscovering ? 24 : 4
                                                    Behavior on anchors.leftMargin { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                                                    Text { 
                                                        id: rotIcon
                                                        anchors.centerIn: parent; font.family: "Material Symbols Outlined"; font.pixelSize: 16
                                                        color: parent.parent.isDiscovering ? Theme.primary : Theme.surface_variant
                                                        text: parent.parent.isDiscovering ? "\ue86a" : "\ue5cd" 
                                                        
                                                        RotationAnimation {
                                                            target: rotIcon; property: "rotation"
                                                            loops: Animation.Infinite; from: 0; to: 360; duration: 2000; running: rotIcon.parent.parent.parent.isDiscovering
                                                            onRunningChanged: if (!running) rotIcon.rotation = 0
                                                        }
                                                    }
                                                }
                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        if (adapter) {
                                                            adapter.discovering = !adapter.discovering;
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }

                                    // Device List
                                    Repeater {
                                        model: adapter && adapterState ? adapter.devices.values : []
                                        delegate: Rectangle {
                                            id: btPairDelegate
                                            Layout.fillWidth: true; Layout.preferredHeight: visible ? 72 : 0
                                            property bool isSelected: modelData.connected
                                            property bool showForget: false
                                            radius: isSelected ? height / 2 : 16
                                            color: isSelected ? Theme.secondary_container : (btPairItemMouse.containsMouse ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : Theme.surface_container)
                                            Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                                            visible: !(modelData.paired || modelData.connected)
                                            
                                            Rectangle {
                                                width: parent.radius; height: parent.radius; color: parent.color
                                                anchors.top: parent.top; anchors.left: parent.left
                                                opacity: parent.isSelected || btPairItemMouse.containsMouse ? 0.0 : 1.0
                                                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                            }
                                            Rectangle {
                                                width: parent.radius; height: parent.radius; color: parent.color
                                                anchors.top: parent.top; anchors.right: parent.right
                                                opacity: parent.isSelected || btPairItemMouse.containsMouse ? 0.0 : 1.0
                                                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                            }
                                            property bool hasDeviceBelow: {
                                                if (!adapter || !adapter.devices.values) return false;
                                                for (let i = index + 1; i < adapter.devices.values.length; ++i) {
                                                    let d = adapter.devices.values[i];
                                                    if (d && !(d.paired || d.connected)) return true;
                                                }
                                                return false;
                                            }
                                            
                                            Rectangle {
                                                width: parent.radius; height: parent.radius; color: parent.color
                                                anchors.bottom: parent.bottom; anchors.left: parent.left
                                                visible: parent.hasDeviceBelow
                                                opacity: parent.isSelected || btPairItemMouse.containsMouse ? 0.0 : 1.0
                                                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                            }
                                            Rectangle {
                                                width: parent.radius; height: parent.radius; color: parent.color
                                                anchors.bottom: parent.bottom; anchors.right: parent.right
                                                visible: parent.hasDeviceBelow
                                                opacity: parent.isSelected || btPairItemMouse.containsMouse ? 0.0 : 1.0
                                                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                            }
                                            
                                            RowLayout {
                                                anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20; spacing: 16
                                                Text { text: "\ue1a7"; font.family: "Material Symbols Outlined"; font.pixelSize: 24; color: Theme.on_surface_variant }
                                                ColumnLayout {
                                                    Layout.alignment: Qt.AlignVCenter; spacing: 0; Layout.fillWidth: true
                                                    Text { text: modelData.name ? modelData.name : "Unknown Device"; font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface; Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft }
                                                    Text { text: "Available to pair"; font.family: Vars.fontFamily; font.pixelSize: 11; font.weight: 500; color: Theme.on_surface_variant; visible: text !== ""; Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft }
                                                }
                                            }
                                            MouseArea {
                                                id: btPairItemMouse
                                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                                onClicked: (mouse) => {
                                                    parent.forceActiveFocus();
                                                    if (mouse.button === Qt.RightButton) {
                                                        btPairDelegate.showForget = true;
                                                    } else {
                                                        if (!modelData.connected) modelData.connect();
                                                    }
                                                }
                                            }
                                            
                                            // Forget Overlay
                                            Rectangle {
                                                anchors.fill: parent
                                                radius: parent.radius
                                                color: Theme.surface_container_highest
                                                visible: btPairDelegate.showForget
                                                opacity: btPairDelegate.showForget ? 1.0 : 0.0
                                                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
                                                
                                                RowLayout {
                                                    anchors.fill: parent; anchors.margins: 16; spacing: 16
                                                    Text {
                                                        text: "Forget " + (modelData.name || "Device") + "?"
                                                        font.family: Vars.fontFamily; font.pixelSize: 16; color: Theme.on_surface; Layout.fillWidth: true; elide: Text.ElideRight
                                                    }
                                                    Rectangle {
                                                        width: 80; height: 32; radius: 16; color: "transparent"
                                                        border.color: Theme.outline; border.width: 1
                                                        Text { anchors.centerIn: parent; text: "Cancel"; color: Theme.on_surface; font.family: Vars.fontFamily; font.pixelSize: 14 }
                                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: btPairDelegate.showForget = false }
                                                    }
                                                    Rectangle {
                                                        width: 80; height: 32; radius: 16; color: Theme.error ? Theme.error : "#ffb4ab"
                                                        Text { anchors.centerIn: parent; text: "Forget"; color: Theme.on_error ? Theme.on_error : "#690005"; font.family: Vars.fontFamily; font.pixelSize: 14; font.weight: 500 }
                                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (modelData.forget) modelData.forget(); btPairDelegate.showForget = false; } }
                                                    }
                                                }
                                            }
                                        }
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
        Quickshell.execDetached({ command: ["hypr-manager", "--" + key, strVal] });
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
                
                root.allVars = newVars;
                applyFilter();
            }
        }
    }
    
    function applyFilter() {
        var term = searchInput.text.trim();
        settingsModel.clear();
        for (var k = 0; k < root.allVars.length; k++) {
            var v = root.allVars[k];
            if (term === "" || Vars.fuzzyMatch(term, v.key) || Vars.fuzzyMatch(term, v.help) || Vars.fuzzyMatch(term, v.category)) {
                settingsModel.append(v);
            }
        }
    }

    Popup {
        id: wifiPasswordPopup
        x: panel.x + (panel.width - width) / 2
        y: panel.y + (panel.height - height) / 2
        width: Math.min(360, panel.width - 40)
        modal: true
        dim: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        property var targetNetwork: null
        
        padding: 24
        
        Overlay.modal: Rectangle {
            color: Qt.rgba(0, 0, 0, 0.4)
            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
        }
        
        background: Rectangle {
            color: Theme.surface_container_high
            radius: 28 
            border.color: Theme.outline_variant
            border.width: 1
            layer.enabled: true
            layer.effect: MultiEffect { shadowEnabled: true; shadowBlur: 1.5; shadowColor: Qt.rgba(0,0,0,0.3); shadowVerticalOffset: 6 }
        }
        
        contentItem: ColumnLayout {
            spacing: 24
            
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 16
                
                Text {
                    text: "Connect to " + (wifiPasswordPopup.targetNetwork ? wifiPasswordPopup.targetNetwork.name : "Network")
                    font.family: Vars.fontFamily
                    font.pixelSize: 24
                    font.weight: 400
                    color: Theme.on_surface
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                }
                
                Rectangle {
                    Layout.fillWidth: true
                    height: 56
                    color: wifiPwdInput.activeFocus ? Qt.tint(Theme.surface_container_highest, Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08)) : Theme.surface_container_highest
                    radius: 16
                    border.color: wifiPwdInput.activeFocus ? Theme.primary : Theme.outline
                    border.width: wifiPwdInput.activeFocus ? 2 : 1
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                    Behavior on color { ColorAnimation { duration: 150 } }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 8
                        spacing: 12
                        
                        Text { text: "\ue897"; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: wifiPwdInput.activeFocus ? Theme.primary : Theme.on_surface_variant }
                        
                        TextInput {
                            id: wifiPwdInput
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            verticalAlignment: Text.AlignVCenter
                            font.family: Vars.fontFamily
                            font.pixelSize: 16
                            color: Theme.on_surface
                            echoMode: pwdToggle.showPwd ? TextInput.Normal : TextInput.Password
                            selectByMouse: true
                            clip: true
                            Keys.onReturnPressed: wifiPasswordPopup.submit()
                        }
                        
                        Rectangle {
                            id: pwdToggle
                            property bool showPwd: false
                            width: 36; height: 36; radius: 18
                            color: pwdToggleHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent"
                            Text {
                                anchors.centerIn: parent
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 20
                                color: Theme.on_surface_variant
                                text: pwdToggle.showPwd ? "\ue8f4" : "\ue8f5"
                            }
                            MouseArea {
                                id: pwdToggleHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: pwdToggle.showPwd = !pwdToggle.showPwd
                            }
                            Behavior on color { ColorAnimation { duration: 150 } }
                        }
                    }
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                spacing: 8
                
                Rectangle {
                    implicitWidth: cancelBtnTxt.implicitWidth + 32
                    implicitHeight: 40
                    radius: 20
                    color: cancelHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent"
                    Text { id: cancelBtnTxt; anchors.centerIn: parent; text: "Cancel"; color: Theme.primary; font.family: Vars.fontFamily; font.pixelSize: 14; font.weight: 500 }
                    MouseArea { id: cancelHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: wifiPasswordPopup.close() }
                    Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                }
                
                Rectangle {
                    implicitWidth: connectBtnTxt.implicitWidth + 32
                    implicitHeight: 40
                    radius: 20
                    color: connectHover.containsMouse ? Qt.tint(Theme.primary, Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.08)) : Theme.primary
                    Text { id: connectBtnTxt; anchors.centerIn: parent; text: "Connect"; color: Theme.on_primary; font.family: Vars.fontFamily; font.pixelSize: 14; font.weight: 500 }
                    MouseArea { id: connectHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: wifiPasswordPopup.submit() }
                    Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                }
            }
        }
        
        onOpened: {
            wifiPwdInput.text = "";
            pwdToggle.showPwd = false;
            wifiPwdInput.forceActiveFocus();
        }
        
        function submit() {
            if (targetNetwork) {
                if (wifiPwdInput.text.length > 0) {
                    targetNetwork.connect(wifiPwdInput.text);
                } else {
                    targetNetwork.connect();
                }
            }
            close();
        }
    }
}
