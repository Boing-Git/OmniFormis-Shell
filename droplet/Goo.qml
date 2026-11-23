import QtQuick
import QtQuick.Shapes

// The liquid between two circles: one filled shape that joins circle A to circle B the way
// two drops of water join. While they overlap it is a fat neck; as they move apart the neck
// stretches, thins and pinches off. With `thread` above 0 a thread of that thickness stays
// between them however far they go (a connected chain), flaring out smoothly into each
// circle where it meets it, the way a strand of liquid does.
//
// Put it under the circles' own discs. The bridge doesn't stop at the circles' rims: it
// runs on to both middles, so it lies well under each disc and no seam can show where the
// two meet (two shapes that only touch leave a hairline between them). `bodyA` / `bodyB`
// also fill that circle itself, for one that has no disc of its own (the liquid behind
// the screen's edge, the drop on the cursor).
Shape {
    id: root

    // the two circles: middles and radii, in this item's px
    property real ax: 0
    property real ay: 0
    property real ar: 0
    property real bx: 0
    property real by: 0
    property real br: 0
    property color color: "white"

    // how fat the neck is while the circles touch (0..1: the share of the way round to the
    // circles' outer tangent that the neck takes hold at)
    property real spread: 0.5

    // the thickness (px) of the thread that stays once the neck has gone: 0 for none
    property real thread: 0

    // where the thread meets a circle it flares out to this share of the circle's radius
    // each side, over this share of the radius along the thread
    property real flare: 0.42
    property real flareLength: 0.85

    // how far apart (in sums of the two radii) the neck has thinned all the way
    property real snapAt: 2.3


    // true: circle A / B itself is filled too (it has no disc of its own)
    property bool bodyA: false
    property bool bodyB: false

    // a whole circle as a path
    function disc(cx, cy, r) {
        if (r < 0.5) return ""
        const f = n => n.toFixed(2)
        return "M " + f(cx - r) + " " + f(cy)
            + " A " + f(r) + " " + f(r) + " 0 1 0 " + f(cx + r) + " " + f(cy)
            + " A " + f(r) + " " + f(r) + " 0 1 0 " + f(cx - r) + " " + f(cy) + " Z"
    }

    preferredRendererType: Shape.CurveRenderer

    // The bridge's outline (after Hiroyuki Sato's metaball path): two points on each
    // circle, either side of the line between them, joined by curves that leave each
    // circle along its tangent
    readonly property string outline: {
        const r1 = ar, r2 = br
        if (r1 < 0.5 || r2 < 0.5) return ""
        const dx = bx - ax, dy = by - ay, d = Math.hypot(dx, dy)

        // one inside the other: nothing to join
        if (d <= Math.abs(r1 - r2) + 0.5) return ""

        // 0 while they overlap well, 1 once they are snapAt apart
        const total = r1 + r2
        const far = Math.max(0, Math.min(1, (d - total * 0.7) / Math.max(1, total * (snapAt - 0.7))))
        const v = spread * Math.pow(1 - far, 1.6)

        // thinner than this it has pinched off (a hairline is not liquid)
        if (v < 0.004) return ""

        // where the circles cross, as angles from the line between them (0 when apart)
        let u1 = 0, u2 = 0
        if (d < total) {
            u1 = Math.acos(Math.max(-1, Math.min(1, (r1 * r1 + d * d - r2 * r2) / (2 * r1 * d))))
            u2 = Math.acos(Math.max(-1, Math.min(1, (r2 * r2 + d * d - r1 * r1) / (2 * r2 * d))))
        }
        const between = Math.atan2(dy, dx)
        const tangent = Math.acos(Math.max(-1, Math.min(1, (r1 - r2) / d)))

        // Liquid thins in the middle, not at its feet: each side of the neck leaves its
        // circle's rim, runs down to a waist halfway between the circles, and back up to
        // the other rim. The feet stay fairly wide while the waist thins to nothing.
        // (Sato's path instead moves its feet in to the line between the circles as it
        // thins, so its sides cross near each end: a neck pinched at both ends with a
        // lens between them)
        const k = v / spread
        const foot = spread * Math.pow(k, 0.45)
        const t1 = u1 + (tangent - u1) * foot
        const t2 = (Math.PI - u2) - (Math.PI - u2 - tangent) * foot
        const ux = dx / d, uy = dy / d, nx = -uy, ny = ux
        const f = n => n.toFixed(2)
        const pt = p => f(p[0]) + " " + f(p[1])

        // a foot's two points (s = 1 / -1 for the two sides), as along the axis / across it
        const at = (cx, cy, r, t, s) => [cx + r * Math.cos(t) * ux + s * r * Math.sin(t) * nx,
                                         cy + r * Math.cos(t) * uy + s * r * Math.sin(t) * ny]
        const h1 = r1 * Math.sin(t1), h2 = r2 * Math.sin(t2)
        const g1 = r1 * Math.cos(t1), g2 = d + r2 * Math.cos(t2)

        // the waist: halfway between the feet, as wide as the narrower foot while the
        // circles still overlap, down to nothing as they part
        const w = Math.min(h1, h2) * Math.pow(k, 0.75)
        if (w < 0.6) return ""
        const mid = (g1 + g2) / 2
        const run = Math.max(1, g2 - g1)

        // one side, A's foot to B's foot through the waist. Each foot leaves along its rim
        // (turned towards the other circle), its handle never long enough to dip below
        // the waist: so the two sides can never cross
        const side = s => {
            const p1 = at(ax, ay, r1, t1, s), p2 = at(bx, by, r2, t2, s)
            const m = [ax + ux * mid + s * nx * w, ay + uy * mid + s * ny * w]
            const rim = (p, cx, cy, r, toward) => {
                let tx = -(p[1] - cy) / r, ty = (p[0] - cx) / r
                if ((tx * ux + ty * uy) * toward < 0) { tx = -tx; ty = -ty }
                return [tx, ty]
            }
            const d1 = rim(p1, ax, ay, r1, 1), d2 = rim(p2, bx, by, r2, -1)
            const drop1 = Math.abs(d1[0] * nx + d1[1] * ny), drop2 = Math.abs(d2[0] * nx + d2[1] * ny)
            const l1 = Math.min(run * 0.32, Math.max(0, h1 - w) * 0.95 / Math.max(0.15, drop1))
            const l2 = Math.min(run * 0.32, Math.max(0, h2 - w) * 0.95 / Math.max(0.15, drop2))
            const lm = run * 0.24
            return { p1: p1, p2: p2, m: m,
                     c1: [p1[0] + d1[0] * l1, p1[1] + d1[1] * l1], c2: [m[0] - ux * lm, m[1] - uy * lm],
                     c3: [m[0] + ux * lm, m[1] + uy * lm], c4: [p2[0] + d2[0] * l2, p2[1] + d2[1] * l2] }
        }
        const top = side(1), bot = side(-1)

        // from each circle's rim the outline goes on to that circle's middle, so the
        // bridge reaches right under both discs
        return "M " + pt(top.p1)
            + " C " + pt(top.c1) + " " + pt(top.c2) + " " + pt(top.m)
            + " C " + pt(top.c3) + " " + pt(top.c4) + " " + pt(top.p2)
            + " L " + f(bx) + " " + f(by)
            + " L " + pt(bot.p2)
            + " C " + pt(bot.c4) + " " + pt(bot.c3) + " " + pt(bot.m)
            + " C " + pt(bot.c2) + " " + pt(bot.c1) + " " + pt(bot.p1)
            + " L " + f(ax) + " " + f(ay)
            + " Z"
    }

    // The thread: the same thickness all the way, except where it meets a circle: there
    // each side leaves the circle's rim along the rim, and bends round into the thread
    // (a fillet), so there is no corner where the two join. Like the neck, it runs on to
    // both middles
    readonly property string strand: {
        const r1 = ar, r2 = br, w = thread / 2
        if (w < 0.25 || r1 < 0.5 || r2 < 0.5) return ""
        const dx = bx - ax, dy = by - ay, d = Math.hypot(dx, dy)
        const room = d - r1 - r2
        if (room < 2) return ""
        const ux = dx / d, uy = dy / d, nx = -uy, ny = ux
        const f = n => n.toFixed(2)

        // one end: the two points on circle (cx, cy, r) the thread grows out of, where each
        // side has straightened into the thread, and the handles between them. `s` is 1 on
        // A (the thread leaves along u) and -1 on B
        const end = (cx, cy, r, s) => {
            const half = Math.min(r * 0.92, w + r * flare)
            const along = Math.sqrt(Math.max(0, r * r - half * half))
            const len = Math.min(r * flareLength, room * 0.46)
            const side = k => {
                // on the rim, k = 1 or -1 for the two sides
                const px = cx + s * ux * along + k * nx * half, py = cy + s * uy * along + k * ny * half

                // the rim's own direction there, turned to head for the other circle
                let tx = -(py - cy) / r, ty = (px - cx) / r
                if ((tx * ux + ty * uy) * s < 0) { tx = -tx; ty = -ty }
                const qx = cx + s * ux * (r + len) + k * nx * w, qy = cy + s * uy * (r + len) + k * ny * w
                return { p: [px, py], c1: [px + tx * len * 0.55, py + ty * len * 0.55],
                         c2: [qx - s * ux * len * 0.6, qy - s * uy * len * 0.6], q: [qx, qy] }
            }
            return [side(1), side(-1)]
        }
        const a = end(ax, ay, r1, 1), b = end(bx, by, r2, -1)
        const pt = p => f(p[0]) + " " + f(p[1])
        return "M " + pt(a[0].p)
            + " C " + pt(a[0].c1) + " " + pt(a[0].c2) + " " + pt(a[0].q)
            + " L " + pt(b[0].q)
            + " C " + pt(b[0].c2) + " " + pt(b[0].c1) + " " + pt(b[0].p)
            + " L " + f(bx) + " " + f(by)
            + " L " + pt(b[1].p)
            + " C " + pt(b[1].c1) + " " + pt(b[1].c2) + " " + pt(b[1].q)
            + " L " + pt(a[1].q)
            + " C " + pt(a[1].c2) + " " + pt(a[1].c1) + " " + pt(a[1].p)
            + " L " + f(ax) + " " + f(ay)
            + " Z"
    }

    // each its own path (overlapping, the same colour): together they read as one body
    ShapePath {
        fillColor: root.color
        strokeColor: "transparent"
        fillRule: ShapePath.WindingFill
        PathSvg { path: root.strand }
    }
    ShapePath {
        fillColor: root.color
        strokeColor: "transparent"

        // (filled whole wherever the outline might fold over itself: no holes)
        fillRule: ShapePath.WindingFill
        PathSvg { path: root.outline }
    }
    ShapePath {
        fillColor: root.bodyA ? root.color : "transparent"
        strokeColor: "transparent"
        PathSvg { path: root.bodyA ? root.disc(root.ax, root.ay, root.ar) : "" }
    }
    ShapePath {
        fillColor: root.bodyB ? root.color : "transparent"
        strokeColor: "transparent"
        PathSvg { path: root.bodyB ? root.disc(root.bx, root.by, root.br) : "" }
    }
}
