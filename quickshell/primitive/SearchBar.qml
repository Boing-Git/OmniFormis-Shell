import QtQuick
import QtQuick.Shapes
import Quickshell
import "../variables.js" as Vars

// A curved search bar that sits on a dial's rim: a pill-shaped arc with the typed
// letters laid along it. It has no logic of its own; it only draws, takes the
// typing, and tells you what happened through its signals.
//
//   SearchBar {
//       anchors.fill: parent
//       cx: dial.centerX; cy: dial.centerY
//       radius: dial.expandedSize * 0.9
//       fromDeg: dial.startDeg + 5
//       barColor: ...; borderColor: ...; letterColor: ...; errorColor: ...; blobColor: ...
//       searching: dial.searching
//       onClicked: dial.searching = true
//       onTextChanged: dial.searchText = text
//   }
//
// Long text slides: the newest letter stays at the end and the oldest fade out
// at the start.
Item {
    id: bar

    // ── geometry ── the circle the bar follows (pass the dial's centre) and
    // the stretch of it the bar covers, in degrees
    property real cx: width
    property real cy: height
    property real radius: 360
    property real fromDeg: 180
    property real sweep: 80

    // true: the letters run the other way, tops towards the centre, so a bar on the
    // lower half of its circle (a dial along the top of the screen) still reads upright.
    // Decided from where the bar sits; set it yourself to override
    property bool flipped: Math.sin((fromDeg + sweep / 2) * Math.PI / 180) > 0.01

    // ── look ──
    property real barWidth: 26

    // the ring drawn around the bar while `searching`
    property real borderWidth: 3

    // how much room one letter takes along the bar, px
    property real letterWidth: 9
    property real fontSize: 14

    // the size of the shape that pops up behind a letter as you type it
    property real blobSize: 18

    // how long the shape stays behind a freshly typed letter before shrinking away, ms
    property int blobHold: 2

    // how many letters the fade at the start of the bar spreads over
    property real fadeLetters: 3

    // letters sliding off the start fade down to this (0..1), then disappear
    property real fadeMin: 0.3

    // shown, dimmed, while there's no text
    property string placeholder: "Type to search"

    // the matches for the text: how many, and which one is selected (0-based); the bar
    // shows "2 / 7" past its end while there's text. -1: no counter
    property int matchCount: -1
    property int matchIndex: -1

    // the counter's colour
    required property var counterColor

    // ── colours ── all required: there are no defaults
    required property var barColor
    required property var borderColor
    required property var letterColor

    // the letters turn this colour while `matched` is false
    required property var errorColor
    required property var blobColor

    // the letter's colour while it's on top of the pop-up shape (e.g. on_primary for a primary shape)
    required property var blobLetterColor
    Component.onCompleted: {
        if (barColor === undefined) console.error("SearchBar: no barColor was passed; there is no default, set it")
        if (borderColor === undefined) console.error("SearchBar: no borderColor was passed; there is no default, set it")
        if (letterColor === undefined) console.error("SearchBar: no letterColor was passed; there is no default, set it")
        if (errorColor === undefined) console.error("SearchBar: no errorColor was passed; there is no default, set it")
        if (blobColor === undefined) console.error("SearchBar: no blobColor was passed; there is no default, set it")
        if (blobLetterColor === undefined) console.error("SearchBar: no blobLetterColor was passed; there is no default, set it")
    }

    // ── state ──
    // true while the user is typing here: shows the border. You set it; set it
    // from onClicked, onAccepted and onCancelled.
    property bool searching: false

    // false turns the letters errorColor (nothing matches what was typed), and the bar
    // shakes once, sideways, the moment that happens
    property bool matched: true
    onMatchedChanged: if (!matched && input.text !== "") shaker.kick(Vars.kickFor(6, Vars.shakeSpring))     // first swing: 6 px
    transform: Translate { x: shaker.value }

    // the shake: a bouncy spring kicked sideways, ringing out round 0
    SpringValue {
        id: shaker
        stiffness: Vars.shakeSpring.stiffness
        dampingRatio: Vars.shakeSpring.dampingRatio
        epsilon: 0.05
    }

    // what's been typed
    property alias text: input.text

    // ── signals ──
    // the bar was clicked
    signal clicked()

    // Enter was pressed
    signal accepted()

    // Esc was pressed (the text is already cleared)
    signal cancelled()

    // Tab or Down (+1), Shift+Tab or Up (-1)
    signal step(int dir)

    // ── functions ──
    // give the bar the keyboard
    function focusInput() { input.forceActiveFocus() }

    // add typed text at the end
    function insert(s) { input.insert(input.length, s) }

    // empty the text
    function clear() { input.text = "" }

    // delete one letter, as Backspace does (the selection, or the letter before the
    // cursor): for a dial that gets the key when the field doesn't have the focus
    function backspace() {
        if (input.selectedText !== "") { input.remove(input.selectionStart, input.selectionEnd); return }
        if (input.cursorPosition > 0) input.remove(input.cursorPosition - 1, input.cursorPosition)
    }

    // delete the word before the cursor (Ctrl+Backspace)
    function backspaceWord() {
        const t = input.text, c = input.cursorPosition
        let i = c
        while (i > 0 && t[i - 1] === " ") i--
        while (i > 0 && t[i - 1] !== " ") i--
        input.remove(i, c)
    }

    // one letter's width as an angle (the same px is a smaller angle on a bigger circle)
    readonly property real charDeg: letterWidth / radius * 180 / Math.PI

    // how many letters fit in the bar
    readonly property int maxChars: Math.floor(sweep / charDeg)

    // how many letters have slid off the start (0 while it all fits)
    readonly property int slide: Math.max(0, input.text.length - maxChars)

    // the shape library for the pop-up shapes
    M3Shapes { id: shapes }

    // the pop-up shapes in a random order, shuffled once (Fisher-Yates); letter n
    // uses shapeQueue[n % length], so neighbouring letters get different shapes
    readonly property var shapeQueue: {
        const list = ["Slanted", "Arch", "Flag", "Arrow", "Semicircle", "Triangle", "Diamond", "Clamshell",
                      "Pentagon", "Gem", "Sunny", "VerySunny", "4SidedCookie", "GhostIsh", "SoftBurst"]
        for (let i = list.length - 1; i > 0; i--) {
            const j = Math.floor(Math.random() * (i + 1));
            [list[i], list[j]] = [list[j], list[i]]
        }
        return list
    }

    // ── the caret ── one M3 shape (blobColor) sitting where the next letter will land.
    // It glides along on a spring as you type, morphs to the next shape of shapeQueue
    // on every keystroke and gives a little pop, so typing feels alive without a
    // separate shape jumping out of every letter
    readonly property real caretAlong: charDeg * (input.text.length - slide + 0.5)
    SpringValue {
        id: caretSpring
        to: bar.caretAlong
        stiffness: Vars.springs.expressive.fast.spatial.stiffness
        dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio
        epsilon: 0.01
        Component.onCompleted: snap(to)
    }
    SpringValue {
        id: caretPop
        to: 1
        stiffness: Vars.springs.expressive.fast.spatial.stiffness
        dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio
        epsilon: 0.005
        value: 1
    }
    property int caretStep: 0
    onTextChanged: {
        caretStep++
        caretPop.snap(1.35)
        caretPop.start()
    }

    Item {
        id: caret
        readonly property real a: (bar.flipped ? bar.fromDeg + bar.sweep - caretSpring.value : bar.fromDeg + caretSpring.value) * Math.PI / 180
        width: bar.blobSize
        height: bar.blobSize
        x: bar.cx + bar.radius * Math.cos(a) - width / 2
        y: bar.cy + bar.radius * Math.sin(a) - height / 2
        rotation: a * 180 / Math.PI + (bar.flipped ? -90 : 90)
        scale: caretPop.value
        z: 1

        // only while typing, and never past the bar's end
        opacity: bar.searching && caretSpring.value < bar.sweep ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

        ShapeMorph {
            anchors.fill: parent
            shape: bar.shapeQueue[bar.caretStep % bar.shapeQueue.length]
            color: bar.blobColor
        }
    }

    // ── the counter ── "2 / 7", just past the bar's end, upright
    SmoothText {
        id: counter
        readonly property real pastDeg: (bar.barWidth / 2 + bar.borderWidth + 10 + width / 2) / bar.radius * 180 / Math.PI
        readonly property real a: (bar.flipped ? bar.fromDeg - pastDeg : bar.fromDeg + bar.sweep + pastDeg) * Math.PI / 180
        x: bar.cx + bar.radius * Math.cos(a) - width / 2
        y: bar.cy + bar.radius * Math.sin(a) - height / 2
        text: bar.matchCount > 0 ? (bar.matchIndex + 1) + " / " + bar.matchCount : "0"
        font.pixelSize: bar.fontSize * 0.85
        font.weight: 700
        color: bar.matched ? bar.counterColor : bar.errorColor
        opacity: input.text !== "" && bar.matchCount >= 0 ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
    }

    // the bar: a border ring (only while searching) under one thick arc with round ends
    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: bar.searching ? bar.borderColor : "transparent"
            strokeWidth: bar.barWidth + bar.borderWidth * 2
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: bar.cx; centerY: bar.cy
                radiusX: bar.radius; radiusY: bar.radius
                startAngle: bar.fromDeg
                sweepAngle: bar.sweep
            }
            Behavior on strokeColor {
                ColorAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier }
            }
        }

        // the bar itself: a container, so glass when the shell is translucent (Prefs.glass);
        // liquid glass draws it itself (below)
        ShapePath {
            fillColor: "transparent"
            strokeColor: glass.active ? "transparent" : Prefs.glass(bar.barColor, "ring")
            strokeWidth: bar.barWidth
            capStyle: ShapePath.RoundCap
            PathAngleArc {
                centerX: bar.cx; centerY: bar.cy
                radiusX: bar.radius; radiusY: bar.radius
                startAngle: bar.fromDeg
                sweepAngle: bar.sweep
            }
        }
    }

    // liquid glass in the bar's place (Settings → Liquid glass), over the ring drawn round
    // it while searching and under the letters: it sees the wallpaper through the dial's
    // colour under it
    LiquidGlass {
        id: glass
        anchors.fill: parent
        shape: "arc"
        cx: bar.cx
        cy: bar.cy
        radius: bar.radius
        thickness: bar.barWidth
        startDeg: bar.fromDeg
        sweepDeg: bar.sweep
        tint: Prefs.liquidBody(bar.barColor, "ring")
        under: host ? Prefs.liquidBody(host.color, host.glassKind) : "transparent"
    }

    // Clicking the bar counts as "inside" only along the curved bar itself (see
    // containmentMask), so clicks anywhere else still reach whatever is behind.
    // No hover tracking, so a dial under it stays open.
    MouseArea {
        anchors.fill: parent
        hoverEnabled: false
        cursorShape: Qt.IBeamCursor
        onClicked: bar.clicked()
        containmentMask: QtObject {
            // true when (x, y) is on the bar: the right distance from the centre,
            // and between the bar's start and end angles
            function contains(point: point): bool {
                const dx = point.x - bar.cx, dy = point.y - bar.cy
                const half = bar.barWidth / 2 + bar.borderWidth
                if (Math.abs(Math.hypot(dx, dy) - bar.radius) > half) return false
                const cap = half / bar.radius * 180 / Math.PI   // the round ends stick out this far

                // the angle measured from the bar's start, 0..360 (fromDeg can be any angle,
                // e.g. negative on a dial on the left edge)
                const deg = ((Math.atan2(dy, dx) * 180 / Math.PI - bar.fromDeg) % 360 + 360) % 360
                return deg <= bar.sweep + cap || deg >= 360 - cap
            }
        }
    }

    // the real text field: invisible, it only takes the typing
    TextInput {
        id: input
        opacity: 0

        // deleting is done here, so Backspace / Delete never leave the field (a dial
        // treats them as "remove this" otherwise): Ctrl+Backspace takes a word, Ctrl+U
        // the lot. With nothing to delete the key is swallowed, not passed on
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Backspace) {
                if (event.modifiers & Qt.ControlModifier) bar.backspaceWord()
                else bar.backspace()
                event.accepted = true
            } else if (event.key === Qt.Key_Delete) {
                if (selectedText !== "") remove(selectionStart, selectionEnd)
                else if (cursorPosition < length) remove(cursorPosition, cursorPosition + 1)
                event.accepted = true
            } else if (event.key === Qt.Key_U && (event.modifiers & Qt.ControlModifier)) {
                text = ""
                event.accepted = true
            }
        }
        Keys.onEscapePressed: { text = ""; bar.cancelled() }
        Keys.onReturnPressed: bar.accepted()
        Keys.onTabPressed: bar.step(1)
        Keys.onBacktabPressed: bar.step(-1)
        Keys.onDownPressed: bar.step(1)
        Keys.onUpPressed: bar.step(-1)
    }

    // the letters, placed one by one along the arc. A ListView (not a Repeater) so a
    // deleted letter can play its exit animation before it goes. Every slot is a
    // 1px-wide item stacked at the same spot (spacing -1), and the letter inside
    // places itself on the arc, so the list never moves anything. enabled: false
    // lets clicks fall through to the bar's MouseArea.
    ListView {
        anchors.fill: parent
        orientation: ListView.Horizontal
        spacing: -1
        interactive: false
        enabled: false

        // placeholder letters get a "\u0001" in front so they never match a typed
        // letter: otherwise typing "a" would reuse the "a" of "search" and slide it over
        model: ScriptModel {
            values: input.text === "" ? bar.placeholder.split("").map(c => "\u0001" + c) : input.text.split("")
        }

        delegate: Item {
            id: slot
            required property string modelData
            required property int index

            // true once the letter was deleted: it's kept alive just for the exit animation
            property bool removing: false

            // where the letter was when it was deleted (its index is meaningless after that)
            property real frozenAlong: 0

            width: 1
            height: 1

            ListView.onRemove: {
                // placeholder letters just go, so they don't overlap the first typed letter
                if (letter.isPlaceholder) return
                slot.removing = true
                exitAnim.start()
            }

            SequentialAnimation {
                id: exitAnim
                PropertyAction { target: slot; property: "ListView.delayRemove"; value: true }

                // the letter fades and shrinks away
                ParallelAnimation {
                    NumberAnimation { target: letter; property: "life"; to: 0; duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier }
                }
                PropertyAction { target: slot; property: "ListView.delayRemove"; value: false }
            }

            Item {
                id: letter
                readonly property bool isPlaceholder: slot.modelData.length > 1
                readonly property string modelData: slot.modelData.charAt(slot.modelData.length - 1)
                readonly property int index: slot.index

                // 1 while the letter is there, animated to 0 when it's deleted
                property real life: 1

                // where the letter would be from its index (only valid while it's still in the text)
                readonly property real liveAlong: bar.charDeg * (index - bar.slide + 0.5)

                // remember the last valid position, so a deleted letter stays where it was
                onLiveAlongChanged: if (!slot.removing && index >= 0) slot.frozenAlong = liveAlong

                // a typed letter is a brand-new delegate (deleting never makes one), so
                // each new letter plays its own pop-up effect once, start to finish
                Component.onCompleted: {
                    slot.frozenAlong = liveAlong
                    if (!isPlaceholder) typeAnim.start()
                }

                // this letter's position along the bar, in degrees from the start of the bar
                readonly property real along: slot.removing ? slot.frozenAlong : liveAlong

                // this letter's angle on the circle, in radians (cos/sin want radians)
                readonly property real a: (bar.flipped ? bar.fromDeg + bar.sweep - along : bar.fromDeg + along) * Math.PI / 180

                // 0 at the start of the bar, rising to 1 over `fadeLetters` letters; only
                // while letters are sliding off (nothing to fade while all the text fits)
                readonly property real edge: bar.slide > 0
                    ? Math.max(0, Math.min(1, along / (bar.charDeg * bar.fadeLetters)))
                    : 1

                // fadeMin at the start, up to 1 further in (eased); letters that slid
                // off the bar (along < 0) are hidden
                readonly property real inBar: along < 0 ? 0 : bar.fadeMin + (1 - bar.fadeMin) * (edge * edge * (3 - 2 * edge))

                width: glyph.width
                height: glyph.height
                x: bar.cx + bar.radius * Math.cos(a) - width / 2
                y: bar.cy + bar.radius * Math.sin(a) - height / 2
                rotation: a * 180 / Math.PI + (bar.flipped ? -90 : 90)    // lean along the curve
                opacity: (input.text === "" ? 0.5 : 1) * inBar * life
                scale: 0.5 + 0.5 * life                      // shrinks to half as it's deleted

                SmoothText {
                    id: glyph
                    anchors.centerIn: parent
                    text: letter.modelData
                    font.pixelSize: bar.fontSize

                    color: bar.matched ? bar.letterColor : bar.errorColor
                }

                // the typing effect: the new letter pops in (the caret ahead of it morphs)
                NumberAnimation {
                    id: typeAnim
                    target: glyph; property: "scale"; from: 0.4; to: 1
                    duration: Prefs.fastSpatial.duration
                    easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.fastSpatial.bezier
                }
            }
        }
    }
}
