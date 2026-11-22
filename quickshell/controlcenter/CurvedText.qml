import QtQuick
import "../primitive"

// One line of text laid along an arc around (cx, cy), centred on the angle `centerDeg`,
// each character turned to follow the curve. The text reads left to right and is
// never upside down: it flips (top facing outwards) on corners where it would be.
// Too long for `maxDeg` → cut with "…".
Item {
    id: root

    property string text: ""
    property real cx: 0
    property real cy: 0
    property real radius: 100

    // the angle the text is centred on (degrees, 0 = right, 90 = down)
    property real centerDeg: 45

    // the longest the text may run along the arc (degrees)
    property real maxDeg: 80
    property font font
    required property color color

    // true: the tops of the letters face away from the centre
    readonly property bool flipped: Math.sin(centerDeg * Math.PI / 180) < 0

    // the font as drawn: hinting off (as SmoothText draws), so measuring matches the letters
    readonly property font drawFont: Qt.font({
        family: font.family, pixelSize: font.pixelSize, weight: font.weight,
        italic: font.italic, hintingPreference: Font.PreferNoHinting
    })

    FontMetrics { id: fm; font: root.drawFont }

    // the characters to draw (cut to fit), and where each one's middle sits along the line (px)
    readonly property var layout: {
        // fm.advanceWidth() is a call a binding can't follow: read the metrics' font,
        // so a font set (or changed) after the text still lays the letters out again
        fm.font
        const maxLen = maxDeg * Math.PI / 180 * radius

        // Latin/Greek/Cyrillic bend letter by letter; anything past them (Devanagari,
        // Arabic, Thai, emoji…) needs whole runs shaped together, so it bends word by word
        const complex = /[^\u0000-\u052F\u1E00-\u1EFF\u2000-\u206F\u20A0-\u20CF]/.test(text)
        let chars = complex ? text.split(/(\s+)/).filter(s => s !== "") : Array.from(text)
        const width = cs => cs.reduce((w, c) => w + fm.advanceWidth(c), 0)
        if (width(chars) > maxLen) {
            while (chars.length > 0 && width(chars) + fm.advanceWidth("…") > maxLen) chars.pop()
            while (chars.length > 0 && chars[chars.length - 1] === " ") chars.pop()
            chars.push("…")
        }

        // measured as a growing run of text (not letter by letter) so the kerning
        // between letter pairs is kept and the spacing stays even
        const total = fm.advanceWidth(chars.join(""))
        const out = []
        let run = ""
        for (const c of chars) {
            const before = fm.advanceWidth(run)
            run += c
            out.push({ c: c, mid: -total / 2 + (before + fm.advanceWidth(run)) / 2 })
        }
        return out
    }

    Repeater {
        model: root.layout

        SmoothText {
            required property var modelData

            // reading left to right runs towards smaller angles, or larger ones when flipped
            readonly property real deg: root.centerDeg + (root.flipped ? 1 : -1) * modelData.mid / root.radius * 180 / Math.PI
            readonly property real rad: deg * Math.PI / 180

            text: modelData.c
            font: root.drawFont
            color: root.color

            x: root.cx + root.radius * Math.cos(rad) - width / 2
            y: root.cy + root.radius * Math.sin(rad) - height / 2
            rotation: root.flipped ? deg + 90 : deg - 90
        }
    }
}
