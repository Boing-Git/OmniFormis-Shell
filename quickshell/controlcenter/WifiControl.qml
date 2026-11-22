import QtQuick
import Quickshell.Networking

// The Wi-Fi control of the control center: the tile, the networks in the inner ring,
// and scanning while it's the selected control. ControlCenter.qml uses `control`.
QtObject {
    id: wifi

    required property var dial

    // Wi-Fi only lists the connected network until it scans: scan while the
    // dial is open on this control
    readonly property bool active: dial.open && !!dial.currentControl && dial.currentControl.key === "wifi"

    // a binding on every Wi-Fi device there is, now and later (setting it once on the
    // devices of the moment left a device that came back after a reconnect, or Wi-Fi
    // being switched on, with scanning off: only the connected network showed then)
    readonly property Instantiator _scanning: Instantiator {
        model: Networking.devices
        delegate: QtObject {
            required property var modelData
            readonly property Binding _b: Binding {
                target: modelData
                property: "scannerEnabled"
                value: wifi.active
                when: !!modelData && modelData.type === DeviceType.Wifi
            }
        }
    }

    // The Wi-Fi icon for a signal strength (0..1 or 0..100): 1, 2 or 3 bars, or the full
    // fan from 70% up (NetworkManager's 70% is a strong link, so a good network reads full,
    // as on a phone). The same glyphs as the date badge (DateStatusIcon.qml)
    function glyph(strength) {
        const pct = strength <= 1 ? strength * 100 : strength
        return pct >= 70 ? "\ue1d8" : pct >= 50 ? "\uebe1" : pct >= 30 ? "\uebd6" : "\uebe4"
    }

    // the tile's icon: off, not connected, or connected: the Wi-Fi arcs (a toggle tile reads
    // best as the Wi-Fi symbol; the signal strength is on each network's pill and the date
    // badge)
    readonly property string tileIcon: {
        if (!Networking.wifiEnabled) return ""
        for (const d of Networking.devices.values) {
            if (d.type !== DeviceType.Wifi) continue
            for (const n of d.networks.values)
                if (n.connected) return "wifi"
        }
        return ""
    }

    // networks flung off the ring (names): disconnected and hidden until the dial closes
    property var dismissed: []
    function dismiss(n) {
        if (n.connected) n.disconnect()
        wifi.dismissed = wifi.dismissed.concat([n.name])
    }
    readonly property bool dialOpen: dial.open
    onDialOpenChanged: if (!dialOpen) dismissed = []

    readonly property var control: ({
        key: "wifi",
        label: "Wi-Fi",
        icon: wifi.tileIcon,
        shape: "VerySunny",
        shapeSelected: "Sunny",
        on: Networking.wifiEnabled,
        toggle: () => { Networking.wifiEnabled = !Networking.wifiEnabled },

        // the networks the adapters can see: connected first, then strongest
        devices: () => {
            const out = []
            for (const d of Networking.devices.values) {
                if (d.type !== DeviceType.Wifi) continue
                for (const n of d.networks.values) {
                    if (n.name === "") continue
                    if (wifi.dismissed.indexOf(n.name) >= 0 && !(n.connected && n.state !== ConnectionState.Disconnecting)) continue
                    out.push({
                        label: n.name,
                        icon: wifi.glyph(n.signalStrength),
                        shape: "Circle",
                        on: n.connected,
                        strength: n.signalStrength,
                        status: (n.state === ConnectionState.Connecting
                            || n.state === ConnectionState.Disconnecting) ? "loading"
                            : n.connected ? "connected"
                            : n.known     ? "paired"      // saved network
                            : "none",
                        activate: () => { if (n.connected) n.disconnect(); else n.connect() },

                        // fling it off the ring to dismiss it (hidden; disconnected if it
                        // was). It comes back once it's connected again, or the dial reopens
                        drag: "device",
                        fling: () => wifi.dismiss(n)
                    })
                }
            }
            return out.sort((a, b) => (b.on - a.on) || (b.strength - a.strength))
        }
    })
}
