pragma Singleton
import QtQuick
import "controlcenter"

// The screen's brightness, one copy for the whole shell (controlcenter/BrightnessLevel):
// the control center's knob and the brightness OSD turn the same level, so a change on
// one shows on the other (a DDC monitor can't be read back, so a second copy would
// drift apart). Read `Brightness.level`.
QtObject {
    id: root

    readonly property BrightnessLevel level: BrightnessLevel {}
}
