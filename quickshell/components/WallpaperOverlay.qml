import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland
import QtQuick.Effects
import ".."
import QtCore
import "Variables"
import "../Variables/variables.js" as Vars

PanelWindow {
    id: root

    WlrLayershell.namespace: "quickshell-wallpaper"
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

        Item {
            id: maskContainer
            anchors.fill: parent
            visible: false
            layer.enabled: true
            layer.samples: 16 // Ultra-smooth MSAA for mask edges
            layer.smooth: true
            layer.textureMirroring: ShaderEffectSource.NoMirroring

            Image {
                id: maskCanvas
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: root.currentMaskOffsetX
                anchors.verticalCenterOffset: root.currentMaskOffsetY

                // The SVG path expects a 100x100 bounding box.
                property real calculatedSize: Math.min(parent.width, parent.height) * root.currentMaskScale
                width: calculatedSize
                height: calculatedSize

                // Keep a static high-res sourceSize to prevent the SVG engine from re-rasterizing every frame during the scale animation
                sourceSize.width: Math.max(parent.width, parent.height)
                sourceSize.height: Math.max(parent.width, parent.height)

                // Animate changes to size (either through scale slider or shape swap)
                Behavior on calculatedSize {
                    NumberAnimation {
                        duration: 800
                        easing.type: Easing.OutElastic
                    }
                }

                smooth: true
                antialiasing: true
                mipmap: true // <-- FIX: Smooths the SVG when it scales down

                property string currentPathName: root.currentMaskShape
                property string currentPath: m3.getPath(currentPathName)

                onCurrentPathNameChanged: {
                    if (maskCanvas.status === Image.Ready) {
                        shapeAnim.restart();
                    } else {
                        maskCanvas.updateSource();
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
                    ScriptAction {
                        script: maskCanvas.updateSource()
                    }
                    NumberAnimation {
                        target: maskCanvas
                        property: "scale"
                        to: 1.0
                        duration: 550
                        easing.type: Easing.OutElastic
                    }
                }

                function updateSource() {
                    maskCanvas.source = "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100' shape-rendering='geometricPrecision'><path d='" + maskCanvas.currentPath + "' fill='white'/></svg>";
                }

                Component.onCompleted: updateSource()
            } // Close maskCanvas
        } // Close maskContainer

        Image {
            id: wallpaperImage
            anchors.fill: parent
            source: root.currentWallpaper
            fillMode: Image.PreserveAspectCrop

            smooth: true         // <-- FIX: Ensure wallpaper interpolates smoothly
            antialiasing: true   // <-- FIX: Hardware antialiasing for the image
            mipmap: true         // <-- FIX: Smooth downscaling for large wallpapers

            opacity: root.currentMaskEnabled ? 0.0 : 1.0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation {
                    duration: 500
                    easing.type: Easing.InOutQuad
                }
            }
        }

        Rectangle {
            anchors.fill: parent

            antialiasing: true // <-- FIX: Ensure edge smoothing for the background layer

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

        MultiEffect {
            anchors.fill: parent
            source: wallpaperImage
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
            layer.enabled: true
            layer.smooth: true
            layer.samples: 8
        }
    } // Close Item parent
} // Close PanelWindow
