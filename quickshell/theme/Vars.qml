pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "variables.js" as RawVars

QtObject {
    id: root

    property real radiusAmount: RawVars.radiusAmount !== undefined ? RawVars.radiusAmount : 0
    property real baseRadiusSmall: RawVars.radiusSmall !== undefined ? RawVars.radiusSmall : 0
    property real radiusSmall: baseRadiusSmall * (radiusAmount * 2)
    property real radiusMedium: (baseRadiusSmall + paddingSmall) * (radiusAmount * 2)
    property real radiusLarge: (baseRadiusSmall + paddingSmall + paddingMedium) * (radiusAmount * 2)
    property real radiusExtraLarge: (baseRadiusSmall + paddingSmall + paddingMedium + paddingLarge) * (radiusAmount * 2)
    property real cornerPower: RawVars.cornerPower !== undefined ? RawVars.cornerPower : 0
    property real spacingSmall: RawVars.spacingSmall !== undefined ? RawVars.spacingSmall : 0
    property real spacingMedium: RawVars.spacingMedium !== undefined ? RawVars.spacingMedium : 0
    property real spacingLarge: RawVars.spacingLarge !== undefined ? RawVars.spacingLarge : 0
    property real paddingSmall: RawVars.paddingSmall !== undefined ? RawVars.paddingSmall : 0
    property real paddingMedium: RawVars.paddingMedium !== undefined ? RawVars.paddingMedium : 0
    property real paddingLarge: RawVars.paddingLarge !== undefined ? RawVars.paddingLarge : 0
    property string fontFamily: RawVars.fontFamily !== undefined ? RawVars.fontFamily : ""
    property real fontWeight: RawVars.fontWeight !== undefined ? RawVars.fontWeight : 0
    property bool fontItalic: RawVars.fontItalic !== undefined ? RawVars.fontItalic : false
    property real fontRounding: RawVars.fontRounding !== undefined ? RawVars.fontRounding : 0
    property real fontGrading: RawVars.fontGrading !== undefined ? RawVars.fontGrading : 0
    property bool fontBaselineEnabled: RawVars.fontBaselineEnabled !== undefined ? RawVars.fontBaselineEnabled : false
    property real animationDuration: RawVars.animationDuration !== undefined ? RawVars.animationDuration : 0
    property real flickDeceleration: RawVars.flickDeceleration !== undefined ? RawVars.flickDeceleration : 0
    property real maximumFlickVelocity: RawVars.maximumFlickVelocity !== undefined ? RawVars.maximumFlickVelocity : 0
    property bool _translucent: RawVars._translucent !== undefined ? RawVars._translucent : false
    property bool _liquidGlass: RawVars._liquidGlass !== undefined ? RawVars._liquidGlass : false
    property real blurAmount: RawVars.blurAmount !== undefined ? RawVars.blurAmount : 0
    property real panelOpacity: RawVars.panelOpacity !== undefined ? RawVars.panelOpacity : 0
    property real componentOpacity: RawVars.componentOpacity !== undefined ? RawVars.componentOpacity : 0
    property real currentBrightness: RawVars.currentBrightness !== undefined ? RawVars.currentBrightness : 0
    property real overviewGridRows: RawVars.overviewGridRows !== undefined ? RawVars.overviewGridRows : 0
    property real overviewGridColumns: RawVars.overviewGridColumns !== undefined ? RawVars.overviewGridColumns : 0
    property real overviewScale: RawVars.overviewScale !== undefined ? RawVars.overviewScale : 0
    property real gameLibraryRows: RawVars.gameLibraryRows !== undefined ? RawVars.gameLibraryRows : 0
    property real gameLibraryColumns: RawVars.gameLibraryColumns !== undefined ? RawVars.gameLibraryColumns : 0
    property real gameLibraryScale: RawVars.gameLibraryScale !== undefined ? RawVars.gameLibraryScale : 0
    property bool wallpaperMaskEnabled: RawVars.wallpaperMaskEnabled !== undefined ? RawVars.wallpaperMaskEnabled : false
    property real wallpaperMaskScale: RawVars.wallpaperMaskScale !== undefined ? RawVars.wallpaperMaskScale : 0
    property string wallpaperMaskShape: RawVars.wallpaperMaskShape !== undefined ? RawVars.wallpaperMaskShape : ""
    property string wallpaperMaskColor: RawVars.wallpaperMaskColor !== undefined ? RawVars.wallpaperMaskColor : ""
    property real wallpaperMaskOffsetX: RawVars.wallpaperMaskOffsetX !== undefined ? RawVars.wallpaperMaskOffsetX : 0
    property real wallpaperMaskOffsetY: RawVars.wallpaperMaskOffsetY !== undefined ? RawVars.wallpaperMaskOffsetY : 0
    property string clockShape: RawVars.clockShape !== undefined ? RawVars.clockShape : ""
    property bool clockShowTicks: RawVars.clockShowTicks !== undefined ? RawVars.clockShowTicks : false
    property bool clockShowCenterDot: RawVars.clockShowCenterDot !== undefined ? RawVars.clockShowCenterDot : false
    property bool clockShowDate: RawVars.clockShowDate !== undefined ? RawVars.clockShowDate : true
    property string clockSecondHandStyle: RawVars.clockSecondHandStyle !== undefined ? RawVars.clockSecondHandStyle : "Orbiting Dot"
    property real clockHandThickness: RawVars.clockHandThickness !== undefined ? RawVars.clockHandThickness : 15
    property string mediaPlayerShape: RawVars.mediaPlayerShape !== undefined ? RawVars.mediaPlayerShape : ""
    property real mediaPlayerArtScale: RawVars.mediaPlayerArtScale !== undefined ? RawVars.mediaPlayerArtScale : 0
    property real mediaPlayerArtOffsetX: RawVars.mediaPlayerArtOffsetX !== undefined ? RawVars.mediaPlayerArtOffsetX : 0
    property real mediaPlayerArtOffsetY: RawVars.mediaPlayerArtOffsetY !== undefined ? RawVars.mediaPlayerArtOffsetY : 0
    property real mediaPlayerWaveThickness: RawVars.mediaPlayerWaveThickness !== undefined ? RawVars.mediaPlayerWaveThickness : 0
    property string mediaPlayerOrientation: RawVars.mediaPlayerOrientation !== undefined ? RawVars.mediaPlayerOrientation : ""
    property string mediaPlayerLyricsExpansion: RawVars.mediaPlayerLyricsExpansion !== undefined ? RawVars.mediaPlayerLyricsExpansion : ""
    property bool mediaPlayerLyricsAutoScroll: RawVars.mediaPlayerLyricsAutoScroll !== undefined ? RawVars.mediaPlayerLyricsAutoScroll : false
    property bool mediaPlayerExpandOverlaps: RawVars.mediaPlayerExpandOverlaps !== undefined ? RawVars.mediaPlayerExpandOverlaps : false
    property string panelStyle: RawVars.panelStyle !== undefined ? RawVars.panelStyle : ""
    property string pillPosition: RawVars.pillPosition !== undefined ? RawVars.pillPosition : ""
    property string liquidGlassPreset: RawVars.liquidGlassPreset !== undefined ? RawVars.liquidGlassPreset : "apple"
    property string clockPillMode: RawVars.clockPillMode !== undefined ? RawVars.clockPillMode : "Always Visible"
    property bool gameMode: RawVars.gameMode !== undefined ? RawVars.gameMode : false
    property bool desktopClockEnabled: RawVars.desktopClockEnabled !== undefined ? RawVars.desktopClockEnabled : false
    property bool desktopClockAnchorEnabled: RawVars.desktopClockAnchorEnabled !== undefined ? RawVars.desktopClockAnchorEnabled : false
    property string desktopClockAnchorPoint: RawVars.desktopClockAnchorPoint !== undefined ? RawVars.desktopClockAnchorPoint : ""
    property real desktopClockAnchorCurve: RawVars.desktopClockAnchorCurve !== undefined ? RawVars.desktopClockAnchorCurve : 0
    property bool desktopCalenderEnabled: RawVars.desktopCalenderEnabled !== undefined ? RawVars.desktopCalenderEnabled : false
    property bool desktopCalenderAnchorEnabled: RawVars.desktopCalenderAnchorEnabled !== undefined ? RawVars.desktopCalenderAnchorEnabled : false
    property string desktopCalenderAnchorPoint: RawVars.desktopCalenderAnchorPoint !== undefined ? RawVars.desktopCalenderAnchorPoint : ""
    property real desktopCalenderAnchorCurve: RawVars.desktopCalenderAnchorCurve !== undefined ? RawVars.desktopCalenderAnchorCurve : 0
    property bool desktopMediaPlayerEnabled: RawVars.desktopMediaPlayerEnabled !== undefined ? RawVars.desktopMediaPlayerEnabled : false
    property bool desktopMediaPlayerAnchorEnabled: RawVars.desktopMediaPlayerAnchorEnabled !== undefined ? RawVars.desktopMediaPlayerAnchorEnabled : false
    property string desktopMediaPlayerAnchorPoint: RawVars.desktopMediaPlayerAnchorPoint !== undefined ? RawVars.desktopMediaPlayerAnchorPoint : ""
    property real desktopMediaPlayerAnchorCurve: RawVars.desktopMediaPlayerAnchorCurve !== undefined ? RawVars.desktopMediaPlayerAnchorCurve : 0
    property bool desktopMediaPlayerAnchorExpandFix: RawVars.desktopMediaPlayerAnchorExpandFix !== undefined ? RawVars.desktopMediaPlayerAnchorExpandFix : false
    property bool desktopSystemVitalsEnabled: RawVars.desktopSystemVitalsEnabled !== undefined ? RawVars.desktopSystemVitalsEnabled : false
    property bool desktopSystemVitalsAnchorEnabled: RawVars.desktopSystemVitalsAnchorEnabled !== undefined ? RawVars.desktopSystemVitalsAnchorEnabled : false
    property string desktopSystemVitalsAnchorPoint: RawVars.desktopSystemVitalsAnchorPoint !== undefined ? RawVars.desktopSystemVitalsAnchorPoint : ""
    property real desktopSystemVitalsAnchorCurve: RawVars.desktopSystemVitalsAnchorCurve !== undefined ? RawVars.desktopSystemVitalsAnchorCurve : 0
    property bool desktopSystemVitalsBackgroundEnabled: RawVars.desktopSystemVitalsBackgroundEnabled !== undefined ? RawVars.desktopSystemVitalsBackgroundEnabled : true
    property bool desktopAudioVisualizerEnabled: RawVars.desktopAudioVisualizerEnabled !== undefined ? RawVars.desktopAudioVisualizerEnabled : false
    property bool desktopAudioVisualizerAnchorEnabled: RawVars.desktopAudioVisualizerAnchorEnabled !== undefined ? RawVars.desktopAudioVisualizerAnchorEnabled : false
    property string desktopAudioVisualizerAnchorPoint: RawVars.desktopAudioVisualizerAnchorPoint !== undefined ? RawVars.desktopAudioVisualizerAnchorPoint : ""
    property real desktopAudioVisualizerAnchorCurve: RawVars.desktopAudioVisualizerAnchorCurve !== undefined ? RawVars.desktopAudioVisualizerAnchorCurve : 0
    property int desktopAudioVisualizerBars: RawVars.desktopAudioVisualizerBars !== undefined ? RawVars.desktopAudioVisualizerBars : 24
    property bool desktopAudioVisualizerBackgroundEnabled: RawVars.desktopAudioVisualizerBackgroundEnabled !== undefined ? RawVars.desktopAudioVisualizerBackgroundEnabled : true
    property string desktopAudioVisualizerShape: RawVars.desktopAudioVisualizerShape !== undefined ? RawVars.desktopAudioVisualizerShape : "Sunny"
    property string desktopAudioVisualizerShapeMode: RawVars.desktopAudioVisualizerShapeMode !== undefined ? RawVars.desktopAudioVisualizerShapeMode : "Single"
    property string desktopAudioVisualizerColorMode: RawVars.desktopAudioVisualizerColorMode !== undefined ? RawVars.desktopAudioVisualizerColorMode : "Theme"
    property string desktopAudioVisualizerColor: RawVars.desktopAudioVisualizerColor !== undefined ? RawVars.desktopAudioVisualizerColor : "primary"
    property string desktopAudioVisualizerGradientStart: RawVars.desktopAudioVisualizerGradientStart !== undefined ? RawVars.desktopAudioVisualizerGradientStart : "primary"
    property string desktopAudioVisualizerGradientEnd: RawVars.desktopAudioVisualizerGradientEnd !== undefined ? RawVars.desktopAudioVisualizerGradientEnd : "tertiary"
    property string desktopAudioVisualizerLayout: RawVars.desktopAudioVisualizerLayout !== undefined ? RawVars.desktopAudioVisualizerLayout : "Circular"
    property string desktopAudioVisualizerPositionShape: RawVars.desktopAudioVisualizerPositionShape !== undefined ? RawVars.desktopAudioVisualizerPositionShape : "Circle"
    property real desktopAudioVisualizerShapeSize: RawVars.desktopAudioVisualizerShapeSize !== undefined ? RawVars.desktopAudioVisualizerShapeSize : 26
    property real desktopAudioVisualizerSpacing: RawVars.desktopAudioVisualizerSpacing !== undefined ? RawVars.desktopAudioVisualizerSpacing : 8
    property real desktopAudioVisualizerRadius: RawVars.desktopAudioVisualizerRadius !== undefined ? RawVars.desktopAudioVisualizerRadius : 42
    property string desktopAudioVisualizerPresets: RawVars.desktopAudioVisualizerPresets !== undefined ? RawVars.desktopAudioVisualizerPresets : "[]"
    property real historyUpdated: RawVars.historyUpdated !== undefined ? RawVars.historyUpdated : 0
    property var m3Standard: RawVars.m3Standard
    property var m3StandardDecelerate: RawVars.m3StandardDecelerate
    property var m3StandardAccelerate: RawVars.m3StandardAccelerate
    property var m3EmphasizedDecelerate: RawVars.m3EmphasizedDecelerate
    property var m3EmphasizedAccelerate: RawVars.m3EmphasizedAccelerate
    property var m3ExpressiveSpatialFast: RawVars.m3ExpressiveSpatialFast
    property var m3ExpressiveSpatialSlow: RawVars.m3ExpressiveSpatialSlow
    property var customStandard: RawVars.customStandard
    property var customStandardDecelerate: RawVars.customStandardDecelerate
    property var customStandardAccelerate: RawVars.customStandardAccelerate
    property var customEmphasizedDecelerate: RawVars.customEmphasizedDecelerate
    property var customEmphasizedAccelerate: RawVars.customEmphasizedAccelerate
    property var customExpressiveSpatialFast: RawVars.customExpressiveSpatialFast
    property var customExpressiveSpatialSlow: RawVars.customExpressiveSpatialSlow

    // Low-spec mode, decided by Hyprland (hypr/modules/hardware.lua) from its LowSpec variable:
    // opaque panels, no wallpaper mask or audio visualizer, and less multisampling on layers
    property bool lowSpec: false
    // 4x is the most that every GPU able to run Hyprland (GLES 3.0) is guaranteed to support
    property int layerSamples: lowSpec ? 4 : 32
    property FileView _lowSpecState: FileView {
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/omniformis-low-spec"
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.lowSpec = text().trim() === "1"
    }

    function update() {
        if (root.radiusAmount !== RawVars.radiusAmount) root.radiusAmount = RawVars.radiusAmount;
        if (root.radiusSmall !== RawVars.radiusSmall) root.radiusSmall = RawVars.radiusSmall;
        if (root.cornerPower !== RawVars.cornerPower) root.cornerPower = RawVars.cornerPower;
        if (root.spacingSmall !== RawVars.spacingSmall) root.spacingSmall = RawVars.spacingSmall;
        if (root.spacingMedium !== RawVars.spacingMedium) root.spacingMedium = RawVars.spacingMedium;
        if (root.spacingLarge !== RawVars.spacingLarge) root.spacingLarge = RawVars.spacingLarge;
        if (root.paddingSmall !== RawVars.paddingSmall) root.paddingSmall = RawVars.paddingSmall;
        if (root.paddingMedium !== RawVars.paddingMedium) root.paddingMedium = RawVars.paddingMedium;
        if (root.paddingLarge !== RawVars.paddingLarge) root.paddingLarge = RawVars.paddingLarge;
        if (root.fontFamily !== RawVars.fontFamily) root.fontFamily = RawVars.fontFamily;
        if (root.fontWeight !== RawVars.fontWeight) root.fontWeight = RawVars.fontWeight;
        if (root.fontItalic !== RawVars.fontItalic) root.fontItalic = RawVars.fontItalic;
        if (root.fontRounding !== RawVars.fontRounding) root.fontRounding = RawVars.fontRounding;
        if (root.fontGrading !== RawVars.fontGrading) root.fontGrading = RawVars.fontGrading;
        if (root.fontBaselineEnabled !== RawVars.fontBaselineEnabled) root.fontBaselineEnabled = RawVars.fontBaselineEnabled;
        if (root.animationDuration !== RawVars.animationDuration) root.animationDuration = RawVars.animationDuration;
        if (root.flickDeceleration !== RawVars.flickDeceleration) root.flickDeceleration = RawVars.flickDeceleration;
        if (root.maximumFlickVelocity !== RawVars.maximumFlickVelocity) root.maximumFlickVelocity = RawVars.maximumFlickVelocity;
        if (root._translucent !== RawVars._translucent) root._translucent = RawVars._translucent;
        if (root._liquidGlass !== RawVars._liquidGlass) root._liquidGlass = RawVars._liquidGlass;
        if (root.blurAmount !== RawVars.blurAmount) root.blurAmount = RawVars.blurAmount;
        if (root.panelOpacity !== RawVars.panelOpacity) root.panelOpacity = RawVars.panelOpacity;
        if (root.componentOpacity !== RawVars.componentOpacity) root.componentOpacity = RawVars.componentOpacity;
        if (root.currentBrightness !== RawVars.currentBrightness) root.currentBrightness = RawVars.currentBrightness;
        if (root.overviewGridRows !== RawVars.overviewGridRows) root.overviewGridRows = RawVars.overviewGridRows;
        if (root.overviewGridColumns !== RawVars.overviewGridColumns) root.overviewGridColumns = RawVars.overviewGridColumns;
        if (root.overviewScale !== RawVars.overviewScale) root.overviewScale = RawVars.overviewScale;
        if (root.gameLibraryRows !== RawVars.gameLibraryRows) root.gameLibraryRows = RawVars.gameLibraryRows;
        if (root.gameLibraryColumns !== RawVars.gameLibraryColumns) root.gameLibraryColumns = RawVars.gameLibraryColumns;
        if (root.gameLibraryScale !== RawVars.gameLibraryScale) root.gameLibraryScale = RawVars.gameLibraryScale;
        if (root.wallpaperMaskEnabled !== RawVars.wallpaperMaskEnabled) root.wallpaperMaskEnabled = RawVars.wallpaperMaskEnabled;
        if (root.wallpaperMaskScale !== RawVars.wallpaperMaskScale) root.wallpaperMaskScale = RawVars.wallpaperMaskScale;
        if (root.wallpaperMaskShape !== RawVars.wallpaperMaskShape) root.wallpaperMaskShape = RawVars.wallpaperMaskShape;
        if (root.wallpaperMaskColor !== RawVars.wallpaperMaskColor) root.wallpaperMaskColor = RawVars.wallpaperMaskColor;
        if (root.wallpaperMaskOffsetX !== RawVars.wallpaperMaskOffsetX) root.wallpaperMaskOffsetX = RawVars.wallpaperMaskOffsetX;
        if (root.wallpaperMaskOffsetY !== RawVars.wallpaperMaskOffsetY) root.wallpaperMaskOffsetY = RawVars.wallpaperMaskOffsetY;
        if (root.clockShape !== RawVars.clockShape) root.clockShape = RawVars.clockShape;
        if (root.clockShowTicks !== RawVars.clockShowTicks) root.clockShowTicks = RawVars.clockShowTicks;
        if (root.clockShowCenterDot !== RawVars.clockShowCenterDot) root.clockShowCenterDot = RawVars.clockShowCenterDot;
        if (root.clockShowDate !== RawVars.clockShowDate) root.clockShowDate = RawVars.clockShowDate;
        if (root.clockSecondHandStyle !== RawVars.clockSecondHandStyle) root.clockSecondHandStyle = RawVars.clockSecondHandStyle;
        if (root.clockHandThickness !== RawVars.clockHandThickness) root.clockHandThickness = RawVars.clockHandThickness;
        if (root.mediaPlayerShape !== RawVars.mediaPlayerShape) root.mediaPlayerShape = RawVars.mediaPlayerShape;
        if (root.mediaPlayerArtScale !== RawVars.mediaPlayerArtScale) root.mediaPlayerArtScale = RawVars.mediaPlayerArtScale;
        if (root.mediaPlayerArtOffsetX !== RawVars.mediaPlayerArtOffsetX) root.mediaPlayerArtOffsetX = RawVars.mediaPlayerArtOffsetX;
        if (root.mediaPlayerArtOffsetY !== RawVars.mediaPlayerArtOffsetY) root.mediaPlayerArtOffsetY = RawVars.mediaPlayerArtOffsetY;
        if (root.mediaPlayerWaveThickness !== RawVars.mediaPlayerWaveThickness) root.mediaPlayerWaveThickness = RawVars.mediaPlayerWaveThickness;
        if (root.mediaPlayerOrientation !== RawVars.mediaPlayerOrientation) root.mediaPlayerOrientation = RawVars.mediaPlayerOrientation;
        if (root.mediaPlayerLyricsExpansion !== RawVars.mediaPlayerLyricsExpansion) root.mediaPlayerLyricsExpansion = RawVars.mediaPlayerLyricsExpansion;
        if (root.mediaPlayerLyricsAutoScroll !== RawVars.mediaPlayerLyricsAutoScroll) root.mediaPlayerLyricsAutoScroll = RawVars.mediaPlayerLyricsAutoScroll;
        if (root.mediaPlayerExpandOverlaps !== RawVars.mediaPlayerExpandOverlaps) root.mediaPlayerExpandOverlaps = RawVars.mediaPlayerExpandOverlaps;
        if (root.panelStyle !== RawVars.panelStyle) root.panelStyle = RawVars.panelStyle;
        if (root.pillPosition !== RawVars.pillPosition) root.pillPosition = RawVars.pillPosition;
        if (root.liquidGlassPreset !== RawVars.liquidGlassPreset) root.liquidGlassPreset = RawVars.liquidGlassPreset;
        if (root.clockPillMode !== RawVars.clockPillMode) root.clockPillMode = RawVars.clockPillMode;
        if (root.gameMode !== RawVars.gameMode) root.gameMode = RawVars.gameMode;
        if (root.desktopClockEnabled !== RawVars.desktopClockEnabled) root.desktopClockEnabled = RawVars.desktopClockEnabled;
        if (root.desktopClockAnchorEnabled !== RawVars.desktopClockAnchorEnabled) root.desktopClockAnchorEnabled = RawVars.desktopClockAnchorEnabled;
        if (root.desktopClockAnchorPoint !== RawVars.desktopClockAnchorPoint) root.desktopClockAnchorPoint = RawVars.desktopClockAnchorPoint;
        if (root.desktopClockAnchorCurve !== RawVars.desktopClockAnchorCurve) root.desktopClockAnchorCurve = RawVars.desktopClockAnchorCurve;
        if (root.desktopCalenderEnabled !== RawVars.desktopCalenderEnabled) root.desktopCalenderEnabled = RawVars.desktopCalenderEnabled;
        if (root.desktopCalenderAnchorEnabled !== RawVars.desktopCalenderAnchorEnabled) root.desktopCalenderAnchorEnabled = RawVars.desktopCalenderAnchorEnabled;
        if (root.desktopCalenderAnchorPoint !== RawVars.desktopCalenderAnchorPoint) root.desktopCalenderAnchorPoint = RawVars.desktopCalenderAnchorPoint;
        if (root.desktopCalenderAnchorCurve !== RawVars.desktopCalenderAnchorCurve) root.desktopCalenderAnchorCurve = RawVars.desktopCalenderAnchorCurve;
        if (root.desktopMediaPlayerEnabled !== RawVars.desktopMediaPlayerEnabled) root.desktopMediaPlayerEnabled = RawVars.desktopMediaPlayerEnabled;
        if (root.desktopMediaPlayerAnchorEnabled !== RawVars.desktopMediaPlayerAnchorEnabled) root.desktopMediaPlayerAnchorEnabled = RawVars.desktopMediaPlayerAnchorEnabled;
        if (root.desktopMediaPlayerAnchorPoint !== RawVars.desktopMediaPlayerAnchorPoint) root.desktopMediaPlayerAnchorPoint = RawVars.desktopMediaPlayerAnchorPoint;
        if (root.desktopMediaPlayerAnchorCurve !== RawVars.desktopMediaPlayerAnchorCurve) root.desktopMediaPlayerAnchorCurve = RawVars.desktopMediaPlayerAnchorCurve;
        if (root.desktopMediaPlayerAnchorExpandFix !== RawVars.desktopMediaPlayerAnchorExpandFix) root.desktopMediaPlayerAnchorExpandFix = RawVars.desktopMediaPlayerAnchorExpandFix;
        if (root.desktopSystemVitalsEnabled !== RawVars.desktopSystemVitalsEnabled) root.desktopSystemVitalsEnabled = RawVars.desktopSystemVitalsEnabled;
        if (root.desktopSystemVitalsAnchorEnabled !== RawVars.desktopSystemVitalsAnchorEnabled) root.desktopSystemVitalsAnchorEnabled = RawVars.desktopSystemVitalsAnchorEnabled;
        if (root.desktopSystemVitalsAnchorPoint !== RawVars.desktopSystemVitalsAnchorPoint) root.desktopSystemVitalsAnchorPoint = RawVars.desktopSystemVitalsAnchorPoint;
        if (root.desktopSystemVitalsAnchorCurve !== RawVars.desktopSystemVitalsAnchorCurve) root.desktopSystemVitalsAnchorCurve = RawVars.desktopSystemVitalsAnchorCurve;
        if (root.desktopSystemVitalsBackgroundEnabled !== RawVars.desktopSystemVitalsBackgroundEnabled) root.desktopSystemVitalsBackgroundEnabled = RawVars.desktopSystemVitalsBackgroundEnabled;
        if (root.desktopAudioVisualizerEnabled !== RawVars.desktopAudioVisualizerEnabled) root.desktopAudioVisualizerEnabled = RawVars.desktopAudioVisualizerEnabled;
        if (root.desktopAudioVisualizerAnchorEnabled !== RawVars.desktopAudioVisualizerAnchorEnabled) root.desktopAudioVisualizerAnchorEnabled = RawVars.desktopAudioVisualizerAnchorEnabled;
        if (root.desktopAudioVisualizerAnchorPoint !== RawVars.desktopAudioVisualizerAnchorPoint) root.desktopAudioVisualizerAnchorPoint = RawVars.desktopAudioVisualizerAnchorPoint;
        if (root.desktopAudioVisualizerAnchorCurve !== RawVars.desktopAudioVisualizerAnchorCurve) root.desktopAudioVisualizerAnchorCurve = RawVars.desktopAudioVisualizerAnchorCurve;
        if (root.desktopAudioVisualizerBars !== RawVars.desktopAudioVisualizerBars) root.desktopAudioVisualizerBars = RawVars.desktopAudioVisualizerBars;
        if (root.desktopAudioVisualizerBackgroundEnabled !== RawVars.desktopAudioVisualizerBackgroundEnabled) root.desktopAudioVisualizerBackgroundEnabled = RawVars.desktopAudioVisualizerBackgroundEnabled;
        if (root.desktopAudioVisualizerShape !== RawVars.desktopAudioVisualizerShape) root.desktopAudioVisualizerShape = RawVars.desktopAudioVisualizerShape;
        if (root.desktopAudioVisualizerShapeMode !== RawVars.desktopAudioVisualizerShapeMode) root.desktopAudioVisualizerShapeMode = RawVars.desktopAudioVisualizerShapeMode;
        if (root.desktopAudioVisualizerColorMode !== RawVars.desktopAudioVisualizerColorMode) root.desktopAudioVisualizerColorMode = RawVars.desktopAudioVisualizerColorMode;
        if (root.desktopAudioVisualizerColor !== RawVars.desktopAudioVisualizerColor) root.desktopAudioVisualizerColor = RawVars.desktopAudioVisualizerColor;
        if (root.desktopAudioVisualizerGradientStart !== RawVars.desktopAudioVisualizerGradientStart) root.desktopAudioVisualizerGradientStart = RawVars.desktopAudioVisualizerGradientStart;
        if (root.desktopAudioVisualizerGradientEnd !== RawVars.desktopAudioVisualizerGradientEnd) root.desktopAudioVisualizerGradientEnd = RawVars.desktopAudioVisualizerGradientEnd;
        if (root.desktopAudioVisualizerLayout !== RawVars.desktopAudioVisualizerLayout) root.desktopAudioVisualizerLayout = RawVars.desktopAudioVisualizerLayout;
        if (root.desktopAudioVisualizerPositionShape !== RawVars.desktopAudioVisualizerPositionShape) root.desktopAudioVisualizerPositionShape = RawVars.desktopAudioVisualizerPositionShape;
        if (root.desktopAudioVisualizerShapeSize !== RawVars.desktopAudioVisualizerShapeSize) root.desktopAudioVisualizerShapeSize = RawVars.desktopAudioVisualizerShapeSize;
        if (root.desktopAudioVisualizerSpacing !== RawVars.desktopAudioVisualizerSpacing) root.desktopAudioVisualizerSpacing = RawVars.desktopAudioVisualizerSpacing;
        if (root.desktopAudioVisualizerRadius !== RawVars.desktopAudioVisualizerRadius) root.desktopAudioVisualizerRadius = RawVars.desktopAudioVisualizerRadius;
        if (root.desktopAudioVisualizerPresets !== RawVars.desktopAudioVisualizerPresets) root.desktopAudioVisualizerPresets = RawVars.desktopAudioVisualizerPresets;
        if (root.historyUpdated !== RawVars.historyUpdated) root.historyUpdated = RawVars.historyUpdated;
    }


    // RawVars only changes through setLive(), which sets the property too, and through the
    // notification history, which reports back through historyChanged. One sync at startup
    // is enough.
    Component.onCompleted: {
        RawVars.historyChanged = function() { root.historyUpdated = RawVars.historyUpdated; };
        root.update();
    }

    function getTopLeftRadius(style, pos, isGame, defRad) { return RawVars.getTopLeftRadius(style, pos, isGame, defRad); }
    function getTopRightRadius(style, pos, isGame, defRad) { return RawVars.getTopRightRadius(style, pos, isGame, defRad); }
    function getBottomLeftRadius(style, pos, isGame, defRad) { return RawVars.getBottomLeftRadius(style, pos, isGame, defRad); }
    function getBottomRightRadius(style, pos, isGame, defRad) { return RawVars.getBottomRightRadius(style, pos, isGame, defRad); }
    function fuzzyMatch(pattern, str) { return RawVars.fuzzyMatch(pattern, str); }
    function fuzzyMatchScore(pattern, str) { return RawVars.fuzzyMatchScore(pattern, str); }
    // These read Vars' own properties instead of RawVars, so bindings that call them update when
    // translucency, game mode or low-spec mode changes
    function isTranslucent() { return root._translucent && !root.gameMode && !root.lowSpec; }
    function tColor(baseColor, alpha) {
        if (!root.isTranslucent()) return baseColor;
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, alpha);
    }
    function tColorActive(isActive, baseColor, alpha) {
        if (!isActive) return "transparent";
        return root.tColor(baseColor, alpha);
    }
    function tColorSelected(baseColor, alpha) {
        if (!root.isTranslucent()) return baseColor;
        var targetAlpha = (alpha !== undefined && alpha !== null) ? alpha : 0.90;
        return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, targetAlpha);
    }
    function getFadeCurve(isOpen) { return RawVars.getFadeCurve(isOpen); }
    
    function setLive(key, val) {
        RawVars[key] = val;
        root[key] = val;
    }
    
    // Notifications handling proxy
    property var notificationHistory: RawVars.notificationHistory || []
    
    onHistoryUpdatedChanged: {
        notificationHistory = RawVars.notificationHistory;
    }
    
    function pushNotification(modelData) {
        RawVars.pushNotification(modelData);
        root.historyUpdated = RawVars.historyUpdated;
        root.notificationHistory = RawVars.notificationHistory;
    }
    function removeNotification(seqId) {
        RawVars.removeNotification(seqId);
        root.historyUpdated = RawVars.historyUpdated;
        root.notificationHistory = RawVars.notificationHistory;
    }
    function clearNotifications() {
        RawVars.clearNotifications();
        root.historyUpdated = RawVars.historyUpdated;
        root.notificationHistory = RawVars.notificationHistory;
    }
}
