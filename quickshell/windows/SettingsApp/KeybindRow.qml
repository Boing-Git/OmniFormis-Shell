import QtQuick
import QtQuick.Layouts
import "../.."
import "../../theme"
import "../../core/keycapture.js" as KeyCapture

// One shortcut: what it does, its combination as key chips, and how to change it.
// Click the chips to record a new combination, or use the pencil to type one with variables.
Item {
    id: row

    // The Shortcuts page that owns the recording and editing state (not named `page`, which
    // would shadow the page id when the page passes itself in)
    required property var host
    // { key, kind: "bind" | "modifier" | "key", description, combo, resolved, conflicts, active, error }
    required property var entry
    property bool first: false
    property bool last: false

    readonly property bool capturing: host.capturingKey === entry.key
    readonly property bool editing: host.editingKey === entry.key
    readonly property bool isBind: entry.kind === "bind"
    readonly property bool hasConflict: isBind && entry.conflicts !== undefined && entry.conflicts.length > 0
    readonly property bool usesVariables: {
        var t = KeyCapture.tokens(entry.combo);
        for (var i = 0; i < t.length; i++) {
            if (KeyCapture.isVariable(t[i]) || KeyCapture.isPlaceholder(t[i]))
                return true;
        }
        return false;
    }

    // Layouts size a Loader's item from its implicit size, so the height is declared there
    implicitWidth: 400
    implicitHeight: editing ? 176 : 72
    Behavior on implicitHeight {
        NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow }
    }
    opacity: (isBind && entry.active === false) ? 0.55 : 1.0

    // Same background rules as the sidebar and every other page
    property color targetColor: capturing || editing ? Vars.tColorSelected(Theme.primary_container)
        : (rowMouse.containsMouse ? Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity) : Vars.tColor(Theme.surface_container_high, Vars.componentOpacity))
    Behavior on targetColor { ColorAnimation { duration: Vars.animationDuration } }

    scale: rowMouse.pressed && !editing ? 1.02 : 1.0
    Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }

    Item {
        anchors.fill: parent
        opacity: row.targetColor.a
        Rectangle {
            anchors.fill: parent
            antialiasing: true
            color: Qt.rgba(row.targetColor.r, row.targetColor.g, row.targetColor.b, 1.0)
            property bool pill: row.capturing || row.editing
            topLeftRadius: pill ? 36 : (row.first ? Vars.radiusLarge : 4)
            topRightRadius: pill ? 36 : (row.first ? Vars.radiusLarge : 4)
            bottomLeftRadius: pill ? 36 : (row.last ? Vars.radiusLarge : 4)
            bottomRightRadius: pill ? 36 : (row.last ? Vars.radiusLarge : 4)
            Behavior on topLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
            Behavior on topRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
            Behavior on bottomLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
            Behavior on bottomRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        }
    }

    // A single key of a combination
    component KeyChip: Rectangle {
        id: chip
        property string token: ""
        property bool ghost: false
        // Set while the row is being recorded or edited (inline components cannot see `row`)
        property bool emphasized: false
        readonly property bool variable: KeyCapture.isVariable(token)
        readonly property bool placeholder: KeyCapture.isPlaceholder(token)

        implicitHeight: 32
        implicitWidth: Math.max(32, chipText.implicitWidth + 20)
        radius: height / 2
        antialiasing: true
        color: ghost ? "transparent"
            : (emphasized ? Theme.primary
            : (variable ? Theme.tertiary_container : (placeholder ? "transparent" : Theme.secondary_container)))
        border.width: ghost || placeholder ? 2 : 0
        border.color: emphasized ? Theme.on_primary_container : Theme.outline
        Behavior on color { ColorAnimation { duration: Vars.animationDuration } }

        QsText {
            id: chipText
            anchors.centerIn: parent
            text: KeyCapture.label(chip.token)
            font.family: Vars.fontFamily
            font.pixelSize: 13
            setWeight: 600
            color: chip.ghost ? Theme.on_primary_container
                : (chip.emphasized ? Theme.on_primary
                : (chip.variable ? Theme.on_tertiary_container : (chip.placeholder ? Theme.on_surface_variant : Theme.on_secondary_container)))
        }
    }

    // Opens recording when the card is clicked
    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        enabled: !row.editing
        onClicked: row.host.startCapture(row.entry.key, row.entry.kind === "bind" ? "combo" : row.entry.kind)
    }

    RowLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: Vars.spacingLarge
        anchors.rightMargin: Vars.spacingLarge
        height: 72
        spacing: 16

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            QsText {
                Layout.fillWidth: true
                text: row.entry.description || row.entry.key
                font.family: Vars.fontFamily
                font.pixelSize: 16
                setWeight: Vars.fontWeight
                font.italic: Vars.fontItalic
                color: row.capturing || row.editing ? Theme.on_primary_container : Theme.on_surface
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
            }
            QsText {
                Layout.fillWidth: true
                text: {
                    if (row.capturing)
                        return row.entry.kind === "modifier" ? "Press the modifier you want" : (row.entry.kind === "key" ? "Press the key you want" : "Press the new shortcut, Esc to cancel");
                    if (row.editing)
                        return "Type a combination, use variables like $MM";
                    if (row.entry.error)
                        return row.entry.error;
                    if (row.isBind && row.entry.active === false)
                        return "Not used by the current layout";
                    if (row.hasConflict)
                        return "Also used by " + row.entry.conflicts.join(", ");
                    if (row.isBind && row.entry.combo === "")
                        return "Disabled";
                    if (row.usesVariables && row.entry.resolved && row.entry.resolved.length > 0)
                        return row.entry.resolved.length > 1 ? row.entry.resolved[0] + " to " + row.entry.resolved[row.entry.resolved.length - 1] : row.entry.resolved[0];
                    return row.isBind ? row.entry.key : "";
                }
                visible: text !== ""
                font.family: Vars.fontFamily
                font.pixelSize: 12
                color: row.capturing || row.editing ? Theme.on_primary_container
                    : ((row.entry.error) ? Theme.error : (row.hasConflict ? Theme.tertiary : Theme.on_surface_variant))
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignLeft
            }
        }

        // The combination, or a live preview while recording: one horizontal row of chips
        Row {
            Layout.alignment: Qt.AlignVCenter
            spacing: 6

            Repeater {
                model: {
                    if (row.capturing)
                        return row.host.heldMods.slice().concat(["…"]);
                    return KeyCapture.tokens(row.entry.combo);
                }
                delegate: KeyChip {
                    required property string modelData
                    token: modelData
                    emphasized: row.capturing || row.editing
                    ghost: row.capturing && modelData === "…"
                    SequentialAnimation on opacity {
                        running: row.capturing && modelData === "…"
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.35; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0; duration: 600; easing.type: Easing.InOutSine }
                    }
                }
            }
        }

        // Edit as text, and clear
        Rectangle {
            visible: row.isBind || row.entry.kind === "key"
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            radius: 18
            antialiasing: true
            color: editMouse.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.10) : "transparent"
            QsText {
                anchors.centerIn: parent
                text: row.editing ? "close" : "edit"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 20
                color: row.capturing || row.editing ? Theme.on_primary_container : Theme.on_surface_variant
            }
            MouseArea {
                id: editMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: row.editing ? row.host.stopEditing() : row.host.startEditing(row.entry.key)
            }
        }
        Rectangle {
            visible: row.isBind && row.entry.combo !== ""
            Layout.alignment: Qt.AlignVCenter
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            radius: 18
            antialiasing: true
            color: clearMouse.containsMouse ? Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.16) : "transparent"
            QsText {
                anchors.centerIn: parent
                text: "block"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 20
                color: clearMouse.containsMouse ? Theme.error : (row.capturing || row.editing ? Theme.on_primary_container : Theme.on_surface_variant)
            }
            MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: row.host.setEntry(row.entry.key, "")
            }
        }
    }

    // Typing a combination: variables can be used and are offered as chips to insert
    Item {
        id: editor
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: Vars.spacingLarge
        anchors.rightMargin: Vars.spacingLarge
        anchors.bottomMargin: 14
        height: 88
        opacity: row.editing ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Vars.animationDuration } }

        Rectangle {
            id: field
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 40
            radius: 20
            antialiasing: true
            color: Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)
            border.width: 2
            border.color: row.host.editError !== "" ? Theme.error : Theme.primary

            TextInput {
                id: input
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                verticalAlignment: TextInput.AlignVCenter
                font.family: Vars.fontFamily
                font.pixelSize: 15
                color: Theme.on_surface
                selectByMouse: true
                clip: true
                onTextChanged: row.host.editText = text
                Keys.onReturnPressed: row.host.commitEdit()
                Keys.onEnterPressed: row.host.commitEdit()
                Keys.onEscapePressed: row.host.stopEditing()

                Connections {
                    target: row.host
                    function onEditingKeyChanged() {
                        if (row.editing) {
                            input.text = row.entry.combo !== undefined ? row.entry.combo : (row.entry.value || "");
                            input.forceActiveFocus();
                            input.selectAll();
                        }
                    }
                    function onInsertRequested(text) {
                        if (row.editing) {
                            input.insert(input.cursorPosition, text);
                            input.forceActiveFocus();
                        }
                    }
                }
            }
        }

        QsText {
            id: hint
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.top: field.bottom
            anchors.topMargin: 6
            text: row.host.editError !== "" ? row.host.editError : "Insert a variable:"
            font.family: Vars.fontFamily
            font.pixelSize: 12
            color: row.host.editError !== "" ? Theme.error : Theme.on_primary_container
        }

        Flow {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: hint.bottom
            anchors.topMargin: 6
            spacing: 6
            visible: row.host.editError === ""

            Repeater {
                model: row.host.insertableVariables
                delegate: Rectangle {
                    required property string modelData
                    height: 26
                    width: varText.implicitWidth + 18
                    radius: 13
                    antialiasing: true
                    color: varMouse.containsMouse ? Theme.tertiary : Theme.tertiary_container
                    Behavior on color { ColorAnimation { duration: 120 } }
                    QsText {
                        id: varText
                        anchors.centerIn: parent
                        text: modelData
                        font.family: Vars.fontFamily
                        font.pixelSize: 12
                        setWeight: 600
                        color: varMouse.containsMouse ? Theme.on_tertiary : Theme.on_tertiary_container
                    }
                    MouseArea {
                        id: varMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: row.host.insertRequested(modelData)
                    }
                }
            }
        }
    }
}
