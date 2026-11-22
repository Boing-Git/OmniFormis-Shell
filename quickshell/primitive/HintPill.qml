import QtQuick
import "../variables.js" as Vars

// A short line of words in a pill (an M3 tooltip / snackbar), fading in while `text` is
// set and out when it's emptied; it keeps its last words while it fades out. Used for the
// first-contact hints by a dial.
//
//   HintPill {
//       text: hint                       // "" hides it
//       centerX: ...; centerY: ...       // where its middle wants to be (the parent's px)
//       color: Roles.inverse_surface; textColor: Roles.inverse_on_surface
//   }
Rectangle {
    id: root

    property string text: ""

    // where its middle wants to be; it's kept `margin` px inside the parent
    property real centerX: 0
    property real centerY: 0
    property real margin: 12

    // the room round the words, and their size (M3 labelLarge)
    property real padding: 14
    property real fontSize: 13

    // primitives never pick a colour: always pass them in
    required property color textColor

    x: Math.max(margin, Math.min((parent ? parent.width : 0) - width - margin, centerX - width / 2))
    y: Math.max(margin, Math.min((parent ? parent.height : 0) - height - margin, centerY - height / 2))
    width: words.implicitWidth + padding * 2
    height: words.implicitHeight + padding
    radius: height / 2
    antialiasing: true
    opacity: text !== "" ? 1 : 0
    visible: opacity > 0
    scale: 0.9 + 0.1 * opacity
    Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

    // keeps the last words while fading out
    property string shownText: ""
    onTextChanged: if (text !== "") shownText = text

    SmoothText {
        id: words
        anchors.centerIn: parent
        text: root.shownText
        font.pixelSize: root.fontSize
        font.weight: 600
        color: root.textColor
    }
}
