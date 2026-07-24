import QtQuick
import "../../theme/variables.js" as Vars
import "../.."

Item {
    id: root
    property string side: "left" // "left", "right", "top-left", "top-right", "bottom-left", "bottom-right"
    property real radius: Vars.radiusExtraLarge
    property color color: Theme.surface

    width: radius
    height: radius
    clip: true

    Rectangle {
        width: root.radius * 4
        height: root.radius * 4
        
        x: (root.side === "left" || root.side === "top-right" || root.side === "bottom-right") ? -root.radius * 2 : -root.radius
        y: (root.side === "bottom-left" || root.side === "bottom-right") ? -root.radius * 2 : -root.radius
        
        radius: root.radius * 2
        color: "transparent"
        border.color: root.color
        border.width: root.radius
    }
}
