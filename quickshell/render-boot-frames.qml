import QtQuick
import Quickshell
import "primitive"

// Renders the boot animation (plymouth/dial-e) from the shell's own M3E loading indicator:
// one morph cycle, without the spin (Plymouth's script spins it), as numbered PNGs in
// $BOOT_FRAMES_DIR. Run by scripts/build-plymouth.sh:
//   BOOT_FRAMES_DIR=/some/dir qs -p quickshell/render-boot-frames.qml
ShellRoot {
    id: render
    readonly property string out: Quickshell.env("BOOT_FRAMES_DIR")
    readonly property int frames: 139          // 4.62 s at 30 frames a second
    property int frame: 0

    FloatingWindow {
        implicitWidth: 240
        implicitHeight: 240
        color: "transparent"

        // its own size, whatever the compositor makes of the window (sway tiles it full screen)
        LoadingIndicator {
            id: indicator
            width: 240
            height: 240
            anchors.centerIn: parent
            running: false
            indicatorColor: Roles.primary
            backgroundColor: Roles.primary_container
            opacity: 1
        }

        Timer {
            interval: 120
            running: render.out !== "" && indicator.loaded
            repeat: true
            onTriggered: {
                if (render.frame >= render.frames) { console.log("RENDERED " + render.frames); Qt.quit(); return }
                indicator.cyclePosition = render.frame / render.frames
                const n = render.frame
                Qt.callLater(() => indicator.grabToImage(r => r.saveToFile(render.out + "/frame-" + String(n).padStart(3, "0") + ".png")))
                render.frame++
            }
        }
    }
}
