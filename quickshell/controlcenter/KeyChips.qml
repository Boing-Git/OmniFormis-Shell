import QtQuick
import ".."
import "../primitive"
import "../keycapture.js" as KeyCapture
import "../variables.js" as Vars

// A key combination as one chip per key ("$MM", "Shift", "T"), laid along an arc round
// (cx, cy) and centred on `centerDeg`: the Settings control shows a shortcut this way in
// the gap between the rings. While a new combination is being recorded the chips turn
// primary and a last, outlined chip pulses where the next key will go.
Item {
    id: root

    // the combination's pieces, in order (KeyCapture.tokens)
    property var tokens: []
    property real cx: 0
    property real cy: 0
    property real radius: 100
    property real centerDeg: 45

    // recording: every chip primary, and "…" (if it's among the tokens) outlined and pulsing
    property bool recording: false

    // ── settings ── sizes are px
    property real chipHeight: 32
    property real chipPadding: 22
    property real chipGap: 7
    property real labelSize: 13

    // true: the tops of the letters face away from the centre (as CurvedText)
    readonly property bool flipped: Math.sin(centerDeg * Math.PI / 180) < 0

    FontMetrics {
        id: fm
        font.pixelSize: root.labelSize
        font.weight: 600
        font.hintingPreference: Font.PreferNoHinting
    }

    // each chip's words, its width, and where its middle sits along the arc (px from the centre one)
    readonly property var layout: {
        const items = tokens.map(t => {
            const label = t === "…" || t === "none" ? t : KeyCapture.label(t)
            return { token: t, label: label, w: Math.max(chipHeight, fm.advanceWidth(label) + chipPadding) }
        })
        const total = items.reduce((sum, i) => sum + i.w, 0) + chipGap * Math.max(0, items.length - 1)
        let at = -total / 2
        for (const i of items) {
            i.mid = at + i.w / 2
            at += i.w + chipGap
        }
        return items
    }

    Repeater {
        model: root.layout

        Rectangle {
            id: chip
            required property var modelData

            // reading left to right runs towards smaller angles, or larger ones when flipped
            readonly property real deg: root.centerDeg + (root.flipped ? 1 : -1) * modelData.mid / root.radius * 180 / Math.PI
            readonly property real rad: deg * Math.PI / 180
            readonly property bool ghost: modelData.token === "…" || modelData.token === "none"
            readonly property bool variable: KeyCapture.isVariable(modelData.token)

            width: modelData.w
            height: root.chipHeight
            radius: height / 2
            antialiasing: true
            x: root.cx + root.radius * Math.cos(rad) - width / 2
            y: root.cy + root.radius * Math.sin(rad) - height / 2
            rotation: root.flipped ? deg + 90 : deg - 90

            // M3E: a key is secondary-container, a modifier variable ($MM) tertiary-container;
            // while recording they are primary, and the key still to come is only an outline
            color: ghost ? "transparent"
                : root.recording ? Roles.primary
                : variable ? Roles.tertiary_container : Roles.secondary_container
            border.width: ghost ? 2 : 0
            border.color: root.recording ? Roles.primary : Roles.outline
            Behavior on color { ColorAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

            SequentialAnimation on opacity {
                running: root.recording && chip.modelData.token === "…"
                loops: Animation.Infinite
                NumberAnimation { to: 0.35; duration: Vars.expressiveSlowEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveSlowEffects.bezier }
                NumberAnimation { to: 1.0; duration: Vars.expressiveSlowEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveSlowEffects.bezier }
            }

            SmoothText {
                anchors.centerIn: parent
                text: chip.modelData.label
                font.pixelSize: root.labelSize
                font.weight: 600
                color: chip.ghost ? (root.recording ? Roles.primary : Roles.on_surface_variant)
                    : root.recording ? Roles.on_primary
                    : chip.variable ? Roles.on_tertiary_container : Roles.on_secondary_container
            }
        }
    }
}
