import QtQuick
import "../.."
import "../../theme"

// Circular icon container used by every settings page so bare icons share one
// Material 3 expressive look. It follows the same colour logic as the sidebar:
// a solid secondary circle normally, a solid primary circle when its card is highlighted.
Item {
    id: root

    property string icon: ""
    property bool selected: false
    property bool filled: false
    property int size: 40
    property real iconSize: Math.round(size * 0.55)
    // "secondary" (default), "tertiary" or "primary"
    property string tone: "secondary"

    // Solid accent circles (not the dark tonal containers) so the icon stays
    // readable on top of the dark item backgrounds, matching the sidebar cookies.
    readonly property color containerColor: {
        if (selected)
            return Theme.primary;
        if (tone === "primary")
            return Theme.primary;
        if (tone === "tertiary")
            return Theme.tertiary;
        return Theme.secondary;
    }
    readonly property color onContainerColor: {
        if (selected)
            return Theme.on_primary;
        if (tone === "primary")
            return Theme.on_primary;
        if (tone === "tertiary")
            return Theme.on_tertiary;
        return Theme.on_secondary;
    }
    property alias glyph: glyphText

    implicitWidth: size
    implicitHeight: size
    width: size
    height: size

    FontLoader {
        id: filledFont
        source: "../../theme/assets/MaterialSymbolsRounded-Filled.ttf"
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        antialiasing: true
        color: root.containerColor
        Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
    }

    QsText {
        id: glyphText
        anchors.centerIn: parent
        text: root.icon
        font.family: root.filled ? filledFont.name : "Material Symbols Outlined"
        font.pixelSize: root.iconSize
        color: root.onContainerColor
        Behavior on color { ColorAnimation { duration: Vars.animationDuration } }
    }
}
