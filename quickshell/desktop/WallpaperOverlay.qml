import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import QtQuick.Effects
import ".."
import QtCore
import "Variables"
import "../theme/variables.js" as Vars

PanelWindow {
    id: root

    WlrLayershell.namespace: "quickshell"
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

    property string currentMaskShape: Vars.wallpaperMaskShape !== undefined ? Vars.wallpaperMaskShape : "Circle"
    property real currentMaskScale: Vars.wallpaperMaskScale !== undefined ? Vars.wallpaperMaskScale : 0.7
    property string currentMaskColor: Vars.wallpaperMaskColor !== undefined ? Vars.wallpaperMaskColor : "transparent"
    property bool currentMaskEnabled: Vars.wallpaperMaskEnabled !== undefined ? Vars.wallpaperMaskEnabled : true
    property real currentMaskOffsetX: Vars.wallpaperMaskOffsetX !== undefined ? Vars.wallpaperMaskOffsetX : 0
    property real currentMaskOffsetY: Vars.wallpaperMaskOffsetY !== undefined ? Vars.wallpaperMaskOffsetY : 0

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            var shape = Vars.wallpaperMaskShape !== undefined ? Vars.wallpaperMaskShape : "Circle";
            if (root.currentMaskShape !== shape)
                root.currentMaskShape = shape;

            var scale = Vars.wallpaperMaskScale !== undefined ? Vars.wallpaperMaskScale : 0.7;
            if (root.currentMaskScale !== scale)
                root.currentMaskScale = scale;

            var clr = Vars.wallpaperMaskColor !== undefined ? Vars.wallpaperMaskColor : "transparent";
            if (root.currentMaskColor !== clr)
                root.currentMaskColor = clr;

            var enabled = Vars.wallpaperMaskEnabled !== undefined ? Vars.wallpaperMaskEnabled : true;
            if (root.currentMaskEnabled !== enabled)
                root.currentMaskEnabled = enabled;

            var offsetX = Vars.wallpaperMaskOffsetX !== undefined ? Vars.wallpaperMaskOffsetX : 0;
            if (root.currentMaskOffsetX !== offsetX)
                root.currentMaskOffsetX = offsetX;

            var offsetY = Vars.wallpaperMaskOffsetY !== undefined ? Vars.wallpaperMaskOffsetY : 0;
            if (root.currentMaskOffsetY !== offsetY)
                root.currentMaskOffsetY = offsetY;
        }
    }

    exclusionMode: ExclusionMode.Ignore

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: Theme.background

    Settings {
        id: wpSettings
        category: "WallpaperSwitcher"
        property string currentWallpaper: ""
    }

    // Automatically load the wallpaper path set by the user in the Settings App
    property string currentWallpaper: wpSettings.currentWallpaper !== "" ? "file://" + wpSettings.currentWallpaper : ""

    Item {
        anchors.fill: parent

        M3Shapes {
            id: m3
        }

        // 1. Original fullscreen wallpaper (hidden)
        Image {
            id: wallpaperImage
            anchors.fill: parent
            source: root.currentWallpaper
            fillMode: Image.PreserveAspectCrop
            smooth: true
            antialiasing: true
            mipmap: true
            visible: false
        }

        // 2. The exact bounds of the mask shape
        Item {
            id: maskBounds
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: root.currentMaskOffsetX
            anchors.verticalCenterOffset: root.currentMaskOffsetY

            Behavior on anchors.horizontalCenterOffset {
                NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard }
            }
            Behavior on anchors.verticalCenterOffset {
                NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard }
            }

            property real calculatedSize: Math.min(root.width, root.height) * root.currentMaskScale
            width: calculatedSize
            height: calculatedSize

            Behavior on calculatedSize {
                NumberAnimation {
                    duration: Vars.animationDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Vars.customStandard
                }
            }
            visible: false
        }

        // 3. Cropped section of the fullscreen wallpaper perfectly matching the mask bounds
        Item {
            id: croppedWallpaper
            anchors.fill: maskBounds
            layer.enabled: true
            visible: false
            clip: true

            Image {
                width: wallpaperImage.width
                height: wallpaperImage.height
                x: -maskBounds.x
                y: -maskBounds.y
                source: root.currentWallpaper
                fillMode: Image.PreserveAspectCrop
                smooth: true
                antialiasing: true
                mipmap: true
            }
        }

        // 4. The 1:1 FBO mask perfectly matching the mask bounds (Same as MediaPlayer!)
        Item {
            id: maskContainer
            anchors.fill: maskBounds
            layer.enabled: true
            visible: false

            Item {
                anchors.centerIn: parent
                property real scaleFactor: Math.min(4, 4096 / Math.max(parent.width, parent.height, 1))
                width: parent.width * scaleFactor
                height: parent.height * scaleFactor
                scale: 1.0 / scaleFactor

                Image {
                    id: maskCanvas
                    anchors.fill: parent

                    sourceSize.width: width
                    sourceSize.height: height
                    smooth: true
                    antialiasing: true
                    mipmap: true

                    property string currentPathName: root.currentMaskShape
                    property string currentPath: m3.getPath(currentPathName)

                    source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='" + currentPath + "' fill='white'/></svg>"

                    onCurrentPathNameChanged: {
                        if (maskCanvas.status === Image.Ready) {
                            shapeAnim.restart();
                        }
                    }

                    SequentialAnimation {
                        id: shapeAnim
                        NumberAnimation {
                            target: maskCanvas
                            property: "scale"
                            to: 0.01
                            duration: 250
                            easing.type: Easing.InBack
                        }
                        NumberAnimation {
                            target: maskCanvas
                            property: "scale"
                            to: 1.0
                            duration: 550
                            easing.type: Easing.OutElastic
                        }
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            antialiasing: true
            opacity: root.currentMaskEnabled ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.InOutQuad
                }
            }
            color: {
                var c = root.currentMaskColor;
                if (c === "transparent" || c === undefined)
                    return "transparent";
                if (c === "background")
                    return Theme.background;
                if (c === "primary")
                    return Theme.primary;
                if (c === "secondary")
                    return Theme.secondary;
                if (c === "tertiary")
                    return Theme.tertiary;
                if (c === "surface_variant")
                    return Theme.surface_variant;
                if (c === "error")
                    return Theme.error;
                return "transparent";
            }
            Behavior on color {
                ColorAnimation {
                    duration: 300
                }
            }
        }

        Image {
            id: fallbackWallpaper
            anchors.fill: parent
            source: root.currentWallpaper
            fillMode: Image.PreserveAspectCrop
            smooth: true
            antialiasing: true
            mipmap: true
            opacity: root.currentMaskEnabled ? 0.0 : 1.0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.InOutQuad
                }
            }
        }

        // 5. Final MultiEffect mapping 1:1 on the exact bounds
        MultiEffect {
            id: maskedWallpaperEffect
            anchors.fill: maskBounds
            source: croppedWallpaper
            opacity: root.currentMaskEnabled ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.InOutQuad
                }
            }
            maskEnabled: true
            maskSource: maskContainer
            antialiasing: true
            smooth: true
        }

        // 6. Inner Shadow SVG
        Item {
            id: shadowStrokeContainer
            anchors.fill: maskBounds
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blurMax: 128
                blur: 1.0
                autoPaddingEnabled: false
            }
            visible: false

            Item {
                anchors.centerIn: parent
                property real scaleFactor: Math.min(4, 4096 / Math.max(parent.width, parent.height, 1))
                width: parent.width * scaleFactor
                height: parent.height * scaleFactor
                scale: 1.0 / scaleFactor

                Image {
                    id: shadowCanvas
                    anchors.fill: parent
                    sourceSize.width: width
                    sourceSize.height: height
                    smooth: true
                    antialiasing: true
                    mipmap: true

                    property string currentPathName: root.currentMaskShape
                    property string currentPath: m3.getPath(currentPathName)

                    // Inverted path: draws black outside the shape, casting a directional drop shadow inwards!
                    source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='M -50 -50 L 150 -50 L 150 150 L -50 150 Z " + currentPath + "' fill='black' fill-rule='evenodd'/></svg>"

                    onCurrentPathNameChanged: {
                        if (shadowCanvas.status === Image.Ready) {
                            shadowAnim.restart();
                        }
                    }

                    SequentialAnimation {
                        id: shadowAnim
                        NumberAnimation {
                            target: shadowCanvas
                            property: "scale"
                            to: 0.01
                            duration: 250
                            easing.type: Easing.InBack
                        }
                        NumberAnimation {
                            target: shadowCanvas
                            property: "scale"
                            to: 1.0
                            duration: 550
                            easing.type: Easing.OutElastic
                        }
                    }
                }
            }
        }

        // 7. Inner Shadow Blended
        MultiEffect {
            anchors.fill: maskBounds
            source: shadowStrokeContainer
            maskEnabled: true
            maskSource: maskContainer
            opacity: root.currentMaskEnabled ? 0.8 : 0.0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.InOutQuad
                }
            }
        }
    } // Close Item parent
} // Close PanelWindow
