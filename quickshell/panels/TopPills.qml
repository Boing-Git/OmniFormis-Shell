import QtQuick
import ".."
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import "../theme/variables.js" as Vars

PanelWindow {
    id: topWindow
    
    signal toggleFloatingSettings()
    
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.layer: WlrLayer.Top
    anchors {
        top: true
        left: true
        right: true
    }

    implicitHeight: 750
    color: "transparent"


    signal popupOpened
    signal openOverviewRequested

    property bool gameMode: false

    property int currentSpacingSmall: Vars.spacingSmall !== undefined ? Vars.spacingSmall : 11
    property int currentRadiusExtraLarge: Vars.radiusExtraLarge !== undefined ? Vars.radiusExtraLarge : 38
    property int currentAnimationDuration: Vars.animationDuration !== undefined ? Vars.animationDuration : 240

    Timer {
        interval: 100
        running: true
        repeat: true
        onTriggered: {
            var spaceS = Vars.spacingSmall !== undefined ? Vars.spacingSmall : 11;
            if (topWindow.currentSpacingSmall !== spaceS) topWindow.currentSpacingSmall = spaceS;

            var radXL = Vars.radiusExtraLarge !== undefined ? Vars.radiusExtraLarge : 38;
            if (topWindow.currentRadiusExtraLarge !== radXL) topWindow.currentRadiusExtraLarge = radXL;

            var animD = Vars.animationDuration !== undefined ? Vars.animationDuration : 240;
            if (topWindow.currentAnimationDuration !== animD) topWindow.currentAnimationDuration = animD;
        }
    }

    Process {
        id: gameModeChecker
        command: ["bash", "-c", "grep -qi 'GameMode[ \t]*=[ \t]*true' ~/.config/hypr/modules/variables.lua && echo 'true' || echo 'false'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                topWindow.gameMode = (this.text.trim() === 'true');
            }
        }
    }

    function closeAll() {
        launcherItem.expanded = false;
        controlCenterItem.expanded = false;
        wallpaperSwitcherItem.expanded = false;
        colorSchemeSwitcherItem.expanded = false;
        powerMenuItem.expanded = false;
        emojiPickerItem.expanded = false;
        notificationPopupItem.expanded = false;
        settingsAppItem.expanded = false;
    }

    // 1. The Mask Region Array
    mask: Region {
        Region {
            item: clockHoverZone
        }
        Region {
            item: clockPill
        }
        Region {
            item: workspacesItem.panelMask
        }
        Region {
            item: statusBarItem
        }
        Region {
            item: controlCenterItem.panelMask
        }
        Region {
            item: launcherItem.panelMask
        }
        Region {
            item: powerMenuItem.panelMask
        }
        Region {
            item: polkitItem.panelMask
        }
        Region {
            item: wallpaperSwitcherItem.panelMask
        }
        Region {
            item: colorSchemeSwitcherItem.panelMask
        }
        Region {
            item: notificationPopupItem.panelMask
        }
        Region {
            item: emojiPickerItem.panelMask
        }
        Region {
            item: settingsAppItem.panelMask
        }
        Region {
            item: volumeOsdItem.panelMask
        }
    }

    Item {
        id: clockHoverZone
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: 300
        height: 100
        MouseArea {
            id: clockHoverArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
    }

    // --- Main UI Content ---
    Item {
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            z: -1
            onClicked: closeAll()
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: currentSpacingSmall
            anchors.rightMargin: currentSpacingSmall
            anchors.topMargin: currentSpacingSmall
            anchors.bottomMargin: currentSpacingSmall

            Item {
                Layout.fillWidth: true
            }

            Item {
                Layout.fillWidth: true
            }

            StatusBar {
                id: statusBarItem
                Layout.alignment: Qt.AlignTop
            }
        }
    }

    ClockPill {
        id: clockPill
        gameMode: topWindow.gameMode
        anchors.top: parent.top
        anchors.horizontalCenter: topWindow.gameMode ? undefined : parent.horizontalCenter
        anchors.left: topWindow.gameMode ? parent.left : undefined
        anchors.right: topWindow.gameMode ? parent.right : undefined
        
        property bool isShown: ((clockHoverArea.containsMouse || clockPill.isHovered) && !(launcherItem.expanded || controlCenterItem.expanded || wallpaperSwitcherItem.expanded || colorSchemeSwitcherItem.expanded || powerMenuItem.expanded || polkitItem.expanded || notificationPopupItem.expanded || emojiPickerItem.expanded || settingsAppItem.expanded || volumeOsdItem.isVisible || workspacesItem.overlayVisible) && !topWindow.gameMode)
        
        anchors.topMargin: {
            if (topWindow.gameMode) return 0;
            if (!isShown) return -clockPill.height - 20;
            return (Vars.panelStyle === "Attached" || Vars.panelStyle === "Flat") ? 0 : currentSpacingSmall;
        }
        
        opacity: isShown ? 1.0 : 0.0
        
        Behavior on anchors.topMargin {
            enabled: !topWindow.gameMode
            NumberAnimation {
                duration: currentAnimationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customExpressiveSpatialSlow
            }
        }

        Behavior on opacity {
            enabled: !topWindow.gameMode
            NumberAnimation {
                duration: currentAnimationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customStandard
            }
        }

        onClicked: {
            toggleControlCenter();
        }
        onRightClicked: {
            toggleLauncher();
        }
        onScrolled: delta => {
            if (workspacesItem) {
                workspacesItem.handleScroll(delta);
            }
        }
    }

    HyprWorkspaces {
        id: workspacesItem
        gameMode: topWindow.gameMode
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: topWindow.gameMode || Vars.panelStyle === "Attached" || Vars.panelStyle === "Flat" ? 0 : currentSpacingSmall
        forceHidePill: launcherItem.expanded || controlCenterItem.expanded || wallpaperSwitcherItem.expanded || colorSchemeSwitcherItem.expanded || powerMenuItem.expanded || polkitItem.expanded || notificationPopupItem.expanded || emojiPickerItem.expanded || settingsAppItem.expanded || volumeOsdItem.isVisible
    }

    Launcher {
        id: launcherItem
        gameMode: topWindow.gameMode
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: topWindow.gameMode || Vars.panelStyle === "Attached" || Vars.panelStyle === "Flat" ? 0 : currentSpacingSmall
        width: 100
        height: 40
        focusWindow: topWindow

        onExpandedChanged: {
            if (expanded) {
                topWindow.popupOpened();
                controlCenterItem.expanded = false;
                wallpaperSwitcherItem.expanded = false;
                colorSchemeSwitcherItem.expanded = false;
                powerMenuItem.expanded = false;
                emojiPickerItem.expanded = false;
                settingsAppItem.expanded = false;
            }
        }
        
        onOpenSettingsRequested: {
            toggleSettings();
        }
    }

    function toggleLauncher() {
        if (!polkitItem.expanded) {
            if (launcherItem.expanded && !launcherItem.searchText.startsWith("/")) {
                launcherItem.expanded = false;
            } else {
                topWindow.popupOpened();
                launcherItem.expanded = true;
                launcherItem.searchText = "";
                controlCenterItem.expanded = false;
                wallpaperSwitcherItem.expanded = false;
                colorSchemeSwitcherItem.expanded = false;
                powerMenuItem.expanded = false;
                emojiPickerItem.expanded = false;
                settingsAppItem.expanded = false;
            }
        }
    }

    function toggleControlCenter() {
        if (!polkitItem.expanded) {
            controlCenterItem.expanded = !controlCenterItem.expanded;
            if (controlCenterItem.expanded) {
                topWindow.popupOpened();
                launcherItem.expanded = false;
                wallpaperSwitcherItem.expanded = false;
                colorSchemeSwitcherItem.expanded = false;
                powerMenuItem.expanded = false;
                emojiPickerItem.expanded = false;
                settingsAppItem.expanded = false;
            }
        }
    }

    function toggleWallpaper() {
        if (!polkitItem.expanded) {
            wallpaperSwitcherItem.expanded = !wallpaperSwitcherItem.expanded;
            if (wallpaperSwitcherItem.expanded) {
                topWindow.popupOpened();
                launcherItem.expanded = false;
                controlCenterItem.expanded = false;
                colorSchemeSwitcherItem.expanded = false;
                powerMenuItem.expanded = false;
                emojiPickerItem.expanded = false;
                settingsAppItem.expanded = false;
            }
        }
    }

    function toggleColorScheme() {
        if (!polkitItem.expanded) {
            colorSchemeSwitcherItem.expanded = !colorSchemeSwitcherItem.expanded;
            if (colorSchemeSwitcherItem.expanded) {
                topWindow.popupOpened();
                launcherItem.expanded = false;
                controlCenterItem.expanded = false;
                wallpaperSwitcherItem.expanded = false;
                powerMenuItem.expanded = false;
                emojiPickerItem.expanded = false;
                settingsAppItem.expanded = false;
            }
        }
    }

    function togglePowerMenu() {
        if (!polkitItem.expanded) {
            powerMenuItem.expanded = !powerMenuItem.expanded;
            if (powerMenuItem.expanded) {
                topWindow.popupOpened();
                launcherItem.expanded = false;
                controlCenterItem.expanded = false;
                wallpaperSwitcherItem.expanded = false;
                colorSchemeSwitcherItem.expanded = false;
                emojiPickerItem.expanded = false;
                settingsAppItem.expanded = false;
            }
        }
    }

    function toggleEmojiPicker() {
        if (!polkitItem.expanded) {
            if (launcherItem.expanded && launcherItem.searchText === "/emoji ") {
                launcherItem.expanded = false;
            } else {
                topWindow.popupOpened();
                launcherItem.expanded = true;
                launcherItem.searchText = "/emoji ";
                controlCenterItem.expanded = false;
                wallpaperSwitcherItem.expanded = false;
                colorSchemeSwitcherItem.expanded = false;
                powerMenuItem.expanded = false;
                emojiPickerItem.expanded = false;
                settingsAppItem.expanded = false;
            }
        }
    }

    function toggleClipboard() {
        if (!polkitItem.expanded) {
            if (launcherItem.expanded && launcherItem.searchText === "/clipboard ") {
                launcherItem.expanded = false;
            } else {
                topWindow.popupOpened();
                launcherItem.expanded = true;
                launcherItem.searchText = "/clipboard ";
                controlCenterItem.expanded = false;
                wallpaperSwitcherItem.expanded = false;
                colorSchemeSwitcherItem.expanded = false;
                powerMenuItem.expanded = false;
                emojiPickerItem.expanded = false;
                settingsAppItem.expanded = false;
            }
        }
    }

    function toggleSettings() {
        if (!polkitItem.expanded) {
            settingsAppItem.expanded = !settingsAppItem.expanded;
            if (settingsAppItem.expanded) {
                topWindow.popupOpened();
                launcherItem.expanded = false;
                controlCenterItem.expanded = false;
                wallpaperSwitcherItem.expanded = false;
                colorSchemeSwitcherItem.expanded = false;
                powerMenuItem.expanded = false;
                emojiPickerItem.expanded = false;
            }
        }
    }

    PowerMenu {
        id: powerMenuItem
        gameMode: topWindow.gameMode
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: topWindow.gameMode || Vars.panelStyle === "Attached" || Vars.panelStyle === "Flat" ? 0 : currentSpacingSmall
        width: 100
        height: 40
        focusWindow: topWindow

        onExpandedChanged: {
            if (expanded) {
                topWindow.popupOpened();
                launcherItem.expanded = false;
                controlCenterItem.expanded = false;
                wallpaperSwitcherItem.expanded = false;
                colorSchemeSwitcherItem.expanded = false;
                emojiPickerItem.expanded = false;
                settingsAppItem.expanded = false;
            }
        }
    }

    PolkitDialog {
        id: polkitItem
        gameMode: topWindow.gameMode
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: topWindow.gameMode || Vars.panelStyle === "Attached" || Vars.panelStyle === "Flat" ? 0 : currentSpacingSmall
        width: 100
        height: 40
        focusWindow: topWindow

        onExpandedChanged: {
            if (expanded) {
                topWindow.popupOpened();
                launcherItem.expanded = false;
                controlCenterItem.expanded = false;
                wallpaperSwitcherItem.expanded = false;
                colorSchemeSwitcherItem.expanded = false;
                powerMenuItem.expanded = false;
                emojiPickerItem.expanded = false;
                settingsAppItem.expanded = false;
            }
        }
    }

    NotificationPopup {
        id: notificationPopupItem
        gameMode: topWindow.gameMode
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: topWindow.gameMode || Vars.panelStyle === "Attached" || Vars.panelStyle === "Flat" ? 0 : currentSpacingSmall
        width: 100
        height: 40
        focusWindow: topWindow

        onExpandedChanged: {
            if (expanded) {
                topWindow.popupOpened();
                launcherItem.expanded = false;
                controlCenterItem.expanded = false;
                wallpaperSwitcherItem.expanded = false;
                colorSchemeSwitcherItem.expanded = false;
                powerMenuItem.expanded = false;
                emojiPickerItem.expanded = false;
                settingsAppItem.expanded = false;
            }
        }
    }

    ControlCenter {
        id: controlCenterItem
        gameMode: topWindow.gameMode
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: topWindow.gameMode || Vars.panelStyle === "Attached" || Vars.panelStyle === "Flat" ? 0 : currentSpacingSmall
        width: 100
        height: 40
        focusWindow: topWindow
        forceHidePill: launcherItem.expanded || volumeOsdItem.isVisible || wallpaperSwitcherItem.expanded || colorSchemeSwitcherItem.expanded || powerMenuItem.expanded || polkitItem.expanded || notificationPopupItem.expanded || emojiPickerItem.expanded || settingsAppItem.expanded

        onExpandedChanged: {
            if (expanded) {
                topWindow.popupOpened();
                launcherItem.expanded = false;
                wallpaperSwitcherItem.expanded = false;
                colorSchemeSwitcherItem.expanded = false;
                powerMenuItem.expanded = false;
                emojiPickerItem.expanded = false;
                settingsAppItem.expanded = false;
            }
        }

        onOpenColorSchemeRequested: {
            toggleColorScheme();
        }

        onOpenSettingsRequested: {
            toggleSettings();
        }

        onOpenWallpaperRequested: {
            toggleWallpaper();
        }

        onOpenPowerMenuRequested: {
            togglePowerMenu();
        }

        onOpenOverviewRequested: {
            topWindow.openOverviewRequested();
        }
    }

    VolumeOsd {
        id: volumeOsdItem
        gameMode: topWindow.gameMode
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: topWindow.gameMode ? 55 : (Vars.panelStyle === "Attached" || Vars.panelStyle === "Flat" ? 0 : currentSpacingSmall)
        preventShow: launcherItem.expanded || controlCenterItem.expanded || wallpaperSwitcherItem.expanded || colorSchemeSwitcherItem.expanded || powerMenuItem.expanded || polkitItem.expanded || notificationPopupItem.expanded || emojiPickerItem.expanded || settingsAppItem.expanded || launcherItem.panel.width > 105 || controlCenterItem.panel.width > 105 || powerMenuItem.panel.width > 105 || polkitItem.panel.width > 105 || notificationPopupItem.panel.width > 105 || emojiPickerItem.panel.width > 105 || wallpaperSwitcherItem.panel.width > 105 || colorSchemeSwitcherItem.panel.width > 105 || settingsAppItem.panel.width > 105
    }

    WallpaperSwitcher {
        id: wallpaperSwitcherItem
        gameMode: topWindow.gameMode
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: topWindow.gameMode || Vars.panelStyle === "Attached" || Vars.panelStyle === "Flat" ? 0 : currentSpacingSmall
        focusWindow: topWindow
        forceHidePill: launcherItem.expanded || controlCenterItem.expanded || colorSchemeSwitcherItem.expanded || powerMenuItem.expanded || polkitItem.expanded || notificationPopupItem.expanded || emojiPickerItem.expanded || settingsAppItem.expanded || volumeOsdItem.isVisible

        onExpandedChanged: {
            if (expanded) {
                topWindow.popupOpened();
                launcherItem.expanded = false;
                controlCenterItem.expanded = false;
                colorSchemeSwitcherItem.expanded = false;
                powerMenuItem.expanded = false;
                emojiPickerItem.expanded = false;
            }
        }

        onCloseRequested: expanded = false
    }

    EmojiPicker {
        id: emojiPickerItem
        gameMode: topWindow.gameMode
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: topWindow.gameMode || Vars.panelStyle === "Attached" || Vars.panelStyle === "Flat" ? 0 : currentSpacingSmall
        width: 100
        height: 40
        focusWindow: topWindow

        onExpandedChanged: {
            if (expanded) {
                topWindow.popupOpened();
                launcherItem.expanded = false;
                controlCenterItem.expanded = false;
                wallpaperSwitcherItem.expanded = false;
                colorSchemeSwitcherItem.expanded = false;
                powerMenuItem.expanded = false;
                settingsAppItem.expanded = false;
            }
        }
    }

    ColorSchemeSwitcher {
        id: colorSchemeSwitcherItem
        gameMode: topWindow.gameMode
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: topWindow.gameMode || Vars.panelStyle === "Attached" || Vars.panelStyle === "Flat" ? 0 : currentSpacingSmall
        focusWindow: topWindow
        forceHidePill: launcherItem.expanded || controlCenterItem.expanded || wallpaperSwitcherItem.expanded || powerMenuItem.expanded || polkitItem.expanded || notificationPopupItem.expanded || emojiPickerItem.expanded || settingsAppItem.expanded || volumeOsdItem.isVisible

        onExpandedChanged: {
            if (expanded) {
                topWindow.popupOpened();
                launcherItem.expanded = false;
                controlCenterItem.expanded = false;
                wallpaperSwitcherItem.expanded = false;
                powerMenuItem.expanded = false;
                emojiPickerItem.expanded = false;
                settingsAppItem.expanded = false;
            }
        }

        onCloseRequested: expanded = false
    }

    SettingsApp {
        id: settingsAppItem
        gameMode: topWindow.gameMode
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: topWindow.gameMode || Vars.panelStyle === "Attached" || Vars.panelStyle === "Flat" ? 0 : currentSpacingSmall
        focusWindow: topWindow
        forceHidePill: launcherItem.expanded || controlCenterItem.expanded || wallpaperSwitcherItem.expanded || powerMenuItem.expanded || polkitItem.expanded || notificationPopupItem.expanded || emojiPickerItem.expanded || colorSchemeSwitcherItem.expanded || volumeOsdItem.isVisible
        onDetachToggled: function(isFloating) {
            if (isFloating) topWindow.toggleFloatingSettings();
        }

        onExpandedChanged: {
            if (expanded) {
                topWindow.popupOpened();
                launcherItem.expanded = false;
                controlCenterItem.expanded = false;
                wallpaperSwitcherItem.expanded = false;
                colorSchemeSwitcherItem.expanded = false;
                powerMenuItem.expanded = false;
                emojiPickerItem.expanded = false;
            }
        }

        onCloseRequested: expanded = false
    }

    Repeater {
        model: [launcherItem, clockPill, workspacesItem, powerMenuItem, emojiPickerItem, colorSchemeSwitcherItem, wallpaperSwitcherItem, settingsAppItem, controlCenterItem, notificationPopupItem, polkitItem, volumeOsdItem]
        delegate: Item {
            property var targetPanel: modelData
            property bool hasPanel: !!targetPanel.panel
            
            InvertedCorner {
                x: (parent.hasPanel ? parent.targetPanel.x + parent.targetPanel.panel.x : parent.targetPanel.x) - width + 1
                y: (parent.hasPanel ? parent.targetPanel.y + parent.targetPanel.panel.y : parent.targetPanel.y)
                side: "left"
                visible: Vars.panelStyle === "Framed" && opacity > 0 && (parent.hasPanel ? parent.targetPanel.panel.width : parent.targetPanel.width) > 0
                color: parent.hasPanel ? parent.targetPanel.panel.color : "transparent"
                opacity: (parent.hasPanel ? parent.targetPanel.panel.opacity : 1.0) * parent.targetPanel.opacity
                radius: Math.max(0, currentRadiusExtraLarge - currentSpacingSmall)
            }
            InvertedCorner {
                x: (parent.hasPanel ? parent.targetPanel.x + parent.targetPanel.panel.x + parent.targetPanel.panel.width : parent.targetPanel.x + parent.targetPanel.width) - 1
                y: (parent.hasPanel ? parent.targetPanel.y + parent.targetPanel.panel.y : parent.targetPanel.y)
                side: "right"
                visible: Vars.panelStyle === "Framed" && opacity > 0 && (parent.hasPanel ? parent.targetPanel.panel.width : parent.targetPanel.width) > 0
                color: parent.hasPanel ? parent.targetPanel.panel.color : "transparent"
                opacity: (parent.hasPanel ? parent.targetPanel.panel.opacity : 1.0) * parent.targetPanel.opacity
                radius: Math.max(0, currentRadiusExtraLarge - currentSpacingSmall)
            }
        }
    }
}
