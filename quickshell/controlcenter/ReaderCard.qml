import QtQuick
import ".."
import "../primitive"
import "../variables.js" as Vars

// The card in the middle of the dial while Notifications or Settings is selected: an M3
// shape on the dial's middle line (a picture cut to it, or a value written in it), and
// words curved round it: a small note, a title, and a body wrapped over as many arcs as
// fit. Like the media card it is 0×0 at the dial's centre, sized only from its settings
// (ReaderSettings), and reads top to bottom on every spot.
Item {
    id: card

    // set by the control
    required property var dial
    required property var cfg

    // ── what it shows ──
    // the shape, and its colours (the fill, and what's written or drawn on it)
    property string shape: "Circle"
    property color fill: Roles.primary_container
    property color ink: Roles.on_primary_container

    // in the shape: a picture (a file / URL; it wins), else a value's words, else an icon
    property string image: ""
    property string value: ""
    property string symbol: ""

    // true: the picture fills the shape (a photo); false: it sits inside it (an app's icon)
    property bool imageFills: false

    // the words
    property string note: ""
    property string title: ""
    property string body: ""

    width: 0
    height: 0
    readonly property real cornerDistance: 0
    readonly property bool scaled: false

    readonly property real midDeg: dial.midDeg
    readonly property real midRad: midDeg * Math.PI / 180

    // true where the words are flipped: then the first line read is the furthest out
    readonly property bool flipped: Math.sin(midRad) < 0

    // ── the shape ── it morphs when it changes (another app, a switch flipped)
    Item {
        id: art
        width: card.cfg.artSize
        height: width
        x: card.cfg.artDistance * Math.cos(card.midRad) - width / 2
        y: card.cfg.artDistance * Math.sin(card.midRad) - height / 2

        ShapeMorph {
            anchors.fill: parent
            shape: card.shape
            color: card.fill
            Behavior on color { ColorAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
        }

        // the picture, cut to the same shape (shown over the morph once it's loaded)
        ShapeImage {
            id: picture
            anchors.fill: parent
            visible: card.image !== "" && ready
            shape: card.shape
            source: card.image
            color: card.fill
            coverScale: card.imageFills ? 1 : 0.66
        }

        // a value: big at a letter or two, smaller for a word
        SmoothText {
            id: valueText
            anchors.centerIn: parent
            visible: !picture.visible && card.value !== ""
            text: card.value
            width: Math.min(implicitWidth, card.cfg.valueMaxWidth)
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: card.value.length <= 2 ? card.cfg.valueSize : card.cfg.valueSmallSize
            font.weight: 800
            color: card.ink
            Behavior on color { ColorAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

            // a little bounce each time the value changes
            onTextChanged: if (visible) pop.restart()
            SequentialAnimation {
                id: pop
                NumberAnimation { target: valueText; property: "scale"; to: 1.18; duration: 60; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.fastSpatial.bezier }
                NumberAnimation { target: valueText; property: "scale"; to: 1; duration: 300; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.fastSpatial.bezier }
            }
        }
        SymbolIcon {
            anchors.centerIn: parent
            visible: !picture.visible && card.value === "" && card.symbol !== ""
            text: card.symbol
            size: parent.width * 0.5
            filled: true
            color: card.ink
        }
    }

    // ── the words ── on arcs from cfg.firstArc outwards, lineGap apart. Read top to
    // bottom they are: the note, the title, the body. Top is the arc nearest the centre,
    // or the furthest one where the words are flipped
    readonly property int headLines: (note !== "" ? 1 : 0) + (title !== "" ? 1 : 0)
    readonly property int bodyLines: paragraph.lines.length
    readonly property int totalLines: headLines + bodyLines

    // the arc of the line read `k`-th (0 = first)
    function arcOf(k) { return cfg.firstArc + (flipped ? totalLines - 1 - k : k) * cfg.lineGap }

    CurvedText {
        visible: card.note !== ""
        text: card.note
        radius: card.arcOf(0)
        centerDeg: card.midDeg
        maxDeg: card.cfg.maxDeg
        font.pixelSize: card.cfg.noteSize
        font.weight: 600
        color: Roles.on_surface_variant
    }
    CurvedText {
        visible: card.title !== ""
        text: card.title
        radius: card.arcOf(card.note !== "" ? 1 : 0)
        centerDeg: card.midDeg
        maxDeg: card.cfg.maxDeg
        font.pixelSize: card.cfg.titleSize
        font.weight: card.cfg.titleWeight
        color: Roles.on_surface
    }
    CurvedParagraph {
        id: paragraph
        text: card.body

        // its own arcs start after the head's, or (flipped) nearest the centre
        radius: card.cfg.firstArc + (card.flipped ? 0 : card.headLines) * card.cfg.lineGap
        lineGap: card.cfg.lineGap
        maxLines: Math.max(1, card.cfg.arcs - card.headLines)
        centerDeg: card.midDeg
        maxDeg: card.cfg.maxDeg
        font.pixelSize: card.cfg.bodySize
        color: Roles.on_surface_variant
    }
}
