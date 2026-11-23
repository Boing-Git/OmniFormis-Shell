import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import "../variables.js" as Vars

// The pictures a LiquidGlass sees through itself, as textures: the wallpaper and the same
// blurred (Backdrop.qml), loaded only while liquid glass is on. Every Image is its own copy
// on the GPU, so there's one of these per window, shared by every glass in it: DialDelegate
// makes one for its dial and what sits on it (dial.liquidBackdrop); the lock makes its own
// from its softened picture.
Item {
    id: root

    // what to load ("" for nothing): by default the wallpaper, at the screen's size
    property string source: Prefs.liquidOn ? Backdrop.sharpUrl : ""
    property string blurSource: Prefs.liquidOn ? Backdrop.blurUrl : ""
    property size sourceSize: Backdrop.sharpSize

    // decoded keeping its shape and covering sourceSize (false: as it is, e.g. to share the
    // lock's already-loaded picture, which LiquidGlass then covers the screen with itself)
    property bool crop: true

    // false only to have the picture in the very first frame (one that's already loaded)
    property bool asynchronous: true

    // Sees: Live (Backdrop.live): the wallpaper with every window streamed over it, in place
    // of the pictures. Off for a backdrop with its own picture (the lock)
    property bool live: Backdrop.live

    // streaming at all: only while the dial it belongs to is out (opening, open or closing);
    // closed, nothing is captured and the pictures are let go
    property bool awake: true

    // the part of the screen its glass can show (the dial's box, with room for the bend and
    // the shadow, in screen px): only the windows reaching into it are streamed. Empty: all
    property rect area: Qt.rect(0, 0, 0, 0)
    function _under(list) {
        const a = area
        if (a.width <= 0 || a.height <= 0) return list
        const m = Vars.liquid.liveMargin, b = Backdrop.deco.border
        return list.filter(w => w.x - b < a.x + a.width + m && w.x + w.w + b > a.x - m
                             && w.y - b < a.y + a.height + m && w.y + w.h + b > a.y - m)
    }

    // the two pictures; the blurred one is the sharp one until it's made (or with Blur 0)
    readonly property Item sharp: live && liveScene.item ? liveScene.item.sharp : sharpImage
    readonly property Item blurred: live && liveScene.item ? liveScene.item.blurred : blurImage.loaded ? blurImage : sharpImage

    // a picture is there to see
    readonly property bool ready: live ? !!liveScene.item : sharpImage.loaded

    // Never seen, yet not `visible: false`: an Image only hands a new picture on to a shader
    // while it's drawn, so these two are drawn, 1 px and fully transparent
    width: 1
    height: 1
    opacity: 0

    Image {
        id: sharpImage
        readonly property bool loaded: source != "" && implicitWidth > 0
        width: 1
        height: 1
        source: root.source
        sourceSize: root.sourceSize
        fillMode: root.crop ? Image.PreserveAspectCrop : Image.Stretch
        asynchronous: root.asynchronous

        // a new wallpaper loads behind the one shown: the glass never goes blank in between
        retainWhileLoading: true
    }
    Image {
        id: blurImage
        readonly property bool loaded: source != "" && implicitWidth > 0
        width: 1
        height: 1
        source: root.blurSource
        asynchronous: true
        retainWhileLoading: true
    }

    // the live scene, screen-sized: the wallpaper, then each window where it is. Rendered
    // into a texture (never drawn itself); the blurred one is the same at a fraction of the
    // size, smoothed back up (no blur effect: Qt 6.12's effects crash)
    Loader {
        id: liveScene
        active: root.live && root.awake
        sourceComponent: Item {
            readonly property Item sharp: sharpTex
            readonly property Item blurred: Prefs.liquidBlur > 0 && blurTex ? blurTex : sharpTex

            Item {
                id: scene
                width: Backdrop.screenSize.width
                height: Backdrop.screenSize.height

                Image {
                    anchors.fill: parent
                    source: Backdrop.wallpaper === "" ? "" : Backdrop.fileUrl(Backdrop.wallpaper)
                    sourceSize: Backdrop.sharpSize
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    retainWhileLoading: true
                }
                // every window under the dial, as Hyprland draws it (rounded, in its border). One
                // delegate per window for as long as it's there (keyed by its address), so a
                // window that moves keeps its stream
                Repeater {
                    id: windows
                    model: ScriptModel { objectProp: "key"; values: root._under(Backdrop.liveWindows) }
                    LiveWindow {}
                }

                // a new frame of each window a few dozen times a second (not on every frame the
                // compositor draws: Vars.liquid.liveFps)
                Timer {
                    interval: 1000 / Math.max(1, Vars.liquid.liveFps)
                    repeat: true
                    running: true
                    onTriggered: { for (let i = 0; i < windows.count; i++) { const w = windows.itemAt(i); if (w) w.capture() } }
                }
            }
            ShaderEffectSource {
                id: sharpTex
                width: 1
                height: 1
                sourceItem: scene
                hideSource: true
                live: true
                textureSize: Backdrop.sharpSize
            }

            // the blur: the scene halved again and again, each step averaging the last (a
            // single big shrink skips pixels and comes out blocky). Blur 1 ≈ 4 halvings, about
            // the library's own blur at full strength
            readonly property int halvings: Math.max(1, Math.min(levels.count, Math.round(Math.log2(1 + Prefs.liquidBlur * 15))))
            readonly property Item blurTex: levels.itemAt(halvings - 1)
            Repeater {
                id: levels
                model: 6
                ShaderEffectSource {
                    required property int index
                    width: Backdrop.screenSize.width
                    height: Backdrop.screenSize.height
                    sourceItem: index === 0 ? scene : levels.itemAt(index - 1)
                    live: true
                    smooth: true
                    textureSize: Qt.size(Math.max(1, Math.round(Backdrop.sharpSize.width / Math.pow(2, index + 1))),
                                         Math.max(1, Math.round(Backdrop.sharpSize.height / Math.pow(2, index + 1))))
                }
            }
        }
    }

    // one window: its stream, cut to Hyprland's rounding, in Hyprland's border (the active
    // window's colours, or the inactive one), moved and faded as Hyprland's workspace
    // animation moves it (Backdrop.inDX ...)
    component LiveWindow: Item {
        id: win
        required property var modelData
        readonly property bool leaving: modelData.leaving
        readonly property bool entering: modelData.entering
        readonly property real b: Backdrop.deco.border
        readonly property bool active: !!Hyprland.activeToplevel && Hyprland.activeToplevel.address === modelData.key

        x: modelData.x + (leaving ? Backdrop.outDX : entering ? Backdrop.inDX : 0)
        y: modelData.y + (leaving ? Backdrop.outDY : entering ? Backdrop.inDY : 0)
        width: modelData.w
        height: modelData.h
        z: modelData.z
        opacity: leaving ? Backdrop.outOpacity : entering ? Backdrop.inOpacity : 1

        Rectangle {
            x: -win.b
            y: -win.b
            width: win.width + 2 * win.b
            height: win.height + 2 * win.b
            radius: Backdrop.deco.rounding + win.b
            visible: win.b > 0
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0; color: win.active ? Backdrop.deco.active : Backdrop.deco.inactive }
                GradientStop { position: 1; color: win.active ? Backdrop.deco.active2 : Backdrop.deco.inactive }
            }
        }
        ClippingRectangle {
            anchors.fill: parent
            radius: Backdrop.deco.rounding
            color: "transparent"

            ScreencopyView {
                id: view
                anchors.fill: parent

                // A capture that fails (the window was hidden, resized, went fullscreen) ends
                // for good and leaves the window blank, until liquid glass was toggled: it's
                // started again a moment later, sooner the first times. A leaving window keeps
                // its last frame and isn't captured any more
                property bool resting: false
                property int retryMs: 250
                captureSource: resting ? null : win.modelData.handle
                onHasContentChanged: if (hasContent) retryMs = 250
                Timer {
                    interval: view.retryMs
                    running: !win.leaving && !view.hasContent && !view.resting
                    onTriggered: {
                        console.info("liquid glass: capture of " + win.modelData.key + " stopped, starting it again")
                        view.retryMs = Math.min(4000, view.retryMs * 2)
                        view.resting = true
                        Qt.callLater(() => view.resting = false)
                    }
                }
            }
        }
        function capture() { if (!leaving && view.hasContent) view.captureFrame() }
    }
}
