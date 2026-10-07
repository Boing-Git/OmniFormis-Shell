import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../.."
import "../../theme"
import "../../core/keycapture.js" as KeyCapture

// Shortcuts: every keybind as its full combination. Click one and press the new keys to record it,
// or type it with variables. Changes apply to Hyprland straight away.
Item {
    id: page
    Layout.fillWidth: true
    Layout.fillHeight: true

    property string pageTitle: "Shortcuts"
    property string pageIcon: ""
    property string pageShape: "Puffy"
    property color pageColor: Theme.primary
    property color pageOnColor: Theme.on_primary
    property string searchText: ""

    // ---- data from `omniformis hypr binds --json` ----
    property var byKey: ({})          // key -> entry, replaced on every change so rows re-bind
    property var rows: []             // [{ type: "header" | "row", key, title, first, last }]
    property var variables: ({})
    property var settingEntries: []
    property var bindEntries: []
    property string layoutName: ""

    // ---- recording ----
    property string capturingKey: ""
    property string captureKind: "combo"     // "combo" | "modifier" | "key"
    property var heldMods: []
    property bool useVariables: true

    // ---- typing ----
    property string editingKey: ""
    property string editText: ""
    property string editError: ""
    signal insertRequested(string text)

    // Variables offered while typing: the modifier variables and the directional keys
    readonly property var insertableVariables: {
        var out = [];
        for (var name in variables) {
            if (KeyCapture.canonicalModifier(variables[name]) !== "")
                out.push("$" + name);
        }
        ["left", "right", "up", "down"].forEach(function (n) {
            if (variables[n] !== undefined)
                out.push("$" + n);
        });
        out.push("{n}");
        return out;
    }

    onSearchTextChanged: rebuildRows()

    // ------------------------------------------------------------------ loading

    Process {
        id: loader
        command: ["bash", "-c", "\"$HOME/.local/bin/omniformis\" hypr binds --json"]
        stdout: StdioCollector {
            onStreamFinished: page.applyData(this.text)
        }
    }

    function reload() {
        loader.running = false;
        loader.running = true;
    }

    // Shortcuts are re-read a moment after a change, so conflicts and resolved keys catch up
    Timer {
        id: refreshTimer
        interval: 1300
        onTriggered: page.reload()
    }

    function applyData(text) {
        var data;
        try {
            data = JSON.parse(text);
        } catch (e) {
            return;
        }
        var map = {};
        var settings = data.settings || [];
        settings.forEach(function (s) {
            map[s.key] = { key: s.key, kind: s.kind, category: s.category, description: s.description, combo: s.value };
        });
        (data.binds || []).forEach(function (b) {
            map[b.key] = { key: b.key, kind: "bind", category: b.category, description: b.description, combo: b.combo,
                resolved: b.resolved, conflicts: b.conflicts, active: b.active, error: b.error };
        });
        page.variables = data.variables || {};
        page.layoutName = data.layout || "";
        page.settingEntries = settings.map(function (s) { return s.key; });
        page.bindEntries = (data.binds || []).map(function (b) { return b.key; });
        page.byKey = map;
        rebuildRows();
    }

    function matches(entry, q) {
        if (q === "")
            return true;
        var hay = (entry.description + " " + entry.key + " " + entry.combo + " " + (entry.resolved || []).join(" ") + " " + entry.category).toLowerCase();
        return q.split(/\s+/).every(function (term) { return hay.indexOf(term) !== -1; });
    }

    // Rebuilding the row list resets the scroll position, so it only changes when the set of
    // visible shortcuts does, not when one of them is edited.
    property string rowsSignature: ""
    function rebuildRows() {
        var q = (page.searchText || "").toLowerCase().trim();
        var out = [];
        var order = page.settingEntries.concat(page.bindEntries);
        var groups = [];
        var seen = {};
        order.forEach(function (key) {
            var e = page.byKey[key];
            if (!e || !matches(e, q))
                return;
            if (seen[e.category] === undefined) {
                seen[e.category] = groups.length;
                groups.push({ title: e.category, keys: [] });
            }
            groups[seen[e.category]].keys.push(key);
        });
        groups.forEach(function (g) {
            out.push({ type: "header", key: "h:" + g.title, title: g.title });
            g.keys.forEach(function (k, i) {
                out.push({ type: "row", key: k, first: i === 0, last: i === g.keys.length - 1 });
            });
        });
        var signature = out.map(function (r) { return r.key + (r.first ? "^" : "") + (r.last ? "$" : ""); }).join("|");
        if (signature !== page.rowsSignature) {
            page.rowsSignature = signature;
            page.rows = out;
        }
    }

    Component.onCompleted: reload()
    onVisibleChanged: {
        if (visible)
            reload();
        else
            stopEverything();
    }
    Component.onDestruction: leaveCaptureSubmap()

    // ------------------------------------------------------------------ saving

    function setEntry(key, value) {
        var entry = page.byKey[key];
        if (!entry)
            return;
        var updated = Object.assign({}, page.byKey);
        updated[key] = Object.assign({}, entry, { combo: value, resolved: [], conflicts: [], error: null });
        page.byKey = updated;
        SettingsApply.set("hypr", key, value);
        refreshTimer.restart();
    }

    // ------------------------------------------------------------------ recording

    // While recording, Hyprland is switched to an empty submap so it passes every key through
    // instead of running the shortcut being replaced. It is always switched back, and a watchdog
    // does it too if the shell dies mid-recording.
    function enterCaptureSubmap() {
        Quickshell.execDetached({ command: ["bash", "-c",
            "hyprctl dispatch 'hl.dsp.submap(\"omniformis_capture\")' >/dev/null 2>&1; " +
            "( sleep 90; [ \"$(hyprctl submap 2>/dev/null)\" = omniformis_capture ] && hyprctl dispatch 'hl.dsp.submap(\"reset\")' >/dev/null 2>&1 ) >/dev/null 2>&1 &"] });
    }
    function leaveCaptureSubmap() {
        Quickshell.execDetached({ command: ["bash", "-c",
            "[ \"$(hyprctl submap 2>/dev/null)\" = omniformis_capture ] && hyprctl dispatch 'hl.dsp.submap(\"reset\")' >/dev/null 2>&1; true"] });
    }

    function startCapture(key, kind) {
        stopEditing();
        page.capturingKey = key;
        page.captureKind = kind;
        page.heldMods = [];
        enterCaptureSubmap();
        catcher.forceActiveFocus();
    }

    function stopCapture() {
        if (page.capturingKey === "")
            return;
        page.capturingKey = "";
        page.heldMods = [];
        leaveCaptureSubmap();
    }

    function stopEverything() {
        stopCapture();
        stopEditing();
    }

    function finishCapture(modifiers, keyToken) {
        var key = page.capturingKey;
        var kind = page.captureKind;
        stopCapture();
        if (kind === "modifier")
            return;
        if (kind === "key")
            setEntry(key, keyToken.length === 1 ? keyToken.toLowerCase() : keyToken);
        else
            setEntry(key, KeyCapture.buildCombo(modifiers, keyToken, page.useVariables, page.variables));
    }

    // Keyboard: modifiers build up the preview, the first real key completes the combination
    Item {
        id: catcher
        focus: true
        Keys.onPressed: (event) => {
            if (page.capturingKey === "")
                return;
            event.accepted = true;
            var modOfKey = KeyCapture.modifierOfKey(event.key);
            if (modOfKey !== "") {
                if (page.captureKind === "modifier") {
                    var target = page.capturingKey;
                    page.stopCapture();
                    page.setEntry(target, modOfKey);
                    return;
                }
                page.heldMods = KeyCapture.modifiersFrom(event.modifiers);
                return;
            }
            if (event.key === Qt.Key_Escape && event.modifiers === Qt.NoModifier) {
                page.stopCapture();
                return;
            }
            var name = KeyCapture.keyName(event);
            if (name === "" || page.captureKind === "modifier")
                return;
            page.finishCapture(KeyCapture.modifiersFrom(event.modifiers), name);
        }
        Keys.onReleased: (event) => {
            if (page.capturingKey !== "")
                page.heldMods = KeyCapture.modifiersFrom(event.modifiers);
        }
    }

    // ------------------------------------------------------------------ typing

    function startEditing(key) {
        stopCapture();
        page.editError = "";
        page.editingKey = key;
    }

    function stopEditing() {
        page.editingKey = "";
        page.editError = "";
    }

    onEditTextChanged: {
        if (page.editingKey !== "")
            page.editError = KeyCapture.validate(page.editText, page.variables);
    }

    function commitEdit() {
        if (page.editingKey === "")
            return;
        var error = KeyCapture.validate(page.editText, page.variables);
        if (error !== "") {
            page.editError = error;
            return;
        }
        var key = page.editingKey;
        stopEditing();
        setEntry(key, page.editText.trim());
    }

    // ------------------------------------------------------------------ layout

    M3Shapes { id: m3Shapes }

    ColumnLayout {
        anchors.fill: parent
        spacing: Vars.spacingMedium

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Item {
                width: 38
                height: 38
                Image {
                    anchors.fill: parent
                    sourceSize: Qt.size(width, height)
                    source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='" + m3Shapes.getPath(page.pageShape) + "' fill='" + String(page.pageColor || "#3b383e").replace("#", "%23") + "'/></svg>"
                    smooth: true
                    antialiasing: true
                }
                QsText {
                    anchors.centerIn: parent
                    text: page.pageIcon
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: page.pageOnColor
                }
            }

            QsText {
                Layout.fillWidth: true
                text: page.pageTitle
                font.family: Vars.fontFamily
                font.pixelSize: 18
                setWeight: 600
                color: Theme.on_surface
                elide: Text.ElideRight
            }
        }

        Flickable {
            id: scroller
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentHeight: listColumn.implicitHeight + 112
            clip: true
            flickDeceleration: Vars.flickDeceleration
            maximumFlickVelocity: Vars.maximumFlickVelocity

            ColumnLayout {
                id: listColumn
                width: parent.width
                spacing: 4

                // Recording option: swap modifiers for the modifier variables
                Item {
                    id: variablesCard
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80

                    property color targetColor: varsMouse.containsMouse ? Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity) : Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)
                    Behavior on targetColor { ColorAnimation { duration: Vars.animationDuration } }
                    scale: varsMouse.pressed ? 1.02 : 1.0
                    Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }

                    Item {
                        anchors.fill: parent
                        opacity: variablesCard.targetColor.a
                        Rectangle {
                            anchors.fill: parent
                            antialiasing: true
                            color: Qt.rgba(variablesCard.targetColor.r, variablesCard.targetColor.g, variablesCard.targetColor.b, 1.0)
                            radius: Vars.radiusLarge
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Vars.spacingLarge
                        anchors.rightMargin: Vars.spacingLarge
                        spacing: 16

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            QsText {
                                Layout.fillWidth: true
                                text: "Use variables when recording"
                                font.family: Vars.fontFamily
                                font.pixelSize: 16
                                setWeight: Vars.fontWeight
                                font.italic: Vars.fontItalic
                                color: Theme.on_surface
                                horizontalAlignment: Text.AlignLeft
                            }
                            QsText {
                                Layout.fillWidth: true
                                text: "Recorded modifiers are stored as $MM, $SM, $TM and $QM, so changing a modifier updates every shortcut that uses it"
                                font.family: Vars.fontFamily
                                font.pixelSize: 12
                                color: Theme.on_surface_variant
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignLeft
                            }
                        }

                        Rectangle {
                            width: 52
                            height: 32
                            radius: 16
                            antialiasing: true
                            color: page.useVariables ? Vars.tColorSelected(Theme.primary) : Vars.tColor(Theme.surface_variant, Vars.componentOpacity)
                            Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
                            Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                antialiasing: true
                                color: page.useVariables ? Theme.on_primary : Theme.on_surface_variant
                                anchors.verticalCenter: parent.verticalCenter
                                x: page.useVariables ? 24 : 4
                                Behavior on x { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            }
                        }
                    }

                    MouseArea {
                        id: varsMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.useVariables = !page.useVariables
                    }
                }

                Repeater {
                    model: page.rows
                    delegate: Loader {
                        id: rowLoader
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.topMargin: modelData.type === "header" ? Vars.spacingMedium : 0
                        sourceComponent: modelData.type === "header" ? headerComponent : rowComponent

                        // Same pill-badge-and-divider section header as every other settings
                        // list (UnifiedSettingsPage's section.delegate), so Shortcuts reads as
                        // part of the same app instead of a plain bold label of its own.
                        Component {
                            id: headerComponent
                            Item {
                                width: rowLoader.width
                                height: 52

                                RowLayout {
                                    anchors {
                                        left: parent.left; right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: 2; rightMargin: 2
                                    }
                                    spacing: 10

                                    Rectangle {
                                        implicitWidth: headerBadgeText.implicitWidth + 18
                                        implicitHeight: 24
                                        radius: 12
                                        antialiasing: true
                                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                                        Layout.alignment: Qt.AlignVCenter

                                        QsText {
                                            id: headerBadgeText
                                            anchors.centerIn: parent
                                            text: rowLoader.modelData.title
                                            color: Theme.primary
                                            font.pixelSize: 11
                                            setWeight: 700
                                            font.family: Vars.fontFamily
                                            font.letterSpacing: 0.8
                                        }
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 1
                                        color: Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.1)
                                    }
                                }
                            }
                        }
                        Component {
                            id: rowComponent
                            KeybindRow {
                                width: rowLoader.width
                                host: page
                                entry: page.byKey[rowLoader.modelData.key] || ({ key: rowLoader.modelData.key, kind: "bind", combo: "" })
                                first: rowLoader.modelData.first
                                last: rowLoader.modelData.last
                            }
                        }
                    }
                }
            }
        }
    }

    // Recording a combination that uses the mouse: scroll or click while holding modifiers
    MouseArea {
        anchors.fill: parent
        z: 100
        enabled: page.capturingKey !== ""
        visible: enabled
        acceptedButtons: Qt.AllButtons
        onWheel: (wheel) => {
            var mods = KeyCapture.modifiersFrom(wheel.modifiers);
            if (mods.length === 0 || page.captureKind !== "combo") {
                wheel.accepted = true;
                return;
            }
            wheel.accepted = true;
            page.finishCapture(mods, wheel.angleDelta.y > 0 ? "mouse_up" : "mouse_down");
        }
        onPressed: (mouse) => {
            var mods = KeyCapture.modifiersFrom(mouse.modifiers);
            var codes = {};
            codes[Qt.LeftButton] = "272";
            codes[Qt.RightButton] = "273";
            codes[Qt.MiddleButton] = "274";
            codes[Qt.BackButton] = "275";
            codes[Qt.ForwardButton] = "276";
            // A plain click just cancels, holding a modifier records the mouse button
            if (mods.length === 0 || page.captureKind !== "combo" || codes[mouse.button] === undefined) {
                page.stopCapture();
                return;
            }
            page.finishCapture(mods, "mouse:" + codes[mouse.button]);
        }
    }
}
