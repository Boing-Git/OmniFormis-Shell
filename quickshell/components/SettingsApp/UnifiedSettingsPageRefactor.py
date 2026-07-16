import re

with open("UnifiedSettingsPage.qml", "r") as f:
    content = f.read()

# 1. Update hyprManagerProc parsing to add min, max, step default values
content = content.replace(
    'newVars.push({ key: key, type: type, help: helpPart, enums: enums.join("|||"), val: valPart, category: category, source: "Hyprland" });',
    'newVars.push({ key: key, type: type, help: helpPart, enums: enums.join("|||"), val: valPart, category: category, source: "Hyprland", min: 0, max: 0, step: 0 });'
)

# 2. Update qsManagerProc parsing to assign slider types and min/max/step
new_qs_parsing = """                    var min = 0; var max = 0; var step = 0;
                    if (key.includes("Duration")) {
                        type = "slider"; min = 0; max = 1000; step = 10;
                    } else if (key.startsWith("radius") || key.startsWith("spacing") || key.startsWith("padding")) {
                        type = "slider"; min = 0; max = 100; step = 1;
                    } else if (key.includes("Scale")) {
                        type = "slider"; min = 0.1; max = 2.0; step = 0.05;
                    }
                    
                    var enumsStr = "";
                    if (key === "wallpaperMaskShape") {
                        type = "enum";
                        enumsStr = "Circle|||Square|||Squircle|||Hexagon|||Octagon|||Star 4|||Star 5|||Star 6|||Star 8|||Clover 4|||Clover 8|||Scallop 8|||Scallop 12|||Burst 8|||Burst 12|||Cross|||Diamond|||Pentagon|||Heptagon|||Nonagon|||Decagon|||Dodecagon|||Star 12|||Star 16|||Clover 6|||Scallop 6|||Burst 6|||Burst 16|||Gear 8|||Gear 12|||Blob 1|||Blob 2|||Blob 3|||Blob 4|||Blob 5";
                    }
                    
                    newVars.push({ key: key, type: type, help: "Quickshell variable", enums: enumsStr, val: valPart, category: category, source: "Quickshell", min: min, max: max, step: step });"""

content = re.sub(
    r'                    var enumsStr = "";\n                    if \(key === "wallpaperMaskShape"\) \{.*?\n                    newVars\.push\(\{ key: key, type: type, help: "Quickshell variable", enums: enumsStr, val: valPart, category: category, source: "Quickshell" \}\);',
    new_qs_parsing,
    content,
    flags=re.DOTALL
)

# 3. Update delegate properties
content = content.replace(
    'property string itemSource: model.source',
    'property string itemSource: model.source\n            property real itemMin: model.min\n            property real itemMax: model.max\n            property real itemStep: model.step'
)

# 4. Update delegate height to handle dynamic wrapping
content = content.replace('height: 80', 'height: Math.max(80, delegateRow.implicitHeight + 32)')
# Also add id: delegateRow to the RowLayout inside delegate
content = content.replace('RowLayout {\n                anchors.fill: parent\n                anchors.margins: Vars.spacingLarge\n                spacing: Vars.spacingMedium', 'RowLayout {\n                id: delegateRow\n                anchors.fill: parent\n                anchors.margins: Vars.spacingLarge\n                spacing: Vars.spacingMedium')

# 5. Add Slider to the delegate UI
slider_code = """
                Slider {
                    visible: delegateRoot.itemType === "slider"
                    Layout.fillWidth: true
                    Layout.preferredWidth: 320
                    implicitHeight: 40
                    padding: 0
                    
                    from: delegateRoot.itemMin
                    to: delegateRoot.itemMax
                    stepSize: delegateRoot.itemStep
                    value: parseFloat(delegateRoot.itemVal)
                    
                    onMoved: {
                        var rounded = Number((value).toFixed(3));
                        settingsModel.setProperty(delegateRoot.delegateIndex, "val", rounded.toString());
                        updateVariable(delegateRoot.itemKey, rounded.toString(), delegateRoot.itemSource);
                    }
                    
                    background: Item {
                        x: parent.leftPadding
                        y: parent.topPadding + (parent.availableHeight - 40) / 2
                        width: parent.availableWidth
                        height: 40
                        
                        Item {
                            x: 0; y: 0; height: parent.height
                            width: Math.max(0, parent.parent.visualPosition * (parent.width - 4) - 4)
                            clip: true
                            Rectangle {
                                width: parent.parent.width
                                height: parent.height
                                radius: 12
                                color: Theme.primary
                            }
                        }
                        
                        Item {
                            x: parent.parent.visualPosition * (parent.width - 4) + 4
                            y: 0; height: parent.height
                            width: parent.width - x
                            clip: true
                            Rectangle {
                                x: -parent.x
                                width: parent.parent.width
                                height: parent.height
                                radius: 12
                                color: Theme.surface_container_highest
                            }
                        }
                        
                        Rectangle {
                            x: parent.parent.visualPosition * (parent.width - 4)
                            y: 0; width: 4; height: 40
                            color: Theme.background
                        }
                    }
                }"""

# 6. Add Flow layout for enums to replace ComboBox
flow_code = """
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
                            
                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                            
                            Text {
                                id: chipText
                                anchors.centerIn: parent
                                text: modelData
                                font.family: Vars.fontFamily
                                font.pixelSize: 13
                                color: isSelected ? Theme.on_primary : Theme.on_surface
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
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
                }"""

# Replace the ComboBox with the Flow and add the Slider
content = re.sub(r'                ComboBox \{.*?\n                        \}\n                    \}\n                \}', slider_code + '\n' + flow_code, content, flags=re.DOTALL)

with open("UnifiedSettingsPage.qml", "w") as f:
    f.write(content)
