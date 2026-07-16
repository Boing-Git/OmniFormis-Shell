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
    property string activeCategory: "General"
    onActiveCategoryChanged: applyFilter()

    function updateVariable(key, val, source) {
        var isQs = source === "Quickshell" || source === "quickshell";
        var cmd = isQs ? '["omniformis", "qs", "set", "' + key + '", "' + val + '"]' : '["omniformis", "hypr", "--' + key + '", "' + val + '"]';
        var proc = Qt.createQmlObject('import Quickshell.Io; Process { command: ' + cmd + '; onExited: destroy() }', rootPage);
        proc.running = true;

        if (isQs) {
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
        flickDeceleration: 1000
        maximumFlickVelocity: 4000
        focus: true
        KeyNavigation.up: searchInput

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

        delegate: Rectangle {
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
            radius: 16
            color: delegateMouse.containsMouse ? Qt.tint(Theme.surface_container, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : Theme.surface_container
            Behavior on color {
                ColorAnimation {
                    duration: Vars.animationDuration
                }
            }

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
                opacity: (index < settingsModel.count - 1 && settingsModel.get(index).source === settingsModel.get(index + 1).source) ? 1.0 : 0.0
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
                opacity: (index < settingsModel.count - 1 && settingsModel.get(index).source === settingsModel.get(index + 1).source) ? 1.0 : 0.0
                Behavior on opacity {
                    NumberAnimation {
                        duration: Vars.animationDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Vars.customExpressiveSpatialSlow
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
                onClicked: {
                    settingsList.currentIndex = delegateRoot.delegateIndex;
                }
            }

            RowLayout {
                id: delegateRow
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
                    visible: delegateRoot.itemType === "slider"
                    Layout.fillWidth: true
                    Layout.preferredWidth: 320
                    implicitHeight: 48
                    padding: 0

                    from: delegateRoot.itemMin
                    to: delegateRoot.itemMax
                    stepSize: delegateRoot.itemStep
                    value: parseFloat(delegateRoot.itemVal)

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

                    background: Item {
                        x: parent.leftPadding
                        y: parent.topPadding + (parent.availableHeight - 40) / 2
                        width: parent.availableWidth
                        height: 40

                        // LEFT TRACK (Active Fill)
                        Item {
                            x: 0
                            y: 0
                            height: parent.height
                            width: Math.max(0, (parent.parent.visualPosition * (parent.width - 4)) - 4)
                            clip: true
                            Rectangle {
                                width: parent.parent.width
                                height: parent.height
                                radius: 12
                                color: Theme.primary
                            }
                        }

                        // RIGHT TRACK (Inactive Base)
                        Item {
                            x: (parent.parent.visualPosition * (parent.width - 4)) + 4 + 4
                            y: 0
                            height: parent.height
                            width: Math.max(0, parent.width - x)
                            clip: true
                            Rectangle {
                                x: -parent.x
                                width: parent.parent.width
                                height: parent.height
                                radius: 12
                                color: Theme.surface_container_highest
                            }
                        }
                    }

                    handle: Rectangle {
                        x: parent.leftPadding + parent.visualPosition * (parent.availableWidth - width)
                        y: parent.topPadding + (parent.availableHeight - height) / 2
                        width: 4
                        height: 50
                        radius: 2
                        color: Theme.primary
                    }
                }

                Flow {
                    visible: delegateRoot.itemType === "enum"
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: parent.visible ? delegateRoot.itemEnums.split("|||") : []
                        delegate: Rectangle {
                            property bool isSelected: delegateRoot.itemVal === modelData
                            height: 32
                            width: chipText.implicitWidth + 24
                            radius: height / 2
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

                Flow {
                    visible: delegateRoot.itemType === "color"
                    Layout.fillWidth: true
                    spacing: 8
                    Repeater {
                        model: parent.visible ? delegateRoot.itemEnums.split("|||") : []
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

                    newVars.push({
                        key: key,
                        type: type,
                        help: helpPart,
                        enums: enums.join("|||"),
                        val: valPart,
                        category: category,
                        source: "Hyprland",
                        min: 0,
                        max: 0,
                        step: 0
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
                    } else if (key === "overviewGridRows" || key === "overviewGridColumns" || key === "overviewScale") {
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
                    }

                    var enumsStr = "";
                    if (key === "wallpaperMaskShape") {
                        type = "enum";
                        enumsStr = "Circle|||Square|||Slanted|||Arch|||Flag|||Arrow|||Semicircle|||Oval|||Pill|||Triangle|||Diamond|||Clamshell|||Pentagon|||Gem|||VerySunny|||Sunny|||4SidedCookie|||6SidedCookie|||7SidedCookie|||9SidedCookie|||12SidedCookie|||GhostIsh|||4LeafClover|||8LeafClover|||Burst|||SoftBurst|||Boom|||SoftBoom|||Flower|||Puffy|||PuffyDiamond|||PixelCircle|||PixelTriangle|||Bun|||Heart";
                    } else if (key === "wallpaperMaskColor") {
                        type = "color";
                        enumsStr = "transparent|||background|||primary|||secondary|||tertiary|||surface_variant|||error";
                    } else if (key === "wallpaperMaskEnabled") {
                        type = "bool";
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
        for (var k = 0; k < rootPage.allVars.length; k++) {
            var v = rootPage.allVars[k];
            if (v.category !== rootPage.activeCategory)
                continue;
            if (term === "" || Vars.fuzzyMatch(term, v.key) || Vars.fuzzyMatch(term, v.help)) {
                settingsModel.append(v);
            }
        }
    }
}
