import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import "../.."
import "../../theme/variables.js" as Vars

ColumnLayout {
    id: rootPage

    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Vars.spacingMedium

    property var allVars: []
    property string activeCategory: "General"
    property string copiedSliderValue: ""
    onActiveCategoryChanged: applyFilter()

    function updateVariable(key, val, source) {
        var isQs = source === "Quickshell" || source === "quickshell";
        var cmdArray = [];
        var isLive = false;
        if (isQs) {
            var liveVars = ["clockShape", "clockShowTicks", "clockShowCenterDot", "wallpaperMaskShape", "wallpaperMaskScale", "wallpaperMaskColor", "wallpaperMaskEnabled", "wallpaperMaskOffsetX", "wallpaperMaskOffsetY", "mediaPlayerShape"];
            isLive = liveVars.indexOf(key) !== -1;
            cmdArray = ["sh", "-c", "$HOME/.local/bin/omniformis qs set \"$1\" \"$2\"", "sh", key, val];
        } else {
            cmdArray = ["sh", "-c", "$HOME/.local/bin/omniformis hypr set \"$1\" \"$2\"", "sh", key, val];
        }
        var cmd = JSON.stringify(cmdArray);
        var proc = Qt.createQmlObject('import Quickshell.Io; Process { command: ' + cmd + '; onExited: destroy() }', rootPage);
        proc.running = true;

        if (isQs && isLive) {
            try {
                if (val === "true" || val === "false") {
                    eval("Vars." + key + " = " + val + ";");
                } else if (!isNaN(Number(val)) && val !== "") {
                    eval("Vars." + key + " = " + Number(val) + ";");
                } else {
                    eval("Vars." + key + " = '" + val + "';");
                }
            } catch (e) {}
        }
    }

    function loadSettings() {
        rootPage.allVars = [];
        hyprManagerProc.running = true;
        qsManagerProc.running = true;
    }

    Component.onCompleted: {
        loadSettings();
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        Text {
            text: activeCategory
            font.family: Vars.fontFamily
            font.pixelSize: 16
            font.weight: 500
            color: Theme.on_surface
        }
        Text {
            text: "Manage settings for " + activeCategory
            font.family: Vars.fontFamily
            font.pixelSize: 12
            color: Theme.on_surface
            opacity: 0.7
        }
    }

    Rectangle {
        Layout.fillWidth: true
        height: 72
        color: Vars.translucent ? Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 0.5) : Theme.surface_container
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
                contentItem: Text {
                    text: "Refresh"
                    color: Theme.on_surface
                    font.family: Vars.fontFamily
                    font.bold: true
                }
                MouseArea {
                    id: refreshBtnHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: loadSettings()
                }
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
        focus: true
        KeyNavigation.up: searchInput

        // boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: Vars.flickDeceleration
        maximumFlickVelocity: Vars.maximumFlickVelocity

        Keys.onReturnPressed: {
            if (currentItem) {
                currentItem.triggerAction();
            }
        }
        Keys.onRightPressed: {
            if (currentItem)
                currentItem.triggerAction();
        }

        section.property: "source"
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

        delegate: Item {
            id: delegateRoot
            property int delegateIndex: index
            property string itemKey: model.key
            property string itemType: model.type
            property string itemHelp: model.help
            property string itemEnums: model.enums
            property string itemVal: model.val
            property string itemSource: model.source
            property real itemMin: model.min
            property real itemMax: model.max
            property real itemStep: model.step

            width: ListView.view.width
            height: Math.max(80, delegateRow.implicitHeight + 32)
            property bool isSelected: false
            
            property color targetColor: delegateMouse.containsMouse ? Qt.tint((Vars.translucent ? Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 0.5) : Theme.surface_container), Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : (Vars.translucent ? Qt.rgba(Theme.surface_container.r, Theme.surface_container.g, Theme.surface_container.b, 0.5) : Theme.surface_container)
            Behavior on targetColor {
                ColorAnimation {
                    duration: Vars.animationDuration
                }
            }
            
            Item {
                anchors.fill: parent
                layer.enabled: true
                opacity: parent.targetColor.a
                
                Rectangle {
                    anchors.fill: parent
                    radius: 16
                    color: Qt.rgba(parent.parent.targetColor.r, parent.parent.targetColor.g, parent.parent.targetColor.b, 1.0)
                    
                    Rectangle {
                        width: parent.radius
                        height: parent.radius
                        color: parent.color
                        anchors.top: parent.top
                        anchors.left: parent.left
                        opacity: (index > 0 && settingsModel.get(index).source === settingsModel.get(index - 1).source) ? 1.0 : 0.0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: Vars.animationDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Vars.customExpressiveSpatialSlow
                            }
                        }
                    }
                    Rectangle {
                        width: parent.radius
                        height: parent.radius
                        color: parent.color
                        anchors.top: parent.top
                        anchors.right: parent.right
                        opacity: (index > 0 && settingsModel.get(index).source === settingsModel.get(index - 1).source) ? 1.0 : 0.0
                        Behavior on opacity {
                            NumberAnimation {
                                duration: Vars.animationDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Vars.customExpressiveSpatialSlow
                            }
                        }
                    }
                    Rectangle {
                        width: parent.radius
                        height: parent.radius
                        color: parent.color
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        opacity: {
                            var current = settingsModel.get(index);
                            var next = index < settingsModel.count - 1 ? settingsModel.get(index + 1) : null;
                            return (current && next && current.source === next.source) ? 1.0 : 0.0;
                        }
                        Behavior on opacity {
                            NumberAnimation {
                                duration: Vars.animationDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Vars.customExpressiveSpatialSlow
                            }
                        }
                    }
                    Rectangle {
                        width: parent.radius
                        height: parent.radius
                        color: parent.color
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        opacity: {
                            var current = settingsModel.get(index);
                            var next = index < settingsModel.count - 1 ? settingsModel.get(index + 1) : null;
                            return (current && next && current.source === next.source) ? 1.0 : 0.0;
                        }
                        Behavior on opacity {
                            NumberAnimation {
                                duration: Vars.animationDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Vars.customExpressiveSpatialSlow
                            }
                        }
                    }
                }
            }

            function triggerAction() {
                if (itemType === "bool") {
                    var newVal = itemVal === "true" ? "false" : "true";
                    settingsModel.setProperty(delegateIndex, "val", newVal);
                    updateVariable(itemKey, newVal, itemSource);
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
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                    settingsList.currentIndex = delegateRoot.delegateIndex;
                }
                onClicked: {
                    settingsList.currentIndex = delegateRoot.delegateIndex;
                }
            }

            RowLayout {
                id: delegateRow
                anchors.fill: parent
                anchors.margins: Vars.spacingLarge
                spacing: 24

                ColumnLayout {
                    Layout.preferredWidth: 350
                    Layout.minimumWidth: 200
                    Layout.fillWidth: true
                    spacing: 4
                    Text {
                        text: delegateRoot.itemKey
                        font.family: Vars.fontFamily
                        font.pixelSize: 16
                        font.weight: 600
                        color: Theme.on_surface
                    }
                    Text {
                        text: (delegateRoot.itemType === "enum" || delegateRoot.itemType === "color") ? delegateRoot.itemHelp.replace(/\s*\(.*\)/, "") : delegateRoot.itemHelp
                        font.family: Vars.fontFamily
                        font.pixelSize: 12
                        color: Theme.on_surface_variant
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }

                Item {
                    Layout.fillWidth: true
                    visible: delegateRoot.itemType !== "enum" && !(delegateRoot.itemType === "number" && parseFloat(delegateRoot.itemVal) >= 50)
                }

                Rectangle {
                    visible: delegateRoot.itemType === "bool"
                    width: 52
                    height: 32
                    radius: 16
                    color: delegateRoot.itemVal === "true" ? Theme.primary : Theme.surface_variant
                    border.color: delegateRoot.activeFocus ? Theme.on_surface : "transparent"
                    border.width: delegateRoot.activeFocus ? 2 : 0
                    Behavior on color {
                        ColorAnimation {
                            duration: Vars.animationDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Vars.customStandard
                        }
                    }

                    Rectangle {
                        width: 24
                        height: 24
                        radius: 12
                        color: delegateRoot.itemVal === "true" ? Theme.on_primary : Theme.on_surface_variant
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: delegateRoot.itemVal === "true" ? 24 : 4
                        Behavior on anchors.leftMargin {
                            NumberAnimation {
                                duration: Vars.animationDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Vars.customStandard
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 16
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
                            updateVariable(delegateRoot.itemKey, newVal, delegateRoot.itemSource);
                        }
                    }
                }

                Rectangle {
                    visible: delegateRoot.itemType === "string" || (delegateRoot.itemType === "number" && parseFloat(delegateRoot.itemVal) >= 50)
                    width: 150
                    height: 32
                    radius: Vars.radiusSmall
                    color: Theme.surface_container_highest
                    border.color: tInput.activeFocus ? Theme.primary : "transparent"
                    border.width: 1

                    TextInput {
                        id: tInput
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
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
                                updateVariable(delegateRoot.itemKey, text, delegateRoot.itemSource);
                            }
                        }
                        Keys.onEscapePressed: {
                            text = delegateRoot.itemVal;
                            tInput.focus = false;
                            settingsList.forceActiveFocus();
                        }
                    }
                }

                RowLayout {
                    visible: delegateRoot.itemType === "number" && parseFloat(delegateRoot.itemVal) < 50
                    spacing: 4
                    height: 32

                    Rectangle {
                        width: 80
                        height: 32
                        radius: Vars.radiusSmall
                        color: Theme.surface_container_highest
                        border.color: numInput.activeFocus ? Theme.primary : "transparent"
                        border.width: 1
                        TextInput {
                            id: numInput
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            verticalAlignment: Text.AlignVCenter
                            text: delegateRoot.itemVal
                            font.family: Vars.fontFamily
                            font.pixelSize: 14
                            color: Theme.on_surface
                            selectByMouse: true
                            onAccepted: {
                                numInput.focus = false;
                                settingsList.forceActiveFocus();
                            }
                            onEditingFinished: {
                                if (text !== delegateRoot.itemVal) {
                                    settingsModel.setProperty(delegateRoot.delegateIndex, "val", text);
                                    updateVariable(delegateRoot.itemKey, text, delegateRoot.itemSource);
                                }
                            }
                            Keys.onEscapePressed: {
                                text = delegateRoot.itemVal;
                                numInput.focus = false;
                                settingsList.forceActiveFocus();
                            }
                        }
                    }

                    Rectangle {
                        width: 32
                        height: 32
                        radius: Vars.radiusSmall
                        color: numMinusHover.containsMouse ? Theme.surface_container_high : Theme.surface_container_highest
                        Text {
                            anchors.centerIn: parent
                            text: "remove"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 20
                            color: Theme.on_surface
                        }
                        MouseArea {
                            id: numMinusHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var val = parseFloat(delegateRoot.itemVal) - 1;
                                settingsModel.setProperty(delegateRoot.delegateIndex, "val", val.toString());
                                updateVariable(delegateRoot.itemKey, val.toString(), delegateRoot.itemSource);
                            }
                        }
                    }

                    Rectangle {
                        width: 32
                        height: 32
                        radius: Vars.radiusSmall
                        color: numPlusHover.containsMouse ? Theme.surface_container_high : Theme.surface_container_highest
                        Text {
                            anchors.centerIn: parent
                            text: "add"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 20
                            color: Theme.on_surface
                        }
                        MouseArea {
                            id: numPlusHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                var val = parseFloat(delegateRoot.itemVal) + 1;
                                settingsModel.setProperty(delegateRoot.delegateIndex, "val", val.toString());
                                updateVariable(delegateRoot.itemKey, val.toString(), delegateRoot.itemSource);
                            }
                        }
                    }
                }

                Slider {
                    id: m3Slider
                    visible: delegateRoot.itemType === "slider"
                    Layout.fillWidth: true
                    Layout.preferredWidth: 320
                    implicitHeight: 48
                    padding: 0

                    from: delegateRoot.itemMin
                    to: delegateRoot.itemMax
                    stepSize: delegateRoot.itemStep
                    value: parseFloat(delegateRoot.itemVal)
                    snapMode: showTicks ? Slider.SnapAlways : Slider.NoSnap

                    property real trackHeight: 36
                    property real handleWidth: 4
                    property real handleHeight: trackHeight + 8
                    property real handleMargin: 6
                    property real leftRadiusLarge: 12
                    property real leftRadiusSmall: 4
                    property real dotSize: 6
                    property real gap: 2
                    // Only show ticks if the total number of ticks is small (e.g. <= 25) to prevent dense lines
                    property bool showTicks: ((delegateRoot.itemMax - delegateRoot.itemMin) / delegateRoot.itemStep) <= 25

                    // Auto-detect mode: if 'from' is negative, use centered/bidirectional mode
                    property bool isCentered: delegateRoot.itemMin < 0

                    onMoved: {
                        var rounded = Number((value).toFixed(3));
                        settingsModel.setProperty(delegateRoot.delegateIndex, "val", rounded.toString());

                        // Live update for quickshell vars directly via JS for instant visual feedback
                        if (delegateRoot.itemSource === "Quickshell" || delegateRoot.itemSource === "quickshell") {
                            try {
                                eval("Vars." + delegateRoot.itemKey + " = " + rounded + ";");
                            } catch (e) {}
                        }
                    }

                    onPressedChanged: {
                        if (!pressed) { // Only save to system/file on release
                            var rounded = Number((value).toFixed(3));
                            updateVariable(delegateRoot.itemKey, rounded.toString(), delegateRoot.itemSource);
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        cursorShape: Qt.ArrowCursor
                        onClicked: mouse => {
                            if (mouse.button === Qt.RightButton) {
                                sliderContextMenu.popup();
                            }
                        }

                        Menu {
                            id: sliderContextMenu
                            width: 220
                            topPadding: 8
                            bottomPadding: 8

                            background: Rectangle {
                                implicitWidth: 220
                                color: Theme.surface_container_highest
                                radius: 12
                                border.color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.4)
                                border.width: 1
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    shadowEnabled: true
                                    shadowBlur: 1.0
                                    shadowColor: Qt.rgba(0, 0, 0, 0.25)
                                    shadowVerticalOffset: 4
                                    shadowHorizontalOffset: 0
                                }
                            }

                            MenuItem {
                                enabled: false // read-only
                                implicitWidth: 220
                                implicitHeight: 36
                                contentItem: Item {
                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 16
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "Value"
                                        color: Theme.on_surface_variant
                                        font.family: Vars.fontFamily
                                        font.pixelSize: 13
                                    }
                                    Text {
                                        anchors.right: parent.right
                                        anchors.rightMargin: 16
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: Number(m3Slider.value).toFixed(3)
                                        color: Theme.on_surface
                                        font.family: Vars.fontFamily
                                        font.pixelSize: 14
                                        font.weight: 600
                                    }
                                }
                                background: Rectangle {
                                    color: "transparent"
                                }
                            }

                            MenuSeparator {
                                implicitWidth: 220
                                implicitHeight: 12
                                contentItem: Rectangle {
                                    implicitWidth: 188
                                    implicitHeight: 1
                                    color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, 0.5)
                                    anchors.centerIn: parent
                                }
                            }

                            MenuItem {
                                implicitWidth: 220
                                implicitHeight: 40
                                contentItem: RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    spacing: 12
                                    Text {
                                        text: "\ue14d" // content_copy
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 18
                                        color: parent.parent.highlighted ? Theme.primary : Theme.on_surface_variant
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: "Copy Value"
                                        color: parent.parent.highlighted ? Theme.primary : Theme.on_surface
                                        font.family: Vars.fontFamily
                                        font.pixelSize: 14
                                        font.weight: 500
                                    }
                                }
                                background: Rectangle {
                                    color: parent.highlighted ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
                                    radius: 8
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                onTriggered: rootPage.copiedSliderValue = delegateRoot.itemVal
                            }

                            MenuItem {
                                implicitWidth: 220
                                implicitHeight: 40
                                enabled: rootPage.copiedSliderValue !== ""
                                contentItem: RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    spacing: 12
                                    Text {
                                        text: "\ue14f" // content_paste
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 18
                                        color: parent.enabled ? (parent.parent.highlighted ? Theme.primary : Theme.on_surface_variant) : Theme.outline
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: "Paste Value"
                                        color: parent.enabled ? (parent.parent.highlighted ? Theme.primary : Theme.on_surface) : Theme.outline
                                        font.family: Vars.fontFamily
                                        font.pixelSize: 14
                                        font.weight: 500
                                    }
                                    Text {
                                        text: rootPage.copiedSliderValue ? Number(rootPage.copiedSliderValue).toFixed(3) : ""
                                        color: Theme.on_surface_variant
                                        font.family: Vars.fontFamily
                                        font.pixelSize: 12
                                    }
                                }
                                background: Rectangle {
                                    color: parent.highlighted ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
                                    radius: 8
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                onTriggered: {
                                    if (rootPage.copiedSliderValue !== "") {
                                        var rounded = Number((parseFloat(rootPage.copiedSliderValue)).toFixed(3));
                                        m3Slider.value = rounded;
                                        settingsModel.setProperty(delegateRoot.delegateIndex, "val", rounded.toString());
                                        updateVariable(delegateRoot.itemKey, rounded.toString(), delegateRoot.itemSource);
                                    }
                                }
                            }
                            
                            MenuItem {
                                implicitWidth: 220
                                implicitHeight: 40
                                contentItem: RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    spacing: 12
                                    Text {
                                        text: "\ue166" // undo
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 18
                                        color: parent.parent.highlighted ? Theme.error : Theme.on_surface_variant
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: "Reset Value"
                                        color: parent.parent.highlighted ? Theme.error : Theme.on_surface
                                        font.family: Vars.fontFamily
                                        font.pixelSize: 14
                                        font.weight: 500
                                    }
                                }
                                background: Rectangle {
                                    color: parent.highlighted ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : "transparent"
                                    radius: 8
                                    anchors.fill: parent
                                    anchors.margins: 4
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }
                                onTriggered: {
                                    var safeDefault = Math.max(m3Slider.from, Math.min(0, m3Slider.to));
                                    if (m3Slider.value !== safeDefault) {
                                        m3Slider.value = safeDefault;
                                        settingsModel.setProperty(delegateRoot.delegateIndex, "val", safeDefault.toString());
                                        updateVariable(delegateRoot.itemKey, safeDefault.toString(), delegateRoot.itemSource);
                                    }
                                }
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════
                    // MODE A: Centered/Bidirectional slider (- to 0 to +)
                    // ═══════════════════════════════════════════════
                    background: Item {
                        visible: m3Slider.isCentered
                        x: m3Slider.leftPadding
                        y: m3Slider.topPadding + (m3Slider.availableHeight - m3Slider.trackHeight) / 2
                        width: m3Slider.availableWidth
                        height: m3Slider.trackHeight

                        property real handlePos: m3Slider.visualPosition * (width - m3Slider.handleWidth)
                        property real centerX: width / 2

                        property bool isLeftOfCenter: handlePos + m3Slider.handleWidth / 2 < centerX

                        // LEFT TRACK — rounded left, little rounded right, with dot
                        // Stops at center (with gap) when handle is right of center
                        Rectangle {
                            id: leftTrackCentered
                            x: 0
                            y: 0
                            width: {
                                var endAt = parent.isLeftOfCenter ? parent.handlePos - m3Slider.gap : parent.centerX - m3Slider.gap;
                                return Math.max(m3Slider.leftRadiusLarge * 2, endAt);
                            }
                            height: parent.height
                            color: Theme.surface_container_highest

                            topLeftRadius: m3Slider.leftRadiusLarge
                            bottomLeftRadius: m3Slider.leftRadiusLarge
                            topRightRadius: m3Slider.leftRadiusSmall
                            bottomRightRadius: m3Slider.leftRadiusSmall

                            // Dot at left end
                            Rectangle {
                                width: m3Slider.dotSize
                                height: m3Slider.dotSize
                                radius: m3Slider.dotSize / 2
                                color: Theme.on_surface_variant
                                anchors.verticalCenter: parent.verticalCenter
                                x: m3Slider.leftRadiusLarge - m3Slider.dotSize / 2
                                opacity: !m3Slider.showTicks && leftTrackCentered.width > m3Slider.leftRadiusLarge * 2.5 ? 0.6 : 0.0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 150
                                    }
                                }
                            }
                        }

                        // COLORED INDICATOR — spans from center to handle with margins
                        // When handle is LEFT of center: right side at center, left side at handle
                        // When handle is RIGHT of center: left side at center, right side at handle
                        Rectangle {
                            id: coloredIndicatorCentered
                            property real handleRight: parent.handlePos + m3Slider.handleWidth + m3Slider.gap
                            property real handleLeft: parent.handlePos - m3Slider.gap

                            x: parent.isLeftOfCenter ? handleRight : parent.centerX + m3Slider.gap
                            y: 0
                            width: parent.isLeftOfCenter ? Math.max(0, parent.centerX - m3Slider.gap - handleRight) : Math.max(0, handleLeft - parent.centerX - m3Slider.gap)
                            height: parent.height
                            color: Theme.primary
                            radius: m3Slider.leftRadiusSmall
                            visible: width > 2
                        }

                        // RIGHT TRACK — little rounded left, rounded right, with dot
                        // Starts at center (with gap) when handle is left of center
                        Rectangle {
                            id: rightTrackCentered
                            x: {
                                var startAt = parent.isLeftOfCenter ? parent.centerX + m3Slider.gap : parent.handlePos + m3Slider.handleWidth + m3Slider.gap;
                                return startAt;
                            }
                            y: 0
                            width: Math.max(0, parent.width - x)
                            height: parent.height
                            color: Theme.surface_container_highest

                            topLeftRadius: Math.min(m3Slider.leftRadiusSmall, width / 2)
                            bottomLeftRadius: Math.min(m3Slider.leftRadiusSmall, width / 2)
                            topRightRadius: Math.min(m3Slider.leftRadiusLarge, width / 2)
                            bottomRightRadius: Math.min(m3Slider.leftRadiusLarge, width / 2)

                            // Dot at right end
                            Rectangle {
                                width: m3Slider.dotSize
                                height: m3Slider.dotSize
                                radius: m3Slider.dotSize / 2
                                color: Theme.on_surface_variant
                                anchors.verticalCenter: parent.verticalCenter
                                x: parent.width - m3Slider.leftRadiusLarge - m3Slider.dotSize / 2
                                opacity: !m3Slider.showTicks && rightTrackCentered.width > m3Slider.leftRadiusLarge * 2.5 ? 0.6 : 0.0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 150
                                    }
                                }
                            }
                        }

                        // Tick marks for integer steps (centered mode)
                        Repeater {
                            model: m3Slider.showTicks ? Math.max(0, Math.floor((m3Slider.to - m3Slider.from) / m3Slider.stepSize) + 1) : 0
                            Rectangle {
                                property real tickPos: (m3Slider.handleWidth / 2) + (m3Slider.availableWidth - m3Slider.handleWidth) * (index / Math.max(1, (m3Slider.to - m3Slider.from) / m3Slider.stepSize))
                                x: tickPos - width / 2
                                y: (parent.height - height) / 2
                                width: 4
                                height: 4
                                radius: 2

                                property bool inColoredArea: parent.isLeftOfCenter ? (tickPos >= parent.handlePos + m3Slider.handleWidth / 2 && tickPos <= parent.centerX) : (tickPos >= parent.centerX && tickPos <= parent.handlePos + m3Slider.handleWidth / 2)

                                color: inColoredArea ? Theme.surface_container_highest : Theme.primary
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════
                    // MODE B: Unidirectional slider (0 to positive) — uses Loader
                    // ═══════════════════════════════════════════════
                    Loader {
                        active: !m3Slider.isCentered
                        sourceComponent: Item {
                            x: m3Slider.leftPadding
                            y: m3Slider.topPadding + (m3Slider.availableHeight - m3Slider.trackHeight) / 2
                            width: m3Slider.availableWidth
                            height: m3Slider.trackHeight

                            property real handlePos: m3Slider.visualPosition * (width - m3Slider.handleWidth)

                            // LEFT TRACK (Colored fill — no dot for 0-to-+ sliders)
                            Rectangle {
                                id: leftTrackUni
                                x: 0
                                y: 0
                                width: Math.max(0, parent.handlePos - m3Slider.gap)
                                height: parent.height
                                color: Theme.primary

                                topLeftRadius: Math.min(m3Slider.leftRadiusLarge, width / 2)
                                bottomLeftRadius: Math.min(m3Slider.leftRadiusLarge, width / 2)
                                topRightRadius: Math.min(m3Slider.leftRadiusSmall, width / 2)
                                bottomRightRadius: Math.min(m3Slider.leftRadiusSmall, width / 2)
                            }

                            // RIGHT TRACK (Inactive)
                            Rectangle {
                                id: rightTrackUni
                                x: parent.handlePos + m3Slider.handleWidth + m3Slider.gap
                                y: 0
                                width: Math.max(0, parent.width - x)
                                height: parent.height
                                color: Theme.surface_container_highest

                                topLeftRadius: Math.min(m3Slider.leftRadiusSmall, width / 2)
                                bottomLeftRadius: Math.min(m3Slider.leftRadiusSmall, width / 2)
                                topRightRadius: Math.min(m3Slider.leftRadiusLarge, width / 2)
                                bottomRightRadius: Math.min(m3Slider.leftRadiusLarge, width / 2)

                                // Dot at right end
                                Rectangle {
                                    width: m3Slider.dotSize
                                    height: m3Slider.dotSize
                                    radius: m3Slider.dotSize / 2
                                    color: Theme.on_surface_variant
                                    anchors.verticalCenter: parent.verticalCenter
                                    x: parent.width - m3Slider.leftRadiusLarge - m3Slider.dotSize / 2
                                    opacity: !m3Slider.showTicks && rightTrackUni.width > m3Slider.leftRadiusLarge * 2.5 ? 0.6 : 0.0
                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 150
                                        }
                                    }
                                }
                            }

                            // Tick marks for integer steps (unidirectional mode)
                            Repeater {
                                model: m3Slider.showTicks ? Math.max(0, Math.floor((m3Slider.to - m3Slider.from) / m3Slider.stepSize) + 1) : 0
                                Rectangle {
                                    property real tickPos: (m3Slider.handleWidth / 2) + (m3Slider.availableWidth - m3Slider.handleWidth) * (index / Math.max(1, (m3Slider.to - m3Slider.from) / m3Slider.stepSize))
                                    x: tickPos - width / 2
                                    y: (parent.height - height) / 2
                                    width: 4
                                    height: 4
                                    radius: 2

                                    property bool inColoredArea: tickPos <= parent.handlePos + m3Slider.handleWidth / 2

                                    color: inColoredArea ? Theme.surface_container_highest : Theme.primary
                                }
                            }
                        }
                    }

                    handle: Rectangle {
                        x: m3Slider.leftPadding + m3Slider.visualPosition * (m3Slider.availableWidth - width)
                        y: m3Slider.topPadding + (m3Slider.availableHeight - height) / 2
                        width: m3Slider.handleWidth
                        height: m3Slider.handleHeight
                        radius: width / 2
                        color: Theme.primary
                    }
                } // End inner Slider

                Item {
                    visible: delegateRoot.itemType === "enum"
                    Layout.fillWidth: true
                    Layout.minimumWidth: 400
                    implicitHeight: enumFlow.implicitHeight

                    Flow {
                        id: enumFlow
                        width: parent.width
                        anchors.right: parent.right
                        layoutDirection: (delegateRoot.itemEnums.split("|||").length < 5) ? Qt.RightToLeft : Qt.LeftToRight
                        spacing: 2
                        Repeater {
                        id: enumRepeater
                        model: {
                            if (!parent.visible) return [];
                            let arr = delegateRoot.itemEnums.split("|||");
                            return arr.length < 5 ? arr.reverse() : arr;
                        }
                        delegate: Rectangle {
                            property bool isSelected: delegateRoot.itemVal === modelData

                            // Determine row wrapping by checking the 'y' coordinate of siblings
                            property var prevItem: index > 0 ? enumRepeater.itemAt(index - 1) : null
                            property var nextItem: index < (enumRepeater.count - 1) ? enumRepeater.itemAt(index + 1) : null
                            property bool isRTL: enumFlow.layoutDirection === Qt.RightToLeft
                            property var visualLeftItem: isRTL ? nextItem : prevItem
                            property var visualRightItem: isRTL ? prevItem : nextItem
                            
                            property bool hasLeft: visualLeftItem && visualLeftItem.y === y
                            property bool hasRight: visualRightItem && visualRightItem.y === y

                            height: 32
                            width: chipText.implicitWidth + 24

                            topLeftRadius: isSelected ? height / 2 : (hasLeft ? 4 : height / 2)
                            bottomLeftRadius: isSelected ? height / 2 : (hasLeft ? 4 : height / 2)
                            topRightRadius: isSelected ? height / 2 : (hasRight ? 4 : height / 2)
                            bottomRightRadius: isSelected ? height / 2 : (hasRight ? 4 : height / 2)

                            Behavior on topLeftRadius {
                                NumberAnimation {
                                    duration: Vars.animationDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Vars.customExpressiveSpatialSlow
                                }
                            }
                            Behavior on bottomLeftRadius {
                                NumberAnimation {
                                    duration: Vars.animationDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Vars.customExpressiveSpatialSlow
                                }
                            }
                            Behavior on topRightRadius {
                                NumberAnimation {
                                    duration: Vars.animationDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Vars.customExpressiveSpatialSlow
                                }
                            }
                            Behavior on bottomRightRadius {
                                NumberAnimation {
                                    duration: Vars.animationDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Vars.customExpressiveSpatialSlow
                                }
                            }

                            color: isSelected ? Theme.primary : Theme.surface_container_highest

                            Behavior on color {
                                ColorAnimation {
                                    duration: Vars.animationDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Vars.customExpressiveSpatialSlow
                                }
                            }

                            Text {
                                id: chipText
                                anchors.centerIn: parent
                                text: modelData
                                font.family: Vars.fontFamily
                                font.pixelSize: 13
                                color: isSelected ? Theme.on_primary : Theme.on_surface
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Vars.animationDuration
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: Vars.customExpressiveSpatialSlow
                                    }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    settingsModel.setProperty(delegateRoot.delegateIndex, "val", modelData);
                                    updateVariable(delegateRoot.itemKey, modelData, delegateRoot.itemSource);
                                }
                            }
                        }
                        }
                    }
                }

                M3Shapes {
                    id: m3ShapesObj
                }

                Grid {
                    visible: delegateRoot.itemType === "shape"
                    columns: 6
                    spacing: 2
                    Repeater {
                        id: shapeRepeater
                        model: parent.visible ? delegateRoot.itemEnums.split("|||") : []
                        delegate: Rectangle {
                            property bool isSelected: delegateRoot.itemVal === modelData

                            property bool hasLeft: index % 6 !== 0
                            property bool hasRight: index % 6 !== 5 && index !== shapeRepeater.count - 1

                            height: 36
                            width: 48

                            topLeftRadius: isSelected ? height / 2 : (hasLeft ? 4 : height / 2)
                            bottomLeftRadius: isSelected ? height / 2 : (hasLeft ? 4 : height / 2)
                            topRightRadius: isSelected ? height / 2 : (hasRight ? 4 : height / 2)
                            bottomRightRadius: isSelected ? height / 2 : (hasRight ? 4 : height / 2)

                            Behavior on topLeftRadius {
                                NumberAnimation {
                                    duration: Vars.animationDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Vars.customExpressiveSpatialSlow
                                }
                            }
                            Behavior on bottomLeftRadius {
                                NumberAnimation {
                                    duration: Vars.animationDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Vars.customExpressiveSpatialSlow
                                }
                            }
                            Behavior on topRightRadius {
                                NumberAnimation {
                                    duration: Vars.animationDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Vars.customExpressiveSpatialSlow
                                }
                            }
                            Behavior on bottomRightRadius {
                                NumberAnimation {
                                    duration: Vars.animationDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Vars.customExpressiveSpatialSlow
                                }
                            }

                            color: isSelected ? Theme.primary : Theme.surface_container_highest

                            Behavior on color {
                                ColorAnimation {
                                    duration: Vars.animationDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Vars.customExpressiveSpatialSlow
                                }
                            }

                            Shape {
                                width: 100
                                height: 100
                                anchors.centerIn: parent
                                scale: 0.24
                                layer.enabled: true
                                layer.samples: 8
                                layer.mipmap: true
                                layer.smooth: true
                                antialiasing: true

                                ShapePath {
                                    fillColor: isSelected ? Theme.on_primary : Theme.on_surface
                                    strokeColor: "transparent"
                                    strokeWidth: 0
                                    PathSvg {
                                        path: m3ShapesObj.getPath(modelData)
                                    }
                                }
                            }

                            MouseArea {
                                id: shapeHoverArea
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: {
                                    settingsModel.setProperty(delegateRoot.delegateIndex, "val", modelData);
                                    updateVariable(delegateRoot.itemKey, modelData, delegateRoot.itemSource);
                                }
                            }
                        }
                    }
                }

                Item {
                    visible: delegateRoot.itemType === "color"
                    Layout.fillWidth: true
                    Layout.minimumWidth: 300
                    implicitHeight: colorFlow.implicitHeight

                    Flow {
                        id: colorFlow
                        width: parent.width
                        anchors.right: parent.right
                        layoutDirection: (delegateRoot.itemEnums.split("|||").length < 5) ? Qt.RightToLeft : Qt.LeftToRight
                        spacing: 2
                        Repeater {
                            id: colorRepeater
                        model: {
                            if (!parent.visible) return [];
                            let arr = delegateRoot.itemEnums.split("|||");
                            return arr.length < 5 ? arr.reverse() : arr;
                        }
                        delegate: Rectangle {
                            property bool isSelected: delegateRoot.itemVal === modelData
                            height: 32
                            width: 32
                            radius: height / 2
                            border.width: isSelected ? 2 : (modelData === "transparent" ? 1 : 0)
                            border.color: isSelected ? Theme.on_surface : Theme.outline

                            color: {
                                if (modelData === "transparent")
                                    return "transparent";
                                if (modelData === "background")
                                    return Theme.background;
                                if (modelData === "primary")
                                    return Theme.primary;
                                if (modelData === "secondary")
                                    return Theme.secondary;
                                if (modelData === "tertiary")
                                    return Theme.tertiary;
                                if (modelData === "surface_variant")
                                    return Theme.surface_variant;
                                if (modelData === "error")
                                    return Theme.error;
                                return "transparent";
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    settingsModel.setProperty(delegateRoot.delegateIndex, "val", modelData);
                                    updateVariable(delegateRoot.itemKey, modelData, delegateRoot.itemSource);
                                }
                            }
                        }
                    }
                }
                }
            }
        }
    }

    Process {
        id: hyprManagerProc
        command: ["omniformis", "hypr", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n");
                var newVars = [];
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.length === 0)
                        continue;

                    var openBracketIdx = line.indexOf("[");
                    var closeBracketIdx = line.indexOf("]", openBracketIdx);
                    if (openBracketIdx === -1 || closeBracketIdx === -1)
                        continue;

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

                    // Map hyprland categories to UI categories
                    if (category === "Decoration" || category === "Shadows" || category === "Blur" || category === "Animation Style") {
                        category = "Appearance";
                    } else if (category === "Input" || category === "Gestures" || category === "Modifiers" || category === "Quickshell Keybinds") {
                        category = "Input";
                    } else {
                        category = "General";
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
                            enums = match[1].split(",").map(function (s) {
                                return s.trim();
                            });
                        }
                    } else if (typePart === "number" || typePart === "int") {
                        type = "number";
                    }

                    var min = 0;
                    var max = 0;
                    var step = 0;

                    if (type === "number") {
                        if (key === "gaps_in") {
                            type = "slider";
                            max = 50;
                            step = 1;
                        } else if (key === "gaps_out") {
                            type = "slider";
                            max = 100;
                            step = 1;
                        } else if (key === "singleWindowGapsOut") {
                            type = "slider";
                            max = 100;
                            step = 1;
                        } else if (key === "border_size") {
                            type = "slider";
                            max = 20;
                            step = 1;
                        } else if (key === "rounding") {
                            type = "slider";
                            max = 50;
                            step = 1;
                        } else if (key === "rounding_power") {
                            type = "slider";
                            min = 1.0;
                            max = 50.0;
                            step = 1.0;
                        } else if (key === "active_opacity" || key === "inactive_opacity" || key === "windowOpacity") {
                            type = "slider";
                            min = 0.0;
                            max = 1.0;
                            step = 0.05;
                        } else if (key === "shadow_range") {
                            type = "slider";
                            max = 100;
                            step = 1;
                        } else if (key === "shadow_render_power") {
                            type = "slider";
                            min = 1;
                            max = 4;
                            step = 1;
                        } else if (key === "blur_size") {
                            type = "slider";
                            max = 20;
                            step = 1;
                        } else if (key === "blur_passes") {
                            type = "slider";
                            max = 10;
                            step = 1;
                        } else if (key === "blur_vibrancy") {
                            type = "slider";
                            min = 0.0;
                            max = 1.0;
                            step = 0.05;
                        } else if (key === "gesture_fingers") {
                            type = "slider";
                            min = 3;
                            max = 5;
                            step = 1;
                        } else if (key === "env_xcursor_size" || key === "env_hyprcursor_size") {
                            type = "slider";
                            min = 16;
                            max = 64;
                            step = 2;
                        } else if (key === "vrr") {
                            type = "enum";
                            enums = ["0", "1", "2"];
                        }
                    }

                    newVars.push({
                        key: key,
                        type: type,
                        help: helpPart,
                        enums: enums.join("|||"),
                        val: valPart,
                        category: category,
                        source: "Hyprland",
                        min: min,
                        max: max,
                        step: step
                    });
                }

                rootPage.allVars = rootPage.allVars.concat(newVars);
                applyFilter();
            }
        }
    }

    Process {
        id: qsManagerProc
        command: ["omniformis", "qs", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n");
                var newVars = [];
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.length === 0)
                        continue;

                    var colonIdx = line.indexOf(":");
                    if (colonIdx === -1)
                        continue;

                    var key = line.substring(0, colonIdx).trim();
                    if (key === "notificationHistory" || key === "historyUpdated")
                        continue;

                    var valPart = line.substring(colonIdx + 1).trim();
                    if (valPart.startsWith('"') && valPart.endsWith('"')) {
                        valPart = valPart.substring(1, valPart.length - 1);
                    }

                    var type = "string";
                    if (valPart === "true" || valPart === "false") {
                        type = "bool";
                    } else if (!isNaN(Number(valPart)) && valPart !== "") {
                        type = "number";
                    }

                    var category = "Appearance";
                    if (key.startsWith("spacing") || key.startsWith("padding")) {
                        category = "General";
                    } else if (key === "animationDuration") {
                        category = "Appearance";
                    } else if (key.startsWith("radius")) {
                        category = "Appearance";
                    } else if (key === "overviewGridRows" || key === "overviewGridColumns" || key === "overviewScale" || key.startsWith("desktop") || key === "mediaPlayerShape") {
                        category = "General";
                    }

                    var min = 0;
                    var max = 0;
                    var step = 0;
                    if (key.includes("Duration")) {
                        type = "slider";
                        min = 0;
                        max = 1000;
                        step = 10;
                    } else if (key === "radiusAmount") {
                        type = "slider";
                        min = 0.0;
                        max = 1.0;
                        step = 0.05;
                    } else if (key.toLowerCase().includes("opacity")) {
                        type = "slider";
                        min = 0.0;
                        max = 1.0;
                        step = 0.1;
                    } else if (key.startsWith("radius") || key.startsWith("spacing") || key.startsWith("padding")) {
                        type = "slider";
                        min = 0;
                        max = 50;
                        step = 1;
                    } else if (key.includes("Scale")) {
                        type = "slider";
                        min = 0.1;
                        max = 2.0;
                        step = 0.05;
                    } else if (key === "wallpaperMaskOffsetX" || key === "wallpaperMaskOffsetY") {
                        type = "slider";
                        min = -500;
                        max = 500;
                        step = 1;
                    }

                    var enumsStr = "";
                    if (key === "wallpaperMaskShape") {
                        type = "shape";
                        enumsStr = "Circle|||Square|||Slanted|||Arch|||Flag|||Arrow|||Semicircle|||Oval|||Pill|||Triangle|||Diamond|||Clamshell|||Pentagon|||Gem|||VerySunny|||Sunny|||4SidedCookie|||6SidedCookie|||7SidedCookie|||9SidedCookie|||12SidedCookie|||GhostIsh|||4LeafClover|||8LeafClover|||Burst|||SoftBurst|||Boom|||SoftBoom|||Flower|||Puffy|||PuffyDiamond|||PixelCircle|||PixelTriangle|||Bun|||Heart";
                    } else if (key === "wallpaperMaskColor") {
                        type = "color";
                        enumsStr = "transparent|||background|||primary|||secondary|||tertiary|||surface_variant|||error";
                    } else if (key === "wallpaperMaskEnabled") {
                        type = "bool";
                    } else if (key === "clockShape") {
                        type = "shape";
                        enumsStr = "Circle|||Square|||VerySunny|||Sunny|||4SidedCookie|||6SidedCookie|||7SidedCookie|||9SidedCookie|||12SidedCookie|||SoftBurst|||SoftBoom|||Flower|||Puffy|||Bun";
                    } else if (key === "mediaPlayerShape") {
                        type = "shape";
                        enumsStr = "Circle|||Square|||Slanted|||Arch|||Flag|||Arrow|||Semicircle|||Oval|||Pill|||Triangle|||Diamond|||Clamshell|||Pentagon|||Gem|||VerySunny|||Sunny|||4SidedCookie|||6SidedCookie|||7SidedCookie|||9SidedCookie|||12SidedCookie|||GhostIsh|||4LeafClover|||8LeafClover|||Burst|||SoftBurst|||Boom|||SoftBoom|||Flower|||Puffy|||PuffyDiamond|||PixelCircle|||PixelTriangle|||Bun|||Heart";
                    } else if (key === "panelStyle") {
                        type = "enum";
                        enumsStr = "Floating|||Attached|||Framed";
                    }

                    newVars.push({
                        key: key,
                        type: type,
                        help: "Quickshell variable",
                        enums: enumsStr,
                        val: valPart,
                        category: category,
                        source: "Quickshell",
                        min: min,
                        max: max,
                        step: step
                    });
                }

                rootPage.allVars = rootPage.allVars.concat(newVars);
                applyFilter();
            }
        }
    }

    function applyFilter() {
        var term = searchInput.text.trim();
        settingsModel.clear();
        var filteredVars = [];
        for (var k = 0; k < rootPage.allVars.length; k++) {
            var v = rootPage.allVars[k];
            if (v.category !== rootPage.activeCategory)
                continue;
            if (term === "" || Vars.fuzzyMatch(term, v.key) || Vars.fuzzyMatch(term, v.help)) {
                filteredVars.push(v);
            }
        }
        filteredVars.sort(function (a, b) {
            if (a.source !== b.source) {
                return a.source.localeCompare(b.source);
            }
            return a.key.localeCompare(b.key);
        });
        for (var i = 0; i < filteredVars.length; i++) {
            settingsModel.append(filteredVars[i]);
        }
    }

    Item {
        id: fabContainer
        Layout.preferredWidth: 0
        Layout.preferredHeight: 0

        Item {
            id: reloadFab
            width: 64
            height: 64
            x: rootPage.width - width - 32 - fabContainer.x
            y: rootPage.height - height - 32 - fabContainer.y
            property real radius: width / 2
            z: 100

            Rectangle {
                id: fabMask
                anchors.fill: parent
                radius: reloadFab.radius
                color: "black"
                visible: false
                layer.enabled: true
                layer.samples: 4
            }

            Item {
                id: finalMaskedContainer
                anchors.fill: parent
                layer.enabled: true
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: fabMask
                    shadowEnabled: true
                    shadowBlur: 1.0
                    shadowColor: Qt.rgba(0,0,0,0.25)
                    shadowVerticalOffset: 4
                    shadowHorizontalOffset: 0
                }

                ShaderEffectSource {
                    anchors.fill: parent
                    sourceItem: settingsList
                    sourceRect: Qt.rect(rootPage.width - reloadFab.width - 32 - settingsList.x, rootPage.height - reloadFab.height - 32 - settingsList.y, reloadFab.width, reloadFab.height)
                    
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blurMax: 48
                        blur: 1.0
                        autoPaddingEnabled: false
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: Vars.translucent ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.4) : Theme.primary
                }
            }

            Text {
                id: fabIcon
                anchors.centerIn: parent
                text: "refresh"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 28
                color: Theme.on_primary
            }

            SequentialAnimation {
                id: fabShapeAnim
                NumberAnimation {
                    target: reloadFab
                    property: "radius"
                    to: 16
                    duration: 250
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: reloadFab
                    property: "radius"
                    to: 32
                    duration: 250
                    easing.type: Easing.InQuad
                }
                ScriptAction {
                    script: {
                        var reloadCmd = JSON.stringify(["sh", "-c", "setsid bash $HOME/Dotfiles/scripts/reload.sh > /dev/null 2>&1 &"]);
                        var p = Qt.createQmlObject('import Quickshell.Io; Process { command: ' + reloadCmd + '; onExited: destroy() }', rootPage);
                        p.running = true;
                    }
                }
            }

            SequentialAnimation {
                id: fabIconAnim
                RotationAnimation {
                    target: fabIcon
                    property: "rotation"
                    from: 0
                    to: 360
                    duration: 500
                    easing.type: Easing.InOutCubic
                }
                ScriptAction {
                    script: fabIcon.rotation = 0
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!fabShapeAnim.running) {
                        fabShapeAnim.start();
                        fabIconAnim.start();
                    }
                }
            }
        }
    }
}
