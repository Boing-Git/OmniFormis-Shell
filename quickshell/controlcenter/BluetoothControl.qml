import QtQuick
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire

// The Bluetooth control of the control center: the tile, a Scan pill and the devices
// in the inner ring, pairing / connecting / forgetting, and discovery.
// ControlCenter.qml uses `control`.
Item {
    id: bt

    required property var dial

    // defaultAdapter is null when there's no Bluetooth adapter
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool active: dial.open && !!dial.currentControl && dial.currentControl.key === "bluetooth"

    // ── discovery ──
    // off until you press the Scan pill, and off again when the dial closes or another
    // control is selected. scanOn is what we want, and the adapter is kept in line with it
    // (so "Scanning…" always stops it)
    property bool scanOn: false
    onActiveChanged: if (!active) scanOn = false

    // ── dismissed ── devices flung off the ring (addresses): unpaired (BlueZ disconnects
    // them first) and hidden. One comes back when you scan
    property var dismissed: []
    function dismiss(d) {
        forget(d)
        if (d.connected) d.disconnect()
        dismissed = dismissed.concat([d.address])
    }
    onScanOnChanged: {
        applyScan()

        // a scan brings dismissed devices back
        if (scanOn) dismissed = []
    }
    function applyScan() {
        if (adapter && adapter.enabled && adapter.discovering !== scanOn) adapter.discovering = scanOn
    }
    Connections {
        target: bt.adapter
        function onDiscoveringChanged() { Qt.callLater(bt.applyScan) }
        function onEnabledChanged() { Qt.callLater(bt.applyScan) }
    }

    // ── pairing ──
    // a device was clicked: cancel a pairing in progress, disconnect a connected one,
    // connect a paired one, or pair (and trust) a new one
    function activate(d) {
        // scanning slows down / blocks connecting and pairing on many adapters
        scanOn = false
        if (d.pairing) d.cancelPair()
        else if (d.connected) d.disconnect()
        else if (d.paired) d.connect()
        else {
            // the adapter refuses new pairings while it isn't pairable
            if (adapter && !adapter.pairable) adapter.pairable = true
            d.trusted = true
            pairingDevice = d
            d.pair()
        }
    }

    // forget a device: unpair it (it reappears only if discovered again)
    function forget(d) {
        if (d.pairing) d.cancelPair()
        if (d.paired || d.trusted || d.bonded) d.forget()
    }

    // the device being paired; once it's paired, connect it (BlueZ only pairs)
    property var pairingDevice: null
    Connections {
        target: bt.pairingDevice
        ignoreUnknownSignals: true
        function onPairedChanged() {
            const d = bt.pairingDevice
            if (d && d.paired) { bt.pairingDevice = null; d.connect() }
        }
        function onPairingChanged() {
            const d = bt.pairingDevice
            if (d && !d.pairing && !d.paired) bt.pairingDevice = null   // pairing failed
        }
    }

    // ── playing through a device ── (a device pill dropped on the Media tile) connects it
    // if it isn't, then makes its speaker the default output once Pipewire has it
    property var playDevice: null
    function playOn(d) {
        scanOn = false
        playDevice = d
        if (!d.connected) d.connect()
        playTries = 0
        playRetry.restart()
        trySink()
    }

    // the Pipewire speaker of a Bluetooth device (matched by its address), or null
    function sinkOf(d) {
        const a = (d.address || "").toUpperCase()
        const name = "bluez_output." + a.replace(/:/g, "_")
        return Pipewire.nodes.values.find(n => n.isSink && n.audio && !n.isStream
            && ((n.properties && String(n.properties["api.bluez5.address"] || "").toUpperCase() === a)
                || n.name.toUpperCase().indexOf(name.toUpperCase()) === 0)) || null
    }

    function trySink() {
        const d = playDevice
        if (!d) return
        const s = sinkOf(d)
        if (s) { Pipewire.preferredDefaultAudioSink = s; playDevice = null; playRetry.stop() }
    }

    // its speaker shows up a moment after it connects: look again for a while
    property int playTries: 0
    Timer {
        id: playRetry
        interval: 500
        repeat: true
        onTriggered: {
            bt.trySink()
            if (++bt.playTries >= 30) { bt.playDevice = null; stop() }
        }
    }

    // the tile's icon: off, on, or connected (any device connected)
    readonly property string tileIcon: {
        if (!adapter || !adapter.enabled) return "bluetooth_disabled"
        return Bluetooth.devices.values.some(d => d.connected) ? "bluetooth_connected" : "bluetooth"
    }

    readonly property var control: ({
        key: "bluetooth",
        label: "Bluetooth",
        icon: bt.tileIcon,
        shape: "4SidedCookie",
        shapeSelected: "6SidedCookie",
        on: !!bt.adapter && bt.adapter.enabled,
        toggle: () => { if (bt.adapter) bt.adapter.enabled = !bt.adapter.enabled },

        // the Scan pill, then the devices: connected first, then paired, then new ones.
        // Click: connect / disconnect, or pair a new one. Right-click / Delete: forget.
        devices: () => {
            if (!bt.adapter || !bt.adapter.enabled) return []
            const scan = {
                label: bt.scanOn ? "Scanning…" : "Scan",
                icon: bt.scanOn ? "bluetooth_searching" : "search",
                shape: "Circle",
                on: bt.scanOn,
                status: bt.scanOn ? "loading" : "none",
                activate: () => { bt.scanOn = !bt.scanOn }
            }

            // devices found by a scan but never paired only show while scanning
            // (or while one of them is being paired)
            const list = Bluetooth.devices.values
                .filter(d => d.paired || d.connected || d.pairing || bt.scanOn || d === bt.pairingDevice)
                .filter(d => bt.dismissed.indexOf(d.address) < 0 || (d.connected && d.state !== BluetoothDeviceState.Disconnecting) || bt.scanOn)
                .map(d => ({
                    label: d.name !== "" ? d.name : d.deviceName,
                    icon: d.connected ? "bluetooth_connected" : (d.paired ? "bluetooth" : "add_link"),
                    shape: "Circle",
                    on: d.connected,
                    paired: d.paired,
                    status: (d.state === BluetoothDeviceState.Connecting
                        || d.state === BluetoothDeviceState.Disconnecting
                        || d.pairing) ? "loading"
                        : d.connected ? "connected"
                        : d.paired    ? "paired"
                        : "none",
                    activate: () => bt.activate(d),
                    secondary: () => bt.forget(d),

                    // pull it off the ring: onto the Media tile to play through it, or
                    // fling it away to unpair it (off the ring)
                    drag: "device",
                    dropOn: { media: () => bt.playOn(d) },
                    fling: () => bt.dismiss(d) }))
                .sort((x, y) => (y.on - x.on) || (y.paired - x.paired))
            return [scan].concat(list)
        }
    })
}
