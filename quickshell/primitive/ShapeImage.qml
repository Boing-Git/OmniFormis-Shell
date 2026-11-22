import QtQuick
import QtQuick.Shapes

// A picture cut to an M3 shape (an app's icon, a sender's face, a cover): the shape is
// filled with the picture, covering it and centred, never stretched. While there is no
// picture (none given, or still loading) the shape shows in `color`, so put a fallback
// icon over it and bind its `visible` to `!ready`.
//
//   ShapeImage { width: 64; height: 64; shape: "Gem"; source: icon; color: Roles.primary_container }
Item {
    id: root

    property url source: ""

    // the M3Shapes name to cut it to
    property string shape: "Circle"

    // the shape's own fill, behind the picture: primitives never pick a colour
    required property color color

    // how big the picture is inside the shape (1 = just covering it; below 1 it sits
    // inside with the colour showing round it, e.g. 0.62 for an app icon on its shape)
    property real coverScale: 1

    // true once the picture is showing
    readonly property bool ready: picture.status === Image.Ready

    // the picture, used only as the shape's fill (not drawn by itself)
    Image {
        id: picture
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.width: 256
        sourceSize.height: 256

        // shapes are mostly smaller than its 256 px (an app's icon, a face): mipmaps keep
        // the picture smooth instead of jagged at that size
        mipmap: true
        visible: false
    }

    M3Shapes { id: lib }

    // a plain Shape filled with the picture (no layers / effects)
    Shape {
        id: outline
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: "transparent"
            fillColor: root.color
            scale: lib.fitScale(outline)
            PathSvg { path: lib.getPath(root.shape) }
        }
        ShapePath {
            strokeColor: "transparent"
            fillColor: "transparent"
            fillItem: root.ready ? picture : null

            // the picture is laid out at its own size, top-left on the shape's corner: fit
            // it to the shape (covering it, centred), then scale it round the middle
            readonly property real cw: outline.width / 2
            readonly property real ch: outline.height / 2
            readonly property real tw: Math.max(1, picture.implicitWidth)
            readonly property real th: Math.max(1, picture.implicitHeight)
            readonly property real fit: Math.max(outline.width / tw, outline.height / th)
            fillTransform: PlanarTransform.fromScale(root.coverScale, root.coverScale, cw, ch)
                .times(PlanarTransform.fromAffineMatrix(fit, 0, 0, fit, cw - tw * fit / 2, ch - th * fit / 2))
            scale: lib.fitScale(outline)
            PathSvg { path: lib.getPath(root.shape) }
        }
    }
}
