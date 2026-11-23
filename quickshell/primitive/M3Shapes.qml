import QtQuick
import "../variables.js" as Vars
import "m3shapes.js" as M3

QtObject {
    // the paths and their measuring live in m3shapes.js (one copy for every shell: a link to
    // ../shared, or ../../../shared from Puffy)
    readonly property var m3AbstractPaths: M3.paths

    // Every shape name, in the order they're defined above — for anything that wants to cycle
    // through "all shapes" rather than a single chosen one.
    readonly property var allShapeNames: Object.keys(m3AbstractPaths)

    // the square box every path is drawn in (see Vars.m3ShapeBox)
    readonly property real box: Vars.m3ShapeBox

    // the scale that fits any shape's path to `item` (the Shape it's drawn in)
    function fitScale(item) { return Qt.size(item.width / box, item.height / box) }

    // the shape as the design draws it (Prefs.shapeStyle): Round keeps circles and capsules
    // and makes every other shape a circle
    readonly property var roundKeeps: ["Circle", "Pill"]
    function styled(shapeName) {
        return Prefs.shapeStyle === "round" && roundKeeps.indexOf(shapeName) < 0 ? "Circle" : shapeName
    }

    function getPath(shapeName) {
        return m3AbstractPaths[styled(shapeName)] || m3AbstractPaths["Circle"];
    }

    function samplePath(pathStr, steps) { return M3.samplePath(pathStr, steps) }

    function getShapePeaks(shapeName) {
        var pts = samplePath(getPath(shapeName), 10);
        var dists = pts.map(function(p) { return Math.hypot(p.x - 50, p.y - 50); });
        var peaks = [];
        var n = dists.length;
        for (var j = 0; j < n; j++) {
            var prev = dists[(j - 1 + n) % n];
            var nxt = dists[(j + 1) % n];
            if (dists[j] > prev && dists[j] > nxt) {
                peaks.push(pts[j]);
            }
        }
        return peaks;
    }

    // `count` points evenly by angle round a shape's own outline (M3.outlinePoints)
    function getOutlinePoints(shapeName, count) { return count <= 0 ? [] : M3.outlinePoints(getPath(shapeName), count) }
}
