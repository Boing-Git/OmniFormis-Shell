import QtQuick
import Quickshell.Services.Pipewire

// The default speaker's volume, for the control center's volume knob (the same sink
// the volume OSD follows). No visuals.
//
//   value 0..1, muted, available, icon    set(v), toggleMute()
Item {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink

    // Pipewire only reports a node's volume while something tracks it
    PwObjectTracker { objects: [root.sink] }

    readonly property bool available: !!(sink && sink.audio)
    readonly property real value: available ? Math.max(0, Math.min(1, sink.audio.volume)) : 0
    readonly property bool muted: available && sink.audio.muted

    // the volume is never locked; here so the knob can treat both levels alike
    readonly property bool locked: false

    // the Material Symbols icon for the level right now
    readonly property string icon: muted || value <= 0 ? "volume_off"
        : value < 0.34 ? "volume_mute"
        : value < 0.67 ? "volume_down" : "volume_up"

    // sets the volume (0..1) and unmutes
    function set(v) {
        if (!available) return
        sink.audio.muted = false
        sink.audio.volume = Math.max(0, Math.min(1, v))
    }

    function toggleMute() {
        if (available) sink.audio.muted = !sink.audio.muted
    }
}
