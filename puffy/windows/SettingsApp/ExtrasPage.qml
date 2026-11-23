import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../.."
import "../../theme"
import "../../core/primitives" as Primitives

// Settings → Extras: the switches for Puffy's extras, and today's screen time.
//   Ask the AI    the launcher's /ask mode (Super + A); variables.js `assistant`
//   Mascot        Puffy hiding in plain sight; variables.js `mascots`
//   Automations   the launcher's /run mode; variables.js `automations`
//   Screen time   the switch every shell shares (../scripts/screentime.py on | off), and
//                 under it the apps used today, longest first, each with its bar
Item {
    id: extras

    property string pageTitle: "Extras"
    property string pageIcon: ""
    property string pageShape: "Puffy"
    property color pageColor: Theme.secondary
    property color pageOnColor: Theme.on_secondary
    property string searchText: ""

    M3Shapes { id: m3Shapes }

    readonly property string omniformis: Quickshell.env("HOME") + "/.local/bin/omniformis"
    readonly property string screenTimeScript: Quickshell.shellDir + "/../scripts/screentime.py"

    // a Puffy setting, written through omniformis (Vars follows the file)
    Process { id: setter }
    function setVar(key, value) { setter.exec([omniformis, "qs", "set", key, String(value)]) }

    // ── screen time ── { on, days: [{ date, apps: { class: seconds } }] }
    property var usage: ({ on: true, days: [] })
    Process {
        id: reader
        command: [extras.screenTimeScript, "json", "1"]
        stdout: StdioCollector { onStreamFinished: { try { extras.usage = JSON.parse(text) } catch (e) {} } }
    }
    onVisibleChanged: if (visible) reader.running = true
    Component.onCompleted: reader.running = true
    Process { id: switcher; onExited: reader.running = true }

    readonly property var today: usage.days.length > 0 ? usage.days[0].apps : ({})
    readonly property var apps: Object.keys(today).sort((a, b) => today[b] - today[a]).slice(0, 12)
    readonly property real most: apps.length > 0 ? today[apps[0]] : 1
    readonly property real total: Object.values(today).reduce((a, b) => a + b, 0)
    function pretty(s) {
        const m = Math.floor(s / 60)
        return m >= 60 ? Math.floor(m / 60) + " h " + (m % 60) + " min" : m >= 1 ? m + " min" : "< 1 min"
    }

    Flickable {
        anchors.fill: parent
        contentHeight: layout.implicitHeight + Vars.spacingLarge
        clip: true

        ColumnLayout {
            id: layout
            width: parent.width
            spacing: Vars.spacingLarge

            Item { Layout.preferredHeight: Vars.spacingLarge }

            // the title, as every page has it
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Vars.spacingLarge
                Layout.rightMargin: Vars.spacingLarge
                spacing: 12
                Item {
                    width: 38
                    height: 38
                    Image {
                        anchors.fill: parent
                        sourceSize: Qt.size(width, height)
                        source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='" + m3Shapes.getPath(extras.pageShape) + "' fill='" + String(extras.pageColor).replace("#", "%23") + "'/></svg>"
                        smooth: true
                    }
                    QsText { anchors.centerIn: parent; text: extras.pageIcon; font.family: "Material Symbols Outlined"; font.pixelSize: 20; color: extras.pageOnColor }
                }
                QsText { Layout.fillWidth: true; text: extras.pageTitle; font.family: Vars.fontFamily; font.pixelSize: 18; setWeight: 600; color: Theme.on_surface }
            }

            // ── the switches ── one card each, as the About page's cards
            Repeater {
                model: [
                    { icon: "auto_awesome", title: "Ask the AI", sub: "The launcher's /ask mode, and Super + A. A local model does what you type with the desktop's own commands.",
                      on: Vars.assistant !== false, flip: () => extras.setVar("assistant", !(Vars.assistant !== false)) },
                    { icon: "sentiment_satisfied", title: "Mascot", sub: "Puffy hides in plain sight. Find it.",
                      on: Vars.mascots !== false, flip: () => extras.setVar("mascots", !(Vars.mascots !== false)) },
                    { icon: "bolt", title: "Automations", sub: "The launcher's /run mode: runs of steps (open Steam and Spotify, play, open a game…) kept in ~/.config/automations.",
                      on: Vars.automations !== false, flip: () => extras.setVar("automations", !(Vars.automations !== false)) },
                    { icon: "hourglass_top", title: "Screen time", sub: "Counts how long each app is used. One switch for every shell: off stops the counting.",
                      on: extras.usage.on, flip: () => switcher.exec([extras.screenTimeScript, extras.usage.on ? "off" : "on"]) }
                ]
                Rectangle {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.leftMargin: Vars.spacingLarge
                    Layout.rightMargin: Vars.spacingLarge
                    Layout.preferredHeight: 76
                    radius: 16
                    color: Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 16
                        QsText { text: modelData.icon; font.family: "Material Symbols Outlined"; font.pixelSize: 24; color: Theme.on_surface_variant }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            QsText { Layout.fillWidth: true; text: modelData.title; font.family: Vars.fontFamily; font.pixelSize: 16; setWeight: Font.Medium; color: Theme.on_surface }
                            QsText { Layout.fillWidth: true; text: modelData.sub; font.family: Vars.fontFamily; font.pixelSize: 12; color: Theme.on_surface_variant; elide: Text.ElideRight }
                        }
                        Primitives.ToggleSwitch { checked: modelData.on; onToggled: modelData.flip() }
                    }
                }
            }

            // ── today ── an app per row, with a bar as long as its share of the longest
            QsText {
                Layout.leftMargin: Vars.spacingLarge + 4
                visible: extras.usage.on
                text: "Today  ·  " + extras.pretty(extras.total)
                font.family: Vars.fontFamily
                font.pixelSize: 14
                setWeight: 600
                color: Theme.on_surface_variant
            }
            Repeater {
                model: extras.usage.on ? extras.apps : []
                Rectangle {
                    required property var modelData
                    // (looked up again once the app list has loaded: it loads in the background)
                    readonly property var entry: DesktopEntries.applications.values.length >= 0 ? DesktopEntries.heuristicLookup(modelData) : null
                    Layout.fillWidth: true
                    Layout.leftMargin: Vars.spacingLarge
                    Layout.rightMargin: Vars.spacingLarge
                    Layout.preferredHeight: 56
                    radius: 14
                    color: Vars.tColor(Theme.surface_container, Vars.componentOpacity)
                    // the bar: its share of the day's longest
                    Rectangle {
                        anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                        width: parent.width * Math.max(0.04, extras.today[modelData] / extras.most)
                        radius: parent.radius
                        color: Vars.tColor(Theme.primary_container, 0.55)
                    }
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12
                        Image {
                            Layout.preferredWidth: 28
                            Layout.preferredHeight: 28
                            sourceSize: Qt.size(28, 28)
                            source: entry && entry.icon ? Quickshell.iconPath(entry.icon, true) : ""
                        }
                        QsText { Layout.fillWidth: true; text: entry ? entry.name : modelData; font.family: Vars.fontFamily; font.pixelSize: 14; color: Theme.on_surface; elide: Text.ElideRight }
                        QsText { text: extras.pretty(extras.today[modelData]); font.family: Vars.fontFamily; font.pixelSize: 14; setWeight: 600; color: Theme.on_surface }
                    }
                }
            }
        }
    }
}
