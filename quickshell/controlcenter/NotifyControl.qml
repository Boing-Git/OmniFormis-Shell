import QtQuick
import ".."
import "../primitive"

// The Notifications control of the control center: everything that's waiting (Notifs.qml).
// The tile switches Do not disturb; the inner ring has a pill per app that sent
// something (wearing that app's shape, its badge counting what it sent), then Clear all;
// the tick ring in the knobs' place turns through that app's notifications; and the
// middle of the dial shows the one you're on: its picture, who and when, and its words.
// ControlCenter.qml uses `control`.
//
//   app pill     click: what the notification is for (most apps: come to the front)
//                right-click / Delete: dismiss the one showing
//                pull it off the ring and flick it away: dismiss all of that app's
Item {
    id: notify

    required property var dial

    // ★ the card's and the dial's sizes while this is selected: controlcenter/ReaderSettings.qml ★
    readonly property var cfg: ReaderSettings { liveSize: notify.dial.expandedSize; sweepDeg: notify.dial.sweepDeg }

    // the dial is open on this control: what's here has been looked at
    readonly property bool active: dial.open && dial.inNotify
    onActiveChanged: if (active) Notifs.markSeen()
    Connections {
        target: Notifs
        function onArrived() { if (notify.active) Qt.callLater(Notifs.markSeen) }
    }

    // ── what's selected ── the app at the mark, and which of its notifications
    readonly property var groups: Notifs.apps
    readonly property var group: active || dial.inNotify ? (groups[dial.innerIndex] || null) : null
    readonly property string groupKey: group ? group.key : ""

    // which of the app's notifications is showing (0 = its newest); back to the newest
    // when another app comes to the mark
    property int shownIndex: 0
    onGroupKeyChanged: shownIndex = 0
    readonly property var shown: group ? group.items[Math.min(shownIndex, group.items.length - 1)] : null
    readonly property var info: Notifs.info(shown)

    // ── the value the tick ring turns ── which of the app's notifications (see KnobRing):
    // one tick each, the newest first; nothing to turn when there's only one
    QtObject {
        id: which
        readonly property int count: notify.group ? notify.group.items.length : 0
        readonly property bool available: count > 1
        readonly property int steps: Math.max(1, count - 1)
        readonly property real value: Math.min(notify.shownIndex, steps) / steps
        readonly property bool muted: false
        readonly property bool locked: false
        readonly property string icon: notify.info.symbol
        readonly property string text: (Math.min(notify.shownIndex, steps) + 1) + "/" + count
        readonly property string subject: notify.groupKey

        // a few ticks spread wide, many packed closer; a long one every fifth
        readonly property real tickDeg: Math.max(3, Math.min(9, 40 / steps))
        readonly property int major: 5
        function set(v) { notify.shownIndex = Math.round(v * steps) }
    }

    // the tile's icon: off, something waiting, or nothing
    readonly property string tileIcon: Prefs.dnd ? "notifications_off"
        : Notifs.count > 0 ? "notifications_unread" : "notifications"

    // ── the card in the middle ──
    property Component corner: Component {
        ReaderCard {
            dial: notify.dial
            cfg: notify.cfg
            shape: notify.shown ? notify.info.shape : "Circle"
            fill: notify.info.urgent ? Roles.error_container : notify.shown ? Roles.primary_container : Roles.surface_container_high
            ink: notify.info.urgent ? Roles.on_error_container : notify.shown ? Roles.on_primary_container : Roles.on_surface_variant
            image: notify.info.image
            symbol: notify.shown ? notify.info.symbol : Prefs.dnd ? "notifications_off" : "notifications_none"
            note: notify.shown ? notify.info.app + (notify.info.age !== "" ? "  ·  " + notify.info.age : "") : ""
            title: notify.shown ? notify.info.summary : "All caught up"
            body: notify.shown ? notify.info.body : Prefs.dnd ? "Do not disturb is on: nothing pops out" : ""
        }
    }

    readonly property var control: ({
        key: "notify",
        label: "Notifications",
        icon: notify.tileIcon,
        shape: "Arch",
        shapeSelected: "SoftBurst",

        // on = notifications pop out; the tile switches Do not disturb
        on: !Prefs.dnd,
        toggle: () => Prefs.toggle("dnd"),
        size: notify.cfg.dialSize,
        dateIcon: false,
        corner: notify.corner,
        value: which,
        hint: "notifyCenter",

        // its own control center settings while selected (ReaderSettings → controlCenter)
        settings: notify.cfg.controlCenter,

        // a pill per app, most recent first, then Clear all
        devices: () => {
            const apps = notify.groups.map(g => ({
                label: g.name,
                icon: Notifs.symbolOf(g.items[0]),
                iconShape: g.shape,
                shape: "Circle",
                on: false,
                status: "none",
                badgeText: g.items.length,
                activate: () => Notifs.open(notify.shown),
                secondary: () => Notifs.dismiss(notify.shown),

                // flick it away: all of that app's go
                drag: "device",
                fling: () => Notifs.dismissApp(g.key)
            }))
            if (apps.length === 0) return []
            return apps.concat([{
                label: "Clear all", icon: "clear_all", shape: "Circle", on: false, status: "none",
                badgeIcon: "delete_sweep",
                activate: () => Notifs.dismissAll()
            }])
        }
    })
}
