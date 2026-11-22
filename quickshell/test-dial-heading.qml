import QtQuick
import Quickshell
import "primitive"

// Enter during a spin acts on the item the ring is turning to (AppLauncher, WallpaperDial,
// PowerMenu and the control center's inner ring read DialRotation.heading). 50 snaps to
// random items, each read back at a random moment of the spin: heading must be the target,
// though pos (the item under the mark) often isn't yet.
//   timeout 60 qs -p quickshell/test-dial-heading.qml     (prints PASS or FAIL)
ShellRoot {
    id: test
    property int round: 0
    property int midSpin: 0
    property int target: 0

    DialRotation { id: rot; stepDeg: 10 }

    Timer {
        id: next
        interval: 1
        onTriggered: {
            if (test.round === 50) {
                console.log("PASS: 50 spins, " + test.midSpin + " read while another item was under the mark")
                Qt.exit(0)
                return
            }
            test.round++
            test.target = rot.pos + Math.floor(Math.random() * 41) - 20
            rot.snapTo(test.target)
            check.interval = Math.floor(Math.random() * 150)
            check.restart()
        }
    }
    Timer {
        id: check
        onTriggered: {
            if (rot.pos !== test.target) test.midSpin++
            if (rot.heading !== test.target) {
                console.log("FAIL: round " + test.round + ": heading " + rot.heading + ", target " + test.target)
                Qt.exit(1)
                return
            }
            next.restart()
        }
    }
    Component.onCompleted: next.start()
}
