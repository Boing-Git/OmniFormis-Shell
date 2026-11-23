import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../../theme"

// The M3-style slider used everywhere in the shell: an icon-led fill track with a thin pill
// handle, used by Control Center's Sliders.qml and the Volume/Brightness OSDs (horizontal +
// vertical). The handle thickens while pressed for a clearer grab affordance.
//
// Settings uses the same component with `enableTicks`/`enableContextMenu` turned on: it adds
// tick marks along the track, a "centered" track mode for signed ranges (grows from the middle
// instead of the left edge), and a right-click Copy/Paste/Reset Value menu.
Slider {
    id: root

    implicitWidth: orientation === Qt.Vertical ? trackHeight : 320
    implicitHeight: orientation === Qt.Vertical ? 320 : 48 // Strict M3 48dp minimum touch target
    padding: 0

    property string icon: ""
    property int trackHeight: 40
    property int gap: 4
    property int handleWidth: 4
    property int handleWidthPressed: 8
    property real leftRadiusLarge: 6
    property real leftRadiusSmall: 2
    property real dotSize: 6

    // Settings-only extras, off by default so Control Center / OSD sliders render unchanged.
    property bool enableTicks: false
    property bool enableContextMenu: false
    property bool isCentered: from < 0
    property bool showTicks: enableTicks && stepSize > 0 && ((to - from) / stepSize) <= 25
    property string clipboardValue: ""

    signal valueCopied(string value)
    signal valuePasted(real value)
    signal valueReset(real value)

    snapMode: showTicks ? Slider.SnapAlways : Slider.NoSnap

    property real currentHandleWidth: root.pressed ? handleWidthPressed : handleWidth
    Behavior on currentHandleWidth { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    Loader {
        active: root.enableContextMenu
        anchors.fill: parent
        sourceComponent: MouseArea {
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
                    color: Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)
                    radius: 12
                    antialiasing: true
                    border.color: Theme.outline_variant
                    border.width: 1
                }

                MenuItem {
                    enabled: false
                    implicitWidth: 220
                    implicitHeight: 36
                    contentItem: Item {
                        QsText {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Value"
                            color: Theme.on_surface_variant
                            font.family: Vars.fontFamily
                            font.pixelSize: 13
                        }
                        QsText {
                            anchors.right: parent.right
                            anchors.rightMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: Number(root.value).toFixed(3)
                            color: Theme.on_surface
                            font.family: Vars.fontFamily
                            font.pixelSize: 14
                            setWeight: Vars.fontWeight
                            font.italic: Vars.fontItalic
                        }
                    }
                    background: Rectangle { color: "transparent" }
                }

                MenuSeparator {
                    implicitWidth: 220
                    implicitHeight: 12
                    contentItem: Rectangle {
                        implicitWidth: 188
                        implicitHeight: 1
                        color: Qt.rgba(Theme.outline_variant.r, Theme.outline_variant.g, Theme.outline_variant.b, Vars.componentOpacity)
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
                        QsText {
                            text: ""
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 18
                            color: parent.parent.highlighted ? Theme.primary : Theme.on_surface_variant
                        }
                        QsText {
                            Layout.fillWidth: true
                            text: "Copy Value"
                            color: parent.parent.highlighted ? Theme.primary : Theme.on_surface
                            font.family: Vars.fontFamily
                            font.pixelSize: 14
                            setWeight: Vars.fontWeight
                            font.italic: Vars.fontItalic
                        }
                    }
                    background: Rectangle {
                        color: parent.highlighted ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
                        radius: 8
                        antialiasing: true
                        anchors.fill: parent
                        anchors.margins: 4
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    onTriggered: root.valueCopied(Number(root.value).toFixed(3).toString())
                }

                MenuItem {
                    implicitWidth: 220
                    implicitHeight: 40
                    enabled: root.clipboardValue !== undefined && root.clipboardValue !== ""
                    contentItem: RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12
                        QsText {
                            text: ""
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 18
                            color: parent.enabled ? (parent.parent.highlighted ? Theme.primary : Theme.on_surface_variant) : Theme.outline
                        }
                        QsText {
                            Layout.fillWidth: true
                            text: "Paste Value"
                            color: parent.enabled ? (parent.parent.highlighted ? Theme.primary : Theme.on_surface) : Theme.outline
                            font.family: Vars.fontFamily
                            font.pixelSize: 14
                            setWeight: Vars.fontWeight
                            font.italic: Vars.fontItalic
                        }
                        QsText {
                            text: root.clipboardValue ? Number(root.clipboardValue).toFixed(3) : ""
                            color: Theme.on_surface_variant
                            font.family: Vars.fontFamily
                            font.pixelSize: 12
                        }
                    }
                    background: Rectangle {
                        color: parent.highlighted ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
                        radius: 8
                        antialiasing: true
                        anchors.fill: parent
                        anchors.margins: 4
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    onTriggered: {
                        if (root.clipboardValue !== "") {
                            var rounded = Number((parseFloat(root.clipboardValue)).toFixed(3));
                            root.value = rounded;
                            root.valuePasted(rounded);
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
                        QsText {
                            text: ""
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 18
                            color: parent.parent.highlighted ? Theme.error : Theme.on_surface_variant
                        }
                        QsText {
                            Layout.fillWidth: true
                            text: "Reset Value"
                            color: parent.parent.highlighted ? Theme.error : Theme.on_surface
                            font.family: Vars.fontFamily
                            font.pixelSize: 14
                            setWeight: Vars.fontWeight
                            font.italic: Vars.fontItalic
                        }
                    }
                    background: Rectangle {
                        color: parent.highlighted ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.12) : "transparent"
                        radius: 8
                        antialiasing: true
                        anchors.fill: parent
                        anchors.margins: 4
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    onTriggered: {
                        var safeDefault = Math.max(root.from, Math.min(0, root.to));
                        if (root.value !== safeDefault) {
                            root.value = safeDefault;
                            root.valueReset(safeDefault);
                        }
                    }
                }
            }
        }
    }

    background: Item {
        x: root.leftPadding
        y: root.topPadding
        width: root.availableWidth
        height: root.availableHeight

        // HORIZONTAL TRACK, UNCENTERED (fill grows from the left edge)
        Item {
            anchors.centerIn: parent
            width: parent.width
            height: root.trackHeight
            visible: root.orientation === Qt.Horizontal && !root.isCentered

            property real handlePos: root.visualPosition * (width - root.currentHandleWidth)

            QsText {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: root.icon
                font.family: "Material Symbols Outlined"
                font.pixelSize: 20
                color: Theme.on_surface_variant
                opacity: 0.8
                renderType: Text.QtRendering
                font.hintingPreference: Font.PreferNoHinting
            }

            Rectangle {
                antialiasing: true
                id: leftTrackUni
                x: 0
                y: 0
                width: Math.max(0, parent.handlePos - root.gap)
                height: parent.height
                color: Theme.primary
                clip: true

                topLeftRadius: Math.min(root.leftRadiusLarge, width / 2)
                bottomLeftRadius: Math.min(root.leftRadiusLarge, width / 2)
                topRightRadius: Math.min(root.leftRadiusSmall, width / 2)
                bottomRightRadius: Math.min(root.leftRadiusSmall, width / 2)

                QsText {
                    x: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.icon
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: Theme.on_primary
                    renderType: Text.QtRendering
                    font.hintingPreference: Font.PreferNoHinting
                }
            }

            Rectangle {
                antialiasing: true
                id: rightTrackUni
                x: parent.handlePos + root.currentHandleWidth + root.gap
                y: 0
                width: Math.max(0, parent.width - x)
                height: parent.height
                color: Vars.tColor(Theme.surface_variant, Vars.componentOpacity)

                topLeftRadius: Math.min(root.leftRadiusSmall, width / 2)
                bottomLeftRadius: Math.min(root.leftRadiusSmall, width / 2)
                topRightRadius: Math.min(root.leftRadiusLarge, width / 2)
                bottomRightRadius: Math.min(root.leftRadiusLarge, width / 2)

                Rectangle {
                    visible: root.enableTicks
                    width: root.dotSize
                    height: root.dotSize
                    radius: root.dotSize / 2
                    antialiasing: true
                    color: Theme.on_surface_variant
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent.width - root.leftRadiusLarge - root.dotSize / 2
                    opacity: !root.showTicks && rightTrackUni.width > root.leftRadiusLarge * 2.5 ? 0.6 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }

            Repeater {
                model: root.showTicks ? Math.max(0, Math.floor((root.to - root.from) / root.stepSize) + 1) : 0
                Rectangle {
                    property real tickPos: (root.currentHandleWidth / 2) + (root.availableWidth - root.currentHandleWidth) * (index / Math.max(1, (root.to - root.from) / root.stepSize))
                    x: tickPos - width / 2
                    y: (parent.height - height) / 2
                    width: 4
                    height: 4
                    radius: 2
                    antialiasing: true

                    property bool inColoredArea: tickPos <= parent.handlePos + root.currentHandleWidth / 2
                    color: inColoredArea ? (Vars.tColor(Theme.surface_variant, Vars.componentOpacity)) : (Vars.tColor(Theme.primary, Vars.componentOpacity))
                }
            }
        }

        // HORIZONTAL TRACK, CENTERED (fill grows from the middle, for signed ranges)
        Item {
            anchors.centerIn: parent
            width: parent.width
            height: root.trackHeight
            visible: root.orientation === Qt.Horizontal && root.isCentered

            property real handlePos: root.visualPosition * (width - root.currentHandleWidth)
            property real centerX: width / 2
            property bool isLeftOfCenter: handlePos + root.currentHandleWidth / 2 < centerX

            Rectangle {
                antialiasing: true
                id: leftTrackCentered
                x: 0
                y: 0
                width: {
                    var endAt = parent.isLeftOfCenter ? parent.handlePos - root.gap : parent.centerX - root.gap;
                    return Math.max(root.leftRadiusLarge * 2, endAt);
                }
                height: parent.height
                color: Vars.tColor(Theme.surface_variant, Vars.componentOpacity)

                topLeftRadius: root.leftRadiusLarge
                bottomLeftRadius: root.leftRadiusLarge
                topRightRadius: root.leftRadiusSmall
                bottomRightRadius: root.leftRadiusSmall

                Rectangle {
                    visible: root.enableTicks
                    width: root.dotSize
                    height: root.dotSize
                    radius: root.dotSize / 2
                    antialiasing: true
                    color: Theme.on_surface_variant
                    anchors.verticalCenter: parent.verticalCenter
                    x: root.leftRadiusLarge - root.dotSize / 2
                    opacity: !root.showTicks && leftTrackCentered.width > root.leftRadiusLarge * 2.5 ? 0.6 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }

            Rectangle {
                id: coloredIndicatorCentered
                property real handleRight: parent.handlePos + root.currentHandleWidth + root.gap
                property real handleLeft: parent.handlePos - root.gap

                x: parent.isLeftOfCenter ? handleRight : parent.centerX + root.gap
                y: 0
                width: parent.isLeftOfCenter ? Math.max(0, parent.centerX - root.gap - handleRight) : Math.max(0, handleLeft - parent.centerX - root.gap)
                height: parent.height
                color: Theme.primary
                radius: root.leftRadiusSmall
                antialiasing: true
                visible: width > 2
            }

            Rectangle {
                antialiasing: true
                id: rightTrackCentered
                x: parent.isLeftOfCenter ? parent.centerX + root.gap : parent.handlePos + root.currentHandleWidth + root.gap
                y: 0
                width: Math.max(0, parent.width - x)
                height: parent.height
                color: Vars.tColor(Theme.surface_variant, Vars.componentOpacity)

                topLeftRadius: Math.min(root.leftRadiusSmall, width / 2)
                bottomLeftRadius: Math.min(root.leftRadiusSmall, width / 2)
                topRightRadius: Math.min(root.leftRadiusLarge, width / 2)
                bottomRightRadius: Math.min(root.leftRadiusLarge, width / 2)

                Rectangle {
                    visible: root.enableTicks
                    width: root.dotSize
                    height: root.dotSize
                    radius: root.dotSize / 2
                    antialiasing: true
                    color: Theme.on_surface_variant
                    anchors.verticalCenter: parent.verticalCenter
                    x: parent.width - root.leftRadiusLarge - root.dotSize / 2
                    opacity: !root.showTicks && rightTrackCentered.width > root.leftRadiusLarge * 2.5 ? 0.6 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }
            }

            Repeater {
                model: root.showTicks ? Math.max(0, Math.floor((root.to - root.from) / root.stepSize) + 1) : 0
                Rectangle {
                    property real tickPos: (root.currentHandleWidth / 2) + (root.availableWidth - root.currentHandleWidth) * (index / Math.max(1, (root.to - root.from) / root.stepSize))
                    x: tickPos - width / 2
                    y: (parent.height - height) / 2
                    width: 4
                    height: 4
                    radius: 2
                    antialiasing: true

                    property bool inColoredArea: parent.isLeftOfCenter ? (tickPos >= parent.handlePos + root.currentHandleWidth / 2 && tickPos <= parent.centerX) : (tickPos >= parent.centerX && tickPos <= parent.handlePos + root.currentHandleWidth / 2)
                    color: inColoredArea ? (Vars.tColor(Theme.surface_variant, Vars.componentOpacity)) : (Vars.tColor(Theme.primary, Vars.componentOpacity))
                }
            }
        }

        // VERTICAL TRACK (value grows from the bottom up, like a fader)
        Item {
            anchors.centerIn: parent
            width: root.trackHeight
            height: parent.height
            visible: root.orientation === Qt.Vertical

            property real handlePos: root.visualPosition * (height - root.currentHandleWidth)

            QsText {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.icon
                font.family: "Material Symbols Outlined"
                font.pixelSize: 20
                color: Theme.on_surface_variant
                opacity: 0.8
                renderType: Text.QtRendering
                font.hintingPreference: Font.PreferNoHinting
            }

            Rectangle {
                antialiasing: true
                x: 0
                y: 0
                width: parent.width
                height: Math.max(0, parent.handlePos - root.gap)
                color: Vars.tColor(Theme.surface_variant, Vars.componentOpacity)

                topLeftRadius: Math.min(root.leftRadiusLarge, height / 2)
                topRightRadius: Math.min(root.leftRadiusLarge, height / 2)
                bottomLeftRadius: Math.min(root.leftRadiusSmall, height / 2)
                bottomRightRadius: Math.min(root.leftRadiusSmall, height / 2)
            }

            Rectangle {
                antialiasing: true
                x: 0
                y: parent.handlePos + root.currentHandleWidth + root.gap
                width: parent.width
                height: Math.max(0, parent.height - y)
                color: Theme.primary
                clip: true

                topLeftRadius: Math.min(root.leftRadiusSmall, height / 2)
                topRightRadius: Math.min(root.leftRadiusSmall, height / 2)
                bottomLeftRadius: Math.min(root.leftRadiusLarge, height / 2)
                bottomRightRadius: Math.min(root.leftRadiusLarge, height / 2)

                QsText {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 12
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.icon
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: Theme.on_primary
                    renderType: Text.QtRendering
                    font.hintingPreference: Font.PreferNoHinting
                }
            }
        }
    }

    handle: Rectangle {
        x: root.leftPadding + (root.orientation === Qt.Vertical ? (root.availableWidth - width) / 2 : root.visualPosition * (root.availableWidth - width))
        y: root.topPadding + (root.orientation === Qt.Vertical ? root.visualPosition * (root.availableHeight - height) : (root.availableHeight - height) / 2)

        width: root.orientation === Qt.Vertical ? (root.trackHeight + 8) : root.currentHandleWidth
        height: root.orientation === Qt.Vertical ? root.currentHandleWidth : (root.trackHeight + 8)
        radius: Math.min(width, height) / 2
        antialiasing: true
        color: Theme.primary
    }
}
