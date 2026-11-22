import QtQuick
import QtQuick.Shapes
import "../variables.js" as Vars

// A Material Symbols icon drawn as one vector shape: the font's outline for the icon is
// filled like any other M3 shape. Smooth at every size, scale and rotation, and the
// filled glyphs have no seams (their overlapping parts fill as one solid shape).
//
//   SymbolIcon { text: "wifi"; size: 24; color: Roles.on_surface; filled: true }
//
// Sized `size` × `size` and the icon sits in the middle like a Text would, so it works
// with anchors.centerIn. Set `family` to draw plain text the same way (e.g. a number).
Item {
    id: root

    // the icon's name (the font turns it into the drawing), or any text
    property string text: ""
    property real size: 24
    required property color color

    // fills in smoothly while true (the font's FILL axis)
    property bool filled: false

    // 0 = outlined .. 1 = filled; follows `filled` unless set
    property real fill: filled ? 1 : 0
    Behavior on fill { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

    // the font's weight axis (100 thin .. 700 bold) and grade (-25 .. 200, finer weight)
    property real weight: 400
    property real grade: 0
    property string family: "Material Symbols Rounded"

    implicitWidth: size
    implicitHeight: size

    FontMetrics { id: fm; font: glyph.font }

    // the same outline, never drawn, only to measure its height (measuring the drawn one
    // would loop: its size updates every time it moves)
    Shape {
        visible: false
        ShapePath {
            PathText { id: measure; text: root.text; font: glyph.font }
        }
    }

    // Drawn as one solid shape, smoothed by multisampling, at twice its size (so a tile
    // growing to "selected" still shows a sharp icon). Not the curve renderer: it smooths the
    // edge of every part of the outline on its own, and where the parts of a filled glyph
    // overlap (the gear's hole, the bell's clapper) that left faint hairline rings
    Item {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4
        layer.smooth: true
        layer.textureSize: Qt.size(Math.ceil(width * 2), Math.ceil(height * 2))

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.GeometryRenderer

            ShapePath {
                fillColor: root.color
                strokeColor: "transparent"

                // the outline's parts overlap: winding fills them as one shape
                fillRule: ShapePath.WindingFill

                // across: centred by its width, like a Text. Down: PathText puts the top of the
                // outline at `y`, so the outline is centred by its own height (Material icons are
                // drawn centred in their box, so this matches a centred Text)
                PathText {
                    id: glyph
                    text: root.text
                    font.family: root.family
                    font.pixelSize: root.size
                    font.variableAxes: root.family === "Material Symbols Rounded"
                        ? ({ "FILL": root.fill, "wght": root.weight, "GRAD": root.grade })
                        : ({})
                    x: (root.width - fm.advanceWidth(root.text)) / 2
                    y: (root.height - measure.height) / 2
                }
            }
        }
    }
}
