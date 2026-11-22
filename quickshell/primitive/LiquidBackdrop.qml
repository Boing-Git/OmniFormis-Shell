import QtQuick
import Quickshell.Wayland

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
        active: root.live
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
                Repeater {
                    model: Backdrop.liveWindows
                    ScreencopyView {
                        required property var modelData
                        captureSource: modelData.handle
                        live: Backdrop.dialOpen
                        x: modelData.x
                        y: modelData.y
                        width: modelData.w
                        height: modelData.h
                    }
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
}
