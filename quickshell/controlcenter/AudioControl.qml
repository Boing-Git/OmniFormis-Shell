import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// The Audio control of the control center: where the sound goes. The tile mutes /
// unmutes the output; the inner ring lists the outputs (speakers, HDMI, Bluetooth…),
// then the microphones, then every app that is playing, each showing which output it
// plays on. ControlCenter.qml uses `control`.
//
//   output pill  click: make it the default output    right-click: mute / unmute it
//   mic pill     click: make it the default input     right-click: mute / unmute it
//   app pill     click: send that app to the next output (cycles through them)
Item {
    id: audio

    required property var dial

    // ── the nodes ── isSink / isStream are known straight away; `properties` (media.class,
    // app name…) and volumes only arrive once a node is tracked, so every node is tracked
    function cls(n) { return n && n.properties ? String(n.properties["media.class"] || "") : "" }
    readonly property var nodes: Pipewire.nodes.values
    PwObjectTracker { objects: audio.nodes }

    readonly property var sinks: nodes.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: nodes.filter(n => n.audio && !n.isSink && !n.isStream)

    // apps playing sound (not apps recording: their class is Stream/Input/Audio)
    readonly property var streams: nodes.filter(n => n.audio && n.isStream && cls(n) !== "Stream/Input/Audio")

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    // ── names and icons ──
    // the short name: the nick ("Odyssey G40B"), else the description, else the node name
    function nameOf(n) {
        if (!n) return ""
        return n.nickname || n.description || n.name
    }

    // the Material Symbols icon for an output: Bluetooth / headphones / HDMI / speaker
    function sinkIcon(n) {
        if (!n) return "volume_off"
        const p = n.properties || {}
        const name = String(n.name || "")
        const ff = String(p["device.form-factor"] || "")
        const bus = String(p["device.bus"] || p["device.api"] || "")
        if (ff === "headphone" || ff === "headset") return "headphones"
        if (name.indexOf("bluez") === 0 || bus.indexOf("bluez") === 0) return "headphones"
        if (name.indexOf("hdmi") >= 0 || name.indexOf("displayport") >= 0) return "tv"
        if (bus === "usb") return "speaker_group"
        return "speaker"
    }

    // the app's name for a stream
    function appOf(n) {
        const p = n.properties || {}
        return String(p["application.name"] || n.description || n.name || "App")
    }

    // the output a stream is linked to right now (null while it isn't linked)
    function targetOf(s) {
        for (const g of Pipewire.linkGroups.values)
            if (g.source === s && g.target && !g.target.isStream) return g.target
        return null
    }

    // ── actions ──
    function useSink(n) { Pipewire.preferredDefaultAudioSink = n }
    function useSource(n) { Pipewire.preferredDefaultAudioSource = n }
    function toggleMute(n) { if (n && n.audio) n.audio.muted = !n.audio.muted }

    // send every stream of an app to the next output (after the one it plays on now).
    // WirePlumber moves a stream when its `target.object` metadata is set
    function cycleApp(list) {
        if (sinks.length === 0) return
        const cur = targetOf(list[0]) || sink
        const i = sinks.indexOf(cur)
        const next = sinks[(i + 1) % sinks.length]
        for (const s of list)
            mover.run(["pw-metadata", String(s.id), "target.object", next.name, "Spa:String"])
    }

    // runs the pw-metadata calls one after the other (one Process can't run two at once)
    QtObject {
        id: mover
        property var queue: []
        function run(cmd) { queue = queue.concat([cmd]); if (!proc.running) next() }
        function next() {
            if (queue.length === 0) return
            proc.command = queue[0]
            queue = queue.slice(1)
            proc.running = true
        }
    }
    Process {
        id: proc
        onExited: mover.next()
    }

    // the tile's icon: muted, or the kind of the output in use
    readonly property bool muted: !!(sink && sink.audio && sink.audio.muted)
    readonly property string tileIcon: !sink ? "volume_off" : muted ? "volume_off" : sinkIcon(sink)

    readonly property var control: ({
        key: "audio",
        label: "Audio",
        icon: audio.tileIcon,
        shape: "Clamshell",
        shapeSelected: "Bun",
        on: !!audio.sink && !audio.muted,
        toggle: () => audio.toggleMute(audio.sink),

        // outputs (the one in use first), then microphones, then the apps playing
        devices: () => {
            const outs = audio.sinks
                .map(n => ({
                    label: audio.nameOf(n),
                    icon: n.audio && n.audio.muted ? "volume_off" : audio.sinkIcon(n),
                    shape: "Circle",
                    on: n === audio.sink,
                    status: n === audio.sink ? "connected" : "none",
                    activate: () => audio.useSink(n),
                    secondary: () => audio.toggleMute(n)
                }))
                .sort((a, b) => b.on - a.on)

            const mics = audio.sources.map(n => ({
                label: audio.nameOf(n),
                icon: n.audio && n.audio.muted ? "mic_off" : "mic",
                shape: "Circle",
                on: n === audio.source,
                status: n === audio.source ? "connected" : "none",
                activate: () => audio.useSource(n),
                secondary: () => audio.toggleMute(n)
            }))

            // one pill per app (a game can open several streams), named "App → Output"
            const byApp = {}
            for (const s of audio.streams) {
                const k = audio.appOf(s)
                ;(byApp[k] = byApp[k] || []).push(s)
            }
            const apps = Object.keys(byApp).map(k => {
                const t = audio.targetOf(byApp[k][0])
                return {
                    label: t ? k + " → " + audio.nameOf(t) : k,
                    icon: t ? audio.sinkIcon(t) : "music_note",
                    badgeIcon: "swap_horiz",
                    shape: "Circle",
                    on: false,
                    status: "none",
                    activate: () => audio.cycleApp(byApp[k])
                }
            })

            return outs.concat(mics).concat(apps)
        }
    })
}
