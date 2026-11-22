import QtQuick
import Qt.labs.folderlistmodel
import Quickshell.Io
import "variables.js" as Vars

// The list of wallpaper files: scans the folder, applies the sort settings and
// (optionally) the shuffle. Everything else just asks urlAt(i).
Item {
    id: root

    property string folder: ""
    property bool showHidden: false
    property string sortBy: "name"          // name | time | size | type | none
    property bool sortDescending: false
    property bool sortCaseSensitive: false
    property bool shuffle: false
    property int shuffleSeed: 1

    // every wallpaper in the folder
    readonly property int allCount: model.count

    // Show only some wallpapers: a list of positions in the full list (e.g. the
    // result of search()), or null for all of them. Everything that asks
    // count / urlAt / nameAt / ... then only sees those, in that order.
    property var filter: null
    readonly property bool filtered: filter !== null

    // how many wallpapers the dial shows (the filtered ones, or all)
    readonly property int count: filter ? filter.length : allCount

    // dial position i (any integer, loops) -> position in the full list
    function toAll(i) {
        if (count <= 0) return -1
        const w = ((i % count) + count) % count
        return filter ? filter[w] : w
    }

    // the wallpaper's own number in the full list (1..allCount), even while filtered
    function numberAt(i) { return toAll(i) + 1 }

    // full-list position -> row in the folder model (applies the shuffle)
    function _row(a) { return (a * stride) % allCount }
    function _nameAll(a) { return model.get(_row(a), "fileName") }
    function _pathAll(a) { return decodeURIComponent(model.get(_row(a), "fileUrl").toString().replace(/^file:\/\//, "")) }
    function _colorAll(a) { return colors[_pathAll(a)] || "" }
    function _catsAll(a) {
        const name = _nameAll(a).toLowerCase(), out = []
        for (const cat in Vars.categoryKeywords)
            if (Vars.categoryKeywords[cat].some(w => name.includes(w))) out.push(cat)
        return out.concat(colorCategories(_colorAll(a)))
    }

    // ── colours ── each wallpaper's main colour, found by
    // scripts/wallpaper-colors.py and remembered in Vars.colorCachePath.
    // { "/full/path.png": "#rrggbb" }; fills in a few seconds after startup
    // the first time, instantly after that.
    property var colors: ({})

    // each wallpaper's 5 main colours and how much of it each covers:
    // { "/full/path.png": [["#rrggbb", 0.42], ...] }
    property var palettes: ({})
    property string colorCachePath: Vars.colorCachePath

    FileView {
        id: colorCache
        path: root.colorCachePath
        printErrors: false      // the cache doesn't exist until the first scan finishes
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const raw = JSON.parse(text()), out = {}
                const pal = {}
                for (const p in raw) { out[p] = raw[p].color; pal[p] = raw[p].palette || [[raw[p].color, 1]] }
                root.colors = out
                root.palettes = pal
            } catch (e) { /* not written yet */ }
        }
    }

    // refresh the cache for this folder (only new pictures cost time)
    Process {
        id: colorScan
        command: ["python3",
                  Qt.resolvedUrl("scripts/wallpaper-colors.py").toString().replace(/^file:\/\//, ""),
                  root.folder, root.colorCachePath]
        onExited: colorCache.reload()
    }
    onFolderChanged: if (folder !== "") colorScan.running = true
    Component.onCompleted: if (folder !== "") colorScan.running = true

    FolderListModel {
        id: model
        folder: root.folder === "" ? "" : "file://" + root.folder
        caseSensitive: false          // name filters
        showDirs: false
        showHidden: root.showHidden
        sortReversed: root.sortDescending
        sortCaseSensitive: root.sortCaseSensitive
        sortField: {
            switch (root.sortBy) {
            case "time": return FolderListModel.Time
            case "size": return FolderListModel.Size
            case "type": return FolderListModel.Type
            case "none": return FolderListModel.Unsorted
            default:     return FolderListModel.Name
            }
        }
        nameFilters: [
            "*.jpg", "*.jpeg", "*.png", "*.gif",
            "*.bmp", "*.tga", "*.tiff", "*.tif",
            "*.pnm", "*.pbm", "*.pgm", "*.ppm", "*.pam",
            "*.ff", "*.farbfeld"
        ]
    }

    // ── shuffle ── a fixed scramble: position i shows file (i * stride) % count.
    // It is a true permutation (every file exactly once) as long as stride and
    // count share no common factor, so we search for such a stride. The starting
    // guess is ~0.618 of the list so neighbours end up far apart, and
    // root.shuffleSeed nudges it to give a different scramble.
    function gcd(a, b) {
        while (b !== 0) { const t = b; b = a % b; a = t }
        return a
    }
    function findStride(n, seed) {
        if (n < 3) return 1
        let s = (Math.floor(n * 0.618) + Math.abs(seed)) % n
        if (s < 1) s = 1
        for (let i = 0; i < n; i++) {
            const c = ((s + i - 1) % (n - 1)) + 1   // stay within 1..n-1
            if (gcd(c, n) === 1) return c
        }
        return 1
    }
    readonly property int stride: root.shuffle ? findStride(allCount, root.shuffleSeed) : 1

    // Wallpaper at dial position i. i may be any integer (negative or huge):
    // the list loops forever.
    function urlAt(i) {
        if (count <= 0) return ""
        return model.get(_row(toAll(i)), "fileUrl")
    }

    // File name (e.g. "forest.png") of the wallpaper at dial position i.
    function nameAt(i) {
        if (count <= 0) return ""
        return _nameAll(toAll(i))
    }

    // Dial position (0..count-1) of the file at a plain path, or -1.
    function indexOfPath(path) {
        if (path === "" || count <= 0) return -1
        for (let i = 0; i < count; i++)
            if (decodeURIComponent(urlAt(i).toString().replace(/^file:\/\//, "")) === path) return i
        return -1
    }

    function pathAt(i) {
        return decodeURIComponent(urlAt(i).toString().replace(/^file:\/\//, ""))
    }

    // main colour of the wallpaper at position i ("#rrggbb"), or "" if not known yet
    function colorAt(i) { return colors[pathAt(i)] || "" }

    // ── categories ──
    readonly property var colorCategoryNames: ["red", "orange", "yellow", "green", "cyan",
                                               "blue", "purple", "pink", "grey", "dark", "light"]
    readonly property var nameCategoryNames: Object.keys(Vars.categoryKeywords)
    readonly property var categoryNames: nameCategoryNames.concat(colorCategoryNames)

    // Colour names the search knows on top of the categories above. Typing one
    // finds wallpapers whose main colour is close to it, closest first.
    readonly property var namedColors: ({
        black: "#000000", white: "#ffffff", silver: "#c0c0c0", charcoal: "#36454f", slate: "#708090",
        brown: "#7b4a2a", chocolate: "#5c3317", tan: "#d2b48c", beige: "#e8dcc0", cream: "#fffdd0",
        sand: "#c2b280", khaki: "#c3b091", olive: "#808000", maroon: "#800000", wine: "#722f37",
        crimson: "#dc143c", scarlet: "#ff2400", ruby: "#9b111e", cherry: "#d2042d", rose: "#e8457a",
        coral: "#ff7f50", salmon: "#fa8072", peach: "#ffcba4", apricot: "#fbceb1", rust: "#b7410e",
        copper: "#b87333", bronze: "#cd7f32", amber: "#ffbf00", gold: "#d4af37", mustard: "#e1ad01",
        lemon: "#fff44f", lime: "#32cd32", chartreuse: "#7fff00", mint: "#98ff98", sage: "#9caf88",
        emerald: "#50c878", jade: "#00a86b", forest: "#228b22", moss: "#8a9a5b", teal: "#008080",
        turquoise: "#40e0d0", aqua: "#00ffff", cerulean: "#007ba7", azure: "#007fff", sky: "#87ceeb",
        cobalt: "#0047ab", sapphire: "#0f52ba", royal: "#4169e1", navy: "#000080", midnight: "#191970",
        indigo: "#4b0082", violet: "#8f00ff", lavender: "#b57edc", lilac: "#c8a2c8", plum: "#8e4585",
        magenta: "#ff00ff", fuchsia: "#c154c1", orchid: "#da70d6", mauve: "#b784a7", blush: "#de5d83",
        neon: "#39ff14", pastel: "#c9b6e4", ice: "#d6f1ff", snow: "#fffafa", ash: "#b2beb5"
    })

    // "#rrggbb" -> CIE Lab: a colour space where equal distances look equally
    // different to the eye (RGB doesn't: there light blue and peach are "close")
    function _lab(hex) {
        const lin = v => { v /= 255; return v <= 0.04045 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4) }
        const [r, g, b] = _rgb(hex).map(lin)
        const x = (0.4124 * r + 0.3576 * g + 0.1805 * b) / 0.95047
        const y =  0.2126 * r + 0.7152 * g + 0.0722 * b
        const z = (0.0193 * r + 0.1192 * g + 0.9505 * b) / 1.08883
        const f = t => t > 0.008856 ? Math.cbrt(t) : 7.787 * t + 16 / 116
        const fx = f(x), fy = f(y), fz = f(z)
        return [116 * fy - 16, 500 * (fx - fy), 200 * (fy - fz)]
    }

    // how different two colours look (0 = same, ~10 = clearly different,
    // 50+ = unrelated). Lightness counts a bit less than hue and saturation,
    // since a darker/lighter version of a colour still reads as that colour.
    function colorDistance(a, b) {
        const [l1, a1, b1] = _lab(a), [l2, a2, b2] = _lab(b)
        return Math.hypot((l1 - l2) * 0.5, a1 - a2, b1 - b2)
    }

    // the closest any big-enough part of wallpaper `a` (full-list position) gets to `hex`
    function _paletteDistance(a, hex) {
        const pal = palettes[_pathAll(a)]
        if (!pal) return Infinity
        let best = Infinity
        for (const [c, share] of pal) {
            if (share < 0.08) continue                 // ignore specks

            // a colour covering more of the picture counts a little more
            best = Math.min(best, colorDistance(hex, c) - 6 * share)
        }
        return best
    }

    // how close counts as "that colour" (see colorDistance): lower = stricter
    property real colorMatchDistance: 22

    function _rgb(hex) {
        const n = parseInt(hex.slice(1), 16)
        return [(n >> 16) & 255, (n >> 8) & 255, n & 255]
    }

    // colour categories of "#rrggbb": its hue name, plus dark/light/grey
    function colorCategories(hex) {
        if (!hex) return []
        const [r, g, b] = _rgb(hex).map(v => v / 255)
        const mx = Math.max(r, g, b), mn = Math.min(r, g, b), d = mx - mn
        const l = (mx + mn) / 2
        const out = []
        if (l < 0.2) out.push("dark")
        if (l > 0.8) out.push("light")

        // too little colour to have a hue
        if (d < 0.06 || (mx > 0 && d / mx < 0.18)) { out.push("grey"); return out }
        let h
        if (mx === r) h = ((g - b) / d) % 6
        else if (mx === g) h = (b - r) / d + 2
        else h = (r - g) / d + 4
        h = (h * 60 + 360) % 360
        out.push(h < 15 ? "red" : h < 40 ? "orange" : h < 65 ? "yellow" : h < 165 ? "green"
               : h < 195 ? "cyan" : h < 255 ? "blue" : h < 290 ? "purple" : h < 345 ? "pink" : "red")
        return out
    }

    // name categories of the wallpaper at i, from Vars.categoryKeywords
    function nameCategoriesAt(i) {
        const name = nameAt(i).toLowerCase(), out = []
        for (const cat in Vars.categoryKeywords)
            if (Vars.categoryKeywords[cat].some(w => name.includes(w))) out.push(cat)
        return out
    }

    // every category of the wallpaper at i, e.g. ["city", "night", "blue", "dark"]
    function categoriesAt(i) {
        return nameCategoriesAt(i).concat(colorCategories(colorAt(i)))
    }

    // ── search ── all matching positions in the FULL list (0..allCount-1),
    // best first, whatever the filter is. Pass the result to `filter` to show only them.
    //   "12"        -> wallpaper number 12 (the numbers start at 1)
    //   "#3050ff"   -> wallpapers by how close their main colour is (closest first;
    //                  "#35f" short form works too)
    //   "blue"      -> wallpapers in that category (colour or name category)
    //   "forest"    -> names starting with it, then names containing it
    // Several words narrow it down: "city blue" = city wallpapers that are blue.
    function search(query) {
        const q = String(query).trim().toLowerCase()
        if (q === "" || allCount <= 0) return []
        if (/^[0-9]+$/.test(q)) {
            const n = parseInt(q, 10)
            return n >= 1 && n <= allCount ? [n - 1] : []
        }
        let hex = q.match(/^#?([0-9a-f]{6}|[0-9a-f]{3})$/)

        // a colour name that isn't a category ("teal", "gold") works like its hex
        const named = namedColors[q] !== undefined && categoryNames.indexOf(q) < 0
        if (named || (hex && (q.startsWith("#") || /[0-9]/.test(q)))) {
            let h = named ? namedColors[q].slice(1) : hex[1]
            if (h.length === 3) h = h.split("").map(c => c + c).join("")
            const scored = []
            for (let i = 0; i < allCount; i++) {
                const d = _paletteDistance(i, "#" + h)
                if (d < colorMatchDistance) scored.push([i, d])   // only ones that really look like it
            }
            scored.sort((a, b) => a[1] - b[1])
            const closest = scored.map(s => s[0])
            if (!named) return closest

            // a colour name can also be in file names ("forest", "rose"): those first
            const byName = []
            for (let i = 0; i < allCount; i++) if (_nameAll(i).toLowerCase().includes(q)) byName.push(i)
            return byName.concat(closest.filter(i => byName.indexOf(i) < 0))
        }

        // words: every word must match (a category, or part of the name)
        const words = q.split(/\s+/)
        const starts = [], rest = []
        for (let i = 0; i < allCount; i++) {
            const name = _nameAll(i).toLowerCase()
            const cats = _catsAll(i)
            let ok = true
            for (const w of words) {
                if (cats.indexOf(w) >= 0 || name.includes(w)) continue
                const c = namedColors[w]
                if (c !== undefined && _paletteDistance(i, c) < colorMatchDistance) continue
                ok = false; break
            }
            if (!ok) continue
            if (name.startsWith(words[0])) starts.push(i); else rest.push(i)
        }
        return starts.concat(rest)
    }

    // the best match, or -1
    function find(query) {
        const m = search(query)
        return m.length > 0 ? m[0] : -1
    }
}
