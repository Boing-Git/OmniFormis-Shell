import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import QtCore
import "../.."
import "../../theme"

Flickable {
    id: quickPageRoot

    Layout.fillWidth: true
    Layout.fillHeight: true

    contentWidth: width
    contentHeight: mainCol.implicitHeight + 64
    clip: true
    interactive: true

    flickDeceleration: Vars.flickDeceleration
    maximumFlickVelocity: Vars.maximumFlickVelocity

    property string pageTitle: "Quick & Presets"
    property string pageIcon: "\ue41d"
    property string pageShape: "Puffy"
    property color pageColor: Theme.primary
    property color pageOnColor: Theme.on_primary
    property string searchText: ""

    signal openWallpaperSwitcher()

    M3Shapes { id: m3Shapes }

    FontLoader {
        id: filledIconFont
        source: "../../theme/assets/MaterialSymbolsRounded-Filled.ttf"
    }

    Settings {
        id: wallpaperSettings
        category: "WallpaperSwitcher"
        property string matugenScheme: "scheme-tonal-spot"
        property string wallpaperDir: ""
        property string currentWallpaper: ""
        property bool automaticSync: true
        property string awwwTransitionType: "wipe"
        property string awwwTransitionStep: "90"
        property string awwwTransitionAngle: "30"
    }

    Settings {
        id: themeModeSettings
        category: "ColorScheme"
        property string currentMode: "dark"
    }

    Settings {
        id: presetStorage
        category: "ConfigurationPresets"
        property string savedPresetsJson: "[]"
    }

    // Process for running matugen and color scheme scripts
    // NOTE: set-theme.sh already handles killing and restarting quickshell at the end,
    // so we do NOT call reload.sh from onExited — that would race and leave QS dead.
    Process {
        id: execProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    console.log("[QUICK PAGE STDOUT]\n" + this.text);
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    console.error("[QUICK PAGE STDERR]\n" + this.text);
            }
        }
        onExited: (code, status) => {
            if (code !== 0) {
                console.error("[USER ACTION] Matugen exited with code: " + code);
            }
            // set-theme.sh already restarts quickshell — no reload.sh needed here
        }
    }

    function syncMatugenAndTheme() {
        var wp = wallpaperSettings.currentWallpaper || "";
        var cleanWp = wp.replace(/^file:\/\//, "");
        var settings = wallpaperSettings;
        var matugenSchemeArg = (settings.matugenScheme === "scheme-auto" || settings.matugenScheme === "auto") ? "scheme-tonal-spot" : (settings.matugenScheme || "scheme-tonal-spot");
        
        var mode = themeModeSettings.currentMode || "dark";
        var trans = wallpaperSettings.awwwTransitionType || "wipe";
        var step = wallpaperSettings.awwwTransitionStep || "90";
        var angle = wallpaperSettings.awwwTransitionAngle || "30";
        
        var cmd = "";
        if (cleanWp !== "" && wallpaperSettings.automaticSync !== false) {
            cmd += "bash ~/Dotfiles/scripts/auto_scheme_matugen.sh '" + cleanWp + "' '" + mode + "'; ";
        } else {
            cmd += "matugen image '" + cleanWp + "' -m '" + mode + "' -t '" + matugenSchemeArg + "' --prefer saturation; ";
        }
        console.log("[USER ACTION] Running set-theme mode switch: " + mode);
        cmd += "bash ~/.config/color-schemes/set-theme.sh 'material-you' '" + mode + "'; ";

        execProc.command = ["bash", "-c", cmd];
        execProc.running = true;
    }

    // Presets Model management
    ListModel {
        id: presetsModel
    }

    function refreshPresetsModel() {
        presetsModel.clear();
        try {
            var list = JSON.parse(presetStorage.savedPresetsJson || "[]");
            for (var i = 0; i < list.length; i++) {
                var item = list[i];
                presetsModel.append({
                    "presetId": item.id || Date.now().toString(),
                    "name": item.name || ("Preset " + (i + 1)),
                    "timestamp": item.timestamp || "",
                    "wallpaper": item.wallpaper || "",
                    "matugenScheme": item.matugenScheme || "scheme-tonal-spot",
                    "colorMode": item.colorMode || "dark",
                    "maskShape": item.maskShape || "6SidedCookie",
                    "variablesJson": JSON.stringify(item.variables || {})
                });
            }
        } catch (e) {
            console.error("Error parsing savedPresetsJson:", e);
        }
    }

    function createNewPreset() {
        try {
            var existingList = JSON.parse(presetStorage.savedPresetsJson || "[]");
            var varSnapshot = {
                animationDuration: Vars.animationDuration,
                translucent: (Vars._translucent && !Vars.gameMode),
                blurAmount: Vars.blurAmount,
                overviewGridRows: Vars.overviewGridRows,
                overviewGridColumns: Vars.overviewGridColumns,
                overviewScale: Vars.overviewScale,
                gameLibraryRows: Vars.gameLibraryRows,
                gameLibraryColumns: Vars.gameLibraryColumns,
                gameLibraryScale: Vars.gameLibraryScale,
                radiusAmount: Vars.radiusAmount,
                radiusSmall: Vars.radiusSmall,
                radiusMedium: Vars.radiusMedium,
                radiusLarge: Vars.radiusLarge,
                radiusExtraLarge: Vars.radiusExtraLarge,
                spacingSmall: Vars.spacingSmall,
                spacingMedium: Vars.spacingMedium,
                spacingLarge: Vars.spacingLarge,
                paddingSmall: Vars.paddingSmall,
                paddingMedium: Vars.paddingMedium,
                paddingLarge: Vars.paddingLarge,
                wallpaperMaskEnabled: Vars.wallpaperMaskEnabled,
                wallpaperMaskScale: Vars.wallpaperMaskScale,
                wallpaperMaskShape: Vars.wallpaperMaskShape,
                wallpaperMaskColor: Vars.wallpaperMaskColor,
                wallpaperMaskOffsetX: Vars.wallpaperMaskOffsetX,
                wallpaperMaskOffsetY: Vars.wallpaperMaskOffsetY,
                clockShape: Vars.clockShape,
                clockShowTicks: Vars.clockShowTicks,
                clockShowCenterDot: Vars.clockShowCenterDot,
                panelStyle: Vars.panelStyle,
                pillPosition: Vars.pillPosition,
                clockPillMode: Vars.clockPillMode,
                mediaPlayerShape: Vars.mediaPlayerShape,
                mediaPlayerArtScale: Vars.mediaPlayerArtScale,
                gameMode: Vars.gameMode,
                desktopClockEnabled: Vars.desktopClockEnabled,
                desktopCalenderEnabled: Vars.desktopCalenderEnabled,
                desktopMediaPlayerEnabled: Vars.desktopMediaPlayerEnabled,
                desktopMediaPlayerAnchorExpandFix: Vars.desktopMediaPlayerAnchorExpandFix,
                liquidGlass: (Vars._liquidGlass && !Vars.gameMode),
                liquidGlassPreset: Vars.liquidGlassPreset
            };

            var count = existingList.length + 1;
            var timeString = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
            var newObj = {
                id: Date.now().toString() + "-" + Math.random().toString(36).substring(2, 7),
                name: "Config Preset " + count,
                timestamp: "Saved at " + timeString,
                wallpaper: wallpaperSettings.currentWallpaper,
                matugenScheme: wallpaperSettings.matugenScheme || "scheme-tonal-spot",
                colorMode: themeModeSettings.currentMode || "dark",
                maskShape: Vars.wallpaperMaskShape || "6SidedCookie",
                variables: varSnapshot
            };

            existingList.push(newObj);
            presetStorage.savedPresetsJson = JSON.stringify(existingList);
            refreshPresetsModel();
        } catch (e) {
            console.error("Failed to create preset:", e);
        }
    }

    function applyPreset(index) {
        if (index < 0 || index >= presetsModel.count) return;
        var item = presetsModel.get(index);
        var varsObj = JSON.parse(item.variablesJson || "{}");

        var shellCmds = "";
        for (var key in varsObj) {
            var val = varsObj[key];
            // Apply live in JS
            try {
                eval("Vars." + key + " = " + JSON.stringify(val) + ";");
            } catch (e) {}
            // Build command to save persistently via omniformis
            var omniKey = key;
            if (key === "translucent") {
                omniKey = "_translucent";
                shellCmds += "$HOME/.local/bin/omniformis hypr set 'blur_enabled' '" + (val ? "true" : "false") + "'; ";
            }
            if (key === "liquidGlass") {
                omniKey = "_liquidGlass";
                shellCmds += "$HOME/.local/bin/omniformis hypr set 'liquidGlass' '" + (val ? "true" : "false") + "'; ";
            }
            shellCmds += "$HOME/.local/bin/omniformis qs set '" + omniKey + "' '" + val + "'; ";
        }

        if (item.wallpaper !== "") {
            wallpaperSettings.currentWallpaper = item.wallpaper;
        }
        if (item.matugenScheme !== "") {
            wallpaperSettings.matugenScheme = item.matugenScheme;
        }
        if (item.colorMode !== "") {
            themeModeSettings.currentMode = item.colorMode;
        }

        var wp = wallpaperSettings.currentWallpaper || "";
        var cleanWp = wp.replace(/^file:\/\//, "");
        var scheme = wallpaperSettings.matugenScheme || "scheme-tonal-spot";
        var matugenArg = (scheme === "scheme-auto" || scheme === "auto") ? "scheme-tonal-spot" : scheme;
        var mode = themeModeSettings.currentMode || "dark";

        if (cleanWp !== "") {
            var trans2 = wallpaperSettings.awwwTransitionType || "wipe";
            var step2 = wallpaperSettings.awwwTransitionStep || "90";
            var angle2 = wallpaperSettings.awwwTransitionAngle || "30";
            Quickshell.execDetached({ command: ["bash", "-c", "awww img '" + cleanWp + "' --transition-type " + trans2 + " --transition-angle " + angle2 + " --transition-step " + step2] });
            if (scheme === "scheme-auto" || scheme === "auto") {
                shellCmds += "matugen image '" + cleanWp + "' -m '" + mode + "' -t 'scheme-tonal-spot' --prefer saturation; ";
                Quickshell.execDetached({
                    command: ["bash", "-c", "sleep 1.5; bash ~/Dotfiles/scripts/auto_scheme_matugen.sh '" + cleanWp + "' '" + mode + "'; bash ~/.config/color-schemes/set-theme.sh material-you " + mode + "; nohup bash ~/Dotfiles/scripts/reload.sh >/dev/null 2>&1 &"]
                });
            } else {
                shellCmds += "matugen image '" + cleanWp + "' -m '" + mode + "' -t '" + matugenArg + "' --prefer saturation; ";
            }
        }
        shellCmds += "bash ~/.config/color-schemes/set-theme.sh 'material-you' '" + mode + "'; ";
        shellCmds += "nohup bash -c 'sleep 0.25 && bash ~/Dotfiles/scripts/reload.sh' >/dev/null 2>&1 &";

        execProc.command = ["bash", "-c", shellCmds];
        execProc.running = true;
    }

    function deletePreset(index) {
        if (index < 0 || index >= presetsModel.count) return;
        var targetId = presetsModel.get(index).presetId;
        try {
            var list = JSON.parse(presetStorage.savedPresetsJson || "[]");
            list = list.filter(function(p) { return p.id !== targetId; });
            presetStorage.savedPresetsJson = JSON.stringify(list);
            refreshPresetsModel();
        } catch (e) {
            console.error("Error deleting preset:", e);
        }
    }

    Component.onCompleted: {
        refreshPresetsModel();
    }

    ColumnLayout {
        id: mainCol
        width: parent.width
        spacing: 24

        // ═════════════════════════════════════════════════════════════
        // SECTION 1: WALLPAPER & COLORS (Android 14 Material 3 Styling)
        // ═════════════════════════════════════════════════════════════
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 16

            // M3 Styled Section Header
            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Vars.spacingLarge
                Layout.rightMargin: Vars.spacingLarge
                spacing: 12

                // M3 Cookie Background Shape containing Monitor/Screen Icon (Without inverted background box!)
                Item {
                    width: 38
                    height: 38

                    Image {
                        anchors.fill: parent
                        sourceSize: Qt.size(width, height)
                        source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='" + m3Shapes.getPath(quickPageRoot.pageShape) + "' fill='" + String(quickPageRoot.pageColor || "#3b383e").replace("#", "%23") + "'/></svg>"
                        smooth: true
                        antialiasing: true
                    }

                    QsText {
                        anchors.centerIn: parent
                        text: quickPageRoot.pageIcon
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 20
                        color: quickPageRoot.pageOnColor
                    }
                }

                QsText {
                    Layout.fillWidth: true
                    text: quickPageRoot.pageTitle
                    font.family: Vars.fontFamily
                    font.pixelSize: 18
                    setWeight: 600
                    color: Theme.on_surface
                    elide: Text.ElideRight
                }
            }

            // Folder Selection for Wallpapers
            Rectangle {
                id: pathInputContainer
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                color: pathInput.activeFocus ? Theme.primary_container : (Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity))
                border.color: pathInput.activeFocus ? Theme.primary : "transparent"
                border.width: pathInput.activeFocus ? 2 : 0
                radius: pathInput.activeFocus ? Vars.radiusLarge : Vars.radiusExtraLarge
                antialiasing: true

                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Vars.spacingMedium
                    anchors.rightMargin: Vars.spacingMedium
                    spacing: 12

                    QsText {
                        text: "folder"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 20
                        color: pathInput.activeFocus ? Theme.on_primary_container : Theme.on_surface
                        opacity: 0.7
                    }

                    TextInput {
                        id: pathInput
                        Layout.fillWidth: true
                        font.family: Vars.fontFamily
                        font.pixelSize: 14
                        color: pathInput.activeFocus ? Theme.on_primary_container : Theme.on_surface
                        verticalAlignment: Text.AlignVCenter
                        text: wallpaperSettings.wallpaperDir
                        selectByMouse: true
                        MouseArea { anchors.fill: parent; cursorShape: Qt.IBeamCursor; onPressed: (mouse) => { parent.forceActiveFocus(); mouse.accepted = false; } }
                        
                        QsText {
                            text: "Wallpaper Folder Path..."
                            font.family: Vars.fontFamily
                            font.pixelSize: 14
                            color: Theme.on_surface
                            opacity: 0.6
                            visible: !pathInput.text && !pathInput.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        onAccepted: {
                            wallpaperSettings.wallpaperDir = text;
                            pathInput.focus = false;
                        }
                    }
                }
            }

            // Split Dashboard Layout (Left Wallpaper Monitor Box + Right Mode & Schemes Grid)
            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                // Left Box: Dark Widescreen Wallpaper Monitor Container & Squircle FAB
                Item {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 540
                    Layout.minimumWidth: 420
                    Layout.preferredHeight: 310

                    // Widescreen rectangular card with 28px rounded corner clipping and zero edge gap
                    Rectangle {
                        id: wpCard
                        anchors.fill: parent
                        radius: 28
                        antialiasing: true
                        color: Qt.rgba(0.08, 0.09, 0.10, 1.0)
                        border.color: Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12)
                        border.width: 1
                        clip: true

                        // Wallpaper scaled slightly larger with negative margins and masked to card bounds
                        Image {
                            id: wpPrevImg
                            anchors.fill: parent
                            anchors.margins: -4 // scale past edges before masking to guarantee zero gap
                            fillMode: Image.PreserveAspectCrop
                            source: wallpaperSettings.currentWallpaper !== "" ? (wallpaperSettings.currentWallpaper.startsWith("file://") ? wallpaperSettings.currentWallpaper : "file://" + wallpaperSettings.currentWallpaper) : ""
                            smooth: true
                            antialiasing: true
                            mipmap: true

                            layer.enabled: true
                            layer.samples: Vars.layerSamples
                            layer.smooth: true
                            layer.effect: MultiEffect {
                                maskEnabled: true
                                maskSource: topWpMask
                                maskThresholdMin: 0.5
                                maskSpreadAtMin: 1.0
                            }
                        }

                        Item {
                            id: topWpMask
                            layer.enabled: true
                            layer.smooth: true
                            layer.samples: Vars.layerSamples
                            anchors.fill: parent
                            visible: false
                            Rectangle {
                                anchors.fill: parent
                                radius: 28
                                antialiasing: true
                            }
                        }

                        // Elegant fallback icon when wallpaper image is loading or empty
                        QsText {
                            anchors.centerIn: parent
                            text: "\ue386"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 42
                            color: Theme.on_surface_variant
                            opacity: 0.4
                            visible: wpPrevImg.status !== Image.Ready
                        }
                    }

                    // M3 Squircle FAB Button to Open Wallpaper Switcher
                    Rectangle {
                        id: fabButton
                        width: 54
                        height: 54
                        radius: 18 // M3 Squircle curvature
                        antialiasing: true
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 22

                        // Muted sage/accent tone matching Android 14 M3 FAB
                        color: fabHover.pressed ? Qt.darker(Theme.secondary_container, 1.15) : (fabHover.containsMouse ? Qt.tint(Theme.secondary_container, Qt.rgba(Theme.on_secondary_container.r, Theme.on_secondary_container.g, Theme.on_secondary_container.b, 0.12)) : Qt.rgba(Theme.secondary_container.r, Theme.secondary_container.g, Theme.secondary_container.b, 0.85))
                        

                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                        scale: fabHover.pressed ? 1.08 : 1.0

                        QsText {
                            anchors.centerIn: parent
                            text: "edit" // pen / edit icon
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 24
                            color: Theme.on_secondary_container
                            scale: fabHover.pressed ? 0.92 : 1.0
                            Behavior on scale { NumberAnimation { duration: 150 } }
                        }

                        MouseArea {
                            id: fabHover
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                quickPageRoot.openWallpaperSwitcher();
                            }
                        }
                    }
                }

                // Right Box: Light & Dark Modes + Matugen Color Schemes Grid
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 460
                    Layout.minimumWidth: 340
                    Layout.fillHeight: true
                    spacing: 12

                    // Top Row: Light & Dark Mode Toggle Buttons
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        // Light Mode Button
                        Rectangle {
                            antialiasing: true
                            Layout.fillWidth: true
                            Layout.preferredHeight: 82
                            property bool isSelected: themeModeSettings.currentMode === "light"
                            topLeftRadius: 26
                            bottomLeftRadius: 26
                            topRightRadius: isSelected ? 26 : 6
                            bottomRightRadius: isSelected ? 26 : 6

                            Behavior on topLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            Behavior on bottomLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            Behavior on topRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            Behavior on bottomRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            color: isSelected ? (Vars.tColorSelected(Theme.primary_container)) : (lightHover.containsMouse ? (Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)) : (Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)))
                            border.width: 0

                            Behavior on color { ColorAnimation { duration: 180 } }
                            scale: lightHover.pressed ? 1.08 : 1.0
                            Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                QsText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "\ue518"
                                    font.family: parent.parent.isSelected ? filledIconFont.name : "Material Symbols Outlined"
                                    font.pixelSize: 24
                                    color: parent.parent.isSelected ? Theme.on_primary_container : Theme.on_surface_variant
                                }
                                QsText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "Light"
                                    font.family: Vars.fontFamily
                                    font.pixelSize: 13
                                    setWeight: parent.parent.isSelected ? 700 : 500
                                    color: parent.parent.isSelected ? Theme.on_primary_container : Theme.on_surface_variant
                                }
                            }

                            MouseArea {
                                id: lightHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (themeModeSettings.currentMode !== "light") {
                                        themeModeSettings.currentMode = "light";
                                        syncMatugenAndTheme();
                                    }
                                }
                            }
                        }

                        // Dark Mode Button
                        Rectangle {
                            antialiasing: true
                            Layout.fillWidth: true
                            Layout.preferredHeight: 82
                            property bool isSelected: themeModeSettings.currentMode === "dark"
                            topLeftRadius: isSelected ? 26 : 6
                            bottomLeftRadius: isSelected ? 26 : 6
                            topRightRadius: 26
                            bottomRightRadius: 26

                            Behavior on topLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            Behavior on bottomLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            Behavior on topRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            Behavior on bottomRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            color: isSelected ? (Vars.tColorSelected(Theme.primary_container)) : (darkHover.containsMouse ? (Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)) : (Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)))
                            border.width: 0

                            Behavior on color { ColorAnimation { duration: 180 } }
                            scale: darkHover.pressed ? 1.08 : 1.0
                            Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 6
                                QsText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "\ue51c"
                                    font.family: parent.parent.isSelected ? filledIconFont.name : "Material Symbols Outlined"
                                    font.pixelSize: 24
                                    color: parent.parent.isSelected ? Theme.on_primary_container : Theme.on_surface_variant
                                }
                                QsText {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: "Dark"
                                    font.family: Vars.fontFamily
                                    font.pixelSize: 13
                                    setWeight: parent.parent.isSelected ? 700 : 500
                                    color: parent.parent.isSelected ? Theme.on_primary_container : Theme.on_surface_variant
                                }
                            }

                            MouseArea {
                                id: darkHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (themeModeSettings.currentMode !== "dark") {
                                        themeModeSettings.currentMode = "dark";
                                        syncMatugenAndTheme();
                                    }
                                }
                            }
                        }
                    }

                    // Bottom Area: Matugen Color Scheme Styles Grid (Icon Top-Left, Text Bottom-Right)
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        rowSpacing: 4
                        columnSpacing: 4

                        Repeater {
                            model: [
                                { name: "Auto", scheme: "scheme-auto", icon: "auto_awesome" },
                                { name: "Content", scheme: "scheme-content", icon: "photo_library" },
                                { name: "Expressive", scheme: "scheme-expressive", icon: "palette" },
                                { name: "Fidelity", scheme: "scheme-fidelity", icon: "tune" },
                                { name: "Fruit Salad", scheme: "scheme-fruit-salad", icon: "local_florist" },
                                { name: "Monochrome", scheme: "scheme-monochrome", icon: "contrast" },
                                { name: "Neutral", scheme: "scheme-neutral", icon: "tonality" },
                                { name: "Rainbow", scheme: "scheme-rainbow", icon: "gradient" },
                                { name: "Tonal Spot", scheme: "scheme-tonal-spot", icon: "adjust" }
                            ]
                            delegate: Rectangle {
                                antialiasing: true
                                Layout.fillWidth: true
                                Layout.preferredHeight: 64

                                property bool isSelected: wallpaperSettings.matugenScheme === modelData.scheme
                                property bool hasLeft: index % 3 !== 0
                                property bool hasRight: index % 3 !== 2
                                property bool hasTop: index >= 3
                                property bool hasBottom: index < 6

                                topLeftRadius: isSelected ? 24 : ((!hasLeft && !hasTop) ? 24 : 6)
                                topRightRadius: isSelected ? 24 : ((!hasRight && !hasTop) ? 24 : 6)
                                bottomLeftRadius: isSelected ? 24 : ((!hasLeft && !hasBottom) ? 24 : 6)
                                bottomRightRadius: isSelected ? 24 : ((!hasRight && !hasBottom) ? 24 : 6)

                                Behavior on topLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                Behavior on topRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                Behavior on bottomLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                Behavior on bottomRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }

                                color: isSelected ? (Vars.tColorSelected(Theme.primary_container)) : (schemeHover.containsMouse ? (Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)) : (Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)))
                                border.width: 0

                                scale: schemeHover.pressed ? 1.08 : 1.0
                                Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }

                                Behavior on color { ColorAnimation { duration: 160 } }

                                // Icon Top-Left
                                QsText {
                                    anchors.top: parent.top
                                    anchors.left: parent.left
                                    anchors.margins: 10
                                    text: modelData.icon
                                    font.family: parent.isSelected ? filledIconFont.name : "Material Symbols Outlined"
                                    font.pixelSize: 17
                                    color: parent.isSelected ? Theme.on_primary_container : Theme.on_surface_variant
                                }

                                // Text Bottom-Right
                                QsText {
                                    anchors.bottom: parent.bottom
                                    anchors.right: parent.right
                                    anchors.margins: 10
                                    text: modelData.name
                                    font.family: Vars.fontFamily
                                    font.pixelSize: 11
                                    setWeight: parent.isSelected ? 700 : 500
                                    color: parent.isSelected ? Theme.on_primary_container : Theme.on_surface
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                MouseArea {
                                    id: schemeHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        wallpaperSettings.matugenScheme = modelData.scheme;
                                        syncMatugenAndTheme();
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Quick Toggles Row (Transparency & Automatic)
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                spacing: 28

                // Global Style Selection
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 10

                    RowLayout {
                        spacing: 12
                        QsText {
                            text: "palette"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 22
                            color: Theme.on_surface_variant
                        }
                        QsText {
                            text: "Global Style"
                            font.family: Vars.fontFamily
                            font.pixelSize: 15
                            setWeight: 500
                            color: Theme.on_surface
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Repeater {
                            id: styleModeRepeater
                            model: [
                                { mode: "solid", icon: "layers_clear" },
                                { mode: "translucent", icon: "layers" },
                                { mode: "liquid", icon: "water_drop" }
                            ]
                            delegate: Rectangle {
                                antialiasing: true
                                Layout.fillWidth: true
                                Layout.preferredHeight: 38
                                property bool isSelected: modelData.mode === "solid" ? (!(Vars._translucent && !Vars.gameMode) && !(Vars._liquidGlass && !Vars.gameMode)) : (modelData.mode === "translucent" ? (Vars._translucent && !Vars.gameMode) : (Vars._liquidGlass && !Vars.gameMode))
                                property bool hasLeft: index > 0
                                property bool hasRight: index < styleModeRepeater.count - 1

                                topLeftRadius: isSelected ? 19 : (hasLeft ? 6 : 19)
                                bottomLeftRadius: isSelected ? 19 : (hasLeft ? 6 : 19)
                                topRightRadius: isSelected ? 19 : (hasRight ? 6 : 19)
                                bottomRightRadius: isSelected ? 19 : (hasRight ? 6 : 19)

                                color: isSelected ? (Vars.tColorSelected(Theme.primary_container)) : (styleModeHover.containsMouse ? (Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)) : (Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)))
                                border.width: 0

                                scale: styleModeHover.pressed ? 1.08 : 1.0
                                Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }

                                Behavior on topLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                Behavior on bottomLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                Behavior on topRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                Behavior on bottomRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }

                                QsText {
                                    anchors.centerIn: parent
                                    text: modelData.icon
                                    font.family: parent.isSelected ? filledIconFont.name : "Material Symbols Outlined"
                                    font.pixelSize: 20
                                    color: parent.isSelected ? Theme.on_primary_container : Theme.on_surface_variant
                                }

                                MouseArea {
                                    id: styleModeHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (parent.isSelected) return;

                                        if (modelData.mode === "solid") {
                                            SettingsApply.set("qs", "_translucent", false);
                                            SettingsApply.set("qs", "_liquidGlass", false);
                                            SettingsApply.set("hypr", "liquidGlass", false);
                                            SettingsApply.set("hypr", "blur_enabled", false);
                                        } else if (modelData.mode === "translucent") {
                                            SettingsApply.set("qs", "_translucent", true);
                                            SettingsApply.set("qs", "_liquidGlass", false);
                                            SettingsApply.set("hypr", "liquidGlass", false);
                                            SettingsApply.set("hypr", "blur_enabled", true);
                                        } else if (modelData.mode === "liquid") {
                                            SettingsApply.set("qs", "_translucent", false);
                                            SettingsApply.set("qs", "_liquidGlass", true);
                                            SettingsApply.set("hypr", "liquidGlass", true);
                                            SettingsApply.set("hypr", "blur_enabled", false);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Wallpaper Transition Selection
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    spacing: 10

                    RowLayout {
                        spacing: 12
                        QsText {
                            text: "\ue503"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 22
                            color: Theme.on_surface_variant
                        }
                        QsText {
                            text: "Wallpaper Transition"
                            font.family: Vars.fontFamily
                            font.pixelSize: 15
                            setWeight: 500
                            color: Theme.on_surface
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Repeater {
                            id: transitionTypeRepeater
                            model: [
                                { mode: "none", label: "None" },
                                { mode: "fade", label: "Fade" },
                                { mode: "wipe", label: "Wipe" },
                                { mode: "wave", label: "Wave" },
                                { mode: "grow", label: "Grow" }
                            ]
                            delegate: Rectangle {
                                antialiasing: true
                                Layout.fillWidth: true
                                Layout.preferredHeight: 38
                                property bool isSelected: (wallpaperSettings.awwwTransitionType || "wipe") === modelData.mode
                                property bool hasLeft: index > 0
                                property bool hasRight: index < transitionTypeRepeater.count - 1

                                topLeftRadius: isSelected ? 19 : (hasLeft ? 6 : 19)
                                bottomLeftRadius: isSelected ? 19 : (hasLeft ? 6 : 19)
                                topRightRadius: isSelected ? 19 : (hasRight ? 6 : 19)
                                bottomRightRadius: isSelected ? 19 : (hasRight ? 6 : 19)

                                color: isSelected ? (Vars.tColorSelected(Theme.primary_container)) : (transHover.containsMouse ? (Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)) : (Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)))
                                border.width: 0

                                scale: transHover.pressed ? 1.08 : 1.0
                                Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }

                                Behavior on topLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                Behavior on bottomLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                Behavior on topRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                Behavior on bottomRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }

                                QsText {
                                    anchors.centerIn: parent
                                    text: modelData.label
                                    font.family: Vars.fontFamily
                                    font.pixelSize: 13
                                    setWeight: parent.isSelected ? 600 : 500
                                    color: parent.isSelected ? Theme.on_primary_container : Theme.on_surface_variant
                                }

                                MouseArea {
                                    id: transHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        wallpaperSettings.awwwTransitionType = modelData.mode;
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Dot Separator
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 4
                Layout.bottomMargin: 0
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                Repeater {
                    model: 3
                    Rectangle {
                        width: 4
                        height: 4
                        radius: 2
                        antialiasing: true
                        color: Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.15)
                    }
                }
            }

            // Side-by-side layout for Pill Position and Panel Style
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 20

                // Pill Position Selection
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    spacing: 10
                    
                    RowLayout {
                    spacing: 12
                    QsText {
                        text: "\ue250"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 22
                        color: Theme.on_surface_variant
                    }
                    QsText {
                        text: "Panel Position"
                        font.family: Vars.fontFamily
                        font.pixelSize: 15
                        setWeight: 500
                        color: Theme.on_surface
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Repeater {
                        id: posRepeater
                        model: [
                            { name: "Left", pos: "Left", icon: "\ue5cb" },
                            { name: "Top", pos: "Top", icon: "\ue5ce" },
                            { name: "Bottom", pos: "Bottom", icon: "\ue5cf" },
                            { name: "Right", pos: "Right", icon: "\ue5cc" }
                        ]
                        delegate: Rectangle {
                            antialiasing: true
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            property bool isSelected: (Vars.pillPosition || "Top") === modelData.pos
                            property bool hasLeft: index > 0
                            property bool hasRight: index < posRepeater.count - 1

                            topLeftRadius: isSelected ? 19 : (hasLeft ? 6 : 19)
                            bottomLeftRadius: isSelected ? 19 : (hasLeft ? 6 : 19)
                            topRightRadius: isSelected ? 19 : (hasRight ? 6 : 19)
                            bottomRightRadius: isSelected ? 19 : (hasRight ? 6 : 19)

                            color: isSelected ? (Vars.tColorSelected(Theme.primary_container)) : (posHover.containsMouse ? (Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)) : (Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)))
                            border.width: 0

                            scale: posHover.pressed ? 1.08 : 1.0
                            Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }

                            Behavior on topLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            Behavior on bottomLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            Behavior on topRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            Behavior on bottomRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }

                            QsText {
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.family: parent.isSelected ? filledIconFont.name : "Material Symbols Outlined"
                                font.pixelSize: 20
                                color: parent.isSelected ? Theme.on_primary_container : Theme.on_surface_variant
                            }

                            MouseArea {
                                id: posHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (Vars.pillPosition !== modelData.pos)
                                        SettingsApply.set("qs", "pillPosition", modelData.pos);
                                }
                            }
                        }
                    }
                }
            }

                // Panel Style Selection
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    spacing: 10

                    RowLayout {
                    spacing: 12
                    QsText {
                        text: "\ue1bd"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 22
                        color: Theme.on_surface_variant
                    }
                    QsText {
                        text: "Panel Style"
                        font.family: Vars.fontFamily
                        font.pixelSize: 15
                        font.weight: 500
                        color: Theme.on_surface
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Repeater {
                        id: styleRepeater
                        model: [
                            { name: "Floating", style: "Floating", icon: "layers" },
                            { name: "Attached", style: "Attached", icon: "vertical_align_top" },
                            { name: "Framed", style: "Framed", icon: "filter_frames" }
                        ]
                        delegate: Rectangle {
                            antialiasing: true
                            Layout.fillWidth: true
                            Layout.preferredHeight: 38
                            property bool isSelected: (Vars.panelStyle || "Floating") === modelData.style
                            property bool hasLeft: index > 0
                            property bool hasRight: index < styleRepeater.count - 1

                            topLeftRadius: isSelected ? 19 : (hasLeft ? 6 : 19)
                            bottomLeftRadius: isSelected ? 19 : (hasLeft ? 6 : 19)
                            topRightRadius: isSelected ? 19 : (hasRight ? 6 : 19)
                            bottomRightRadius: isSelected ? 19 : (hasRight ? 6 : 19)

                            color: isSelected ? (Vars.tColorSelected(Theme.primary_container)) : (styleHover.containsMouse ? (Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)) : (Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)))
                            border.width: 0

                            scale: styleHover.pressed ? 1.08 : 1.0
                            Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }

                            Behavior on topLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            Behavior on bottomLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            Behavior on topRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            Behavior on bottomRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }

                            QsText {
                                anchors.centerIn: parent
                                text: modelData.icon
                                font.family: parent.isSelected ? filledIconFont.name : "Material Symbols Outlined"
                                font.pixelSize: 20
                                color: parent.isSelected ? Theme.on_primary_container : Theme.on_surface_variant
                            }

                            MouseArea {
                                id: styleHover
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (Vars.panelStyle !== modelData.style)
                                        SettingsApply.set("qs", "panelStyle", modelData.style);
                                }
                            }
                        }
                    }
                }
            }
            }

            // Row for Liquid Glass Preset
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 20

                // Liquid Glass Preset Selection
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    spacing: 10

                    RowLayout {
                        spacing: 12
                        QsText {
                            text: "\ue1a6"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 22
                            color: Theme.on_surface_variant
                        }
                        QsText {
                            text: "Liquid Glass Preset"
                            font.family: Vars.fontFamily
                            font.pixelSize: 15
                            font.weight: 500
                            color: Theme.on_surface
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Repeater {
                            id: presetRepeater
                            model: [
                                { name: "Glass", preset: "glass", icon: "\uea08" },
                                { name: "Apple", preset: "apple", icon: "\ue52d" },
                                { name: "Clear", preset: "clear", icon: "\ue8d4" },
                                { name: "Contrasted", preset: "contrasted", icon: "\ue3b9" }
                            ]
                            delegate: Rectangle {
                                antialiasing: true
                                Layout.fillWidth: true
                                Layout.preferredHeight: 38
                                property bool isSelected: (Vars.liquidGlassPreset || "glass") === modelData.preset
                                property bool hasLeft: index > 0
                                property bool hasRight: index < presetRepeater.count - 1

                                topLeftRadius: isSelected ? 19 : (hasLeft ? 6 : 19)
                                bottomLeftRadius: isSelected ? 19 : (hasLeft ? 6 : 19)
                                topRightRadius: isSelected ? 19 : (hasRight ? 6 : 19)
                                bottomRightRadius: isSelected ? 19 : (hasRight ? 6 : 19)

                                color: isSelected ? (Vars.tColorSelected(Theme.primary_container)) : (presetHover.containsMouse ? (Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)) : (Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)))
                                border.width: 0

                                scale: presetHover.pressed ? 1.08 : 1.0
                                Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }

                                Behavior on topLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                Behavior on bottomLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                Behavior on topRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                Behavior on bottomRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    QsText {
                                        text: modelData.icon
                                        font.family: parent.parent.isSelected ? filledIconFont.name : "Material Symbols Outlined"
                                        font.pixelSize: 18
                                        color: parent.parent.isSelected ? Theme.on_primary_container : Theme.on_surface_variant
                                    }
                                    QsText {
                                        text: modelData.name
                                        font.family: Vars.fontFamily
                                        font.pixelSize: 13
                                        font.weight: parent.parent.isSelected ? 700 : 500
                                        color: parent.parent.isSelected ? Theme.on_primary_container : Theme.on_surface_variant
                                    }
                                }

                                MouseArea {
                                    id: presetHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (Vars.liquidGlassPreset !== modelData.preset) {
                                            SettingsApply.set("qs", "liquidGlassPreset", modelData.preset);
                                            SettingsApply.set("hypr", "liquidGlassPreset", modelData.preset);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Clock Pill Visibility Selection
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.alignment: Qt.AlignTop
                    spacing: 10

                    RowLayout {
                        spacing: 12
                        QsText {
                            text: "\ue8f4"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 22
                            color: Theme.on_surface_variant
                        }
                        QsText {
                            text: "Clock Pill Visibility"
                            font.family: Vars.fontFamily
                            font.pixelSize: 15
                            font.weight: 500
                            color: Theme.on_surface
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Repeater {
                            id: clockModeRepeater
                            model: [
                                { name: "Always", mode: "Always Visible", icon: "\ue8f4" },
                                { name: "Dodge", mode: "Dodge Windows", icon: "\ue5d2" },
                                { name: "Auto Hide", mode: "Auto Hide", icon: "\ue8f5" }
                            ]
                            delegate: Rectangle {
                                antialiasing: true
                                Layout.fillWidth: true
                                Layout.preferredHeight: 38
                                property bool isSelected: (Vars.clockPillMode || "Always Visible") === modelData.mode
                                property bool hasLeft: index > 0
                                property bool hasRight: index < clockModeRepeater.count - 1

                                topLeftRadius: isSelected ? 19 : (hasLeft ? 6 : 19)
                                bottomLeftRadius: isSelected ? 19 : (hasLeft ? 6 : 19)
                                topRightRadius: isSelected ? 19 : (hasRight ? 6 : 19)
                                bottomRightRadius: isSelected ? 19 : (hasRight ? 6 : 19)

                                color: isSelected ? (Vars.tColorSelected(Theme.primary_container)) : (modeHover.containsMouse ? (Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)) : (Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)))
                                border.width: 0

                                scale: modeHover.pressed ? 1.08 : 1.0
                                Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }

                                Behavior on topLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                Behavior on bottomLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                Behavior on topRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                Behavior on bottomRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 4
                                    QsText {
                                        text: modelData.icon
                                        font.family: parent.parent.isSelected ? filledIconFont.name : "Material Symbols Outlined"
                                        font.pixelSize: 18
                                        color: parent.parent.isSelected ? Theme.on_primary_container : Theme.on_surface_variant
                                    }
                                    QsText {
                                        text: modelData.name
                                        font.family: Vars.fontFamily
                                        font.pixelSize: 13
                                        font.weight: parent.parent.isSelected ? 700 : 500
                                        color: parent.parent.isSelected ? Theme.on_primary_container : Theme.on_surface_variant
                                    }
                                }

                                MouseArea {
                                    id: modeHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (Vars.clockPillMode !== modelData.mode)
                                            SettingsApply.set("qs", "clockPillMode", modelData.mode);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Horizontal Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)
        }

        // ═════════════════════════════════════════════════════════════
        // SECTION 2: SAVED PRESETS MANAGEMENT
        // ═════════════════════════════════════════════════════════════
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // M3 Shape Container for Presets Icon (Without inverted background box!)
                    Item {
                        width: 38
                        height: 38

                        Image {
                            anchors.fill: parent
                            sourceSize: Qt.size(width, height)
                            source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='" + m3Shapes.getPath("6SidedCookie") + "' fill='" + (Theme.surface_container_highest || "#3b383e") + "'/></svg>"
                            smooth: true
                            antialiasing: true
                        }

                        QsText {
                            anchors.centerIn: parent
                            text: "\ue41d" // presets / customization icon
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 20
                            color: Theme.on_surface_variant
                        }
                    }

                    QsText {
                        Layout.fillWidth: true
                        text: "Configuration Presets"
                        font.family: Vars.fontFamily
                        font.pixelSize: 18
                        font.weight: 600
                        color: Theme.on_surface
                        elide: Text.ElideRight
                    }
                }

                // Animated M3 Rounded Square "+" Add Button
                Rectangle {
                    Layout.alignment: Qt.AlignTop | Qt.AlignRight
                    Layout.preferredHeight: 44
                    Layout.preferredWidth: 44
                    radius: 14
                    antialiasing: true
                    color: createHover.pressed ? Qt.darker(Theme.secondary_container, 1.15) : (createHover.containsMouse ? Qt.tint(Theme.secondary_container, Qt.rgba(Theme.on_secondary_container.r, Theme.on_secondary_container.g, Theme.on_secondary_container.b, 0.12)) : Theme.secondary_container)

                    Behavior on color { ColorAnimation { duration: 150 } }

                    SequentialAnimation on radius {
                        id: morphAnim
                        running: false
                        NumberAnimation { to: 22; duration: 160; easing.type: Easing.OutBack } // morph into circle
                        NumberAnimation { to: 14; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } // morph back to rounded square
                    }

                    QsText {
                        anchors.centerIn: parent
                        text: "add" // material icon ligature for add (+)
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 24
                        color: Theme.on_secondary_container
                        scale: createHover.pressed ? 1.08 : 1.0
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                    }

                    MouseArea {
                        id: createHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            morphAnim.restart();
                            createNewPreset();
                        }
                    }
                }
            }

            // Presets Cards Grid
            Flow {
                Layout.fillWidth: true
                spacing: 16

                QsText {
                    visible: presetsModel.count === 0
                    text: "No presets here"
                    font.family: Vars.fontFamily
                    font.pixelSize: 14
                    color: Theme.on_surface_variant
                    opacity: 0.7
                    Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    font.italic: true
                    wrapMode: Text.WordWrap
                }

                Repeater {
                    model: presetsModel

                    delegate: Item {
                        id: delegateItem
                        width: Math.max(280, Math.floor((parent.width - 16) / 2))
                        height: Math.max(200, Math.floor(width * 0.56))

                        property bool isHovered: cardHoverArea.containsMouse || applyHover.containsMouse || delHover.containsMouse

                        Item {
                            id: cardContainer
                            anchors.fill: parent
                            scale: delegateItem.isHovered ? 1.02 : 1.0
                            Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutBack } }

                            Rectangle {
                                id: cardMask
                                anchors.fill: parent
                                radius: 18
                                antialiasing: true
                                color: "black"
                                visible: false
                            }

                            Item {
                                id: maskedContent
                                anchors.fill: parent
                                layer.enabled: true
                                layer.samples: Vars.layerSamples
                                layer.smooth: true
                                layer.effect: MultiEffect {
                                    maskEnabled: true
                                    maskSource: cardMask
                                    maskThresholdMin: 0.5
                                    maskSpreadAtMin: 1.0
                                }

                                // Card background
                                Rectangle {
                                    id: cardBase
                                    anchors.fill: parent
                                    radius: 18
                                    antialiasing: true
                                    color: Vars.tColor(Theme.surface_container_low, Vars.componentOpacity)
                                    border.color: delegateItem.isHovered ? Theme.primary : Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)
                                    border.width: delegateItem.isHovered ? 2 : 1

                                    Behavior on border.color { ColorAnimation { duration: 250; easing.type: Easing.OutCubic } }

                                    property var presetVars: {
                                        try { return JSON.parse(model.variablesJson || "{}"); } catch(e) { return {}; }
                                    }
                                    property bool wpMaskEnabled: presetVars.wallpaperMaskEnabled !== undefined ? presetVars.wallpaperMaskEnabled : true
                                    property string wpMaskShape: presetVars.wallpaperMaskShape || model.maskShape || "6SidedCookie"
                                    property real wpMaskScale: presetVars.wallpaperMaskScale !== undefined ? presetVars.wallpaperMaskScale : 0.7
                                    property string wpMaskColor: presetVars.wallpaperMaskColor || "transparent"
                                    property string panelPosition: presetVars.pillPosition || "Top"
                                    property string panelStyle: presetVars.panelStyle || "Floating"

                            Rectangle {
                                anchors.fill: parent
                                visible: cardBase.wpMaskEnabled
                                color: {
                                    var c = cardBase.wpMaskColor;
                                    if (c === "background" || c === "transparent" || c === undefined) return Theme.background;
                                    if (c === "primary") return Theme.primary;
                                    if (c === "secondary") return Theme.secondary;
                                    if (c === "tertiary") return Theme.tertiary;
                                    if (c === "surface_variant") return Theme.surface_variant;
                                    if (c === "error") return Theme.error;
                                    return Theme.background;
                                }
                            }

                            Image {
                                id: presetWpImage
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                source: model.wallpaper !== "" ? (model.wallpaper.startsWith("file://") ? model.wallpaper : "file://" + model.wallpaper) : ""
                                smooth: true
                                antialiasing: true
                                mipmap: true
                                visible: false
                                scale: delegateItem.isHovered ? 1.05 : 1.0
                                Behavior on scale { NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
                            }

                            Item {
                                id: shapeMaskCanvas
                                layer.enabled: true
                                layer.smooth: true
                                layer.samples: Vars.layerSamples
                                anchors.fill: parent
                                visible: false

                                Image {
                                    anchors.centerIn: parent
                                    anchors.verticalCenterOffset: -12
                                    width: Math.min(cardBase.width, cardBase.height) * cardBase.wpMaskScale
                                    height: width
                                    sourceSize: Qt.size(width, height)
                                    source: cardBase.wpMaskEnabled ? ("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='" + m3Shapes.getPath(cardBase.wpMaskShape) + "' fill='white'/></svg>") : ""
                                    smooth: true
                                    antialiasing: true
                                    mipmap: true
                                    visible: cardBase.wpMaskEnabled
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 18
                                    antialiasing: true
                                    color: "white"
                                    visible: !cardBase.wpMaskEnabled
                                }
                            }

                            MultiEffect {
                                anchors.fill: parent
                                source: presetWpImage
                                maskEnabled: true
                                maskSource: shapeMaskCanvas
                                antialiasing: true
                                smooth: true
                            }

                            // Bottom 1/4 Translucent Banner
                            Rectangle {
                                antialiasing: true
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: 56
                                bottomLeftRadius: 18
                                bottomRightRadius: 18
                                color: Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)
                                
                                Rectangle {
                                    anchors.top: parent.top
                                    width: parent.width
                                    height: 1
                                    color: Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    spacing: 10

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        RowLayout {
                                            spacing: 6
                                            QsText {
                                                text: cardBase.panelStyle === "Attached" ? "vertical_align_top" : (cardBase.panelStyle === "Framed" ? "filter_frames" : "layers")
                                                font.family: "Material Symbols Outlined"
                                                font.pixelSize: 17
                                                color: Theme.primary
                                            }
                                            QsText {
                                                Layout.fillWidth: true
                                                text: cardBase.panelPosition + " Position"
                                                font.family: Vars.fontFamily
                                                font.pixelSize: 14
                                                font.weight: 700
                                                color: Theme.on_surface
                                                elide: Text.ElideRight
                                            }
                                        }

                                        QsText {
                                            Layout.fillWidth: true
                                            text: model.colorMode + " mode • " + model.matugenScheme.replace("scheme-", "")
                                            font.family: Vars.fontFamily
                                            font.pixelSize: 11
                                            color: Theme.on_surface_variant
                                            opacity: 0.9
                                            elide: Text.ElideRight
                                        }
                                    }

                                    // Segmented Button Group (Apply & Delete)
                                    Row {
                                        Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                        spacing: 4

                                        // Apply Button (more round left, less round right)
                                        Rectangle {
                                            antialiasing: true
                                            width: 80
                                            height: 36
                                            topLeftRadius: 18
                                            bottomLeftRadius: 18
                                            topRightRadius: 6
                                            bottomRightRadius: 6
                                            color: applyHover.containsMouse ? Theme.primary : Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.2)
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            scale: applyHover.pressed ? 1.08 : 1.0
                                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                                            QsText {
                                                anchors.centerIn: parent
                                                text: "Apply"
                                                font.family: Vars.fontFamily
                                                font.pixelSize: 13
                                                font.weight: 600
                                                color: applyHover.containsMouse ? Theme.on_primary : Theme.primary
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }

                                            MouseArea {
                                                id: applyHover
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    console.log("Apply Preset Button Clicked: " + model.presetId);
                                                    applyPreset(index);
                                                }
                                            }
                                        }

                                        // Delete Preset Button (less round left, more round right)
                                        Rectangle {
                                            antialiasing: true
                                            width: 42
                                            height: 36
                                            topLeftRadius: 6
                                            bottomLeftRadius: 6
                                            topRightRadius: 18
                                            bottomRightRadius: 18
                                            color: delHover.containsMouse ? Theme.error : Qt.rgba(Theme.error.r, Theme.error.g, Theme.error.b, 0.18)
                                            Behavior on color { ColorAnimation { duration: 150 } }
                                            scale: delHover.pressed ? 1.08 : 1.0
                                            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }

                                            QsText {
                                                anchors.centerIn: parent
                                                text: "\ue872" // delete trash icon
                                                font.family: "Material Symbols Outlined"
                                                font.pixelSize: 18
                                                color: delHover.containsMouse ? Theme.on_error : Theme.error
                                                Behavior on color { ColorAnimation { duration: 150 } }
                                            }

                                            MouseArea {
                                                id: delHover
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    console.log("Delete Preset Button Clicked: " + model.presetId);
                                                    deletePreset(index);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        } // Ends cardBase
                    } // Ends maskedContent

                    // Clicking anywhere on top 3/4 applies the preset
                    MouseArea {
                        id: cardHoverArea
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: parent.height - 56
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            console.log("Preset Card Clicked: " + model.presetId);
                            applyPreset(index);
                        }
                    }
                } // Ends cardContainer
            } // Ends delegateItem
                }
            }
        }
    }
}
