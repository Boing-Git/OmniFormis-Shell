import QtQuick
import "../variables.js" as Vars

// ╭───────────────────────────────────────────────────────────────╮
// │ LiquidGlass - one piece of liquid glass, a disc or a band      │
// │ along a circle: it bends, fringes and frosts the wallpaper     │
// │ behind it, with a bevelled rim, highlights and a drop shadow.  │
// │                                                               │
// │   LiquidGlass {                                               │
// │       anchors.fill: parent                                    │
// │       shape: "arc"                                            │
// │       cx: dial.centerX; cy: dial.centerY; radius: 350         │
// │       thickness: 80; startDeg: 165; sweepDeg: 120             │
// │       tint: Prefs.liquidBody(bandColor, "ring")                │
// │   }                                                           │
// ╰───────────────────────────────────────────────────────────────╯
// The liquid glass library (Dotfiles/liquidglass-main) ported to the shell: its shader
// (shaders/liquidglass.frag) and its settings, live in Prefs (Settings → Liquid glass). It
// draws only while liquid glass is on and its pictures are loaded (`active`): the container
// it stands in for shows its flat colour otherwise.
//
// It finds the dial it sits on by itself (the nearest DialDelegate up the tree) and sees
// through that dial's pictures (dial.liquidBackdrop); set `backdrop` to give it others. The
// shape is drawn round (cx, cy) in this item's px; for the whole drop shadow to show, the
// item must reach `shadowReach` past the shape (e.g. anchors.margins: -shadowReach).
ShaderEffect {
    id: root

    // ── the shape ──
    //   "disc"  a circle of `radius` round (cx, cy)
    //   "arc"   a band `thickness` wide along the circle of `radius` round (cx, cy), from
    //           startDeg over sweepDeg (0° = right, 90° = down), with `roundEnds` or cut flat
    //   "box"   a card boxWidth × boxHeight round (cx, cy), its corners rounded by `radius`
    property string shape: "disc"
    property real boxWidth: width
    property real boxHeight: height
    property real cx: width / 2
    property real cy: height / 2
    property real radius: Math.min(width, height) / 2
    property real thickness: 40
    property real startDeg: 0
    property real sweepDeg: 360
    property bool roundEnds: true

    // ── colours ── (alpha: how much each covers)
    // the glass's own colour, e.g. Prefs.liquidBody(color, kind): its kind's solidity × Body fill. It fills
    // the body and clears across the bevel, so the rim stays liquid even on a solid dial
    property color tint: "transparent"

    // what lies between the wallpaper and this glass: the dial under a ring (its tint), the
    // lock's scrim. Stack two with over()
    property color under: "transparent"

    // `a` with `b` on it, as one colour (what both together cover, and with what)
    function over(a, b) {
        const A = 1 - (1 - a.a) * (1 - b.a)
        if (A <= 0) return Qt.rgba(0, 0, 0, 0)
        const wa = a.a * (1 - b.a) / A, wb = b.a / A
        return Qt.rgba(a.r * wa + b.r * wb, a.g * wa + b.g * wb, a.b * wa + b.b * wb, A)
    }

    // the box the glass is cut to, in this item's px, if something up the tree clips it (a
    // dial clips to its own box): the drop shadow fades out before it instead of stopping
    // on a line. Empty: not clipped
    property rect clipRect: Qt.rect(0, 0, 0, 0)

    // ── the button mode ── (Liquid glass: Button) the glass brightens while hovered, and
    // while pressed its bevel flattens and its shadow spreads, as the library's buttons do
    property bool hovered: false
    property bool pressed: false

    // ── what it sees ──
    // the dial it sits on: the nearest item up the tree with a liquidBackdrop, looked for
    // once everything is built
    property Item host: null
    Component.onCompleted: {
        if (host) return
        for (let p = parent; p; p = p.parent)
            if (p.liquidBackdrop !== undefined) { host = p; break }
    }
    property LiquidBackdrop backdrop: host ? host.liquidBackdrop : null

    // drawing: liquid glass is on, there's a picture to see and the shader works (if it
    // didn't, the container keeps its flat colour rather than vanish)
    // false: this one stays flat even while liquid glass is on (e.g. rings, Prefs.liquidRings)
    property bool allowed: true

    // true: glass even while liquid glass is off for the dials (a setting of its own asks for
    // it: the lock's sheet)
    property bool force: false

    readonly property bool active: allowed && (force || Prefs.liquidOn) && !!backdrop && backdrop.ready && status !== ShaderEffect.Error
    visible: active

    // how far past the shape the drop shadow reaches, px (it fades out by twice its spread)
    readonly property real shadowReach: Prefs.liquidShadow > 0
        ? Math.ceil(2.4 * Prefs.liquidShadowSpread + Math.abs(Prefs.liquidShadowOffset)) + 2 : 2

    // the button mode's two states, eased like any colour change (0..1)
    readonly property bool button: Prefs.liquidGlass === "button"
    property real hover: button && hovered && !pressed ? 1 : 0
    property real press: button && pressed ? 1 : 0
    Behavior on hover { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
    Behavior on press { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

    // ── what goes to the shader ── each one below is a member of the shaders' uniform
    // block, by name (shaders/liquidglass.vert and .frag). Qt.resolvedUrl: a plain path
    // would be looked up next to the file that uses LiquidGlass, not next to this one
    vertexShader: Qt.resolvedUrl("shaders/liquidglass.vert.qsb")
    fragmentShader: Qt.resolvedUrl("shaders/liquidglass.frag.qsb")
    onStatusChanged: if (status === ShaderEffect.Error) console.warn("LiquidGlass:", log)

    // the pictures (the blurred one is the sharp one until it's made)
    readonly property Item src: backdrop ? backdrop.sharp : null
    readonly property Item srcBlur: backdrop ? backdrop.blurred : null

    // screen UV → picture UV: the picture covers the window as awww covers the screen
    // (scaled to fill, centred, the rest cropped). The dials' windows cover the screen
    function coverOf(img) {
        const W = Math.max(1, Window.width), H = Math.max(1, Window.height)
        const iw = img ? img.implicitWidth : 0, ih = img ? img.implicitHeight : 0
        if (iw <= 0 || ih <= 0) return Qt.vector4d(1, 1, 0, 0)
        const f = Math.max(W / iw, H / ih)
        const sx = W / (iw * f), sy = H / (ih * f)
        return Qt.vector4d(sx, sy, (1 - sx) / 2, (1 - sy) / 2)
    }
    readonly property vector4d srcCover: coverOf(src)
    readonly property vector4d blurCover: coverOf(srcBlur)
    readonly property vector4d clipBox: Qt.vector4d(clipRect.x, clipRect.y, clipRect.x + clipRect.width, clipRect.y + clipRect.height)

    // the item and the window
    readonly property size itemSize: Qt.size(width, height)
    readonly property point centre: Qt.point(cx, cy)
    readonly property real dpr: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1
    readonly property size screenSize: Qt.size(Window.width, Window.height)

    // which way is up in the window's clip space: down on Vulkan, up everywhere else
    readonly property real ndcYUp: GraphicsInfo.api === GraphicsInfo.Vulkan ? -1 : 1

    // the shape: 0 disc, 1 band with round ends, 2 band with flat ends, 3 box
    readonly property real shapeKind: shape === "disc" ? 0 : shape === "box" ? 3 : roundEnds ? 1 : 2
    readonly property size boxHalf: Qt.size(boxWidth / 2, boxHeight / 2)
    readonly property real shapeRadius: radius
    readonly property real shapeHalfWidth: thickness / 2
    readonly property real midRad: (startDeg + sweepDeg / 2) * Math.PI / 180
    readonly property real halfAperture: Math.min(Math.PI, Math.abs(sweepDeg) / 2 * Math.PI / 180)
    readonly property point arcMid: Qt.point(Math.cos(midRad), Math.sin(midRad))
    readonly property point arcAperture: Qt.point(Math.sin(halfAperture), Math.cos(halfAperture))

    // straight colours (a QML color would reach the shader premultiplied)
    readonly property vector4d underColor: Qt.vector4d(under.r, under.g, under.b, under.a)
    readonly property vector4d tintColor: Qt.vector4d(tint.r, tint.g, tint.b, tint.a)

    // the library's settings (Prefs: Settings → Liquid glass), with the button mode's
    // states: +0.2 brightness while hovered; while pressed, 80% of the bevel's depth and
    // 120% of the shadow's spread
    readonly property real refraction: Prefs.liquidRefraction
    readonly property real chroma: Prefs.liquidChroma
    readonly property real edgeHighlight: Prefs.liquidEdge
    readonly property real specular: Prefs.liquidSpecular
    readonly property real fresnel: Prefs.liquidFresnel
    readonly property real distortion: Prefs.liquidDistortion
    readonly property real zRadius: Prefs.liquidDepth * (1 - 0.2 * press)
    readonly property real glassOpacity: Prefs.liquidOpacity
    readonly property real saturation: Prefs.liquidSaturation
    readonly property real coolTint: Prefs.liquidTint
    readonly property real brightness: Prefs.liquidBrightness + 0.2 * hover
    readonly property real shadowOpacity: Prefs.liquidShadow
    readonly property real shadowSpread: Prefs.liquidShadowSpread * (1 + 0.2 * press)
    readonly property real shadowOffsetY: Prefs.liquidShadowOffset
    readonly property real bevelMode: Prefs.liquidBevel === "dome" ? 1 : 0
}
