import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../.."
import "../../theme"
import "../.."
import Quickshell
import "../../theme/variables.js" as Vars

RowLayout {
    id: root

    property string currentTheme: ""
    property string currentMode: "dark"
    property alias searchText: searchInput.text

    signal escapePressed()
    signal searchDownPressed()
    signal modeToggled()
    signal refreshClicked()
    
    function forceSearchFocus() {
        searchInput.forceActiveFocus();
    }

    spacing: Vars.spacingMedium

    RowLayout {
        spacing: 8
        Text {
            text: "Color Schemes"
            font.family: Vars.fontFamily
            font.pixelSize: 18
            font.weight: Font.Bold
            color: Theme.on_surface
        }
    }

    Rectangle {
        id: searchBox
        Layout.fillWidth: true
        Layout.preferredHeight: 44
        color: searchInput.activeFocus ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)
        border.color: searchInput.activeFocus ? Theme.primary : Theme.outline
        border.width: searchInput.activeFocus ? 2 : 1
        radius: Vars.radiusMedium

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Vars.spacingMedium
            anchors.rightMargin: Vars.spacingMedium

            Text {
                text: "search"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 20
                color: Theme.on_surface
                opacity: 0.7
            }

            TextInput {
                id: searchInput
                Layout.fillWidth: true
                font.family: Vars.fontFamily
                font.pixelSize: 14
                color: Theme.on_surface
                focus: true
                selectByMouse: true

                Text {
                    text: "Search themes..."
                    font.family: Vars.fontFamily
                    font.pixelSize: 14
                    color: Theme.on_surface_variant
                    opacity: 0.6
                    visible: !searchInput.text && !searchInput.activeFocus
                }

                Keys.onDownPressed: (event) => {
                    root.searchDownPressed();
                    event.accepted = true;
                }
                Keys.onEscapePressed: {
                    root.escapePressed();
                }
            }

            Text {
                text: "✕"
                font.pixelSize: 14
                color: Theme.on_surface
                visible: searchInput.text.length > 0
                Layout.alignment: Qt.AlignVCenter
                MouseArea {
                    anchors.fill: parent
                    onClicked: searchInput.text = ""
                }
            }
        }
    }

    Button {
        id: modeToggleBtn
        text: root.currentMode === "dark" ? "Dark Mode" : "Light Mode"
        onClicked: {
            root.modeToggled();
        }

        background: Rectangle {
            color: modeToggleBtn.down ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (modeToggleBtn.hovered ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
            border.width: 0
            radius: Vars.radiusMedium
        }
        contentItem: RowLayout {
            spacing: Vars.spacingSmall
            Text {
                text: root.currentMode === "dark" ? "dark_mode" : "light_mode"
                font.family: "Material Symbols Outlined"
                color: Theme.on_surface
                font.pixelSize: 18
            }
            Text {
                text: modeToggleBtn.text
                font.family: Vars.fontFamily
                color: Theme.on_surface
                font.bold: true
                font.pixelSize: 14
            }
        }
    }

    Button {
        id: refreshBtn
        text: "Scan"
        onClicked: root.refreshClicked()

        background: Rectangle {
            color: refreshBtn.down ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (refreshBtn.hovered ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
            border.width: 0
            radius: Vars.radiusMedium
        }
        contentItem: RowLayout {
            spacing: Vars.spacingSmall
            Text {
                text: "refresh"
                font.family: "Material Symbols Outlined"
                color: (refreshBtn.down || refreshBtn.hovered) ? Theme.primary : Theme.on_surface
                font.pixelSize: 18
            }
            Text {
                text: refreshBtn.text
                font.family: Vars.fontFamily
                color: (refreshBtn.down || refreshBtn.hovered) ? Theme.primary : Theme.on_surface
                font.bold: true
                font.pixelSize: 14
            }
        }
    }
}
