pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "primitive"

// The shell's notifications. It is the notification server (what apps send lands here),
// and it keeps each one waiting until you dismiss it. No visuals: the arrival dial
// (NotifyOsd.qml), the control center's Notifications control (controlcenter/
// NotifyControl.qml) and the closed corner's beads (CornerWhispers.qml) all read this.
//
//   Notifs.list           every waiting notification, newest first
//   Notifs.apps           the same grouped by the app that sent them, most recent app first:
//                         [{ key, name, shape, items: [notification, ...] }]
//   Notifs.unseen         how many arrived since you last looked at them
//   Notifs.arrived(n)     one just came in
//   Notifs.info(n)        what to show for one: { app, shape, symbol, image, summary, body, age }
//   Notifs.open(n)        does what clicking it should (its default action), then lets it go
//   Notifs.dismiss(n)  /  dismissApp(key)  /  dismissAll()
//   Notifs.markSeen()     you looked: the beads go
Singleton {
    id: root

    signal arrived(var notification)

    NotificationServer {
        id: server

        // what's waiting survives a reload of the shell
        keepOnReload: true
        persistenceSupported: true
        actionsSupported: true
        imageSupported: true
        bodySupported: true

        // plain words only: the dials draw them along arcs, letter by letter
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: false

        onNotification: n => {
            // nothing to show at all
            if (!n.appName && !n.summary && !n.body && !n.image) return
            n.tracked = true

            // carried over a reload of the shell: still waiting, but not arriving again
            if (n.lastGeneration) return
            const t = Object.assign({}, root.times)
            t[n.id] = Date.now()
            keep.times = JSON.stringify(t)
            root.arrived(n)
        }
    }

    // what must outlive a reload: which ones you've looked at, and when each arrived
    // (id → true, id → ms since 1970). Kept as text: an object can't cross a reload
    PersistentProperties {
        id: keep
        reloadableId: "dialNotifs"
        property string seen: "{}"
        property string times: "{}"
    }
    function parsed(text) {
        try { const o = JSON.parse(text); return o && typeof o === "object" ? o : {} } catch (e) { return {} }
    }
    readonly property var seen: parsed(keep.seen)
    readonly property var times: parsed(keep.times)

    // every waiting notification, newest first
    readonly property var list: server.trackedNotifications.values.slice().reverse()
    readonly property int count: list.length

    // how many of them you haven't looked at yet
    readonly property int unseen: list.filter(n => !seen[n.id]).length

    // you looked at them (the Notifications control was opened): none are new any more
    function markSeen() {
        if (unseen === 0) return
        const s = {}
        for (const n of list) s[n.id] = true
        keep.seen = JSON.stringify(s)
    }

    // ── who sent it ── the installed app if there is one (so it wears that app's shape
    // and icon everywhere), else just the name it gave
    function entryOf(n) { return Apps.entryFor(n.desktopEntry, n.appName) }
    function keyOf(n) {
        const e = entryOf(n)
        return e ? e.id : (n.appName || "notification")
    }
    function nameOf(n) {
        const e = entryOf(n)
        return e ? e.name : (n.appName || "Notification")
    }

    // grouped by app, most recent app first; inside a group, newest first
    readonly property var apps: {
        const out = [], byKey = {}
        for (const n of list) {
            const k = keyOf(n)
            let g = byKey[k]
            if (!g) {
                g = byKey[k] = { key: k, name: nameOf(n), shape: Apps.shapeFor(k), items: [] }
                out.push(g)
            }
            g.items.push(n)
        }
        return out
    }

    // ── what to show for one ──
    // words as plain text: apps send markup and entities whatever the server says it takes
    function plain(text) {
        return String(text || "")
            .replace(/<[^>]*>/g, "")
            .replace(/&amp;/g, "&").replace(/&lt;/g, "<").replace(/&gt;/g, ">")
            .replace(/&quot;/g, '"').replace(/&#39;|&apos;/g, "'")
            .replace(/\s+/g, " ").trim()
    }

    // the Material Symbols icon for what kind of notification it is
    function symbolOf(n) {
        if (n.urgency === NotificationUrgency.Critical) return "priority_high"
        const c = String((n.hints && n.hints["category"]) || "")
        if (c.indexOf("im") === 0) return "chat"
        if (c.indexOf("email") === 0) return "mail"
        if (c.indexOf("call") === 0) return "call"
        if (c.indexOf("transfer") === 0) return "download"
        if (c.indexOf("network") === 0) return "wifi"
        if (c.indexOf("device") === 0) return "devices"
        if (c.indexOf("presence") === 0) return "person"
        return "notifications"
    }

    // "now", "5 min", "2 h", "3 d": how long ago it arrived ("" when that's not known)
    function ageOf(n) {
        const t = times[n.id]
        if (!t) return ""
        const m = Math.floor((Date.now() - t) / 60000)
        if (m < 1) return "now"
        if (m < 60) return m + " min"
        if (m < 1440) return Math.floor(m / 60) + " h"
        return Math.floor(m / 1440) + " d"
    }

    function info(n) {
        if (!n) return { app: "", key: "", shape: "Circle", symbol: "notifications", image: "", summary: "", body: "", age: "", urgent: false }
        const e = entryOf(n)
        const key = e ? e.id : (n.appName || "notification")
        return {
            app: e ? e.name : (n.appName || "Notification"),
            key: key,
            shape: Apps.shapeFor(key),
            symbol: symbolOf(n),

            // the picture it brought (a sender's face, a cover), else the app's icon
            image: Apps.iconSource(n.image) || Apps.iconSource(n.appIcon) || (e ? Apps.iconSource(e.icon) : ""),
            summary: plain(n.summary),
            body: plain(n.body),
            age: ageOf(n),
            urgent: n.urgency === NotificationUrgency.Critical
        }
    }

    // ── acting on them ──
    // what clicking one should do: its default action (most apps: come to the front),
    // else its only action. Then it's let go, unless it asked to stay (`resident`)
    function open(n) {
        if (!n) return
        const acts = n.actions || []
        const a = acts.find(a => a.identifier === "default") || (acts.length === 1 ? acts[0] : null)
        if (a) a.invoke()
        if (n.tracked && !n.resident) n.dismiss()
    }

    function dismiss(n) { if (n) n.dismiss() }
    function dismissApp(key) {
        for (const n of list.filter(n => keyOf(n) === key)) n.dismiss()
    }
    function dismissAll() {
        for (const n of list.slice()) n.dismiss()
    }

    // forget what's known about the ones that are gone
    onListChanged: {
        const ids = {}
        for (const n of list) ids[n.id] = true
        const t = {}, s = {}
        let dropped = false
        for (const id in times) { if (ids[id]) t[id] = times[id]; else dropped = true }
        for (const id in seen) { if (ids[id]) s[id] = true; else dropped = true }
        if (dropped) { keep.times = JSON.stringify(t); keep.seen = JSON.stringify(s) }
    }

    // from a keybind or the terminal:
    //   qs ipc call notifs count      how many are waiting
    //   qs ipc call notifs clear      dismiss them all
    //   qs ipc call notifs dnd        do not disturb on / off
    IpcHandler {
        target: "notifs"
        function count(): string { return root.count + " waiting, " + root.unseen + " new" }
        function clear(): void { root.dismissAll() }
        function dnd(): string { Prefs.toggle("dnd"); return "Do not disturb: " + Prefs.shown("dnd") }
    }
}
