import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import "../../theme"
import "../../core/primitives" as Primitives
import "../.."
import QtQuick.Effects
import QtQuick.Shapes

Rectangle {
    id: mediaPlayerRoot

    FontLoader {
        id: filledIconFont
        source: "../../theme/assets/MaterialSymbolsRounded-Filled.ttf"
    }

    property var preferredMprisPlayer: null
    property var mprisPlayer: {
        let vals = Mpris.players.values;
        if (vals.length === 0)
            return null;
        if (preferredMprisPlayer && vals.indexOf(preferredMprisPlayer) !== -1) {
            return preferredMprisPlayer;
        }
        return vals[0];
    }
    property bool isPlaying: mprisPlayer ? mprisPlayer.isPlaying : false
    // A card inside the Control Center, which is itself a surface_container panel. The desktop
    // widget sets this to the surface every desktop widget shares.
    property color cardColor: Theme.surface_container_highest

    property string currentMediaPlayerShape: Vars.mediaPlayerShape !== undefined ? Vars.mediaPlayerShape : "12SidedCookie"
    property real currentMediaPlayerArtScale: Vars.mediaPlayerArtScale !== undefined ? Vars.mediaPlayerArtScale : 1.0

    property real currentMediaPlayerArtOffsetX: Vars.mediaPlayerArtOffsetX !== undefined ? Vars.mediaPlayerArtOffsetX : 0
    property real currentMediaPlayerArtOffsetY: Vars.mediaPlayerArtOffsetY !== undefined ? Vars.mediaPlayerArtOffsetY : 0
    property alias playerDropdownVisible: playerDropdown.visible

    function updateDropdownPosition() {
        if (playerDropdown.visible && typeof playerSelectorPill !== 'undefined' && playerSelectorPill !== null) {
            var p = playerSelectorPill.mapToItem(mediaPlayerRoot, 0, 0);
            playerDropdown.x = Math.max(8, Math.min(mediaPlayerRoot.width - playerDropdown.width - 8, p.x - (playerDropdown.width - playerSelectorPill.width)));
            var dropHeight = playerDropdown.height;
            if (p.y + playerSelectorPill.height + 8 + dropHeight > mediaPlayerRoot.height || p.y > mediaPlayerRoot.height / 2) {
                playerDropdown.y = Math.max(8, p.y - dropHeight - 8);
            } else {
                playerDropdown.y = p.y + playerSelectorPill.height + 8;
            }
        }
    }

    property bool forceVerticalExpansion: false
    property bool isExpanded: false
    property string lyricsText: ""
    property bool isLoadingLyrics: false
    property string currentLyricsTrack: ""
    property bool isVertical: Vars.mediaPlayerOrientation === "Vertical"
    property bool isHorizontalExpansion: !forceVerticalExpansion && !isVertical && Vars.mediaPlayerLyricsExpansion === "Horizontal"
    property var syncedLyricsLines: []
    property int currentLyricIndex: -1
    property bool hasSyncedLyrics: false
    // While true, the synced-lyrics list is released from its playback-locked scroll range so a
    // manual wheel/drag can actually reach the list's real bounds and hand scrolling off to the
    // panel below (otherwise the view, centered on the current line, never hits a bound and
    // swallows every scroll gesture, trapping the user on top of the expanded player).
    property bool lyricsManualScroll: false

    function parseSyncedLyrics(lrcText) {
        var lines = lrcText.split("\n");
        var parsed = [];
        var regex = /\[(\d{1,3}):(\d{1,2})(?:\.(\d{1,3}))?\](.*)/;
        for (var i = 0; i < lines.length; i++) {
            var match = regex.exec(lines[i]);
            if (match) {
                var min = parseInt(match[1]) || 0;
                var sec = parseInt(match[2]) || 0;
                var msStr = match[3] || "0";
                var ms = parseInt(msStr);
                if (msStr.length === 1) ms *= 100;
                else if (msStr.length === 2) ms *= 10;
                var timeInSec = min * 60 + sec + ms / 1000.0;
                parsed.push({ time: timeInSec, text: match[4].trim() });
            }
        }
        syncedLyricsLines = parsed;
        hasSyncedLyrics = parsed.length > 0;
    }

    property bool autoScrollLyrics: Vars.mediaPlayerLyricsAutoScroll !== undefined ? Vars.mediaPlayerLyricsAutoScroll : true

    function cleanTrackTitle(title) {
        if (!title) return "";
        return title
            .replace(/\s*\(feat\..*?\)/gi, "")
            .replace(/\s*\[feat\..*?\]/gi, "")
            .replace(/\s*\(ft\..*?\)/gi, "")
            .replace(/\s*\[ft\..*?\]/gi, "")
            .replace(/\s*\(remastered.*?\)/gi, "")
            .replace(/\s*\[remastered.*?\]/gi, "")
            .replace(/\s*\(live.*?\)/gi, "")
            .replace(/\s*\[live.*?\]/gi, "")
            .replace(/\s*\(official.*?\)/gi, "")
            .replace(/\s*\[official.*?\]/gi, "")
            .replace(/\s*-\s*remastered.*/gi, "")
            .replace(/\s*-\s*live.*/gi, "")
            .replace(/\s*-\s*single.*/gi, "")
            .replace(/\s*-\s*ep.*/gi, "")
            .trim();
    }

    function fetchLyrics(artist, title) {
        if (!artist || !title) return;
        var queryTrack = artist + " - " + title;
        if (currentLyricsTrack === queryTrack) return;
        
        currentLyricsTrack = queryTrack;
        isLoadingLyrics = true;
        lyricsText = "Loading lyrics...";
        hasSyncedLyrics = false;
        syncedLyricsLines = [];
        
        var cleanedTitle = cleanTrackTitle(title);

        var cmdArray = ["lyrics-fetcher", artist, cleanedTitle || title, "--raw"];
        var cmd = JSON.stringify(cmdArray);
        var qmlString = 'import QtQuick; import Quickshell.Io; Process { ' +
                        'command: ' + cmd + '; ' +
                        'running: true; ' +
                        'stdout: StdioCollector { ' +
                        '    onStreamFinished: { ' +
                        '        var out = this.text.trim(); ' +
                        '        if (out.length > 0 && !out.startsWith("Error:") && !out.includes("not found")) { ' +
                        '            mediaPlayerRoot.lyricsText = out; ' +
                        '            mediaPlayerRoot.isLoadingLyrics = false; ' +
                        '            mediaPlayerRoot.parseSyncedLyrics(out); ' +
                        '        } else { ' +
                        '            mediaPlayerRoot.lyricsText = "No lyrics found."; ' +
                        '            mediaPlayerRoot.isLoadingLyrics = false; ' +
                        '        } ' +
                        '    } ' +
                        '} ' +
                        'onExited: destroy() ' +
                        '}';
        Qt.createQmlObject(qmlString, mediaPlayerRoot);
    }

    property string currentTrackId: mprisPlayer ? (mprisPlayer.trackArtist + " - " + (mprisPlayer.trackTitle || "")) : ""
    onCurrentTrackIdChanged: {
        if (isExpanded) {
            fetchLyrics(mprisPlayer.trackArtist, mprisPlayer.trackTitle || (mprisPlayer.metadata ? mprisPlayer.metadata["xesam:title"] : ""));
        }
    }

    onIsExpandedChanged: {
        if (isExpanded) {
            fetchLyrics(mprisPlayer ? mprisPlayer.trackArtist : "", mprisPlayer ? (mprisPlayer.trackTitle || (mprisPlayer.metadata ? mprisPlayer.metadata["xesam:title"] : "")) : "");
        }
    }

    Timer {
        interval: 100
        repeat: true
        running: mprisPlayer && mprisPlayer.isPlaying && isExpanded && hasSyncedLyrics && autoScrollLyrics
        onTriggered: {
            if (!mprisPlayer || !hasSyncedLyrics) return;
            var posSec = mprisPlayer.position / timeScale;
            var newIndex = -1;
            for (var i = 0; i < syncedLyricsLines.length; i++) {
                if (posSec >= syncedLyricsLines[i].time) {
                    newIndex = i;
                } else {
                    break;
                }
            }
            if (newIndex !== currentLyricIndex) {
                currentLyricIndex = newIndex;
            }
        }
    }

    Layout.fillWidth: isExpanded && isHorizontalExpansion ? false : true
    Layout.preferredWidth: isExpanded && isHorizontalExpansion ? 900 : -1
    Layout.preferredHeight: isExpanded && !isHorizontalExpansion ? 650 : (isVertical ? 300 : 180)
    Behavior on Layout.preferredHeight {
        NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutCubic }
    }
    Behavior on Layout.preferredWidth {
        NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutCubic }
    }
    color: "transparent"

    Primitives.SquircleMask {
        id: rootMaskShape
        anchors.fill: parent
        property real targetRad: 32
        topLeftRadius: targetRad
        topRightRadius: targetRad
        bottomLeftRadius: targetRad
        bottomRightRadius: targetRad
        color: "black"
        visible: true // Keep visible true, hide via ShaderEffectSource
        antialiasing: true
        smooth: true
    }

    ShaderEffectSource {
        id: rootMask
        sourceItem: rootMaskShape
        anchors.fill: parent
        hideSource: true
        visible: false
        // Supersampled so the rounded-corner mask the MultiEffects below cut against has more
        // antialiasing to work with than a flat 1:1 capture would give them.
        textureSize: Qt.size(width * 2, height * 2)
        smooth: true
    }

    // Background Image
    Image {
        id: bgArt
        anchors.fill: parent
        source: mprisPlayer && mprisPlayer.trackArtUrl ? mprisPlayer.trackArtUrl : ""
        fillMode: Image.PreserveAspectCrop
        visible: false
    }

    Item {
        id: combinedBackground
        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true
        layer.samples: Vars.layerSamples
        visible: false

        // Base background for when there is no album art or in opaque mode
        Rectangle {
            anchors.fill: parent
            color: Vars.tColor(mediaPlayerRoot.cardColor, Vars.componentOpacity)
            visible: bgArt.source === "" || !Vars.isTranslucent()
        }

        // Stage 1: Blur the background image
        Item {
            id: blurredBgLayer
            anchors.fill: parent
            layer.enabled: true
            layer.smooth: true
            layer.samples: Vars.layerSamples
            layer.effect: MultiEffect {
                blurEnabled: true
                blurMax: Vars.blurAmount
                blur: 1.0
                saturation: 1.2
                autoPaddingEnabled: false
            }
            visible: bgArt.source !== "" && Vars.isTranslucent()

            Image {
                anchors.fill: parent
                source: bgArt.source
                fillMode: Image.PreserveAspectCrop
            }
        }

        // Overlay for when album art is present to ensure text readability
        Rectangle {
            anchors.fill: parent
            color: mediaPlayerRoot.cardColor
            opacity: Vars.isTranslucent() ? (Vars.componentOpacity * 0.8) : 0.85
            visible: bgArt.source !== "" && Vars.isTranslucent()
        }
    }

    // Stage 2: Mask the combined background to perfectly fit the rounded corners
    Item {
        anchors.fill: parent

        MultiEffect {
            anchors.fill: parent
            source: combinedBackground
            maskEnabled: true
            maskSource: rootMask
            // A soft threshold spread antialiases the mask edge instead of cutting it off as a
            // hard binary step, which otherwise looks jagged on the rounded corners.
            maskThresholdMin: 0.5
            maskSpreadAtMin: 0.1
        }
    }

    property int slideDirection: 1

    property real timeScale: {
        if (!mprisPlayer) return 1000000;
        if (mprisPlayer.length > 10000000) return 1000000;
        if (mprisPlayer.length > 10000) return 1000;
        if (mprisPlayer.length > 0) return 1;
        if (mprisPlayer.position > 10000000) return 1000000;
        if (mprisPlayer.position > 10000) return 1000;
        return 1000000;
    }

    function formatTime(val) {
        if (isNaN(val) || val <= 0)
            return "0:00";
        let totalSeconds = Math.floor(val / timeScale);
        let mins = Math.floor(totalSeconds / 60);
        let secs = Math.floor(totalSeconds % 60);
        return mins + ":" + (secs < 10 ? "0" : "") + secs;
    }

    Timer {
        interval: 1000
        repeat: true
        running: mprisPlayer && mprisPlayer.isPlaying
        onTriggered: {
            if (mprisPlayer && typeof mprisPlayer.positionChanged === "function") {
                mprisPlayer.positionChanged();
            }
        }
    }

    Item {
        id: contentLayer
        anchors.fill: parent
        layer.enabled: true
        layer.smooth: true
        layer.samples: Vars.layerSamples
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: rootMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 0.1
        }

        GridLayout {
            anchors.fill: parent
            anchors.margins: 16
            rowSpacing: 16
            columnSpacing: 16
            columns: (isExpanded && isHorizontalExpansion) ? 2 : 1

            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: isExpanded && isHorizontalExpansion
                columnSpacing: 16
                rowSpacing: 16
                columns: isVertical ? 1 : 2

                // Left: Album Art with upward glow
                Item {
                    Layout.preferredWidth: 148
                    Layout.preferredHeight: 148
                    Layout.alignment: isVertical ? Qt.AlignHCenter : Qt.AlignVCenter

                Item {
                    id: albumArtContainer
                    width: parent.width
                    height: parent.height
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: mediaPlayerRoot.currentMediaPlayerArtOffsetX
                    anchors.verticalCenterOffset: mediaPlayerRoot.currentMediaPlayerArtOffsetY
                    
                    Behavior on anchors.horizontalCenterOffset {
                        NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard }
                    }
                    Behavior on anchors.verticalCenterOffset {
                        NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard }
                    }

                    scale: mediaPlayerRoot.currentMediaPlayerArtScale
                    Behavior on scale {
                        NumberAnimation {
                            duration: Vars.animationDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Vars.customStandard
                        }
                    }

                M3Shapes {
                    id: m3
                }

                Item {
                    id: maskContainer
                    anchors.fill: parent
                    visible: false
                    layer.enabled: true
                    layer.samples: Vars.layerSamples
                    layer.smooth: true
                    layer.textureSize: Qt.size(width * Math.max(1, mediaPlayerRoot.currentMediaPlayerArtScale) * 2, height * Math.max(1, mediaPlayerRoot.currentMediaPlayerArtScale) * 2)

                    Item {
                        id: rotationWrapper
                        anchors.centerIn: parent
                        property real scaleFactor: Math.min(4, 4096 / Math.max(parent.width, parent.height, 1))
                        width: parent.width * scaleFactor
                        height: parent.height * scaleFactor
                        scale: 1.0 / scaleFactor

                        RotationAnimation {
                            target: rotationWrapper
                            property: "rotation"
                            from: 0
                            to: 360
                            duration: 10000
                            loops: Animation.Infinite
                            running: mprisPlayer && mprisPlayer.isPlaying
                        }

                        Image {
                            id: maskImage
                            anchors.fill: parent
                            sourceSize.width: width
                            sourceSize.height: height
                            
                            property string currentPathName: mediaPlayerRoot.currentMediaPlayerShape
                            property string currentPath: m3.getPath(currentPathName)

                            source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='" + currentPath + "' fill='white'/></svg>"
                            smooth: true
                            antialiasing: true
                            mipmap: true

                            onCurrentPathNameChanged: {
                                if (maskImage.status === Image.Ready) {
                                    shapeAnim.restart();
                                }
                            }

                            SequentialAnimation {
                                id: shapeAnim
                                NumberAnimation {
                                    target: maskImage
                                    property: "scale"
                                    to: 0.01
                                    duration: 250
                                    easing.type: Easing.InBack
                                }
                                NumberAnimation {
                                    target: maskImage
                                    property: "scale"
                                    to: 1.0
                                    duration: 550
                                    easing.type: Easing.OutElastic
                                }
                            }
                        }
                    }
                }

                Item {
                    id: albumContent
                    anchors.fill: parent
                    visible: false
                    layer.enabled: true
                    layer.samples: Vars.layerSamples
                    layer.smooth: true
                    layer.textureSize: Qt.size(width * Math.max(1, mediaPlayerRoot.currentMediaPlayerArtScale) * 2, height * Math.max(1, mediaPlayerRoot.currentMediaPlayerArtScale) * 2)

                    // Fallback icon
                    Rectangle {
                        anchors.fill: parent
                        color: Vars.tColor(Theme.surface_container, Vars.componentOpacity)
                        visible: !mprisPlayer || !mprisPlayer.trackArtUrl

                        QsText {
                            anchors.centerIn: parent
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 48
                            antialiasing: true
                            renderType: Text.QtRendering
                            font.hintingPreference: Font.PreferNoHinting
                            color: Theme.on_surface_variant
                            text: "\ue405"
                        }
                    }

                    Image {
                        id: albumImage
                        anchors.fill: parent
                        source: mprisPlayer && mprisPlayer.trackArtUrl ? mprisPlayer.trackArtUrl : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: albumImage.source !== ""
                        antialiasing: true
                        smooth: true
                        mipmap: true
                    }
                }

                MultiEffect {
                    source: albumContent
                    anchors.fill: parent
                    maskEnabled: true
                    maskSource: maskContainer
                    antialiasing: true
                    smooth: true
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                    maskSpreadAtMax: 0.0
                    maskThresholdMax: 1.0
                }
                }
            }

        // Right: Metadata and Controls
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Top section: Titles and Play Button
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Metadata Column
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Layout.alignment: Qt.AlignTop

                    QsText {
                        text: mprisPlayer ? (mprisPlayer.trackTitle || (mprisPlayer.metadata ? mprisPlayer.metadata["xesam:title"] : null) || mprisPlayer.identity || "Unknown Title") : "No Media Playing"
                        font.family: Vars.fontFamily
                        font.pixelSize: 18
                        setWeight: 700
                        color: Theme.on_surface
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    QsText {
                        text: mprisPlayer && mprisPlayer.trackArtist ? mprisPlayer.trackArtist : "Artist"
                        font.family: Vars.fontFamily
                        font.pixelSize: 14
                        color: Theme.on_surface_variant
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    Item {
                        Layout.preferredHeight: 4
                    } // Spacer

                    QsText {
                        text: formatTime(mprisPlayer ? mprisPlayer.position : 0) + " / " + formatTime(mprisPlayer ? mprisPlayer.length : 0)
                        font.family: Vars.fontFamily
                        font.pixelSize: 13
                        color: Theme.on_surface_variant
                    }
                }

                // Player Selector and Play/Pause Button
                RowLayout {
                    Layout.alignment: Qt.AlignBottom | Qt.AlignRight
                    spacing: 12 // Reverted spacing

                    // Player Selector Pill
                    Rectangle {
                        id: playerSelectorPill
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: playerSelectorRow.implicitWidth + 24
                        Layout.preferredHeight: 36
                        Layout.minimumWidth: Layout.preferredWidth
                        radius: 18
                        antialiasing: true
                        // Tonal, so play/pause stays the one filled primary action on the card
                        color: Theme.secondary_container
                        visible: Mpris.players.values.length > 1

                        RowLayout {
                            id: playerSelectorRow
                            anchors.centerIn: parent
                            spacing: 4
                            QsText {
                                text: mprisPlayer ? (mprisPlayer.identity || "Unknown") : "Player"
                                font.family: Vars.fontFamily
                                font.pixelSize: 14
                                color: Theme.on_secondary_container
                                setWeight: 600
                            }
                            QsText {
                                font.family: "Material Symbols Rounded"
                                font.pixelSize: 20
                                antialiasing: true
                                renderType: Text.QtRendering
                                font.hintingPreference: Font.PreferNoHinting
                                color: Theme.on_secondary_container
                                setWeight: 700
                                text: "\ue5cf" // expand_more
                            }
                        }
                        MouseArea {
                            id: playerSelectorMouse
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: playerDropdown.visible = !playerDropdown.visible
                        }
                    }

                    // Play/Pause Button
                    Rectangle {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: 52
                        Layout.preferredHeight: 52
                        Layout.minimumWidth: 52
                        radius: 18
                        antialiasing: true
                        color: Theme.primary

                        QsText {
                            anchors.centerIn: parent
                            font.family: filledIconFont.name
                            font.pixelSize: 28
                            antialiasing: true
                            renderType: Text.QtRendering
                            font.hintingPreference: Font.PreferNoHinting
                            color: Theme.on_primary
                            text: mprisPlayer && mprisPlayer.isPlaying ? "\ue034" : "\ue037" // pause : play_arrow
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (mprisPlayer) {
                                if (typeof mprisPlayer.togglePlaying === "function")
                                    mprisPlayer.togglePlaying();
                                else if (typeof mprisPlayer.playPause === "function")
                                    mprisPlayer.playPause();
                            }
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            } // pushes bottom controls down

            // Bottom Section: Progress and Prev/Next
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                Layout.alignment: Qt.AlignBottom

                // Previous
                QsText {
                    font.family: filledIconFont.name
                    font.pixelSize: 26
                    antialiasing: true
                    renderType: Text.QtRendering
                    font.hintingPreference: Font.PreferNoHinting
                    color: Theme.on_surface_variant
                    text: "\ue045" // skip_previous
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            mediaPlayerRoot.slideDirection = -1;
                            if (mprisPlayer)
                                mprisPlayer.previous();
                        }
                    }
                }

                // Progress Bar Container
                Item {
                    id: progressContainer
                    Layout.fillWidth: true
                    Layout.preferredHeight: 24

                    property bool isDragging: false
                    property real dragRatio: 0
                    property real playRatio: {
                        if (isDragging)
                            return dragRatio;
                        return mprisPlayer && mprisPlayer.length > 0 && mprisPlayer.position !== undefined ? Math.max(0, Math.min(1, mprisPlayer.position / mprisPlayer.length)) : 0;
                    }

                    // Vertical handle (the `|` in the image)
                    Rectangle {
                        id: handle
                        anchors.verticalCenter: parent.verticalCenter
                        x: progressContainer.playRatio * (parent.width - width)
                        width: 2
                        height: 30
                        radius: 1
                        antialiasing: true
                        color: Theme.on_surface
                    }

                    // Squiggly played track
                    Canvas {
                        id: squigglyCanvas
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        width: Math.max(0, handle.x - 6)
                        height: 24
                        renderTarget: Canvas.FramebufferObject
                        antialiasing: true
                        smooth: true
                        layer.enabled: true
                        layer.samples: Vars.layerSamples
                        layer.smooth: true

                        property color waveColor: Theme.primary
                        property real phase: 0

                        NumberAnimation on phase {
                            from: 0
                            to: Math.PI * 2
                            duration: 1500
                            loops: Animation.Infinite
                            running: mprisPlayer && mprisPlayer.isPlaying
                        }

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();
                            ctx.clearRect(0, 0, width, height);
                            if (width <= 0)
                                return;

                            var lw = Vars.mediaPlayerWaveThickness !== undefined ? Vars.mediaPlayerWaveThickness : 2.5;
                            var amplitude = 3;
                            var frequency = 0.25;

                            ctx.beginPath();
                            ctx.lineWidth = lw;
                            ctx.lineCap = "round";
                            ctx.lineJoin = "round";
                            ctx.strokeStyle = waveColor;

                            var pad = lw / 2;
                            var startX = pad;
                            var endX = Math.max(startX, width - pad);

                            for (var x = startX; x <= endX; x += 0.5) {
                                var y = height / 2 + Math.sin(x * frequency - phase) * amplitude;
                                if (x === startX)
                                    ctx.moveTo(x, y);
                                else
                                    ctx.lineTo(x, y);
                            }
                            var finalY = height / 2 + Math.sin(endX * frequency - phase) * amplitude;
                            ctx.lineTo(endX, finalY);

                            ctx.stroke();
                        }

                        onWidthChanged: requestPaint()
                        onWaveColorChanged: requestPaint()
                        onPhaseChanged: requestPaint()
                    }

                    // Unplayed track
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: handle.right
                        anchors.leftMargin: 6
                        anchors.right: parent.right
                        height: 2
                        radius: 1
                        antialiasing: true
                        color: Theme.on_surface_variant

                        // Unplayed part dot (from the image)
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            width: 4
                            height: 4
                            radius: 2
                            antialiasing: true
                            color: Theme.on_surface_variant
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor

                        onPressed: mouse => {
                            progressContainer.isDragging = true;
                            progressContainer.dragRatio = Math.max(0, Math.min(1, mouse.x / width));
                        }

                        onPositionChanged: mouse => {
                            if (pressed) {
                                progressContainer.dragRatio = Math.max(0, Math.min(1, mouse.x / width));
                            }
                        }

                        onReleased: mouse => {
                            if (progressContainer.isDragging) {
                                progressContainer.dragRatio = Math.max(0, Math.min(1, mouse.x / width));
                                progressContainer.isDragging = false;
                                if (mprisPlayer && mprisPlayer.length > 0 && mprisPlayer.canSeek) {
                                    mprisPlayer.position = progressContainer.dragRatio * mprisPlayer.length;
                                }
                            }
                        }
                    }
                }

                // Next
                QsText {
                    font.family: filledIconFont.name
                    font.pixelSize: 26
                    antialiasing: true
                    renderType: Text.QtRendering
                    font.hintingPreference: Font.PreferNoHinting
                    color: Theme.on_surface_variant
                    text: "\ue044" // skip_next
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            mediaPlayerRoot.slideDirection = 1;
                            if (mprisPlayer)
                                mprisPlayer.next();
                        }
                    }
                }
                // Expand Lyrics Button
                QsText {
                    font.family: "Material Symbols Rounded"
                    font.pixelSize: 26
                    antialiasing: true
                    renderType: Text.QtRendering
                    font.hintingPreference: Font.PreferNoHinting
                    color: Theme.on_surface_variant
                    text: mediaPlayerRoot.isExpanded ? "\ue5ce" : "\ue5cf" // expand_less : expand_more
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: mediaPlayerRoot.isExpanded = !mediaPlayerRoot.isExpanded
                    }
                }
            }
        }
    }

    // Lyrics Area
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.preferredWidth: mediaPlayerRoot.isHorizontalExpansion ? 400 : -1
        visible: mediaPlayerRoot.isExpanded
        clip: true
        
        ListView {
            id: lyricsListView
            anchors.fill: parent
            visible: mediaPlayerRoot.hasSyncedLyrics
            model: mediaPlayerRoot.syncedLyricsLines
            clip: true
            spacing: 12

            currentIndex: mediaPlayerRoot.currentLyricIndex
            preferredHighlightBegin: height / 2 - 20
            preferredHighlightEnd: height / 2 + 20
            // StrictlyEnforceRange locks the viewport to the synced currentIndex, so without
            // this override, a manual scroll snaps straight back and the rest of the lyrics
            // are never reachable. Dragging suspends the lock; it resumes a few seconds after
            // the user lets go so the view still catches back up to playback on its own.
            highlightRangeMode: (mediaPlayerRoot.autoScrollLyrics && !mediaPlayerRoot.lyricsManualScroll) ? ListView.StrictlyEnforceRange : ListView.NoHighlightRange
            highlightMoveDuration: Vars.animationDuration

            header: Item { width: lyricsListView.width; height: Math.max(0, lyricsListView.height / 2 - 20) }
            footer: Item { width: lyricsListView.width; height: Math.max(0, lyricsListView.height / 2 - 20) }

            onDraggingChanged: {
                if (dragging) {
                    mediaPlayerRoot.lyricsManualScroll = true;
                    lyricsAutoScrollResumeTimer.stop();
                } else if (!flicking) {
                    lyricsAutoScrollResumeTimer.restart();
                }
            }
            onFlickingChanged: {
                if (!flicking && mediaPlayerRoot.lyricsManualScroll) {
                    lyricsAutoScrollResumeTimer.restart();
                }
            }

            // Plain mouse-wheel scrolling doesn't set dragging/flicking, so it needs its own
            // detection to suspend the playback lock; target: null means it only observes and
            // leaves the Flickable's own wheel handling (and bounds-based propagation) intact.
            WheelHandler {
                target: null
                onWheel: {
                    mediaPlayerRoot.lyricsManualScroll = true;
                    lyricsAutoScrollResumeTimer.restart();
                }
            }

            Timer {
                id: lyricsAutoScrollResumeTimer
                interval: 3000
                onTriggered: mediaPlayerRoot.lyricsManualScroll = false
            }

            Behavior on contentY {
                enabled: mediaPlayerRoot.autoScrollLyrics && !mediaPlayerRoot.lyricsManualScroll && !lyricsListView.dragging && !lyricsListView.flicking
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutCubic
                }
            }
            
            delegate: QsText {
                width: ListView.view.width
                text: modelData.text
                font.family: Vars.fontFamily
                font.pixelSize: (mediaPlayerRoot.autoScrollLyrics && index === mediaPlayerRoot.currentLyricIndex) ? 22 : 16
                setWeight: (mediaPlayerRoot.autoScrollLyrics && index === mediaPlayerRoot.currentLyricIndex) ? 800 : 500
                color: (mediaPlayerRoot.autoScrollLyrics && index === mediaPlayerRoot.currentLyricIndex) ? Theme.on_surface : Theme.on_surface_variant
                opacity: mediaPlayerRoot.autoScrollLyrics ? (index === mediaPlayerRoot.currentLyricIndex ? 1.0 : 0.6) : 0.85
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
                
                Behavior on font.pixelSize { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration } }
            }
        }
        
        Flickable {
            anchors.fill: parent
            visible: !mediaPlayerRoot.hasSyncedLyrics && !mediaPlayerRoot.isLoadingLyrics
            contentWidth: width
            contentHeight: lyricsTextColumn.implicitHeight
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick
            
            Column {
                id: lyricsTextColumn
                width: parent.width
                spacing: 24

                QsText {
                    width: parent.width
                    text: "[ Unsynced Lyrics ]"
                    font.family: Vars.fontFamily
                    font.pixelSize: 14
                    color: Theme.on_surface_variant
                    font.italic: true
                    horizontalAlignment: Text.AlignHCenter
                    visible: mediaPlayerRoot.lyricsText !== "Loading lyrics..." && 
                             mediaPlayerRoot.lyricsText !== "No lyrics found." && 
                             mediaPlayerRoot.lyricsText !== "Error parsing lyrics." && 
                             mediaPlayerRoot.lyricsText !== "Lyrics not found."
                }
                
                QsText {
                    id: lyricsTextElement
                    width: parent.width
                    text: mediaPlayerRoot.lyricsText
                    font.family: Vars.fontFamily
                    font.pixelSize: 16
                    color: Theme.on_surface
                    opacity: 0.85
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Primitives.LoadingIndicator {
            anchors.centerIn: parent
            width: 96
            height: 96
            running: mediaPlayerRoot.isLoadingLyrics
        }
    }
    }
    } // end of contentLayer

    // Backdrop area to dismiss player dropdown when clicking outside
    MouseArea {
        anchors.fill: parent
        z: 95
        enabled: playerDropdown.visible
        visible: enabled
        onClicked: playerDropdown.visible = false
    }

    // MPRIS Player Dropdown
    Item {
        id: playerDropdown
        x: 0
        y: 0
        width: 190
        height: Math.min(Math.max(44, mediaPlayerRoot.height - 24), playerColumn.implicitHeight + 8)
        property real radius: Vars.radiusMedium
        visible: false
        z: 100

        onVisibleChanged: mediaPlayerRoot.updateDropdownPosition()
        onHeightChanged: mediaPlayerRoot.updateDropdownPosition()

        Rectangle {
            id: dropdownMask
            anchors.fill: parent
            radius: playerDropdown.radius
            antialiasing: true
            color: "black"
            visible: false
            layer.enabled: true
            layer.smooth: true
            layer.samples: Vars.layerSamples
        }

        Item {
            id: dropdownShadow
            anchors.fill: parent

            Item {
                id: dropdownFinalMasked
                anchors.fill: parent
                layer.enabled: true
                layer.smooth: true
                layer.samples: Vars.layerSamples
                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: dropdownMask
                }

                Rectangle {
                    anchors.fill: parent
                    radius: playerDropdown.radius
                    antialiasing: true
                    // The same tonal family as the selector it opens from
                    color: Theme.secondary_container
                    border.width: 0
                }
            } // End of dropdownFinalMasked
        } // End of dropdownShadow

        Flickable {
            id: playerDropdownFlickable
            anchors.fill: parent
            anchors.margins: 4
            contentHeight: playerColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: playerColumn
                width: playerDropdownFlickable.width
                spacing: 2

                Repeater {
                    model: Mpris.players.values
                    delegate: Rectangle {
                        width: playerColumn.width
                        height: 36
                        radius: Vars.radiusSmall
                        antialiasing: true
                        // M3 hover state layer: the content color at 8%
                        color: itemMouse.containsMouse ? Qt.rgba(Theme.on_secondary_container.r, Theme.on_secondary_container.g, Theme.on_secondary_container.b, 0.08) : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 12

                            QsText {
                                text: modelData.identity || "Unknown"
                                font.family: Vars.fontFamily
                                font.pixelSize: 14
                                color: mprisPlayer === modelData ? Theme.on_secondary_container : Qt.rgba(Theme.on_secondary_container.r, Theme.on_secondary_container.g, Theme.on_secondary_container.b, 0.7)
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                            }

                            QsText {
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 18
                                antialiasing: true
                                renderType: Text.QtRendering
                                font.hintingPreference: Font.PreferNoHinting
                                color: Theme.on_secondary_container
                                text: "\ue876" // check
                                visible: mprisPlayer === modelData
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                mediaPlayerRoot.preferredMprisPlayer = modelData;
                                playerDropdown.visible = false;
                            }
                        }
                    }
                }
            }
        }
    }

    // Root masks have been replaced with MultiEffect source masking and Rectangle radius
}
