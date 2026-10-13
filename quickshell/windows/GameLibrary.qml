import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import Quickshell.Io
import "../theme"
import "../theme"
import "../core/primitives" as Primitives
import "../daemons"
import ".."

Item {
    id: overviewContainer
    property bool visibleState: false
    property string loadingGameId: ""

    property int lastWindowCount: 0
    Connections {
        target: HyprlandData
        function onWindowListChanged() {
            if (overviewContainer.loadingGameId !== "" && HyprlandData.windowList.length > overviewContainer.lastWindowCount) {
                overviewContainer.loadingGameId = "";
            }
            overviewContainer.lastWindowCount = HyprlandData.windowList.length;
        }
    }
    property bool gameMode: Vars.gameMode !== undefined ? Vars.gameMode : false

    property bool vimKeysEnabled: false
    Process {
        id: vimKeysChecker
        command: ["bash", "-c", "grep -qi 'vimkeys[ \t]*=[ \t]*true' /home/boing/Dotfiles/hypr/modules/variables.lua && echo 'true' || echo 'false'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                overviewContainer.vimKeysEnabled = (this.text.trim() === 'true');
            }
        }
    }

    signal closeRequested

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: libraryPanel
            required property var modelData

            property bool isAnimating: wAnim.running || hAnim.running
            
            function parseGames(text) {
                try {
                    return JSON.parse(text || "[]");
                } catch(e) {
                    return [];
                }
            }
            
            Connections {
                target: overviewContainer
                function onVisibleStateChanged() {
                    console.log("[GAMELIBRARY] visibleState changed to:", overviewContainer.visibleState);
                    if (overviewContainer.visibleState) {
                        MorphState.notifyOpened(panelBackground.targetWidth, panelBackground.targetHeight, panelBackground.defaultRadius, panelBackground);
                    } else {
                        MorphState.notifyClosed();
                    }
                }
            }
            
            visible: true
            color: "transparent"

            WlrLayershell.namespace: "quickshell"
            WlrLayershell.layer: WlrLayer.Overlay
            exclusionMode: ExclusionMode.Ignore
            
            mask: Region {
                item: (overviewContainer.visibleState || isAnimating) ? panelBackground : null
            }
            
            anchors.top: true
            anchors.bottom: true
            anchors.left: true
            anchors.right: true

            screen: modelData

            readonly property var hyprMonitor: Hyprland.monitorFor(libraryPanel.screen)
            readonly property real monitorWidth: hyprMonitor?.width ?? 1920
            readonly property real monitorHeight: hyprMonitor?.height ?? 1080
            readonly property real monitorScale: hyprMonitor?.scale ?? 1

            readonly property real bgPadding: 16
            readonly property real gridSpacing: Vars.spacingMedium

            Timer {
                id: grabDelayTimer
                interval: 50
                running: false
            }

            Connections {
                target: overviewContainer
                function onVisibleStateChanged() {
                    if (overviewContainer.visibleState) {
                        grabDelayTimer.restart();
                    } else {
                        grabDelayTimer.stop();
                    }
                }
            }

            HyprlandFocusGrab {
                id: focusGrab
                windows: [libraryPanel]
                active: !grabDelayTimer.running && (overviewContainer.visibleState || libraryPanel.isAnimating)
                onCleared: {
                    if (overviewContainer.visibleState && !grabDelayTimer.running)
                        overviewContainer.closeRequested();
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                MouseArea {
                    anchors.fill: parent
                    onClicked: overviewContainer.closeRequested()
                }
            }

            Primitives.SquircleMask {
                id: panelBackground
                property bool isBackgroundActive: overviewContainer.visibleState || (MorphState.openCount === 0 && MorphState.activeItem === panelBackground && panelBackground.width > 105)
                layer.enabled: true
                layer.smooth: true
                layer.samples: Vars.layerSamples
                
                // x/y are computed as one atomic expression per axis instead of six independently
                // toggled anchor lines plus four margin lines, so a pillPosition change can't
                // leave this item part-anchored to the old edge while the other axis has already
                // moved to the new one (that mismatch is what made expanded popups fail to
                // render their content after a live position change).
                property real activeMargin: (Vars.panelStyle === "Flat" || Vars.panelStyle === "Attached") ? 0 : Vars.spacingSmall
                x: {
                    if (Vars.pillPosition === "Left") return activeMargin;
                    if (Vars.pillPosition === "Right") return parent.width - width - activeMargin;
                    return (parent.width - width) / 2;
                }
                y: {
                    if (Vars.pillPosition === "Bottom") return parent.height - height - activeMargin;
                    if (Vars.pillPosition === "Left" || Vars.pillPosition === "Right") return (parent.height - height) / 2;
                    return activeMargin;
                }

                property var gamesArray: libraryPanel.parseGames(libraryPanel.gameListText)
                property int actualItems: gamesArray.length
                property int cols: Math.max(1, Math.min(actualItems > 0 ? actualItems : 1, Vars.gameLibraryColumns ?? 4))
                property int actualRows: Math.ceil((actualItems > 0 ? actualItems : 1) / cols)
                property int rows: Math.max(1, Math.min(actualRows, Vars.gameLibraryRows ?? 2))
                
                property real itemW: 150 * (Vars.gameLibraryScale ?? 1.0)
                property real itemH: 225 * (Vars.gameLibraryScale ?? 1.0)
                
                property real calcWidth: (cols * itemW) + (Math.max(0, cols - 1) * libraryPanel.gridSpacing)
                property real calcHeight: (rows * itemH) + (Math.max(0, rows - 1) * libraryPanel.gridSpacing)

                property real targetWidth: calcWidth + libraryPanel.bgPadding * 2
                property real targetHeight: calcHeight + libraryPanel.bgPadding * 2
                
                property real innerMaxWidth: parent.width - (2 * Vars.spacingSmall)
                property bool touchesEdges: false

                width: overviewContainer.visibleState ? (touchesEdges ? innerMaxWidth : targetWidth) : (MorphState.anyExpanded ? MorphState.targetWidth : 100)
                height: overviewContainer.visibleState ? targetHeight : (MorphState.anyExpanded ? MorphState.targetHeight : 40)
                
                onTargetHeightChanged: {
                    if (overviewContainer.visibleState) MorphState.updateDimensions(panelBackground.targetWidth, panelBackground.targetHeight, panelBackground.defaultRadius);
                }
                
                onTargetWidthChanged: {
                    if (overviewContainer.visibleState) MorphState.updateDimensions(panelBackground.targetWidth, panelBackground.targetHeight, panelBackground.defaultRadius);
                }

                property real defaultRadius: overviewContainer.visibleState ? Vars.radiusExtraLarge : (MorphState.anyExpanded ? MorphState.targetRadius : height / 2)
                property real innerFrameRadius: Math.max(0, Vars.radiusExtraLarge - Vars.spacingSmall)

                topLeftRadius: touchesEdges ? innerFrameRadius : Vars.getTopLeftRadius(Vars.panelStyle, Vars.pillPosition, false, defaultRadius)
                topRightRadius: touchesEdges ? innerFrameRadius : Vars.getTopRightRadius(Vars.panelStyle, Vars.pillPosition, false, defaultRadius)
                bottomLeftRadius: touchesEdges ? 0 : Vars.getBottomLeftRadius(Vars.panelStyle, Vars.pillPosition, false, defaultRadius)
                bottomRightRadius: touchesEdges ? 0 : Vars.getBottomRightRadius(Vars.panelStyle, Vars.pillPosition, false, defaultRadius)

                color: Vars.tColorActive(isBackgroundActive, Theme.surface, Vars.panelOpacity)
                
                opacity: isBackgroundActive || expandedUI.opacity > 0 ? 1.0 : 0.0

                Behavior on width {
                    enabled: !overviewContainer.gameMode
                    NumberAnimation {
                        id: wAnim
                        duration: Vars.animationDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Vars.customExpressiveSpatialSlow
                    }
                }
                Behavior on height {
                    enabled: !overviewContainer.gameMode
                    NumberAnimation {
                        id: hAnim
                        duration: Vars.animationDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Vars.customExpressiveSpatialSlow
                    }
                }

                Behavior on color {
                    enabled: !overviewContainer.gameMode
                    ColorAnimation {
                        duration: Vars.animationDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Vars.customExpressiveSpatialSlow
                    }
                }

                Item {
                    id: expandedUI
                    anchors.fill: parent

                    opacity: overviewContainer.visibleState ? 1.0 : 0.0
                    visible: opacity > 0
                    clip: true
                    Behavior on opacity {
                        enabled: !overviewContainer.gameMode
                        NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.getFadeCurve(overviewContainer.visibleState) }
                    }


                    Flickable {
                        id: libraryScrollView
                        anchors.centerIn: parent
                        width: gridLayout.implicitWidth
                        height: parent.height - (libraryPanel.bgPadding * 2)
                        contentWidth: gridLayout.implicitWidth
                        contentHeight: gridLayout.implicitHeight
                        clip: true
                        maximumFlickVelocity: Vars.maximumFlickVelocity

                        NumberAnimation {
                            id: scrollAnim
                            target: libraryScrollView
                            property: "contentY"
                            duration: Vars.animationDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Vars.customExpressiveSpatialSlow
                        }

                        GridLayout {
                            id: gridLayout
                            columns: Vars.gameLibraryColumns ?? 4
                            // Do not set rows, so it wraps naturally
                            columnSpacing: libraryPanel.gridSpacing
                            rowSpacing: libraryPanel.gridSpacing

                        Repeater {
                            model: libraryPanel.parseGames(libraryPanel.gameListText)
                            
                            delegate: Item {
                                implicitWidth: 150 * (Vars.gameLibraryScale ?? 1.0)
                                implicitHeight: 225 * (Vars.gameLibraryScale ?? 1.0)
                                width: implicitWidth
                                height: implicitHeight
                                Layout.preferredWidth: implicitWidth
                                Layout.preferredHeight: implicitHeight
                                
                                Primitives.SquircleMask {
                                    id: clipMaskShape
                                    anchors.fill: parent
                                    topLeftRadius: Vars.radiusMedium
                                    topRightRadius: Vars.radiusMedium
                                    bottomLeftRadius: Vars.radiusMedium
                                    bottomRightRadius: Vars.radiusMedium
                                    color: "black"
                                    visible: true // Hidden by ShaderEffectSource
                                }

                                ShaderEffectSource {
                                    id: clipMask
                                    sourceItem: clipMaskShape
                                    anchors.fill: parent
                                    hideSource: true
                                    visible: false
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Vars.radiusMedium
                                    antialiasing: true
                                    color: Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.05)
                                    visible: modelData.banner === ""
                                }

                                Image {
                                    id: gameImage
                                    anchors.fill: parent
                                    source: modelData.banner ? "file://" + modelData.banner : ""
                                    fillMode: Image.PreserveAspectCrop
                                    visible: false // Drawn by MultiEffect
                                    asynchronous: true
                                    cache: false
                                }

                                MultiEffect {
                                    source: gameImage
                                    anchors.fill: parent
                                    maskEnabled: true
                                    maskSource: clipMask
                                    visible: modelData.banner !== ""
                                }

                                    QsText {
                                        anchors.centerIn: parent
                                        width: parent.width - 16
                                        wrapMode: Text.Wrap
                                        horizontalAlignment: Text.AlignHCenter
                                        text: modelData.name
                                        color: Theme.on_surface
                                        font.family: Vars.fontFamily
                                        font.pixelSize: 14
                                        setWeight: 600
                                        visible: modelData.banner === ""
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Vars.radiusMedium
                                        antialiasing: true
                                        color: Theme.on_surface
                                        opacity: keyboardFocusHandler.selectedIndex === index ? 0.15 : 0
                                        Behavior on opacity { NumberAnimation { duration: 150 } }
                                    }
                                    
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Vars.radiusMedium
                                        antialiasing: true
                                        color: "transparent"
                                        border.color: Theme.on_surface
                                        border.width: 2
                                        opacity: keyboardFocusHandler.selectedIndex === index ? 0.6 : 0
                                        Behavior on opacity { NumberAnimation { duration: 150 } }
                                    }

                                    Item {
                                        anchors.fill: parent
                                        visible: overviewContainer.loadingGameId === modelData.id
                                        Rectangle {
                                            anchors.fill: parent
                                            radius: Vars.radiusMedium
                                            antialiasing: true
                                            color: Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.7)
                                        }
                                        Primitives.LoadingIndicator {
                                            anchors.centerIn: parent
                                            width: 48
                                            height: 48
                                            running: overviewContainer.loadingGameId === modelData.id
                                        }
                                    }

                                    MouseArea {
                                        id: itemMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: keyboardFocusHandler.selectedIndex = index
                                        onClicked: {
                                            overviewContainer.loadingGameId = modelData.id;
                                            Quickshell.execDetached({ command: ["bash", "-c", "steam -silent & sleep 2 && xdg-open steam://rungameid/" + modelData.id] });
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Steam FAB
                    Rectangle {
                        width: 56
                        height: 56
                        radius: 28
                        antialiasing: true
                        color: Theme.primary
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.margins: Vars.paddingMedium
                        
                        Image {
                            anchors.centerIn: parent
                            width: 28
                            height: 28
                            source: "image://icon/steam"
                            fillMode: Image.PreserveAspectFit
                            cache: false
                        }
                        
                        Rectangle {
                            anchors.fill: parent
                            radius: 28
                            antialiasing: true
                            color: Theme.on_primary
                            opacity: fabMouse.containsMouse ? 0.12 : 0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                        
                        MouseArea {
                            id: fabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Quickshell.execDetached({ command: ["steam"] });
                                overviewContainer.closeRequested();
                            }
                        }
                    }
                }
            }

            // === FRAME CORNERS ===
            InvertedCorner {
                anchors.top: panelBackground.top
                anchors.right: panelBackground.left
                side: "left"
                visible: Vars.panelStyle === "Attached" && panelBackground.opacity > 0 && (!Vars.pillPosition || Vars.pillPosition === "Top")
                color: panelBackground.color
                opacity: panelBackground.opacity
                radius: Math.max(0, Math.min(Vars.radiusExtraLarge, Math.min(panelBackground.width, panelBackground.height) / 2))
                antialiasing: true
            }

            InvertedCorner {
                anchors.top: panelBackground.top
                anchors.left: panelBackground.right
                side: "right"
                visible: Vars.panelStyle === "Attached" && panelBackground.opacity > 0 && (!Vars.pillPosition || Vars.pillPosition === "Top")
                color: panelBackground.color
                opacity: panelBackground.opacity
                radius: Math.max(0, Math.min(Vars.radiusExtraLarge, Math.min(panelBackground.width, panelBackground.height) / 2))
                antialiasing: true
            }

            InvertedCorner {
                anchors.bottom: panelBackground.bottom
                anchors.right: panelBackground.left
                side: "bottom-right"
                visible: Vars.panelStyle === "Attached" && panelBackground.opacity > 0 && Vars.pillPosition === "Bottom"
                color: panelBackground.color
                opacity: panelBackground.opacity
                radius: Math.max(0, Math.min(Vars.radiusExtraLarge, Math.min(panelBackground.width, panelBackground.height) / 2))
                antialiasing: true
            }

            InvertedCorner {
                anchors.bottom: panelBackground.bottom
                anchors.left: panelBackground.right
                side: "bottom-left"
                visible: Vars.panelStyle === "Attached" && panelBackground.opacity > 0 && Vars.pillPosition === "Bottom"
                color: panelBackground.color
                opacity: panelBackground.opacity
                radius: Math.max(0, Math.min(Vars.radiusExtraLarge, Math.min(panelBackground.width, panelBackground.height) / 2))
                antialiasing: true
            }

            InvertedCorner {
                anchors.bottom: panelBackground.top
                anchors.left: panelBackground.left
                side: "bottom-left"
                visible: Vars.panelStyle === "Attached" && panelBackground.opacity > 0 && Vars.pillPosition === "Left"
                color: panelBackground.color
                opacity: panelBackground.opacity
                radius: Math.max(0, Math.min(Vars.radiusExtraLarge, Math.min(panelBackground.width, panelBackground.height) / 2))
                antialiasing: true
            }

            InvertedCorner {
                anchors.top: panelBackground.bottom
                anchors.left: panelBackground.left
                side: "top-left"
                visible: Vars.panelStyle === "Attached" && panelBackground.opacity > 0 && Vars.pillPosition === "Left"
                color: panelBackground.color
                opacity: panelBackground.opacity
                radius: Math.max(0, Math.min(Vars.radiusExtraLarge, Math.min(panelBackground.width, panelBackground.height) / 2))
                antialiasing: true
            }

            InvertedCorner {
                anchors.bottom: panelBackground.top
                anchors.right: panelBackground.right
                side: "bottom-right"
                visible: Vars.panelStyle === "Attached" && panelBackground.opacity > 0 && Vars.pillPosition === "Right"
                color: panelBackground.color
                opacity: panelBackground.opacity
                radius: Math.max(0, Math.min(Vars.radiusExtraLarge, Math.min(panelBackground.width, panelBackground.height) / 2))
                antialiasing: true
            }

            InvertedCorner {
                anchors.top: panelBackground.bottom
                anchors.right: panelBackground.right
                side: "top-right"
                visible: Vars.panelStyle === "Attached" && panelBackground.opacity > 0 && Vars.pillPosition === "Right"
                color: panelBackground.color
                opacity: panelBackground.opacity
                radius: Math.max(0, Math.min(Vars.radiusExtraLarge, Math.min(panelBackground.width, panelBackground.height) / 2))
                antialiasing: true
            }
            
            property string gameListText: "[]"
            
            Process {
                id: gameListLoader
                command: ["cat", Quickshell.env("HOME") + "/.cache/quickshell/steam_games.json"]
                running: true
                stdout: StdioCollector {
                    onStreamFinished: {
                        libraryPanel.gameListText = this.text;
                    }
                }
            }
            
            Item {
                id: keyboardFocusHandler
                anchors.fill: parent
                focus: overviewContainer.visibleState
                property int selectedIndex: 0
                
                Connections {
                    target: overviewContainer
                    function onVisibleStateChanged() {
                        if (overviewContainer.visibleState) {
                            keyboardFocusHandler.selectedIndex = 0;
                            vimKeysChecker.running = true;
                        }
                    }
                }
                
                onSelectedIndexChanged: {
                    let itemH = panelBackground.itemH;
                    let spacing = libraryPanel.gridSpacing;
                    let row = Math.floor(selectedIndex / panelBackground.cols);
                    let itemTop = row * (itemH + spacing);
                    let itemBottom = itemTop + itemH;
                    
                    let targetY = libraryScrollView.contentY;
                    if (itemTop < libraryScrollView.contentY) {
                        targetY = itemTop;
                    } else if (itemBottom > libraryScrollView.contentY + libraryScrollView.height) {
                        targetY = itemBottom - libraryScrollView.height;
                    }
                    if (targetY !== libraryScrollView.contentY) {
                        scrollAnim.to = targetY;
                        scrollAnim.restart();
                    }
                }

                Keys.onPressed: event => {
                    let cols = panelBackground.cols;
                    let maxIndex = libraryPanel.parseGames(libraryPanel.gameListText).length - 1;

                    if (event.key === Qt.Key_Escape) {
                        overviewContainer.closeRequested();
                        event.accepted = true;
                        return;
                    }

                    if (maxIndex < 0) return;

                    if (event.key === Qt.Key_Right || (overviewContainer.vimKeysEnabled && (event.key === Qt.Key_L || event.key === Qt.Key_F))) {
                        if (selectedIndex < maxIndex) selectedIndex++;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Left || (overviewContainer.vimKeysEnabled && (event.key === Qt.Key_H || event.key === Qt.Key_A))) {
                        if (selectedIndex > 0) selectedIndex--;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Down || (overviewContainer.vimKeysEnabled && (event.key === Qt.Key_J || event.key === Qt.Key_S))) {
                        if (selectedIndex + cols <= maxIndex) selectedIndex += cols;
                        else selectedIndex = maxIndex;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Up || (overviewContainer.vimKeysEnabled && (event.key === Qt.Key_K || event.key === Qt.Key_D))) {
                        if (selectedIndex - cols >= 0) selectedIndex -= cols;
                        else selectedIndex = 0;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        if (selectedIndex >= 0 && selectedIndex <= maxIndex) {
                            let games = libraryPanel.parseGames(libraryPanel.gameListText);
                            let modelData = games[selectedIndex];
                            if (modelData) {
                                overviewContainer.loadingGameId = modelData.id;
                                Quickshell.execDetached({ command: ["bash", "-c", "steam -silent & sleep 2 && xdg-open steam://rungameid/" + modelData.id] });
                            }
                        }
                        event.accepted = true;
                    }
                }
            }
        }
    }
}
