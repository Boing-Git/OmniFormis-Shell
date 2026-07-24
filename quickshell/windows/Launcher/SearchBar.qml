import QtQuick
import QtQuick.Layouts
import Quickshell
import "../.."
import "../../theme"
import "../.."
import "../../theme/variables.js" as Vars

Rectangle {
    id: root

    property alias text: searchInput.text
    property bool isActiveFocus: searchInput.activeFocus
    property bool expanded: false

    signal downPressed()
    signal returnPressed()
    signal escapePressed()

    Layout.fillWidth: true
    Layout.preferredHeight: 48
    color: searchInput.activeFocus ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Theme.surface_container_highest
    border.color: Theme.primary
    border.width: searchInput.activeFocus ? 2 : 0
    radius: Vars.radiusMedium

    function forceActiveFocus() {
        searchInput.forceActiveFocus();
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Vars.spacingMedium
        anchors.rightMargin: Vars.spacingMedium

        TextInput {
            id: searchInput
            Layout.fillWidth: true
            font.family: Vars.fontFamily
            font.pixelSize: 14
            color: Theme.on_surface
            focus: root.expanded
            selectByMouse: true

            Text {
                text: "Search apps..."
                font.family: Vars.fontFamily
                font.pixelSize: 14
                color: Theme.on_surface_variant
                visible: !searchInput.text && !searchInput.activeFocus
            }

            Keys.onDownPressed: (event) => {
                root.downPressed();
                event.accepted = true;
            }
            Keys.onReturnPressed: (event) => {
                root.returnPressed();
                event.accepted = true;
            }
            Keys.onEscapePressed: (event) => {
                root.escapePressed();
                event.accepted = true;
            }
        }

        Text {
            text: "✕"
            font.pixelSize: 14
            color: Theme.on_surface_variant
            visible: searchInput.text.length > 0
            Layout.alignment: Qt.AlignVCenter
            MouseArea {
                anchors.fill: parent
                onClicked: searchInput.text = ""
            }
        }
    }
}
