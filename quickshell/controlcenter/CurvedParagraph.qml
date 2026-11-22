import QtQuick
import "../primitive"

// A few lines of text laid along arcs round (cx, cy), one under the other: the words are
// wrapped onto as many lines as they need (up to maxLines; the rest becomes "…"). Like
// CurvedText it is never upside down, and it reads top to bottom on every spot: the first
// line is the one nearest the centre, or the furthest where the text is flipped.
//
//   CurvedParagraph {
//       text: body; radius: 120; lineGap: 18; centerDeg: dial.midDeg; maxDeg: 76
//       font.pixelSize: 13; color: Roles.on_surface_variant
//   }
Item {
    id: root

    property string text: ""
    property real cx: 0
    property real cy: 0

    // the arc nearest the centre, and the px from one arc to the next
    property real radius: 100
    property real lineGap: 18

    // the angle the lines are centred on, and the longest a line may run (degrees)
    property real centerDeg: 45
    property real maxDeg: 80
    property int maxLines: 3
    property font font
    required property color color

    // true: the tops of the letters face away from the centre (as CurvedText)
    readonly property bool flipped: Math.sin(centerDeg * Math.PI / 180) < 0

    // the font as drawn (hinting off, as SmoothText draws), so measuring matches
    readonly property font drawFont: Qt.font({
        family: font.family, pixelSize: font.pixelSize, weight: font.weight,
        italic: font.italic, hintingPreference: Font.PreferNoHinting
    })
    FontMetrics { id: fm; font: root.drawFont }

    // the arc line `i` of `n` sits on: the first one nearest the centre, or furthest when flipped
    function radiusOf(i, n) { return radius + (flipped ? n - 1 - i : i) * lineGap }

    // the words wrapped onto exactly `n` lines, or null when they don't fit on that many
    function wrap(words, n) {
        const lines = []
        let w = 0
        for (let i = 0; i < n; i++) {
            const room = maxDeg * Math.PI / 180 * radiusOf(i, n)
            let line = ""
            while (w < words.length) {
                const next = line === "" ? words[w] : line + " " + words[w]
                if (fm.advanceWidth(next) > room && line !== "") break
                line = next
                w++
            }
            lines.push(line)
        }
        return w >= words.length ? lines : null
    }

    // the lines to draw: on as few arcs as the words need; past maxLines the last one is cut
    readonly property var lines: {
        // fm.advanceWidth() is a call a binding can't follow: read the metrics' font,
        // so a font set (or changed) after the text still wraps it again
        fm.font
        const words = text.split(/\s+/).filter(s => s !== "")
        if (words.length === 0) return []
        for (let n = 1; n <= maxLines; n++) {
            const l = wrap(words, n)
            if (l) return l
        }

        // too long: fill maxLines, and let the last line carry the rest (CurvedText cuts it)
        const lines = []
        let w = 0
        for (let i = 0; i < maxLines; i++) {
            const room = maxDeg * Math.PI / 180 * radiusOf(i, maxLines)
            let line = ""
            while (w < words.length) {
                const next = line === "" ? words[w] : line + " " + words[w]
                if (i < maxLines - 1 && fm.advanceWidth(next) > room && line !== "") break
                line = next
                w++
            }
            lines.push(line)
        }
        return lines
    }

    // how far out the block reaches (the last arc), for whatever sits past it
    readonly property real outerRadius: radius + Math.max(0, lines.length - 1) * lineGap

    Repeater {
        model: root.lines

        CurvedText {
            required property string modelData
            required property int index
            cx: root.cx
            cy: root.cy
            text: modelData
            radius: root.radiusOf(index, root.lines.length)
            centerDeg: root.centerDeg
            maxDeg: root.maxDeg
            font: root.font
            color: root.color
        }
    }
}
