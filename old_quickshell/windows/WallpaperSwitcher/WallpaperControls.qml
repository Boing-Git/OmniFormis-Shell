import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import "../.."
import "../../theme"
import QtCore

ColumnLayout {
    id: controlsRoot
    spacing: Vars.spacingMedium
    Layout.fillWidth: true

    property var rootRef: null
    property var settingsRef: null
    property var loadWallpapersProcRef: null
    property var gridViewRef: null
    property var autocompleteProcRef: null
    property var autocompleteModelRef: null
    property alias filterText: searchInput.text
    // Exposed so a hide-on-scroll container can keep this bar on screen while it's actually
    // being typed in, instead of yanking it away out from under an in-progress keystroke.
    readonly property alias hasFocus: searchInput.activeFocus

    function focusSearch() { Qt.callLater(() => { searchInput.forceActiveFocus(); }); }
    function clearSearch() { searchInput.text = ""; }

    RowLayout {
        Layout.fillWidth: true
        spacing: Vars.spacingMedium



        Rectangle {
            id: searchBox
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            color: searchInput.activeFocus ? Theme.primary_container : (Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity))
            border.color: searchInput.activeFocus ? Theme.primary : "transparent"
            border.width: searchInput.activeFocus ? 2 : 0
            radius: searchInput.activeFocus ? Vars.radiusLarge : Vars.radiusExtraLarge
            antialiasing: true

            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
            Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: Vars.spacingMedium
                anchors.rightMargin: Vars.spacingMedium

                QsText {
                    text: "search"
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: searchInput.activeFocus ? Theme.on_primary_container : Theme.on_surface
                    opacity: 0.7
                }

                TextInput {
                    id: searchInput
                    objectName: "searchInput"
                    Layout.fillWidth: true
                    font.family: Vars.fontFamily
                    font.pixelSize: 14
                    color: searchInput.activeFocus ? Theme.on_primary_container : Theme.on_surface
                    focus: true
                    selectByMouse: true

                    QsText {
                        text: "Search wallpapers..."
                        font.family: Vars.fontFamily
                        font.pixelSize: 14
                        color: Theme.on_surface
                        opacity: 0.6
                        visible: !searchInput.text && !searchInput.activeFocus
                    }

                    Keys.onDownPressed: (event) => {
                        if (gridViewRef) gridViewRef.forceActiveFocus();
                        event.accepted = true;
                    }
                    Keys.onReturnPressed: (event) => {
                        if (gridViewRef) gridViewRef.forceActiveFocus();
                        event.accepted = true;
                    }
                    Keys.onEscapePressed: (event) => {
                        if (gridViewRef) gridViewRef.forceActiveFocus();
                        event.accepted = true;
                    }
                }

                QsText {
                    text: "✕"
                    font.pixelSize: 14
                    color: searchInput.activeFocus ? Theme.on_primary_container : Theme.on_surface
                    visible: searchInput.text.length > 0
                    Layout.alignment: Qt.AlignVCenter
                    MouseArea {
                        anchors.fill: parent
                        onClicked: searchInput.text = ""
                    }
                }
            }
        }




    }


}
