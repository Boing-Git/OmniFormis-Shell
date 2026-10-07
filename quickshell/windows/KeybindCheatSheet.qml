import QtQuick
import QtQuick.Layouts
import ".."
import Quickshell
import Quickshell.Io
import "../theme"
import "../core/primitives" as Primitives
import "../core/keycapture.js" as KeyCapture

// A fast, read-only, searchable reference of every shortcut — same data as the Settings app's
// Keybinds page (`omniformis hypr binds --json`), but for quick lookup rather than editing.
// Follows the WallpaperSwitcher/ColorSchemeSwitcher pill/window template exactly.
Item {
    id: root

    Layout.preferredWidth: 100
    Layout.preferredHeight: 40

    property bool expanded: false
    property bool forceHidePill: false
    property var focusWindow: null
    property bool gameMode: Vars.gameMode !== undefined ? Vars.gameMode : false
    property alias panel: panel
    property alias panelMask: panelMask

    opacity: forceHidePill ? 0.0 : 1.0
    visible: opacity > 0

    signal closeRequested

    // ---- data ----
    property var byKey: ({})
    property var rows: []
    property string searchText: ""

    Process {
        id: loader
        command: ["bash", "-c", "\"$HOME/.local/bin/omniformis\" hypr binds --json"]
        stdout: StdioCollector {
            onStreamFinished: root.applyData(this.text)
        }
    }

    function applyData(text) {
        var data;
        try {
            data = JSON.parse(text);
        } catch (e) {
            return;
        }
        var map = {};
        (data.binds || []).forEach(function (b) {
            map[b.key] = b;
        });
        root.byKey = map;
        root.rebuildRows();
    }

    function rebuildRows() {
        var q = (root.searchText || "").toLowerCase().trim();
        var terms = q.length > 0 ? q.split(/\s+/) : [];
        var groups = [];
        var seen = {};
        for (var key in root.byKey) {
            var e = root.byKey[key];
            if (terms.length > 0) {
                var hay = (e.description + " " + e.key + " " + e.combo + " " + (e.resolved || []).join(" ") + " " + e.category).toLowerCase();
                var ok = terms.every(function (t) { return hay.indexOf(t) !== -1; });
                if (!ok) continue;
            }
            if (seen[e.category] === undefined) {
                seen[e.category] = groups.length;
                groups.push({ title: e.category, keys: [] });
            }
            groups[seen[e.category]].keys.push(key);
        }
        // omniformis prints categories/keys in a stable, meaningful order; JS object key order for
        // string keys follows insertion order, and byKey was inserted in that same order.
        var out = [];
        groups.forEach(function (g) {
            out.push({ type: "header", key: "h:" + g.title, title: g.title });
            g.keys.forEach(function (k, i) {
                out.push({ type: "row", key: k, first: i === 0, last: i === g.keys.length - 1 });
            });
        });
        root.rows = out;
    }

    onSearchTextChanged: rebuildRows()
    onExpandedChanged: {
        if (!expanded) {
            MorphState.notifyClosed();
            searchBar.text = "";
        } else {
            MorphState.notifyOpened(620, 700, panel.targetRad, panel);
            loader.running = false;
            loader.running = true;
            searchBar.forceActiveFocus();
        }
    }

    Item {
        id: panelMask
        anchors.top: (!Vars.pillPosition || Vars.pillPosition === "Top") ? parent.top : undefined
        anchors.bottom: Vars.pillPosition === "Bottom" ? parent.bottom : undefined
        anchors.left: Vars.pillPosition === "Left" ? parent.left : undefined
        anchors.right: Vars.pillPosition === "Right" ? parent.right : undefined
        anchors.horizontalCenter: (Vars.pillPosition === "Left" || Vars.pillPosition === "Right") ? undefined : parent.horizontalCenter
        anchors.verticalCenter: (Vars.pillPosition === "Left" || Vars.pillPosition === "Right") ? parent.verticalCenter : undefined

        anchors.topMargin: root.expanded ? -20 : 0
        anchors.bottomMargin: root.expanded ? -20 : 0
        anchors.leftMargin: root.expanded ? -20 : 0
        anchors.rightMargin: root.expanded ? -20 : 0
        width: root.expanded ? 660 : 0
        height: root.expanded ? 740 : 0
    }

    Primitives.SquircleMask {
        id: panel
        property bool isBackgroundActive: root.expanded || (MorphState.openCount === 0 && MorphState.activeItem === panel && panel.width > 105)
        anchors.top: (!Vars.pillPosition || Vars.pillPosition === "Top") ? parent.top : undefined
        anchors.bottom: Vars.pillPosition === "Bottom" ? parent.bottom : undefined
        anchors.left: Vars.pillPosition === "Left" ? parent.left : undefined
        anchors.right: Vars.pillPosition === "Right" ? parent.right : undefined
        anchors.horizontalCenter: (Vars.pillPosition === "Left" || Vars.pillPosition === "Right") ? undefined : parent.horizontalCenter
        anchors.verticalCenter: (Vars.pillPosition === "Left" || Vars.pillPosition === "Right") ? parent.verticalCenter : undefined

        width: root.expanded ? 620 : (MorphState.anyExpanded ? MorphState.targetWidth : 100)
        height: root.expanded ? 700 : (MorphState.anyExpanded ? MorphState.targetHeight : 40)

        color: Vars.tColorActive(isBackgroundActive, Theme.surface, Vars.panelOpacity)
        property real targetRad: root.expanded ? Vars.radiusExtraLarge : (MorphState.anyExpanded ? MorphState.targetRadius : height / 2)
        topLeftRadius: Vars.getTopLeftRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        topRightRadius: Vars.getTopRightRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        bottomLeftRadius: Vars.getBottomLeftRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        bottomRightRadius: Vars.getBottomRightRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)

        opacity: isBackgroundActive || innerUI.opacity > 0 ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on width { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on height { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

        Item {
            id: innerUI
            anchors.centerIn: parent
            width: Math.max(1, parent.width - Vars.spacingLarge * 2)
            height: Math.max(1, parent.height - Vars.spacingLarge * 2)

            opacity: root.expanded ? 1.0 : 0.0
            visible: root.expanded || opacity > 0
            clip: true
            Behavior on opacity {
                enabled: !root.gameMode
                NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.getFadeCurve(root.expanded) }
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: Vars.spacingMedium

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    QsText {
                        text: "Shortcuts"
                        font.family: Vars.fontFamily
                        font.pixelSize: 20
                        setWeight: 700
                        color: Theme.on_surface
                        Layout.fillWidth: true
                    }

                    Rectangle {
                        width: 36; height: 36; radius: 18
                        antialiasing: true
                        color: closeHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent"
                        QsText {
                            anchors.centerIn: parent
                            text: "close"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 20
                            color: Theme.on_surface_variant
                        }
                        MouseArea { id: closeHover; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.expanded = false }
                    }
                }

                Primitives.SearchBar {
                    id: searchBar
                    Layout.fillWidth: true
                    placeholderText: "Search shortcuts..."
                    showIcon: true
                    iconText: "search"
                    defaultHeight: 44
                    onTextChanged: root.searchText = text
                    Keys.onEscapePressed: root.expanded = false
                }

                Flickable {
                    id: scroller
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    contentHeight: listColumn.implicitHeight
                    clip: true
                    flickDeceleration: Vars.flickDeceleration
                    maximumFlickVelocity: Vars.maximumFlickVelocity

                    ColumnLayout {
                        id: listColumn
                        width: scroller.width
                        spacing: 4

                        QsText {
                            Layout.fillWidth: true
                            Layout.topMargin: Vars.spacingLarge
                            visible: root.rows.length === 0
                            text: "No shortcuts match"
                            font.family: Vars.fontFamily
                            font.pixelSize: 14
                            color: Theme.on_surface_variant
                            horizontalAlignment: Text.AlignHCenter
                        }

                        Repeater {
                            model: root.rows
                            delegate: Loader {
                                id: rowLoader
                                required property var modelData
                                Layout.fillWidth: true
                                Layout.topMargin: modelData.type === "header" ? Vars.spacingMedium : 0
                                sourceComponent: modelData.type === "header" ? headerComponent : rowComponent

                                Component {
                                    id: headerComponent
                                    QsText {
                                        width: rowLoader.width
                                        text: rowLoader.modelData.title
                                        font.family: Vars.fontFamily
                                        font.pixelSize: 13
                                        setWeight: 700
                                        color: Theme.primary
                                        leftPadding: Vars.spacingMedium
                                    }
                                }
                                Component {
                                    id: rowComponent
                                    CheatSheetRow {
                                        width: rowLoader.width
                                        entry: root.byKey[rowLoader.modelData.key] || ({})
                                        first: rowLoader.modelData.first
                                        last: rowLoader.modelData.last
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // One read-only shortcut row: description on the left, its combination as key chips on the
    // right, following the same group-corner rule as every other list in this app.
    component CheatSheetRow: Item {
        id: row
        required property var entry
        property bool first: false
        property bool last: false

        implicitHeight: 56
        opacity: entry.active === false ? 0.55 : 1.0

        Rectangle {
            anchors.fill: parent
            antialiasing: true
            color: Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)
            topLeftRadius: row.first ? Vars.radiusLarge : 4
            topRightRadius: row.first ? Vars.radiusLarge : 4
            bottomLeftRadius: row.last ? Vars.radiusLarge : 4
            bottomRightRadius: row.last ? Vars.radiusLarge : 4
        }

        RowLayout {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: Vars.spacingLarge
            anchors.rightMargin: Vars.spacingLarge
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                QsText {
                    Layout.fillWidth: true
                    text: row.entry.description || row.entry.key || ""
                    font.family: Vars.fontFamily
                    font.pixelSize: 14
                    setWeight: 500
                    color: Theme.on_surface
                    elide: Text.ElideRight
                }
                QsText {
                    Layout.fillWidth: true
                    visible: text !== ""
                    text: {
                        if (row.entry.conflicts && row.entry.conflicts.length > 0)
                            return "Also used by " + row.entry.conflicts.join(", ");
                        if (row.entry.active === false)
                            return "Not used by the current layout";
                        return "";
                    }
                    font.family: Vars.fontFamily
                    font.pixelSize: 11
                    color: Theme.tertiary
                    elide: Text.ElideRight
                }
            }

            Row {
                Layout.alignment: Qt.AlignVCenter
                spacing: 5
                Repeater {
                    model: KeyCapture.tokens(row.entry.combo)
                    delegate: KeyChip {
                        required property string modelData
                        token: modelData
                    }
                }
            }
        }
    }

    // A single key of a combination — sibling of CheatSheetRow since inline components cannot nest.
    component KeyChip: Rectangle {
        id: chip
        property string token: ""
        readonly property bool variable: KeyCapture.isVariable(token)
        implicitHeight: 26
        implicitWidth: Math.max(26, chipText.implicitWidth + 16)
        radius: height / 2
        antialiasing: true
        color: variable ? Theme.tertiary_container : Theme.secondary_container
        QsText {
            id: chipText
            anchors.centerIn: parent
            text: KeyCapture.label(chip.token)
            font.family: Vars.fontFamily
            font.pixelSize: 12
            setWeight: 600
            color: chip.variable ? Theme.on_tertiary_container : Theme.on_secondary_container
        }
    }
}
