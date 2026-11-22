import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import "../.."
import "../../theme"

ColumnLayout {
    id: rootPage

    Layout.fillWidth: true
    Layout.fillHeight: true
    spacing: Vars.spacingMedium

    property var allVars: []
    property string activeCategory: "General"
    
    property string pageTitle: ""
    property string pageIcon: ""
    property string pageShape: "Puffy"
    property color pageColor: Theme.primary
    property color pageOnColor: Theme.on_primary
    onActiveCategoryChanged: applyFilter()
    property string copiedSliderValue: ""
    property string searchText: ""
    onSearchTextChanged: applyFilter()

    function prettyTitle(key) {
        var custom = {
            "clockShape": "Desktop Clock Outline Shape",
            "clockDateShape": "Clock Pill Date Badge Shape",
            "clockDateBadgeColor": "Clock Pill Date Badge Color",
            "clockShowTicks": "Show Minute Ticks",
            "clockShowCenterDot": "Show Center Dot Pivot",
            "clockShowDate": "Show Orbiting Date",
            "clockSecondHandStyle": "Second Hand Style",
            "clockHandThickness": "Clock Hand Thickness",
            "wallpaperMaskShape": "Wallpaper Mask Shape",
            "wallpaperMaskScale": "Wallpaper Mask Scale",
            "wallpaperMaskColor": "Wallpaper Mask Color",
            "wallpaperMaskEnabled": "Enable Wallpaper Mask",
            "wallpaperMaskOffsetX": "Wallpaper Mask X Offset",
            "wallpaperMaskOffsetY": "Wallpaper Mask Y Offset",
            "mediaPlayerShape": "Media Player Widget Shape",
            "mediaPlayerArtScale": "Media Player Art Scale",
            "mediaPlayerArtOffsetX": "Media Player Art X Offset",
            "mediaPlayerArtOffsetY": "Media Player Art Y Offset",
            "mediaPlayerWaveThickness": "Media Player Wave Thickness",
            "mediaPlayerOrientation": "Orientation",
            "mediaPlayerLyricsExpansion": "Lyrics Direction",
            "mediaPlayerLyricsAutoScroll": "Auto Scroll",
            "mediaPlayerExpandOverlaps": "Overlay Mode (No Layout Push)",
            "desktopMediaPlayerAnchorExpandFix": "Lock Anchor Position on Expand",
            "desktopAudioVisualizerShape": "Audio Visualizer Bar Shape",
            "desktopAudioVisualizerShapeMode": "Audio Visualizer Bar Shape Mode",
            "desktopAudioVisualizerColorMode": "Audio Visualizer Color Mode",
            "desktopAudioVisualizerColor": "Audio Visualizer Custom Color",
            "desktopAudioVisualizerGradientStart": "Audio Visualizer Gradient Start Color",
            "desktopAudioVisualizerGradientEnd": "Audio Visualizer Gradient End Color",
            "desktopAudioVisualizerLayout": "Audio Visualizer Arrangement",
            "desktopAudioVisualizerLineArrangement": "Audio Visualizer Line Arrangement",
            "desktopAudioVisualizerPositionShape": "Audio Visualizer Position Shape",
            "desktopAudioVisualizerShapeSize": "Audio Visualizer Shape Size",
            "desktopAudioVisualizerLineThickness": "Audio Visualizer Line Thickness",
            "desktopAudioVisualizerLineMirror": "Audio Visualizer Line Mirror",
            "desktopAudioVisualizerLineDirection": "Audio Visualizer Line Direction",
            "desktopAudioVisualizerSpacing": "Audio Visualizer Shape Spacing",
            "desktopAudioVisualizerRadius": "Audio Visualizer Radius / Movement",
            "desktopAudioVisualizerPresets": "Audio Visualizer Layout Presets",
            "gameMode": "Game Mode Optimization",
            "reduceMotion": "Reduce Motion",
            "reduceTransparency": "Reduce Transparency",
            "animationDuration": "Master Animation Duration",
            "flickDeceleration": "Scroll Deceleration Rate",
            "maximumFlickVelocity": "Max Scroll Velocity",
            "blurAmount": "Window Blur Intensity",
            "panelOpacity": "Main Panel Opacity",
            "componentOpacity": "Inner Component Opacity",
            "radiusAmount": "Window Corner Radius Scale",
            "cornerPower": "Window Corner Curve Power (Squircle)",
            "fontFamily": "Interface Font Family",
            "fontWeight": "Interface Font Weight",
            "fontItalic": "Interface Font Italic",
            "fontRounding": "Interface Font Rounding",
            "fontGrading": "Interface Font Grade",
            "fontBaselineEnabled": "Relative Font Baseline Config",
            "pillPosition": "Panel Screen Position",
            "clockPillMode": "Clock Pill Visibility",
            "panelStyle": "Panel Visual Style",
            "gaps_in": "Inner Window Gaps",
            "gaps_out": "Outer Window Gaps",
            "border_size": "Window Border Size",
            "rounding": "Window Corner Rounding",
            "rounding_power": "Rounding Super-ellipse Power",
            "active_opacity": "Active Window Opacity",
            "inactive_opacity": "Inactive Window Opacity",
            "windowOpacity": "Global Window Opacity",
            "follow_mouse": "Follow Mouse Focus",
            "sensitivity": "Cursor Sensitivity",
            "touchpad_natural_scroll": "Touchpad Natural Scrolling",
            "force_default_wallpaper": "Default Hyprland Wallpaper",
            "gesture_direction": "Swipe Gesture Direction",
            "AnimateStyle": "System Animation Style",
            "Layout": "Window Tiling Layout",
            "radiusSmall": "Corner Radius (Small)",
            "radiusMedium": "Corner Radius (Medium)",
            "radiusLarge": "Corner Radius (Large)",
            "radiusExtraLarge": "Corner Radius (Extra Large)",
            "spacingSmall": "Spacing Gap (Small)",
            "spacingMedium": "Spacing Gap (Medium)",
            "spacingLarge": "Spacing Gap (Large)",
            "paddingSmall": "Internal Padding (Small)",
            "paddingMedium": "Internal Padding (Medium)",
            "paddingLarge": "Internal Padding (Large)"
        };
        if (custom[key]) return custom[key];
        var str = key.replace(/_/g, " ").replace(/([A-Z])/g, " $1").replace(/\s+/g, " ").trim();
        return str.charAt(0).toUpperCase() + str.slice(1);
    }

    function prettyHelp(key, rawHelp) {
        var descriptions = {
            "clockShowTicks": "Display hour dial tick marks around the perimeter of the analog clock widget.",
            "clockShowCenterDot": "Render the prominent decorative center pin dot on the analog clock hands.",
            "clockShape": "Select the Material 3 expressive silhouette shape for the desktop clock container.",
            "clockDateShape": "Select the Material 3 shape for the date badge in the panel clock pill.",
            "clockDateBadgeColor": "Choose the theme color used to fill the date and month badges in the panel clock pill.",
            "wallpaperMaskShape": "Select the geometric clipping cutout shape applied to the wallpaper background.",
            "wallpaperMaskScale": "Scale zoom factor for the wallpaper cutout mask geometry.",
            "wallpaperMaskColor": "Solid tint background color visible around the perimeter of the masked wallpaper.",
            "wallpaperMaskEnabled": "Toggle the expressive Material 3 clipping mask over the desktop wallpaper.",
            "wallpaperMaskOffsetX": "Horizontal X-axis pixel shift for positioning the wallpaper clipping mask.",
            "wallpaperMaskOffsetY": "Vertical Y-axis pixel shift for positioning the wallpaper clipping mask.",
            "mediaPlayerShape": "Select the Material 3 cutout shape contour for the desktop audio player widget.",
            "mediaPlayerArtScale": "Scale zoom factor for album artwork displayed inside the desktop audio player.",
            "mediaPlayerArtOffsetX": "Horizontal X-axis pixel shift for positioning the album artwork.",
            "mediaPlayerArtOffsetY": "Vertical Y-axis pixel shift for positioning the album artwork.",
            "mediaPlayerWaveThickness": "Thickness of the wavy timeline stroke inside the media player widget.",
            "mediaPlayerOrientation": "Choose between a Horizontal or Vertical layout for the Media Player.",
            "mediaPlayerLyricsExpansion": "Direction in which the media player expands to show lyrics.",
            "mediaPlayerLyricsAutoScroll": "Enable automatic scrolling and active line highlighting for synchronized lyrics.",
            "desktopMediaPlayerAnchorExpandFix": "Prevent desktop media player anchor from shifting position when expanded.",
            "desktopAudioVisualizerShape": "The shape of each individual bar itself (what each little glyph looks like) — not where the bars are positioned. Only used when Bar Shape Mode is Single. Has no effect in Lines mode, which has no per-bar shapes.",
            "desktopAudioVisualizerShapeMode": "Single uses the one Bar Shape for every bar; All Shapes cycles every bar through the full set of M3 shapes instead. Has no effect in Lines mode.",
            "desktopAudioVisualizerColorMode": "Theme uses the shell's own accent gradient, warming toward louder bars. Custom paints every bar a single flat color. Gradient fills each shape with a two-color blend.",
            "desktopAudioVisualizerColor": "The color used for every bar when Color Mode is set to Custom. Has no effect otherwise.",
            "desktopAudioVisualizerGradientStart": "The first color of the two-color gradient painted across each shape when Color Mode is set to Gradient.",
            "desktopAudioVisualizerGradientEnd": "The second color of the two-color gradient painted across each shape when Color Mode is set to Gradient.",
            "desktopAudioVisualizerLayout": "Arrange the visualizer's bars in a horizontal Linear row, spread around an outline in Circular mode, fill a square matrix cropped to a shape's silhouette in Grid mode, or connect every bar's peak into one continuous stroked line in Lines mode — a classic spectrum-line look with no individual shapes.",
            "desktopAudioVisualizerLineArrangement": "Only used in Lines mode. Row draws the connected line flat, like Linear's bars would sit. Shape traces it around Position Shape's outline instead — the same outline Circular's shapes sit on — as a closed loop that pulses outward with the beat.",
            "desktopAudioVisualizerPositionShape": "In Circular mode, the outline the bars are spread around and pulse outward from. In Grid mode, the silhouette the whole matrix is cropped to instead — a Circle for a round viewport, or an organic M3 shape (like one of the Cookies) for a wobbly, not-quite-round edge. Has no effect in Linear or Lines mode.",
            "desktopAudioVisualizerShapeSize": "Size in pixels of each individual shape in the audio visualizer.",
            "desktopAudioVisualizerLineThickness": "Stroke width in pixels of the connected line in Lines mode. Has no effect in Linear, Circular or Grid mode.",
            "desktopAudioVisualizerLineMirror": "Folds the data in half and plays it back out, so bass sits at both ends of the row and treble meets in the middle — a symmetric, two-channel look. Only used in Lines mode's Row arrangement; has no effect on the Shape arrangement's closed loop.",
            "desktopAudioVisualizerLineDirection": "Which way the row reads, including rotating it onto a vertical column (Top to Bottom / Bottom to Top). Only used in Lines mode's Row arrangement; has no effect on the Shape arrangement's closed loop.",
            "desktopAudioVisualizerSpacing": "Gap in pixels between neighboring shapes in the audio visualizer.",
            "desktopAudioVisualizerRadius": "In Circular mode, the overall radius of the outline the shapes sit on. In Grid mode, how far a shape gets pushed out of its cell on a loud beat — turn it up for a more energetic matrix, down to keep it settled. Has no effect in Linear or Lines mode.",
            "desktopAudioVisualizerPresets": "Save the current shape, layout, size, spacing and radius as a named preset, and reapply or delete saved ones.",
            "gameMode": "The Quickshell half of Game Mode — hides every desktop widget (clock, calendar, media player, system vitals, audio visualizer) and fully stops their polling and subprocesses instead of just pausing their animations, drops panel and card corners to lighter 4x anti-aliasing, and turns off translucency. Toggling the main Game Mode switch (under System & Apps) sets this automatically and restarts the shell to apply it; this one only exists to flip it on its own, without touching Hyprland's side.",
            "reduceMotion": "Skips the shell's corner-rounding and shape-morph animations instead of playing them, for anyone motion-sensitive or who just wants the UI to snap instantly. Unlike Game Mode, nothing is hidden and nothing stops polling — only the animated transitions themselves are removed.",
            "reduceTransparency": "Forces card, panel and widget backgrounds fully opaque instead of blending them against whatever's behind them, for readability on busy wallpapers or just a flatter, higher-contrast look. Overrides the Global Style choice back to opaque without changing which one is selected (Solid / Translucent). Does not currently affect the separate Hyprland Liquid Glass plugin.",
            "animationDuration": "Master transition duration in milliseconds for interface micro-animations.",
            "flickDeceleration": "Friction rate applied when coasting through scrollable UI flick views.",
            "maximumFlickVelocity": "Maximum speed velocity clamp for touch and mouse scroll swiping.",
            "blurAmount": "Gaussian background blur radius applied behind translucent shell elements and windows.",
            "panelOpacity": "Global opacity level for main background panels and floating windows.",
            "componentOpacity": "Global opacity level for interactive components and lists inside panels.",
            "radiusAmount": "Master multiplication ratio applied to window and container corner roundings.",
            "cornerPower": "Adjusts corner curvature (2.0 = standard circle, >2.0 = squircle/super-ellipse).",
            "fontFamily": "Primary typography font family used across Quickshell overlays and panels.",
            "fontWeight": "Variable font weight or static font weight matching (100 to 900).",
            "fontItalic": "Enable italic font style for the primary interface typography.",
            "fontRounding": "Variable font rounding axis (ROND) for softer typography contours.",
            "fontGrading": "Variable font grading axis (GRAD) for modifying visual weight without affecting text flow.",
            "fontBaselineEnabled": "Make font weight, grade, and round settings act as a global additive baseline, preserving semantic boldness.",
            "pillPosition": "Select the edge of the display monitor where the shell control bar is docked.",
            "clockPillMode": "Configure clock pill behavior: Always Visible (reserves exclusive screen margin so windows stay clear), Dodge Windows (visible on empty screen, automatically hides when windows overlap/push it like in KDE), or Auto Hide (reveals on hover).",
            "panelStyle": "Choose between Floating, Attached (flush), or Framed shell bar geometry.",
            "gaps_in": "Spacing distance in pixels between adjacent tiled windows on the workspace.",
            "gaps_out": "Spacing distance in pixels between tiled windows and the outer display monitor screen edge.",
            "border_size": "Thickness in pixels of the colored focus outline ring surrounding windows.",
            "rounding": "Radius in pixels for window frame corner curves.",
            "rounding_power": "Super-ellipse curvature exponent controlling squished rounded corner smoothness.",
            "active_opacity": "Translucency alpha level applied to currently focused active application windows.",
            "inactive_opacity": "Translucency alpha level applied to background unfocused application windows.",
            "follow_mouse": "Determine whether input focus automatically changes to the window directly beneath the pointer.",
            "sensitivity": "Hardware input multiplier scaling pointer movement speed and sensitivity.",
            "touchpad_natural_scroll": "Invert vertical scroll direction on touchpads to mimic direct touch dragging.",
            "force_default_wallpaper": "Control display of standard anime backgrounds when starting the Hyprland compositor.",
            "gesture_direction": "Direction axes monitored when swiping with multi-touch workspace transitions.",
            "AnimateStyle": "Active motion choreography flavor defining easing mechanics and window transitions.",
            "Layout": "Tiling layout algorithm arranging windows (Dwindle, Master, Scrolling, or Monocle).",
            "radiusSmall": "Configure the small rounding radius applied to minor UI components.",
            "radiusMedium": "Configure the medium rounding radius applied to standard UI components.",
            "radiusLarge": "Configure the large rounding radius applied to prominent UI containers.",
            "radiusExtraLarge": "Configure the extra-large rounding radius applied to major interface elements.",
            "spacingSmall": "Configure the small spacing gap between closely related elements.",
            "spacingMedium": "Configure the medium spacing gap between standard elements.",
            "spacingLarge": "Configure the large spacing gap between distinct sections.",
            "paddingSmall": "Configure the small internal padding for minor UI components.",
            "paddingMedium": "Configure the medium internal padding for standard UI components.",
            "paddingLarge": "Configure the large internal padding for major UI containers."
        };
        if (descriptions[key]) return descriptions[key];
        if (!rawHelp || rawHelp === "Quickshell variable" || rawHelp === "Hyprland variable") {
            return "Configure " + rootPage.prettyTitle(key) + " (" + key + ") settings for your environment.";
        }
        return rawHelp;
    }

    // Live when the shell can apply it without a restart (decided by SettingsApply, not by a list)
    function updateVariable(key, val, source) {
        SettingsApply.set(source, key, val);
    }

    function loadSettings() {
        rootPage.allVars = [];
        hyprManagerProc.running = true;
        qsManagerProc.running = true;
    }

    Component.onCompleted: {
        loadSettings();
    }

    M3Shapes { id: m3Shapes }

    RowLayout {
        Layout.fillWidth: true
        spacing: 12

        Item {
            width: 38
            height: 38

            Image {
                anchors.fill: parent
                sourceSize: Qt.size(width, height)
                source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='" + m3Shapes.getPath(rootPage.pageShape) + "' fill='" + String(rootPage.pageColor || "#3b383e").replace("#", "%23") + "'/></svg>"
                smooth: true
                antialiasing: true
            }

            QsText {
                anchors.centerIn: parent
                text: rootPage.pageIcon
                font.family: "Material Symbols Outlined"
                font.pixelSize: 20
                color: rootPage.pageOnColor
            }
        }

        QsText {
            Layout.fillWidth: true
            text: rootPage.pageTitle
            font.family: Vars.fontFamily
            font.pixelSize: 18
            setWeight: 600
            color: Theme.on_surface
            elide: Text.ElideRight
        }
    }



    ListModel {
        id: settingsModel
        ListElement {
            key: ""
            type: ""
            help: ""
            enums: ""
            val: ""
            category: ""
            source: ""
            min: 0.0
            max: 0.0
            step: 0.0
        }
    }

    ListView {
        id: settingsList
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 4
        model: settingsModel
        focus: true
        bottomMargin: 112

        // boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: Vars.flickDeceleration
        maximumFlickVelocity: Vars.maximumFlickVelocity

        Keys.onReturnPressed: {
            if (currentItem) {
                currentItem.triggerAction();
            }
        }
        Keys.onSpacePressed: {
            if (currentItem) {
                currentItem.triggerAction();
            }
        }
        Keys.onRightPressed: {
            if (currentItem)
                currentItem.triggerAction();
        }
        
        property bool vimKeysEnabled: false
        Process {
            id: vimKeysChecker
            command: ["bash", "-c", "grep -qi 'vimkeys[ \t]*=[ \t]*true' /home/boing/Dotfiles/hypr/modules/variables.lua && echo 'true' || echo 'false'"]
            running: true
            stdout: StdioCollector {
                onStreamFinished: {
                    settingsList.vimKeysEnabled = (this.text.trim() === 'true');
                }
            }
        }

        Keys.onPressed: (event) => {
            if (settingsList.vimKeysEnabled) {
                if (event.key === Qt.Key_J || event.key === Qt.Key_S) {
                    incrementCurrentIndex();
                    event.accepted = true;
                } else if (event.key === Qt.Key_K || event.key === Qt.Key_D) {
                    if (currentIndex > 0) {
                        decrementCurrentIndex();
                    }
                    event.accepted = true;
                } else if (event.key === Qt.Key_L || event.key === Qt.Key_H || event.key === Qt.Key_F || event.key === Qt.Key_A) {
                    if (currentItem) currentItem.triggerAction();
                    event.accepted = true;
                }
            }
        }

        section.property: "source"
        section.criteria: ViewSection.FullString
        section.labelPositioning: ViewSection.InlineLabels
        section.delegate: Item {
            width: ListView.view.width
            height: 52
            z: 2

            RowLayout {
                anchors {
                    left: parent.left; right: parent.right
                    verticalCenter: parent.verticalCenter
                    leftMargin: 2; rightMargin: 2
                }
                spacing: 10

                // Pill section badge
                Rectangle {
                    implicitWidth: sectionBadgeText.implicitWidth + 18
                    implicitHeight: 24
                    radius: 12
                    antialiasing: true
                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                    Layout.alignment: Qt.AlignVCenter

                    QsText {
                        id: sectionBadgeText
                        anchors.centerIn: parent
                        text: section
                        color: Theme.primary
                        font.pixelSize: 11
                        setWeight: 700
                        font.family: Vars.fontFamily
                        font.letterSpacing: 0.8
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.1)
                }
            }
        }

        delegate: UnifiedSettingsDelegate {
        }
    }

    Process {
        id: hyprManagerProc
        command: ["/home/boing/.local/bin/omniformis", "hypr", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n");
                var newVars = [];
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.length === 0)
                        continue;

                    var openBracketIdx = line.indexOf("[");
                    var closeBracketIdx = line.indexOf("]", openBracketIdx);
                    if (openBracketIdx === -1 || closeBracketIdx === -1)
                        continue;

                    var leftPart = line.substring(0, openBracketIdx).trim();
                    var valPart = line.substring(openBracketIdx + 1, closeBracketIdx);

                    var dashIdx = line.indexOf("- ", closeBracketIdx);
                    var rawHelp = dashIdx !== -1 ? line.substring(dashIdx + 2).trim() : "";
                    var category = "General";
                    var pipeIdx = rawHelp.indexOf(" | ");
                    var helpPart = rawHelp;
                    if (pipeIdx !== -1) {
                        category = rawHelp.substring(0, pipeIdx).trim();
                        category = category.replace(/^-+\s*/, "");
                        helpPart = rawHelp.substring(pipeIdx + 3).trim();
                    }

                    var colonIdx = leftPart.indexOf(":");
                    if (colonIdx === -1) continue;
                    var key = leftPart.substring(0, colonIdx).trim();
                    var typePart = leftPart.substring(colonIdx + 1).trim();

                    // CRITICAL RULE: ALL wallpaper, wallpaper mask, clock, calendar, and desktop widgets MUST route to the "Desktop" category ("Desktop & Widgets"). NEVER place them in "Theme".
                    // Map hyprland variables to specialized UI categories
                    if (key === "GameMode") {
                        category = "GameMode";
                    } else if (key.toLowerCase().includes("wallpaper") || key.toLowerCase().includes("mask") || key.startsWith("desktop")) {
                        category = "Desktop";
                    } else if (key === "gaps_in" || key === "gaps_out" || key === "singleWindowGapsOut" || key === "enableSingleWindowGaps" || key === "enableSpecialWorkspaceGaps" || key === "border_size" || key === "groupBar" || key === "Layout" || key === "resize_on_border") {
                        category = "Layout";
                    } else if (key === "rounding" || key === "rounding_power" || key === "active_opacity" || key === "inactive_opacity" || key === "windowOpacity" || category === "Shadows" || category === "Blur" || key.startsWith("shadow_") || key.startsWith("blur_")) {
                        category = "Theme";
                    } else if (category === "Animation Style" || key === "AnimateStyle" || key.startsWith("Custom")) {
                        category = "Animations";
                    } else if (category === "Modifiers" || category === "Navigation Keys" || category === "Quickshell Keybinds" || key === "MM" || key === "SM" || key === "TM" || key === "QM" || key.startsWith("Qs") || key === "QuickLauncherKey") {
                        category = "Keybinds";
                    } else if (category === "Input" || category === "Gestures" || key.startsWith("kb_") || key.startsWith("gesture_") || key === "follow_mouse" || key === "sensitivity" || key === "touchpad_natural_scroll" || key === "vimkeys") {
                        category = "Input";
                    } else {
                        category = "General";
                    }

                    var type = "string";
                    var enums = [];
                    if (typePart === "togglable bool") {
                        type = "bool";
                    } else if (typePart.startsWith("enum")) {
                        type = "enum";
                        var match = typePart.match(/\((.*)\)/);
                        if (match) {
                            enums = match[1].split(",").map(function (s) {
                                return s.trim();
                            });
                        }
                    } else if (typePart === "number" || typePart === "int") {
                        type = "number";
                    }

                    var min = 0;
                    var max = 0;
                    var step = 0;

                    if (type === "number") {
                        if (key === "gaps_in") {
                            type = "slider";
                            max = 50;
                            step = 1;
                        } else if (key === "gaps_out") {
                            type = "slider";
                            max = 100;
                            step = 1;
                        } else if (key === "singleWindowGapsOut") {
                            type = "slider";
                            max = 100;
                            step = 1;
                        } else if (key === "border_size") {
                            type = "slider";
                            max = 20;
                            step = 1;
                        } else if (key === "rounding") {
                            type = "slider";
                            max = 50;
                            step = 1;
                        } else if (key === "rounding_power") {
                            type = "slider";
                            min = 1.0;
                            max = 50.0;
                            step = 1.0;
                        } else if (key === "active_opacity" || key === "inactive_opacity" || key === "windowOpacity") {
                            type = "slider";
                            min = 0.0;
                            max = 1.0;
                            step = 0.05;
                        } else if (key === "shadow_range") {
                            type = "slider";
                            max = 100;
                            step = 1;
                        } else if (key === "shadow_render_power") {
                            type = "slider";
                            min = 1;
                            max = 4;
                            step = 1;
                        } else if (key === "blur_size") {
                            type = "slider";
                            max = 20;
                            step = 1;
                        } else if (key === "blur_passes") {
                            type = "slider";
                            max = 10;
                            step = 1;
                        } else if (key === "blur_vibrancy") {
                            type = "slider";
                            min = 0.0;
                            max = 1.0;
                            step = 0.05;
                        } else if (key === "gesture_fingers") {
                            type = "slider";
                            min = 3;
                            max = 5;
                            step = 1;
                        } else if (key === "env_xcursor_size" || key === "env_hyprcursor_size") {
                            type = "slider";
                            min = 16;
                            max = 64;
                            step = 2;
                        } else if (key === "vrr") {
                            type = "enum";
                            enums = ["0", "1", "2"];
                        } else if (key === "sensitivity") {
                            type = "slider";
                            min = -1.0;
                            max = 1.0;
                            step = 0.05;
                        }
                    }

                    // Ensure Hyprland enumerable properties use segmented selection chips in UI
                    if (key === "Layout") {
                        type = "enum";
                        enums = ["Scrolling", "Dwindle", "Master", "Monocle"];
                    } else if (key === "gesture_direction") {
                        type = "enum";
                        enums = ["vertical", "horizontal", "both", "all", "none"];
                    } else if (key === "force_default_wallpaper") {
                        type = "enum";
                        enums = ["-1", "0", "1", "2", "3"];
                    } else if (key === "AnimateStyle" && (enums.length === 0 || type !== "enum")) {
                        type = "enum";
                        enums = ["expressive", "spring", "jelly", "flyingcards", "snappy", "cinematic", "minimal", "fluid", "aggressive", "elegant", "playful", "elastic", "swift", "relaxed", "slipstream", "standard", "fluent", "custom", "none"];
                    }

                    newVars.push({
                        key: key,
                        type: type,
                        help: helpPart,
                        enums: enums.join("|||"),
                        val: valPart,
                        category: category,
                        source: "Hyprland",
                        min: min,
                        max: max,
                        step: step
                    });
                }

                rootPage.allVars = rootPage.allVars.concat(newVars);
                applyFilter();
            }
        }
    }

    Process {
        id: qsManagerProc
        command: ["/home/boing/.local/bin/omniformis", "qs", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n");
                var newVars = [];
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.length === 0)
                        continue;

                    var colonIdx = line.indexOf(":");
                    if (colonIdx === -1)
                        continue;

                    var key = line.substring(0, colonIdx).trim();
                    if (key === "notificationHistory" || key === "historyUpdated" || key === "historyChanged" || key === "translucent" || key === "liquidGlass")
                        continue;

                    var valPart = line.substring(colonIdx + 1).trim();
                    if (valPart.startsWith('"') && valPart.endsWith('"')) {
                        valPart = valPart.substring(1, valPart.length - 1);
                    }

                    var type = "string";
                    if (valPart === "true" || valPart === "false") {
                        type = "bool";
                    } else if (!isNaN(Number(valPart)) && valPart !== "") {
                        type = "number";
                    }

                    // CRITICAL RULE: ALL wallpaper, wallpaper mask, clock, calendar, and desktop widgets MUST route to the "Desktop" category ("Desktop & Widgets"). NEVER place them in "Theme".
                    // Map quickshell variables to specialized UI categories
                    var category = "General";
                    if (key === "gameMode") {
                        category = "GameMode";
                    } else if (key === "clockPillMode" || key === "panelStyle" || key === "pillPosition") {
                        category = "Layout";
                    } else if (key.startsWith("desktop") || key.startsWith("clock") || key.startsWith("mediaPlayer") || key.startsWith("overview") || key.toLowerCase().includes("wallpaper") || key.toLowerCase().includes("mask")) {
                        category = "Desktop";
                    } else if (key.startsWith("spacing") || key.startsWith("padding")) {
                        category = "Layout";
                    } else if (key.startsWith("radius") || key === "cornerPower" || key === "blurAmount" || key === "panelOpacity" || key === "componentOpacity" || key === "fontFamily" || key === "fontWeight" || key === "fontItalic" || key === "fontRounding" || key === "fontGrading" || key === "fontBaselineEnabled" || key === "liquidGlassPreset") {
                        category = "Theme";
                    } else if (key === "animationDuration" || key === "flickDeceleration" || key === "maximumFlickVelocity" || key.startsWith("custom") || key.startsWith("m3")) {
                        category = "Animations";
                    } else {
                        category = "General";
                    }

                    var min = 0;
                    var max = 0;
                    var step = 0;
                    if (key.includes("Duration")) {
                        type = "slider";
                        min = 0;
                        max = 1000;
                        step = 10;
                    } else if (key === "radiusAmount") {
                        type = "slider";
                        min = 0.0;
                        max = 1.0;
                        step = 0.05;
                    } else if (key === "cornerPower") {
                        type = "slider";
                        min = 2.0;
                        max = 10.0;
                        step = 0.1;
                    } else if (key.toLowerCase().includes("opacity")) {
                        type = "slider";
                        min = 0.0;
                        max = 1.0;
                        step = 0.1;
                    } else if (key === "blurAmount") {
                        type = "slider";
                        min = 0;
                        max = 100;
                        step = 1;
                    } else if (key === "panelOpacity" || key === "componentOpacity") {
                        type = "slider";
                        min = 0.0;
                        max = 1.0;
                        step = 0.05;
                    } else if (key === "mediaPlayerWaveThickness") {
                        type = "slider";
                        min = 1.0;
                        max = 10.0;
                        step = 0.5;
                    } else if (key === "clockHandThickness") {
                        type = "slider";
                        min = 2;
                        max = 24;
                        step = 1;
                    } else if (key === "fontWeight") {
                        type = "slider";
                        min = 100;
                        max = 1000;
                        step = 100;
                    } else if (key === "fontRounding") {
                        type = "slider";
                        min = 0;
                        max = 100;
                        step = 1;
                    } else if (key === "fontGrading") {
                        type = "slider";
                        min = -200;
                        max = 150;
                        step = 1;
                    } else if (key.startsWith("radius") || key.startsWith("spacing") || key.startsWith("padding")) {
                        type = "slider";
                        min = 0;
                        max = 50;
                        step = 1;
                    } else if (key.includes("Scale")) {
                        type = "slider";
                        min = 0.1;
                        max = 2.0;
                        step = 0.05;
                    } else if (key.includes("Rows") || key.includes("Columns")) {
                        type = "slider";
                        min = 1;
                        max = 20;
                        step = 1;
                    } else if (key === "wallpaperMaskOffsetX" || key === "wallpaperMaskOffsetY" || key === "mediaPlayerArtOffsetX" || key === "mediaPlayerArtOffsetY") {
                        type = "slider";
                        min = -500;
                        max = 500;
                        step = 1;
                    } else if (key.endsWith("AnchorCurve")) {
                        type = "slider";
                        min = 0;
                        max = 20; // Will be overridden in the delegate dynamically
                        step = 1;
                    } else if (key === "desktopAudioVisualizerBars") {
                        type = "slider";
                        min = 4;
                        max = 64;
                        step = 1;
                    } else if (key === "desktopAudioVisualizerShapeSize") {
                        type = "slider";
                        min = 8;
                        max = 60;
                        step = 1;
                    } else if (key === "desktopAudioVisualizerLineDirection") {
                        type = "enum";
                        enumsStr = "Left to Right|||Right to Left|||Top to Bottom|||Bottom to Top";
                    } else if (key === "desktopAudioVisualizerLineThickness") {
                        type = "slider";
                        min = 1;
                        max = 16;
                        step = 0.5;
                    } else if (key === "desktopAudioVisualizerSpacing") {
                        type = "slider";
                        min = 0;
                        max = 40;
                        step = 1;
                    } else if (key === "desktopAudioVisualizerRadius") {
                        type = "slider";
                        min = 20;
                        max = 150;
                        step = 1;
                    }

                    var enumsStr = "";
                    if (key === "wallpaperMaskShape") {
                        type = "shape";
                        enumsStr = "Circle|||Square|||Slanted|||Arch|||Flag|||Arrow|||Semicircle|||Oval|||Pill|||Triangle|||Diamond|||Clamshell|||Pentagon|||Gem|||VerySunny|||Sunny|||4SidedCookie|||6SidedCookie|||7SidedCookie|||9SidedCookie|||12SidedCookie|||GhostIsh|||4LeafClover|||8LeafClover|||Burst|||SoftBurst|||Boom|||SoftBoom|||Flower|||Puffy|||PuffyDiamond|||PixelCircle|||PixelTriangle|||Bun|||Heart";
                    } else if (key === "wallpaperMaskColor" || key === "clockDateBadgeColor") {
                        type = "color";
                        enumsStr = "transparent|||background|||primary|||secondary|||tertiary|||surface_variant|||error";
                    } else if (key === "wallpaperMaskEnabled" || key === "fontItalic" || key === "fontBaselineEnabled") {
                        type = "bool";
                    } else if (key === "clockShape" || key === "clockDateShape") {
                        type = "shape";
                        enumsStr = "Circle|||Square|||VerySunny|||Sunny|||4SidedCookie|||6SidedCookie|||7SidedCookie|||9SidedCookie|||12SidedCookie|||SoftBurst|||SoftBoom|||Flower|||Puffy|||Bun";
                    } else if (key === "clockSecondHandStyle") {
                        type = "enum";
                        enumsStr = "Orbiting Dot|||Traditional Line|||Hidden";
                    } else if (key === "mediaPlayerShape") {
                        type = "shape";
                        enumsStr = "Circle|||Square|||Slanted|||Arch|||Flag|||Arrow|||Semicircle|||Oval|||Pill|||Triangle|||Diamond|||Clamshell|||Pentagon|||Gem|||VerySunny|||Sunny|||4SidedCookie|||6SidedCookie|||7SidedCookie|||9SidedCookie|||12SidedCookie|||GhostIsh|||4LeafClover|||8LeafClover|||Burst|||SoftBurst|||Boom|||SoftBoom|||Flower|||Puffy|||PuffyDiamond|||PixelCircle|||PixelTriangle|||Bun|||Heart";
                    } else if (key === "mediaPlayerOrientation" || key === "mediaPlayerLyricsExpansion") {
                        type = "enum";
                        enumsStr = "Horizontal|||Vertical";
                    } else if (key === "panelStyle") {
                        type = "enum";
                        enumsStr = "Floating|||Attached|||Framed";
                    } else if (key === "clockPillMode") {
                        type = "enum";
                        enumsStr = "Always Visible|||Dodge Windows|||Auto Hide";
                    } else if (key === "liquidGlassPreset") {
                        type = "enum";
                        enumsStr = "glass|||apple|||clear|||contrasted";
                    } else if (key.endsWith("AnchorPoint")) {
                        type = "enum";
                        enumsStr = "TopLeft|||TopCenter|||TopRight|||MiddleLeft|||Center|||MiddleRight|||BottomLeft|||BottomCenter|||BottomRight";
                    } else if (key === "desktopAudioVisualizerShape") {
                        type = "shape";
                        enumsStr = "Circle|||Square|||Slanted|||Arch|||Flag|||Arrow|||Semicircle|||Oval|||Pill|||Triangle|||Diamond|||Clamshell|||Pentagon|||Gem|||VerySunny|||Sunny|||4SidedCookie|||6SidedCookie|||7SidedCookie|||9SidedCookie|||12SidedCookie|||GhostIsh|||4LeafClover|||8LeafClover|||Burst|||SoftBurst|||Boom|||SoftBoom|||Flower|||Puffy|||PuffyDiamond|||PixelCircle|||PixelTriangle|||Bun|||Heart";
                    } else if (key === "desktopAudioVisualizerLayout") {
                        type = "enum";
                        enumsStr = "Linear|||Circular|||Grid|||Lines";
                    } else if (key === "desktopAudioVisualizerLineArrangement") {
                        type = "enum";
                        enumsStr = "Row|||Shape";
                    } else if (key === "desktopAudioVisualizerShapeMode") {
                        type = "enum";
                        enumsStr = "Single|||All Shapes";
                    } else if (key === "desktopAudioVisualizerColorMode") {
                        type = "enum";
                        enumsStr = "Theme|||Custom|||Gradient";
                    } else if (key === "desktopAudioVisualizerColor" || key === "desktopAudioVisualizerGradientStart" || key === "desktopAudioVisualizerGradientEnd") {
                        type = "color";
                        enumsStr = "primary|||secondary|||tertiary|||surface_variant|||error|||background";
                    } else if (key === "desktopAudioVisualizerPresets") {
                        type = "presetManager";
                    } else if (key === "desktopAudioVisualizerPositionShape") {
                        type = "shape";
                        enumsStr = "Circle|||Square|||Slanted|||Arch|||Flag|||Arrow|||Semicircle|||Oval|||Pill|||Triangle|||Diamond|||Clamshell|||Pentagon|||Gem|||VerySunny|||Sunny|||4SidedCookie|||6SidedCookie|||7SidedCookie|||9SidedCookie|||12SidedCookie|||GhostIsh|||4LeafClover|||8LeafClover|||Burst|||SoftBurst|||Boom|||SoftBoom|||Flower|||Puffy|||PuffyDiamond|||PixelCircle|||PixelTriangle|||Bun|||Heart";
                    }

                    newVars.push({
                        key: key,
                        type: type,
                        help: "Quickshell variable",
                        enums: enumsStr,
                        val: valPart,
                        category: category,
                        source: "Quickshell",
                        min: min,
                        max: max,
                        step: step
                    });
                }

                rootPage.allVars = rootPage.allVars.concat(newVars);
                applyFilter();
            }
        }
    }

    function applyFilter() {
        var term = rootPage.searchText.trim();
        settingsModel.clear();
        var filteredVars = [];
        for (var k = 0; k < rootPage.allVars.length; k++) {
            var v = rootPage.allVars[k];
            if (v.category !== rootPage.activeCategory)
                continue;
            if (term === "" || Vars.fuzzyMatch(term, v.key) || Vars.fuzzyMatch(term, v.help)) {
                filteredVars.push(v);
            }
        }
        filteredVars.sort(function (a, b) {
            if (a.source !== b.source) {
                return a.source.localeCompare(b.source);
            }
            return a.key.localeCompare(b.key);
        });
        for (var i = 0; i < filteredVars.length; i++) {
            settingsModel.append(filteredVars[i]);
        }
    }

    Item {
        id: fabContainer
        Layout.preferredWidth: 0
        Layout.preferredHeight: 0

        Item {
            id: reloadFab
            width: 64
            height: 64
            x: rootPage.width - width - 32 - fabContainer.x
            y: rootPage.height - height - 32 - fabContainer.y
            property real radius: width / 2
            z: 100

            Rectangle {
                id: fabMask
                layer.enabled: true
                layer.smooth: true
                layer.samples: Vars.layerSamples
                anchors.fill: parent
                radius: reloadFab.radius
                antialiasing: true
                color: "black"
                visible: false
            }

            Item {
                id: shadowContainer
                anchors.fill: parent

                Item {
                    id: finalMaskedContainer
                    anchors.fill: parent
                    layer.enabled: true
                    layer.smooth: true
                    layer.samples: Vars.layerSamples
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: fabMask
                    }

                    ShaderEffectSource {
                        anchors.fill: parent
                        sourceItem: settingsList
                        sourceRect: Qt.rect(rootPage.width - reloadFab.width - 32 - settingsList.x, rootPage.height - reloadFab.height - 32 - settingsList.y, reloadFab.width, reloadFab.height)
                        
                        layer.enabled: true
                        layer.smooth: true
                        layer.samples: Vars.layerSamples
                        layer.effect: MultiEffect {
                            blurEnabled: true
                            blurMax: Vars.blurAmount
                            blur: 1.0
                            autoPaddingEnabled: false
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: reloadFab.radius
                        antialiasing: true
                        color: Vars.tColor(Theme.primary, Vars.componentOpacity)
                        border.color: Theme.outline_variant
                        border.width: 1
                    }
                }
            }

            QsText {
                id: fabIcon
                anchors.centerIn: parent
                text: "refresh"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 28
                color: Theme.on_primary
            }

            SequentialAnimation {
                id: fabShapeAnim
                NumberAnimation {
                    target: reloadFab
                    property: "radius"
                    to: 16
                    duration: 250
                    easing.type: Easing.OutQuad
                }
                NumberAnimation {
                    target: reloadFab
                    property: "radius"
                    to: 32
                    duration: 250
                    easing.type: Easing.InQuad
                }
                ScriptAction {
                    script: {
                        var reloadCmd = JSON.stringify(["sh", "-c", "setsid bash $HOME/Dotfiles/scripts/reload.sh > /dev/null 2>&1 &"]);
                        var p = Qt.createQmlObject('import Quickshell.Io; Process { command: ' + reloadCmd + '; onExited: destroy() }', rootPage);
                        p.running = true;
                    }
                }
            }

            SequentialAnimation {
                id: fabIconAnim
                RotationAnimation {
                    target: fabIcon
                    property: "rotation"
                    from: 0
                    to: 360
                    duration: 500
                    easing.type: Easing.InOutCubic
                }
                ScriptAction {
                    script: fabIcon.rotation = 0
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!fabShapeAnim.running) {
                        fabShapeAnim.start();
                        fabIconAnim.start();
                    }
                }
            }
        }
    }
}
