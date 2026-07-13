import QtQuick
import ".."
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../Variables/variables.js" as Vars

PanelWindow {
    id: topWindow
    exclusionMode: gameMode ? ExclusionMode.Ignore : ExclusionMode.Normal
    exclusiveZone: gameMode ? 0 : 50
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
            item: topBarMask
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
    }

    // 2. Fixed Top Bar Mask
    Item {
        id: topBarMask
        width: parent.width
        height: 70
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
            anchors.leftMargin: Vars.spacingSmall
            anchors.rightMargin: Vars.spacingSmall
            anchors.topMargin: Vars.spacingSmall
            anchors.bottomMargin: Vars.spacingSmall

            Item {
                Layout.fillWidth: true
            }

            Item {
                Layout.fillWidth: true
            }

            StatusBar {
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
        anchors.topMargin: topWindow.gameMode ? 0 : 5
        opacity: ((notificationPopupItem.expanded || volumeOsdItem.isVisible) && !topWindow.gameMode) ? 0.0 : 1.0
        Behavior on opacity {
            enabled: !topWindow.gameMode
            NumberAnimation {
                duration: Vars.animationDuration
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
        anchors.topMargin: topWindow.gameMode ? 0 : 5
    }

    Launcher {
        id: launcherItem
        gameMode: topWindow.gameMode
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 5
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
        anchors.topMargin: 5
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
        anchors.topMargin: 5
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
        anchors.topMargin: 5
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
        anchors.topMargin: 5
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
        anchors.topMargin: topWindow.gameMode ? 55 : 5
        preventShow: launcherItem.expanded || controlCenterItem.expanded || wallpaperSwitcherItem.expanded || colorSchemeSwitcherItem.expanded || powerMenuItem.expanded || polkitItem.expanded || notificationPopupItem.expanded || emojiPickerItem.expanded || settingsAppItem.expanded || launcherItem.panel.width > 105 || controlCenterItem.panel.width > 105 || powerMenuItem.panel.width > 105 || polkitItem.panel.width > 105 || notificationPopupItem.panel.width > 105 || emojiPickerItem.panel.width > 105 || wallpaperSwitcherItem.panel.width > 105 || colorSchemeSwitcherItem.panel.width > 105 || settingsAppItem.panel.width > 105
    }

    WallpaperSwitcher {
        id: wallpaperSwitcherItem
        gameMode: topWindow.gameMode
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.topMargin: 5
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
        anchors.topMargin: 5
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
        anchors.topMargin: 5
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
        anchors.topMargin: 5
        focusWindow: topWindow
        forceHidePill: launcherItem.expanded || controlCenterItem.expanded || wallpaperSwitcherItem.expanded || powerMenuItem.expanded || polkitItem.expanded || notificationPopupItem.expanded || emojiPickerItem.expanded || colorSchemeSwitcherItem.expanded || volumeOsdItem.isVisible

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
}
