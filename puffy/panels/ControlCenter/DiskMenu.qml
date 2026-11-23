import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../theme"
import "../.."

// Per-mount disk usage, opened from the "disk" tile in ModuleGrid. No back button — dismissed
// by clicking outside the panel, same as the rest of Control Center.
ColumnLayout {
    id: diskMenu

    property bool isActive: false

    // Supplied by ControlCenter.qml from ModuleGrid's diskRows, so there is a single Process
    // polling df rather than one per view.
    property var rows: []

    anchors.margins: Vars.spacingLarge
    spacing: Vars.spacingMedium

    opacity: isActive ? 1.0 : 0.0
    visible: opacity > 0
    transform: Translate {
        x: isActive ? 0 : 40
        Behavior on x { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
    }
    Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: isActive ? Vars.customEmphasizedDecelerate : Vars.customEmphasizedAccelerate } }

    Flickable {
        id: diskFlickable
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(contentHeight, 450)
        contentHeight: diskListContainer.implicitHeight; clip: true

        ColumnLayout {
            id: diskListContainer
            width: diskFlickable.width; spacing: Vars.spacingSmall

            QsText {
                Layout.fillWidth: true
                Layout.topMargin: Vars.spacingLarge
                visible: diskMenu.rows.length === 0
                text: "No mounted drives found"
                font.family: Vars.fontFamily
                font.pixelSize: 14
                color: Theme.on_surface_variant
                horizontalAlignment: Text.AlignHCenter
            }

            Repeater {
                model: diskMenu.rows
                delegate: Rectangle {
                    id: diskRow
                    required property var modelData
                    required property int index

                    antialiasing: true
                    Layout.fillWidth: true; Layout.preferredHeight: 68
                    property real baseRadius: Vars.radiusLarge
                    property real edgeRadius: 4
                    property bool isFirst: index === 0
                    property bool isLast: index === diskMenu.rows.length - 1

                    topLeftRadius: isFirst ? baseRadius : edgeRadius
                    topRightRadius: isFirst ? baseRadius : edgeRadius
                    bottomLeftRadius: isLast ? baseRadius : edgeRadius
                    bottomRightRadius: isLast ? baseRadius : edgeRadius

                    Behavior on topLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                    Behavior on topRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                    Behavior on bottomLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                    Behavior on bottomRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }

                    color: Vars.tColor(Theme.surface_container_low, Vars.componentOpacity)

                    // Expressive fill colour: primary while there's plenty of room, secondary once
                    // it's getting full, tertiary only once a mount is genuinely near capacity —
                    // not a plain "turns red" bar.
                    readonly property color fillColor: modelData.percent >= 90 ? Theme.tertiary : (modelData.percent >= 75 ? Theme.secondary : Theme.primary)

                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true; spacing: 4

                            RowLayout {
                                Layout.fillWidth: true
                                QsText {
                                    Layout.fillWidth: true
                                    text: diskRow.modelData.target
                                    font.family: Vars.fontFamily
                                    font.pixelSize: 14
                                    setWeight: Font.Bold
                                    color: Theme.on_surface
                                    elide: Text.ElideMiddle
                                }
                                QsText {
                                    text: (diskRow.modelData.avail / 1073741824).toFixed(0) + " GB free"
                                    font.family: Vars.fontFamily
                                    font.pixelSize: 12
                                    color: Theme.on_surface_variant
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 6
                                radius: 3
                                antialiasing: true
                                color: Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)

                                Rectangle {
                                    height: parent.height
                                    radius: parent.radius
                                    antialiasing: true
                                    color: diskRow.fillColor
                                    width: parent.width * Math.max(0, Math.min(100, diskRow.modelData.percent)) / 100
                                    Behavior on width {
                                        NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow }
                                    }
                                    Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
