import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import "../.."
import "../../theme"
import "../../core/primitives" as Primitives

Item {
    id: delegateRoot

    M3Shapes { id: m3ShapesObj }

    property var settingsList: ListView.view
    property var settingsModel: ListView.view.model
    required property int index
    required property var model

    property int delegateIndex: index
    property string itemKey: model ? model.key : ""
    property string itemType: model ? model.type : ""
    property string itemHelp: model ? model.help : ""
    property string itemEnums: model ? model.enums : ""
    property string itemVal: model ? model.val : ""
    property string itemSource: model ? model.source : ""
    property real itemMin: model ? model.min : 0
    property real itemMax: model ? model.max : 0
    property real itemStep: model ? model.step : 0

    width: ListView.view.width
    height: Math.max(80, delegateRow.implicitHeight + 32)
    property bool isSelected: false
    
    property color targetColor: delegateMouse.containsMouse ? (Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)) : (Vars.tColor(Theme.surface_container_high, Vars.componentOpacity))
    Behavior on targetColor {
        ColorAnimation {
            duration: Vars.animationDuration
        }
    }
    
    scale: delegateMouse.pressed ? 1.08 : 1.0
    Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }
    
    
    Item {
        anchors.fill: parent
        opacity: parent.targetColor.a
        
        property bool isEffectivelyFirst: delegateRoot.ListView.previousSection !== delegateRoot.ListView.section
        property bool isEffectivelyLast: delegateRoot.ListView.nextSection !== delegateRoot.ListView.section

        Rectangle {
            antialiasing: true
            anchors.fill: parent
            color: Qt.rgba(parent.parent.targetColor.r, parent.parent.targetColor.g, parent.parent.targetColor.b, 1.0)
            
            topLeftRadius: parent.isEffectivelyFirst ? Vars.radiusLarge : 4
            topRightRadius: parent.isEffectivelyFirst ? Vars.radiusLarge : 4
            bottomLeftRadius: parent.isEffectivelyLast ? Vars.radiusLarge : 4
            bottomRightRadius: parent.isEffectivelyLast ? Vars.radiusLarge : 4

            Behavior on topLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
            Behavior on topRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
            Behavior on bottomLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
            Behavior on bottomRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        }
    }

    function triggerAction() {
        if (itemType === "bool") {
            var newVal = itemVal === "true" ? "false" : "true";
            settingsModel.setProperty(delegateIndex, "val", newVal);
            rootPage.updateVariable(itemKey, newVal, itemSource);
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

        // A fixed width rather than fillWidth: with only one fillWidth sibling competing (the
        // invisible spacer below, or a fillWidth value control), Qt's RowLayout handed nearly all
        // of the row's slack to WHICHEVER fillWidth item happened to have the larger size hint —
        // usually this column, since it has by far the largest preferred width — so it stretched to
        // a different width on every row depending on which control sat next to it (very wide next
        // to a small bool toggle, narrower next to a slider), leaving the whole list looking
        // uneven. Pinning it keeps every row's title column the same width.
        ColumnLayout {
            Layout.preferredWidth: 300
            Layout.minimumWidth: 200
            Layout.maximumWidth: 300
            spacing: 4
            QsText {
                text: rootPage ? rootPage.prettyTitle(delegateRoot.itemKey) : delegateRoot.itemKey
                font.family: Vars.fontFamily
                font.pixelSize: 16
                setWeight: Vars.fontWeight
                font.italic: Vars.fontItalic
                color: Theme.on_surface
            }
            QsText {
                text: rootPage ? rootPage.prettyHelp(delegateRoot.itemKey, (delegateRoot.itemType === "enum" || delegateRoot.itemType === "color") ? delegateRoot.itemHelp.replace(/\s*\(.*\)/, "") : delegateRoot.itemHelp) : delegateRoot.itemHelp
                font.family: Vars.fontFamily
                font.pixelSize: 12
                color: Theme.on_surface_variant
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
        }

        // Pushes a value control that can't position itself (the bool toggle, text/number fields,
        // the shape grid) over to the right edge. Excluded for controls that already claim
        // Layout.fillWidth and right-align their own content (the slider, and the enum/color chip
        // flows) — with the title column now fixed-width, this is the row's only other stretchy
        // item, so including it there too would just split the same growth between two things
        // instead of letting the control itself reach the edge.
        Item {
            Layout.fillWidth: true
            visible: delegateRoot.itemType !== "enum" && delegateRoot.itemType !== "presetManager" && delegateRoot.itemType !== "slider" && delegateRoot.itemType !== "color"
        }

        Rectangle {
            visible: delegateRoot.itemType === "bool"
            width: 52
            height: 32
            radius: 16
            antialiasing: true
            color: delegateRoot.itemVal === "true" ? (Vars.tColorSelected(Theme.primary)) : (Vars.tColor(Theme.surface_variant, Vars.componentOpacity))
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
                antialiasing: true
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

                QsText {
                    anchors.centerIn: parent
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 16
                    color: delegateRoot.itemVal === "true" ? (Vars.tColorSelected(Theme.primary)) : (Vars.tColor(Theme.surface_variant, Vars.componentOpacity))
                    text: delegateRoot.itemVal === "true" ? "\ue5ca" : "\ue5cd"
                }
            }

            scale: toggleMouse.pressed ? 1.08 : 1.0
            Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }

            MouseArea {
                id: toggleMouse
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    var newVal = delegateRoot.itemVal === "true" ? "false" : "true";
                    settingsModel.setProperty(delegateRoot.delegateIndex, "val", newVal);
                    rootPage.updateVariable(delegateRoot.itemKey, newVal, delegateRoot.itemSource);
                }
            }
        }

        Rectangle {
            visible: delegateRoot.itemType === "string" || (delegateRoot.itemType === "number" && parseFloat(delegateRoot.itemVal) >= 50)
            Layout.preferredWidth: Math.max(150, Math.min(450, tInput.implicitWidth + 32))
            height: 32
            radius: Vars.radiusSmall
            antialiasing: true
            color: Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)
            border.color: tInput.activeFocus ? Theme.primary : "transparent"
            border.width: 1

            TextField {
                id: tInput
                anchors.fill: parent
                verticalAlignment: TextInput.AlignVCenter
                text: delegateRoot.itemVal
                font.family: Vars.fontFamily
                font.pixelSize: 14
                color: Theme.on_surface
                selectByMouse: true
                clip: true
                background: Item {}
                padding: 0
                leftPadding: 8
                rightPadding: 8
                MouseArea { anchors.fill: parent; cursorShape: Qt.IBeamCursor; onPressed: (mouse) => { parent.forceActiveFocus(); mouse.accepted = false; } }
                
                onAccepted: {
                    tInput.focus = false;
                    settingsList.forceActiveFocus();
                }
                onEditingFinished: {
                    if (text !== delegateRoot.itemVal) {
                        settingsModel.setProperty(delegateRoot.delegateIndex, "val", text);
                        rootPage.updateVariable(delegateRoot.itemKey, text, delegateRoot.itemSource);
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
                antialiasing: true
                color: Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)
                border.color: numInput.activeFocus ? Theme.primary : "transparent"
                border.width: 1
                TextField {
                    id: numInput
                    anchors.fill: parent
                    verticalAlignment: TextInput.AlignVCenter
                    text: delegateRoot.itemVal
                    font.family: Vars.fontFamily
                    font.pixelSize: 14
                    color: Theme.on_surface
                    selectByMouse: true
                    clip: true
                    background: Item {}
                    padding: 0
                    leftPadding: 8
                    rightPadding: 8
                    MouseArea { anchors.fill: parent; cursorShape: Qt.IBeamCursor; onPressed: (mouse) => { parent.forceActiveFocus(); mouse.accepted = false; } }
                    
                    onAccepted: {
                        numInput.focus = false;
                        settingsList.forceActiveFocus();
                    }
                    onEditingFinished: {
                        if (text !== delegateRoot.itemVal) {
                            settingsModel.setProperty(delegateRoot.delegateIndex, "val", text);
                            rootPage.updateVariable(delegateRoot.itemKey, text, delegateRoot.itemSource);
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
                antialiasing: true
                color: numMinusHover.containsMouse ? (Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)) : (Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity))
                QsText {
                    anchors.centerIn: parent
                    text: "remove"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: Theme.on_surface
                }
                scale: numMinusHover.pressed ? 1.15 : 1.0
                Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }

                MouseArea {
                    id: numMinusHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var step = delegateRoot.itemStep > 0 ? delegateRoot.itemStep : 1;
                        var val = parseFloat(delegateRoot.itemVal) - step;
                        if (delegateRoot.itemMin !== 0 || delegateRoot.itemMax !== 0)
                            val = Math.max(delegateRoot.itemMin, val);
                        val = Number(val.toFixed(4));
                        settingsModel.setProperty(delegateRoot.delegateIndex, "val", val.toString());
                        rootPage.updateVariable(delegateRoot.itemKey, val.toString(), delegateRoot.itemSource);
                    }
                }
            }

            Rectangle {
                width: 32
                height: 32
                radius: Vars.radiusSmall
                antialiasing: true
                color: numPlusHover.containsMouse ? (Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)) : (Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity))
                QsText {
                    anchors.centerIn: parent
                    text: "add"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: Theme.on_surface
                }
                scale: numPlusHover.pressed ? 1.15 : 1.0
                Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }

                MouseArea {
                    id: numPlusHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        var step = delegateRoot.itemStep > 0 ? delegateRoot.itemStep : 1;
                        var val = parseFloat(delegateRoot.itemVal) + step;
                        if (delegateRoot.itemMin !== 0 || delegateRoot.itemMax !== 0)
                            val = Math.min(delegateRoot.itemMax, val);
                        val = Number(val.toFixed(4));
                        settingsModel.setProperty(delegateRoot.delegateIndex, "val", val.toString());
                        rootPage.updateVariable(delegateRoot.itemKey, val.toString(), delegateRoot.itemSource);
                    }
                }
            }
        }

        Primitives.Slider {
            id: m3Slider
            visible: delegateRoot.itemType === "slider"
            Layout.fillWidth: true
            Layout.preferredWidth: 320
            implicitHeight: 48
            padding: 0
            trackHeight: 36
            enableTicks: true
            enableContextMenu: true

            property real computedMax: {
                if (delegateRoot.itemKey.endsWith("AnchorCurve")) {
                    var peaks = m3ShapesObj.getShapePeaks(Vars.wallpaperMaskShape);
                    return peaks.length > 0 ? peaks.length - 1 : -1;
                }
                return delegateRoot.itemMax;
            }

            from: delegateRoot.itemMin
            to: computedMax
            stepSize: delegateRoot.itemStep
            value: parseFloat(delegateRoot.itemVal)

            clipboardValue: rootPage ? rootPage.copiedSliderValue : ""

            onMoved: {
                var rounded = Number((value).toFixed(3));
                if (isCentered && Math.abs(rounded) <= Math.abs(computedMax - delegateRoot.itemMin) * 0.02) {
                    rounded = 0;
                    value = 0;
                }
                settingsModel.setProperty(delegateRoot.delegateIndex, "val", rounded.toString());
                if (delegateRoot.itemSource === "Quickshell" || delegateRoot.itemSource === "quickshell") {
                    try {
                        Vars[delegateRoot.itemKey] = rounded;
                    } catch (e) {
                        console.warn("SettingsApp: Failed to update live slider variable: " + delegateRoot.itemKey + " = " + rounded + ". Error: " + e);
                    }
                }
            }

            onPressedChanged: {
                if (!pressed) {
                    var rounded = Number((value).toFixed(3));
                    if (isCentered && Math.abs(rounded) <= Math.abs(computedMax - delegateRoot.itemMin) * 0.02) {
                        rounded = 0;
                        value = 0;
                    }
                    rootPage.updateVariable(delegateRoot.itemKey, rounded.toString(), delegateRoot.itemSource);
                }
            }

            onValueCopied: function(value) {
                rootPage.copiedSliderValue = value;
            }

            onValuePasted: function(value) {
                settingsModel.setProperty(delegateRoot.delegateIndex, "val", value.toString());
                rootPage.updateVariable(delegateRoot.itemKey, value.toString(), delegateRoot.itemSource);
            }

            onValueReset: function(value) {
                settingsModel.setProperty(delegateRoot.delegateIndex, "val", value.toString());
                rootPage.updateVariable(delegateRoot.itemKey, value.toString(), delegateRoot.itemSource);
            }
        }

        Item {
            visible: delegateRoot.itemType === "enum"
            Layout.fillWidth: true
            Layout.minimumWidth: 400
            implicitHeight: enumFlow.implicitHeight

            Flow {
                id: enumFlow
                width: parent.width
                anchors.right: parent.right
                layoutDirection: Qt.RightToLeft
                spacing: 2
                Repeater {
                    id: enumRepeater
                    model: {
                        if (!parent.visible) return [];
                        return delegateRoot.itemEnums.split("|||").reverse();
                    }
                    delegate: Rectangle {
                        antialiasing: true
                        property bool isSelected: delegateRoot.itemVal === modelData
                        property var prevItem: index > 0 ? enumRepeater.itemAt(index - 1) : null
                        property var nextItem: index < (enumRepeater.count - 1) ? enumRepeater.itemAt(index + 1) : null
                        property bool isRTL: enumFlow.layoutDirection === Qt.RightToLeft
                        property var visualLeftItem: isRTL ? nextItem : prevItem
                        property var visualRightItem: isRTL ? prevItem : nextItem
                        
                        property bool hasLeft: visualLeftItem && visualLeftItem.y === y
                        property bool hasRight: visualRightItem && visualRightItem.y === y

                        height: 32
                        width: chipText.implicitWidth + 24

                        property real baseRadius: Vars.radiusLarge
                        topLeftRadius: isSelected ? baseRadius : (hasLeft ? 4 : baseRadius)
                        bottomLeftRadius: isSelected ? baseRadius : (hasLeft ? 4 : baseRadius)
                        topRightRadius: isSelected ? baseRadius : (hasRight ? 4 : baseRadius)
                        bottomRightRadius: isSelected ? baseRadius : (hasRight ? 4 : baseRadius)

                        Behavior on topLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                        Behavior on bottomLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                        Behavior on topRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                        Behavior on bottomRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

                        scale: chipMouse.pressed ? 1.08 : 1.0
                        Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }

                        color: isSelected ? (Vars.tColorSelected(Theme.primary)) : (Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity))

                        Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

                        QsText {
                            id: chipText
                            anchors.centerIn: parent
                            text: modelData
                            font.family: Vars.fontFamily
                            font.pixelSize: 13
                            color: isSelected ? Theme.on_primary : Theme.on_surface
                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                        }
                        MouseArea {
                            id: chipMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                settingsModel.setProperty(delegateRoot.delegateIndex, "val", modelData);
                                rootPage.updateVariable(delegateRoot.itemKey, modelData, delegateRoot.itemSource);
                            }
                        }
                    }
                }
            }
        }

        Grid {
            visible: delegateRoot.itemType === "shape"
            columns: 6
            spacing: 2
            Repeater {
                id: shapeRepeater
                model: parent.visible ? delegateRoot.itemEnums.split("|||") : []
                delegate: Rectangle {
                    antialiasing: true
                    property bool isSelected: delegateRoot.itemVal === modelData

                    property bool hasLeft: index % 6 !== 0
                    property bool hasRight: index % 6 !== 5 && index !== shapeRepeater.count - 1

                    height: 36
                    width: 48

                    topLeftRadius: isSelected ? height / 2 : (hasLeft ? 4 : height / 2)
                    bottomLeftRadius: isSelected ? height / 2 : (hasLeft ? 4 : height / 2)
                    topRightRadius: isSelected ? height / 2 : (hasRight ? 4 : height / 2)
                    bottomRightRadius: isSelected ? height / 2 : (hasRight ? 4 : height / 2)

                    Behavior on topLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                    Behavior on bottomLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                    Behavior on topRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                    Behavior on bottomRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

                    color: isSelected ? (Vars.tColorSelected(Theme.primary)) : (Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity))
                    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

                    Shape {
                        width: 100
                        height: 100
                        anchors.centerIn: parent
                        scale: 0.24
                        antialiasing: true
                        preferredRendererType: Shape.CurveRenderer

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
                            rootPage.updateVariable(delegateRoot.itemKey, modelData, delegateRoot.itemSource);
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
                // Always RightToLeft, like the enum chip flow below — with 5 or more swatches this
                // used to switch to LeftToRight, which (since the Item above is stretched to fill
                // whatever space the row has going spare) packed every swatch against the Item's
                // left edge and left a bare gap between them and the row's actual right edge.
                layoutDirection: Qt.RightToLeft
                spacing: 2
                Repeater {
                    id: colorRepeater
                    model: {
                        if (!parent.visible) return [];
                        return delegateRoot.itemEnums.split("|||").reverse();
                    }
                    delegate: Rectangle {
                        property bool isSelected: delegateRoot.itemVal === modelData
                        height: 32
                        width: 32
                        radius: height / 2
                        antialiasing: true
                        border.width: isSelected ? 2 : (modelData === "transparent" ? 1 : 0)
                        border.color: isSelected ? Theme.on_surface : Theme.outline

                        color: {
                            if (modelData === "transparent") return "transparent";
                            if (modelData === "background") return Theme.background;
                            if (modelData === "primary") return Theme.primary;
                            if (modelData === "secondary") return Theme.secondary;
                            if (modelData === "tertiary") return Theme.tertiary;
                            if (modelData === "surface_variant") return Theme.surface_variant;
                            if (modelData === "error") return Theme.error;
                            return "transparent";
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                settingsModel.setProperty(delegateRoot.delegateIndex, "val", modelData);
                                rootPage.updateVariable(delegateRoot.itemKey, modelData, delegateRoot.itemSource);
                            }
                        }
                    }
                }
            }
        }

        // Saves the audio visualizer's shape/layout/size/spacing/radius as a named preset (stored
        // as a JSON blob in the same Vars.desktopAudioVisualizerPresets variable everything else
        // here persists through), and lets a saved one be reapplied or removed. Given its own
        // full-width Item (like the enum/shape/color controls do) instead of squeezing into the
        // narrow value column, since a name field + button + wrapping chip list need real room.
        Item {
            id: presetManagerWrap
            visible: delegateRoot.itemType === "presetManager"
            Layout.fillWidth: true
            Layout.minimumWidth: 400
            implicitHeight: presetManagerBox.implicitHeight

            ColumnLayout {
                id: presetManagerBox
                width: parent.width
                spacing: 10

                function currentPresets() {
                    try {
                        var arr = JSON.parse(Vars.desktopAudioVisualizerPresets || "[]");
                        return Array.isArray(arr) ? arr : [];
                    } catch (e) {
                        return [];
                    }
                }

                function persist(arr) {
                    var json = JSON.stringify(arr);
                    settingsModel.setProperty(delegateRoot.delegateIndex, "val", json);
                    rootPage.updateVariable(delegateRoot.itemKey, json, delegateRoot.itemSource);
                }

                function savePreset(name) {
                    var trimmed = (name || "").trim();
                    if (!trimmed) return;
                    var arr = presetManagerBox.currentPresets();
                    var entry = {
                        name: trimmed,
                        shape: Vars.desktopAudioVisualizerShape,
                        shapeMode: Vars.desktopAudioVisualizerShapeMode,
                        colorMode: Vars.desktopAudioVisualizerColorMode,
                        color: Vars.desktopAudioVisualizerColor,
                        gradientStart: Vars.desktopAudioVisualizerGradientStart,
                        gradientEnd: Vars.desktopAudioVisualizerGradientEnd,
                        layout: Vars.desktopAudioVisualizerLayout,
                        lineArrangement: Vars.desktopAudioVisualizerLineArrangement,
                        lineThickness: Vars.desktopAudioVisualizerLineThickness,
                        lineMirror: Vars.desktopAudioVisualizerLineMirror,
                        lineDirection: Vars.desktopAudioVisualizerLineDirection,
                        positionShape: Vars.desktopAudioVisualizerPositionShape,
                        shapeSize: Vars.desktopAudioVisualizerShapeSize,
                        spacing: Vars.desktopAudioVisualizerSpacing,
                        radius: Vars.desktopAudioVisualizerRadius
                    };
                    var idx = arr.findIndex(function(p) { return p.name === trimmed; });
                    if (idx >= 0) arr[idx] = entry; else arr.push(entry);
                    presetManagerBox.persist(arr);
                    presetNameInput.text = "";
                }

                function applyPreset(p) {
                    rootPage.updateVariable("desktopAudioVisualizerShape", p.shape, delegateRoot.itemSource);
                    rootPage.updateVariable("desktopAudioVisualizerShapeMode", p.shapeMode || "Single", delegateRoot.itemSource);
                    rootPage.updateVariable("desktopAudioVisualizerColorMode", p.colorMode || "Theme", delegateRoot.itemSource);
                    rootPage.updateVariable("desktopAudioVisualizerColor", p.color || "primary", delegateRoot.itemSource);
                    rootPage.updateVariable("desktopAudioVisualizerGradientStart", p.gradientStart || "primary", delegateRoot.itemSource);
                    rootPage.updateVariable("desktopAudioVisualizerGradientEnd", p.gradientEnd || "tertiary", delegateRoot.itemSource);
                    rootPage.updateVariable("desktopAudioVisualizerLayout", p.layout, delegateRoot.itemSource);
                    rootPage.updateVariable("desktopAudioVisualizerLineArrangement", p.lineArrangement || "Row", delegateRoot.itemSource);
                    rootPage.updateVariable("desktopAudioVisualizerLineThickness", String(p.lineThickness || 4), delegateRoot.itemSource);
                    rootPage.updateVariable("desktopAudioVisualizerLineMirror", p.lineMirror ? "true" : "false", delegateRoot.itemSource);
                    rootPage.updateVariable("desktopAudioVisualizerLineDirection", p.lineDirection || "Left to Right", delegateRoot.itemSource);
                    rootPage.updateVariable("desktopAudioVisualizerPositionShape", p.positionShape || "Circle", delegateRoot.itemSource);
                    rootPage.updateVariable("desktopAudioVisualizerShapeSize", String(p.shapeSize), delegateRoot.itemSource);
                    rootPage.updateVariable("desktopAudioVisualizerSpacing", String(p.spacing), delegateRoot.itemSource);
                    rootPage.updateVariable("desktopAudioVisualizerRadius", String(p.radius), delegateRoot.itemSource);
                    // Those keys live in other rows of this same list — reload so their sliders
                    // and shape/enum pickers reflect the preset immediately instead of on next open.
                    rootPage.loadSettings();
                }

                function deletePreset(name) {
                    var arr = presetManagerBox.currentPresets().filter(function(p) { return p.name !== name; });
                    presetManagerBox.persist(arr);
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.preferredWidth: 180
                        height: 36
                        radius: Vars.radiusSmall
                        antialiasing: true
                        color: Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)
                        border.color: presetNameInput.activeFocus ? Theme.primary : "transparent"
                        border.width: 1

                        TextField {
                            id: presetNameInput
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            placeholderText: "Preset name"
                            font.family: Vars.fontFamily
                            font.pixelSize: 13
                            color: Theme.on_surface
                            selectByMouse: true
                            clip: true
                            background: Item {}
                            padding: 0
                            leftPadding: 10
                            rightPadding: 10
                            MouseArea { anchors.fill: parent; cursorShape: Qt.IBeamCursor; onPressed: (mouse) => { parent.forceActiveFocus(); mouse.accepted = false; } }
                            onAccepted: presetManagerBox.savePreset(text)
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: saveRow.implicitWidth + 24
                        height: 36
                        radius: Vars.radiusSmall
                        antialiasing: true
                        opacity: presetNameInput.text.trim().length > 0 ? 1.0 : 0.5
                        color: saveMouse.containsMouse ? (Vars.tColorSelected(Theme.primary)) : (Vars.tColor(Theme.primary, 0.9))
                        Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                        Behavior on opacity { NumberAnimation { duration: Vars.animationDuration } }
                        scale: saveMouse.pressed ? 1.05 : 1.0
                        Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }

                        RowLayout {
                            id: saveRow
                            anchors.centerIn: parent
                            spacing: 4
                            QsText {
                                text: "add"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 16
                                color: Theme.on_primary
                            }
                            QsText {
                                text: "Save Preset"
                                font.family: Vars.fontFamily
                                font.pixelSize: 12
                                setWeight: 600
                                color: Theme.on_primary
                            }
                        }

                        MouseArea {
                            id: saveMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: presetNameInput.text.trim().length > 0
                            onClicked: presetManagerBox.savePreset(presetNameInput.text)
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                QsText {
                    Layout.fillWidth: true
                    visible: presetRepeater.count === 0
                    text: "No presets saved yet — name one above and hit Save Preset."
                    font.family: Vars.fontFamily
                    font.pixelSize: 12
                    color: Theme.on_surface_variant
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 8
                    visible: presetRepeater.count > 0

                    Repeater {
                        id: presetRepeater
                        model: presetManagerBox.currentPresets()
                        delegate: Rectangle {
                            id: presetChip
                            required property var modelData
                            radius: height / 2
                            height: 32
                            width: chipRow.implicitWidth + 8
                            antialiasing: true
                            color: Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)

                            RowLayout {
                                id: chipRow
                                anchors.centerIn: parent
                                spacing: 2

                                QsText {
                                    text: presetChip.modelData.name
                                    font.family: Vars.fontFamily
                                    font.pixelSize: 12
                                    setWeight: 600
                                    color: Theme.on_surface
                                    Layout.leftMargin: 12
                                    Layout.rightMargin: 2
                                }

                                Rectangle {
                                    width: 24
                                    height: 24
                                    radius: 12
                                    antialiasing: true
                                    color: applyMouse.containsMouse ? (Vars.tColorSelected(Theme.primary)) : "transparent"
                                    Behavior on color { ColorAnimation { duration: Vars.animationDuration } }

                                    QsText {
                                        anchors.centerIn: parent
                                        text: "check"
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 14
                                        color: applyMouse.containsMouse ? Theme.on_primary : Theme.primary
                                    }

                                    MouseArea {
                                        id: applyMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: presetManagerBox.applyPreset(presetChip.modelData)
                                    }
                                }

                                Rectangle {
                                    width: 24
                                    height: 24
                                    radius: 12
                                    antialiasing: true
                                    Layout.rightMargin: 4
                                    color: deleteMouse.containsMouse ? Theme.error : "transparent"
                                    Behavior on color { ColorAnimation { duration: Vars.animationDuration } }

                                    QsText {
                                        anchors.centerIn: parent
                                        text: "close"
                                        font.family: "Material Symbols Outlined"
                                        font.pixelSize: 14
                                        color: deleteMouse.containsMouse ? Theme.on_error : Theme.error
                                    }

                                    MouseArea {
                                        id: deleteMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: presetManagerBox.deletePreset(presetChip.modelData.name)
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
