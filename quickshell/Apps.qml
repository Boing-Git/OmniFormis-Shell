pragma Singleton
import QtQuick
import Quickshell

// What the shell knows about an app, wherever it shows up (the launcher's ring, a
// notification): the M3 shape it wears and its icon. The shape is worked out from the
// app's id, never from where it sits in a list, so an app looks the same everywhere and
// keeps its shape whatever is installed or moved around it.
//
//   Apps.shapeFor("org.gnome.Calculator")     → "Gem"
//   Apps.entryFor("org.telegram.desktop", "Telegram")   → its DesktopEntry, or null
QtObject {
    id: root

    // the shapes apps take turns wearing: soft, roundish ones that still read apart small
    readonly property var shapes: ["Circle", "Clamshell", "4SidedCookie", "Pill", "SoftBurst", "Gem", "Flower", "Arch",
                                   "Pentagon", "6SidedCookie", "Sunny", "PuffyDiamond", "Bun", "Oval", "Slanted", "8LeafClover"]

    function shapeFor(id) {
        const s = String(id || "")
        let h = 0
        for (let i = 0; i < s.length; i++) h = (h * 31 + s.charCodeAt(i)) >>> 0
        return shapes[h % shapes.length]
    }

    // the installed app a notification came from: by its desktop-entry hint, else by its
    // name; null when the sender isn't an installed app (a script, notify-send)
    function entryFor(desktopEntry, appName) {
        let e = null
        if (desktopEntry) e = DesktopEntries.byId(desktopEntry)
        if (!e && appName) e = DesktopEntries.heuristicLookup(appName)
        return e || null
    }

    // an icon name or path as something an Image can show ("" when there's none)
    function iconSource(icon) {
        if (!icon) return ""
        const s = String(icon)
        if (s.indexOf("/") === 0) return "file://" + s
        if (s.indexOf("file://") === 0 || s.indexOf("image://") === 0) return s
        return Quickshell.iconPath(s, true)
    }
}
