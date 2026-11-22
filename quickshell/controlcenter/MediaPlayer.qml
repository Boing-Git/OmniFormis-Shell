import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Services.Mpris
import ".."
import "../primitive"
import "../variables.js" as Vars

// The media player of the control center: what's playing (MPRIS), the album-art card
// in the dial's corner, the control on the outer ring (with its wavy timeline) and the
// previous / next buttons beside the timeline's gem. ControlCenter.qml creates one and
// uses `control`, `corner` and `gemSides`.
Item {
    id: media

    // the control center's dial, its shape library, and the timeline's current tick
    required property var dial
    required property var shapes
    property real seekPos: 0

    // ★ the media player's settings: controlcenter/MediaSettings.qml ★
    readonly property var cfg: MediaSettings { liveSize: media.dial.expandedSize; sweepDeg: media.dial.sweepDeg }

    // the dial is open on the media control
    readonly property bool active: dial.open && dial.inMedia
    onActiveChanged: if (active && player && player.positionSupported) player.positionChanged()

    // the player that is playing, otherwise the first one
    readonly property var player: {
        const ps = Mpris.players.values
        for (let i = 0; i < ps.length; i++)
            if (ps[i].isPlaying) return ps[i]
        return ps.length > 0 ? ps[0] : null
    }
    readonly property bool playing: !!player && player.isPlaying
    readonly property string title: player && player.trackTitle ? player.trackTitle : "Nothing playing"
    readonly property string artist: player && player.trackArtist ? player.trackArtist : ""
    readonly property string art: player && player.trackArtUrl ? player.trackArtUrl : ""
    readonly property real length: player && player.lengthSupported ? player.length : 0
    readonly property real pos: player && player.positionSupported ? player.position : 0
    readonly property bool canSeek: !!player && player.canSeek && player.positionSupported && length > 0

    // the mouse is on the timeline and there's a track under it: darkens the art and shows
    // the seek time (with nothing playing, the placeholder art stays as it is)
    readonly property bool seekShown: dial.overTimeline && length > 0

    // one tick of the media timeline = this many seconds (so one wheel notch seeks this much);
    // fixed, so the line's length follows the song (a long song runs past the screen edge)
    readonly property real seekStep: cfg.seekStep
    readonly property int ticks: length > 0 ? Math.floor(length / seekStep) + 1 : 0
    readonly property int tick: Math.max(0, Math.min(Math.max(0, ticks - 1), Math.round(pos / seekStep)))

    // changes when the track changes, so the timeline can re-sync
    readonly property string trackKey: player ? (player.trackTitle + "|" + length) : ""

    function toggle() {
        const p = player
        if (p && p.canTogglePlaying) p.togglePlaying()
    }
    function next() {
        const p = player
        if (p && p.canGoNext) p.next()
    }
    function prev() {
        const p = player
        if (p && p.canGoPrevious) p.previous()
    }
    function seekToTick(t) {
        if (!canSeek) return
        player.position = Math.min(length, t * seekStep)
        if (!player.isPlaying && player.canPlay) player.play()
    }
    function fmtTime(s) {
        s = Math.max(0, Math.floor(s))
        const m = Math.floor(s / 60)
        const r = s % 60
        return m + ":" + (r < 10 ? "0" : "") + r
    }

    // players don't push their position: ask for it once a second while the dial
    // is open on the media control and something plays
    Timer {
        interval: 1000
        repeat: true
        running: media.active && media.playing && !!media.player && media.player.positionSupported
        triggeredOnStart: true
        onTriggered: media.player.positionChanged()
    }

    // ── the corner card of the media control: album art, title, artist ──
    // Laid out around the dial's corner like the rings: the art sits on the diagonal and
    // the title and artist curve around it. The card is 0×0 at the corner itself, isn't
    // scaled by the dial (`scaled: false`), and is sized only from MediaSettings, so it
    // fits any dial size and nothing else moves it. The art is cut to an M3 shape that turns
    // while playing; the mouse on the timeline shows the time you are seeking to.
    property Component corner: Component {
        Item {
            id: card
            width: 0
            height: 0
            readonly property real cornerDistance: 0
            readonly property bool scaled: false

            readonly property real midDeg: media.dial.midDeg
            readonly property real midRad: midDeg * Math.PI / 180
            readonly property bool flipped: Math.sin(midRad) < 0

            // sizes from MediaSettings (worked out there)
            readonly property real artR: media.cfg.artR
            readonly property real artD: media.cfg.artDistance
            readonly property real nearR: media.cfg.nearTextR
            readonly property real farR: media.cfg.farTextR

            Item {
                id: artBox
                width: card.artR * 2
                height: width
                // on the middle line, pulled artInset px back towards the dial's centre (the
                // screen edge or corner it lives on); the text doesn't move with it
                x: card.artD * Math.cos(card.midRad) - width / 2 - media.cfg.artInset * Math.cos(card.midRad)
                y: card.artD * Math.sin(card.midRad) - height / 2 - media.cfg.artInset * Math.sin(card.midRad)

                // the cover, used only as the shape's fill (not drawn by itself)
                Image {
                    id: artImage
                    anchors.fill: parent
                    source: media.art
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 384
                    sourceSize.height: 384

                    // the shape shows it smaller than its pixels: mipmaps keep it smooth
                    mipmap: true
                    visible: false
                }

                // the art cut to an M3 shape: a plain Shape filled with the image
                // (no layers / effects, which crashed the scene graph)
                Shape {
                    id: artShape
                    anchors.fill: parent
                    preferredRendererType: Shape.CurveRenderer

                    // turns slowly while playing (the cover turns with it, like a record)
                    // and holds its angle while paused
                    RotationAnimation on rotation {
                        from: 0; to: 360
                        duration: media.cfg.artSpinDuration
                        loops: Animation.Infinite
                        running: media.active && media.cfg.artSpin
                        paused: running && !media.playing
                    }

                    // the background, shown while there's no art
                    ShapePath {
                        strokeColor: "transparent"
                        fillColor: Roles.primary_container
                        scale: media.shapes.fitScale(artShape)
                        PathSvg { path: media.shapes.getPath(media.cfg.artShape) }
                    }

                    // the cover
                    ShapePath {
                        strokeColor: "transparent"
                        fillColor: "transparent"
                        fillItem: artImage.status === Image.Ready ? artImage : null

                        // The cover is laid out at the picture's own size (e.g. 384×384), top-left on
                        // the shape's corner, so first fit it to the shape (covering it, centred), then
                        // shrink it by artCoverScale and, for the "edge" spin, turn it back by the
                        // shape's angle, both around the shape's centre (the rightmost step goes first)
                        readonly property real cw: artShape.width / 2
                        readonly property real ch: artShape.height / 2
                        readonly property real tw: Math.max(1, artImage.implicitWidth)
                        readonly property real th: Math.max(1, artImage.implicitHeight)
                        readonly property real fit: Math.max(artShape.width / tw, artShape.height / th)
                        fillTransform: PlanarTransform.fromRotate(media.cfg.artSpinMode === "edge" ? -artShape.rotation : 0, cw, ch)
                            .times(PlanarTransform.fromScale(media.cfg.artCoverScale, media.cfg.artCoverScale, cw, ch))
                            .times(PlanarTransform.fromAffineMatrix(fit, 0, 0, fit, cw - tw * fit / 2, ch - th * fit / 2))
                        scale: media.shapes.fitScale(artShape)
                        PathSvg { path: media.shapes.getPath(media.cfg.artShape) }
                    }

                    // while the mouse is on the timeline: darkens the art
                    ShapePath {
                        strokeColor: "transparent"
                        fillColor: Qt.rgba(Roles.scrim.r, Roles.scrim.g, Roles.scrim.b, media.cfg.seekShade * artShape.shade)   // M3 scrim
                        scale: media.shapes.fitScale(artShape)
                        PathSvg { path: media.shapes.getPath(media.cfg.artShape) }
                    }

                    property real shade: media.seekShown ? 1 : 0
                    Behavior on shade { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
                }

                // shown while there is no art (or it is still loading)
                SymbolIcon {
                    anchors.centerIn: parent
                    visible: artImage.status !== Image.Ready
                    text: "music_note"
                    size: card.artR * 0.8
                    filled: true
                    color: Roles.on_primary_container
                }

                // while the mouse is on the timeline: the time you are seeking to
                Column {
                    anchors.centerIn: parent
                    opacity: media.seekShown ? 1 : 0
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

                    SmoothText {
                        id: seekTime
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: media.fmtTime(media.seekPos * media.seekStep)
                        font.pixelSize: media.cfg.seekTimeSize
                        font.weight: 700
                        color: Roles.tertiary_fixed

                        // a little bounce each time the time you're seeking to changes
                        onTextChanged: if (visible) seekPop.restart()
                        SequentialAnimation {
                            id: seekPop
                            NumberAnimation { target: seekTime; property: "scale"; to: media.cfg.seekPopScale; duration: media.cfg.seekPopIn; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.fastSpatial.bezier }
                            NumberAnimation { target: seekTime; property: "scale"; to: 1; duration: media.cfg.seekPopOut; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.fastSpatial.bezier }
                        }
                    }
                    SmoothText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: media.fmtTime(media.length)
                        font.pixelSize: media.cfg.seekLengthSize
                        color: Roles.tertiary_fixed_dim         // a "fixed" role: light in both themes, like the time above
                    }
                }
            }

            // the title and artist, curved around the art
            CurvedText {
                text: media.title
                radius: card.flipped ? card.farR : card.nearR
                centerDeg: card.midDeg + media.cfg.textShiftDeg
                maxDeg: media.cfg.textMaxDeg
                font.pixelSize: media.cfg.titleSize
                font.weight: media.cfg.titleWeight
                color: Roles.on_surface
            }
            CurvedText {
                text: media.artist
                radius: card.flipped ? card.nearR : card.farR
                centerDeg: card.midDeg + media.cfg.textShiftDeg
                maxDeg: media.cfg.textMaxDeg
                font.pixelSize: media.cfg.artistSize
                color: Roles.on_surface_variant
            }
        }
    }

    // the control on the outer ring
    readonly property var control: ({
        // the media player: the tile (and a click on the timeline) plays / pauses,
        // the timeline ring seeks, and previous / next are badges on the gem
        key: "media",
        size: media.cfg.dialSize,
        badges: false,
        dateIcon: false,
        corner: media.corner,
        timeline: {
            ticks: () => media.ticks,
            tick: () => media.tick,
            key: () => media.trackKey,
            animated: () => media.playing,
            icon: () => media.playing ? "pause" : "play_arrow",
            canSeek: () => media.canSeek,
            seek: t => media.seekToTick(t),
            activate: () => media.toggle(),

            // its own geometry and look (MediaSettings), not the inner ring's
            style: media.cfg
        },

        // its own control center settings while selected (MediaSettings → controlCenter)
        settings: media.cfg.controlCenter,

        label: "Media",
        icon: "music_note",
        shape: "GhostIsh",
        shapeSelected: "Gem",           // the shape while it's the selected tile
        on: media.playing,
        toggle: () => media.toggle(),

        // no pills: the timeline takes the inner ring's place, and previous / next
        // are badges on the play / pause gem
        devices: () => []
    })

    // previous / next: buttons on the timeline either side of the play / pause gem
    readonly property var gemSides: [
        { icon: "skip_previous", act: () => media.prev() },
        { icon: "skip_next",     act: () => media.next() }
    ]
}
