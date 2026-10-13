import QtQuick
import QtQuick.Effects
import ".."
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import "../theme"

PanelWindow {
    id: topWindow
    
    signal toggleFloatingSettings()
    
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0
    WlrLayershell.namespace: "quickshell"
    WlrLayershell.layer: WlrLayer.Top
    property bool hasAnyPopupOpen: launcherItem.expanded || controlCenterItem.expanded || wallpaperSwitcherItem.expanded || colorSchemeSwitcherItem.expanded || powerMenuItem.expanded || polkitItem.expanded || emojiPickerItem.expanded || settingsAppItem.expanded || cheatSheetItem.expanded
    WlrLayershell.keyboardFocus: hasAnyPopupOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    implicitHeight: 750
    color: "transparent"

    property bool _forceDropGrab: false

    HyprlandFocusGrab {
        id: globalFocusGrab
        windows: [topWindow]
        onActiveChanged: console.log("[DEBUG] HyprlandFocusGrab active changed to:", active)
        active: !_forceDropGrab && topWindow.hasAnyPopupOpen
        onCleared: {
            console.log("[DEBUG] HyprlandFocusGrab onCleared fired! active:", active);
            if (active) {
                // Delay close so screenshot tools (grimblast/slurp) that briefly
                // steal focus don't cause panels to vanish before the capture frame.
                focusLostCloseTimer.restart();
            }
        }
    }

    Timer {
        id: focusLostCloseTimer
        interval: 400
        repeat: false
        onTriggered: {
            // Only close if focus grab is still gone (not a brief screenshot tool steal)
            if (!globalFocusGrab.active && !_forceDropGrab) {
                closeAll();
            }
        }
    }

    property string pillPos: Vars.pillPosition || "Top"
    property int defaultEdgeMargin: (Vars.panelStyle === "Flat" || Vars.panelStyle === "Attached") ? 0 : currentSpacingSmall


    signal popupOpened
    onPopupOpened: {
        topWindow.suppressHover = true;
        pillGraceTimer.stop();
        topWindow.pillHoverGrace = false;
    }
    signal openOverviewRequested
    signal openGameLibraryRequested

    property bool gameMode: Vars.gameMode !== undefined ? Vars.gameMode : false

    property int currentSpacingSmall: Vars.spacingSmall !== undefined ? Vars.spacingSmall : 11
    property int currentRadiusExtraLarge: Vars.radiusExtraLarge !== undefined ? Vars.radiusExtraLarge : 38
    property int currentAnimationDuration: Vars.animationDuration !== undefined ? Vars.animationDuration : 240

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

    function closeAllExcept(item) {
        if (item !== launcherItem) launcherItem.expanded = false;
        if (item !== controlCenterItem) controlCenterItem.expanded = false;
        if (item !== wallpaperSwitcherItem) wallpaperSwitcherItem.expanded = false;
        if (item !== colorSchemeSwitcherItem) colorSchemeSwitcherItem.expanded = false;
        if (item !== powerMenuItem) powerMenuItem.expanded = false;
        if (item !== emojiPickerItem) emojiPickerItem.expanded = false;
        if (item !== cheatSheetItem) cheatSheetItem.expanded = false;
        if (item !== notificationPopupItem) notificationPopupItem.expanded = false;
        if (item !== settingsAppItem) settingsAppItem.expanded = false;
        if (item !== workspacesItem) workspacesItem.cancelOverlay();
        if (item !== volumeOsdItem) volumeOsdItem.isVisible = false;
        if (item !== brightnessOsdItem) brightnessOsdItem.isVisible = false;
    }

    function closeAll() {
        closeAllExcept(null);
    }

    mask: Region {
        Region {
            item: topWindow.hasAnyPopupOpen ? popupScrim : null
        }
        Region {
            item: clockPill.isShown ? clockPill : clockHoverZone
        }
        Region {
            item: (workspacesItem.overlayVisible && !workspacesItem.forceHidePill) ? workspacesItem.panelMask : null
        }
        Region {
            item: controlCenterItem.expanded ? controlCenterItem.panelMask : null
        }
        Region {
            item: launcherItem.expanded ? launcherItem.panelMask : null
        }
        Region {
            item: powerMenuItem.expanded ? powerMenuItem.panelMask : null
        }
        Region {
            item: polkitItem.expanded ? polkitScrim : null
        }
        Region {
            item: wallpaperSwitcherItem.expanded ? wallpaperSwitcherItem.panelMask : null
        }
        Region {
            item: colorSchemeSwitcherItem.expanded ? colorSchemeSwitcherItem.panelMask : null
        }
        Region {
            item: notificationPopupItem.expanded ? notificationPopupItem.panelMask : null
        }
        Region {
            item: emojiPickerItem.expanded ? emojiPickerItem.panelMask : null
        }
        Region {
            item: cheatSheetItem.expanded ? cheatSheetItem.panelMask : null
        }
        Region {
            item: settingsAppItem.expanded ? settingsAppItem.panelMask : null
        }
        Region {
            item: volumeOsdItem.isVisible ? volumeOsdItem.panelMask : null
        }
        Region {
            item: brightnessOsdItem.isVisible ? brightnessOsdItem.panelMask : null
        }
    }

    // Restored popupScrim because Hyprland drops OnDemand focus on every commit
    // if the pointer is over another window. Exclusive focus + Scrim is required for animations.
    MouseArea {
        id: popupScrim
        anchors.fill: parent
        enabled: topWindow.hasAnyPopupOpen
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        onWheel: (wheel) => wheel.accepted = true
        onClicked: closeAll()
        z: -1
    }

    property bool suppressHover: false
    property bool pillHoverGrace: false
    property bool pillHoverActive: clockHoverArea.containsMouse || clockPill.isHovered
    onPillHoverActiveChanged: {
        if (pillHoverActive) {
            pillGraceTimer.stop();
            topWindow.pillHoverGrace = true;
        } else {
            topWindow.suppressHover = false;
            pillGraceTimer.restart();
        }
    }

    Timer {
        id: pillGraceTimer
        interval: 400
        repeat: false
        onTriggered: topWindow.pillHoverGrace = false
    }

    Item {
        id: clockHoverZone
        // x/y are computed as one atomic expression per axis instead of six independently
        // toggled anchor lines, so a pillPos change (e.g. Left -> Top) can't leave this item
        // part-anchored to the old edge while the other axis has already moved to the new one.
        width: (topWindow.pillPos === "Left" || topWindow.pillPos === "Right") ? 18 : clockPill.width
        height: (topWindow.pillPos === "Left" || topWindow.pillPos === "Right") ? clockPill.height : 18
        x: {
            if (topWindow.pillPos === "Left") return 0;
            if (topWindow.pillPos === "Right") return parent.width - width;
            return (parent.width - width) / 2;
        }
        y: {
            if (topWindow.pillPos === "Bottom") return parent.height - height;
            if (topWindow.pillPos === "Left" || topWindow.pillPos === "Right") return (parent.height - height) / 2;
            return 0;
        }
        
        MouseArea {
            id: clockHoverArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
            onEntered: {
                if (!(launcherItem.expanded || controlCenterItem.expanded || wallpaperSwitcherItem.expanded || colorSchemeSwitcherItem.expanded || powerMenuItem.expanded || polkitItem.expanded || notificationPopupItem.expanded || emojiPickerItem.expanded || settingsAppItem.expanded || cheatSheetItem.expanded || volumeOsdItem.isVisible || workspacesItem.overlayVisible)) {
                    topWindow.suppressHover = false;
                }
            }
            onExited: {
                topWindow.suppressHover = false;
            }
            onPositionChanged: {
                if (topWindow.suppressHover && !(launcherItem.expanded || controlCenterItem.expanded || wallpaperSwitcherItem.expanded || colorSchemeSwitcherItem.expanded || powerMenuItem.expanded || polkitItem.expanded || notificationPopupItem.expanded || emojiPickerItem.expanded || settingsAppItem.expanded || cheatSheetItem.expanded || volumeOsdItem.isVisible || workspacesItem.overlayVisible)) {
                    topWindow.suppressHover = false;
                }
            }
        }
    }

    readonly property var hyprMonitor: Hyprland.monitorFor(topWindow.screen)
    property bool isWindowPushingPill: false

    function updateWindowPushing() {
        if (!HyprlandData || !HyprlandData.windowList) {
            isWindowPushingPill = false;
            return;
        }
        var list = HyprlandData.windowList;
        if (list.length === 0) {
            isWindowPushingPill = false;
            return;
        }

        var curWsId = hyprMonitor?.activeWorkspace?.id ?? (Hyprland.focusedWorkspace?.id ?? 1);
        var curMonId = hyprMonitor?.id;
        var monX = hyprMonitor?.x ?? (topWindow.screen ? topWindow.screen.x : 0);
        var monY = hyprMonitor?.y ?? (topWindow.screen ? topWindow.screen.y : 0);
        var monW = topWindow.screen ? topWindow.screen.width : (hyprMonitor?.width ?? 1920);
        var monH = topWindow.screen ? topWindow.screen.height : (hyprMonitor?.height ?? 1080);

        var pillW = clockPill.width > 0 ? clockPill.width : 100;
        var pillH = clockPill.height > 0 ? clockPill.height : 40;
        var margin = topWindow.defaultEdgeMargin;
        var pillX = 0;
        var pillY = 0;

        if (topWindow.pillPos === "Bottom") {
            pillX = (monW - pillW) / 2;
            pillY = monH - pillH - margin;
        } else if (topWindow.pillPos === "Left") {
            pillX = margin;
            pillY = (monH - pillH) / 2;
        } else if (topWindow.pillPos === "Right") {
            pillX = monW - pillW - margin;
            pillY = (monH - pillH) / 2;
        } else { // Top
            pillX = (monW - pillW) / 2;
            pillY = margin;
        }

        var cushion = 10;
        var pLeft = pillX - cushion;
        var pRight = pillX + pillW + cushion;
        var pTop = pillY - cushion;
        var pBottom = pillY + pillH + cushion;

        var pushing = false;
        for (var i = 0; i < list.length; i++) {
            var win = list[i];
            if (!win || !win.mapped || win.hidden) continue;

            var winWsId = win.workspace ? win.workspace.id : null;
            var onThisWs = (winWsId === curWsId) || win.pinned;
            if (!onThisWs) continue;

            if (curMonId !== undefined && win.monitor !== undefined && win.monitor !== curMonId) {
                continue;
            }

            if (win.fullscreen && win.fullscreen !== 0) {
                pushing = true;
                break;
            }

            if (!win.at || !win.size || win.size[0] <= 0 || win.size[1] <= 0) continue;

            var wx = win.at[0] - monX;
            var wy = win.at[1] - monY;
            var ww = win.size[0];
            var wh = win.size[1];

            if ((wx < pRight) && (wx + ww > pLeft) && (wy < pBottom) && (wy + wh > pTop)) {
                pushing = true;
                break;
            }
        }
        if (isWindowPushingPill !== pushing) {
            isWindowPushingPill = pushing;
        }
    }

    Connections {
        target: HyprlandData
        function onWindowListChanged() {
            if (Vars.clockPillMode === "Dodge Windows" || Vars.clockPillMode === "Dodge") {
                topWindow.updateWindowPushing();
            }
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (Vars.clockPillMode === "Dodge Windows" || Vars.clockPillMode === "Dodge") {
                topWindow.updateWindowPushing();
            }
        }
    }

    Timer {
        interval: 150
        running: Vars.clockPillMode === "Dodge Windows" || Vars.clockPillMode === "Dodge"
        repeat: true
        onTriggered: topWindow.updateWindowPushing()
    }

    ClockPill {
        id: clockPill
        gameMode: topWindow.gameMode
        // x/y are computed as one atomic expression per axis instead of six independently
        // toggled anchor lines plus four margin lines, so a pillPos change (e.g. Left -> Top)
        // can't leave the pill part-anchored to the old edge while the other axis has already
        // moved to the new one (the cause of the pill rendering dead-center on a live change).
        x: {
            if (topWindow.pillPos === "Left") return topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Right") return parent.width - width - topWindow.defaultEdgeMargin;
            return (parent.width - width) / 2;
        }
        y: {
            if (topWindow.pillPos === "Bottom") return parent.height - height - topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Left" || topWindow.pillPos === "Right") return (parent.height - height) / 2;
            return topWindow.defaultEdgeMargin;
        }

        readonly property bool hasAnyOverlay: launcherItem.expanded || controlCenterItem.expanded || wallpaperSwitcherItem.expanded || colorSchemeSwitcherItem.expanded || powerMenuItem.expanded || polkitItem.expanded || notificationPopupItem.expanded || emojiPickerItem.expanded || settingsAppItem.expanded || cheatSheetItem.expanded || volumeOsdItem.isVisible || workspacesItem.overlayVisible
        readonly property bool isHoverTriggered: !topWindow.suppressHover && (topWindow.pillHoverGrace || clockHoverArea.containsMouse || clockPill.isHovered)

        property bool isShown: {
            if (hasAnyOverlay) return false;
            var mode = Vars.clockPillMode || "Always Visible";
            if (mode === "Always Visible" || mode === "Always") {
                return true;
            }
            if (mode === "Dodge Windows" || mode === "Dodge") {
                return (!topWindow.isWindowPushingPill || isHoverTriggered);
            }
            return isHoverTriggered;
        }

        opacity: isShown ? 1.0 : 0.0
        visible: opacity > 0
        
        Behavior on opacity {
            enabled: !topWindow.gameMode
            NumberAnimation {
                duration: currentAnimationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: clockPill.isShown ? Vars.customEmphasizedDecelerate : Vars.customEmphasizedAccelerate
            }
        }

        onClicked: {
            topWindow.suppressHover = true;
            pillGraceTimer.stop();
            topWindow.pillHoverGrace = false;
            toggleControlCenter();
        }
        onRightClicked: {
            topWindow.suppressHover = true;
            pillGraceTimer.stop();
            topWindow.pillHoverGrace = false;
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
        // x/y are computed as one atomic expression per axis instead of six independently
        // toggled anchor lines plus four margin lines, so a pillPos change can't leave this
        // item part-anchored to the old edge while the other axis has already moved to the new
        // one (that mismatch is what caused panels to render mid-screen, or with zero effective
        // size, right after a live position change).
        x: {
            if (topWindow.pillPos === "Left") return topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Right") return parent.width - width - topWindow.defaultEdgeMargin;
            return (parent.width - width) / 2;
        }
        y: {
            if (topWindow.pillPos === "Bottom") return parent.height - height - topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Left" || topWindow.pillPos === "Right") return (parent.height - height) / 2;
            return topWindow.defaultEdgeMargin;
        }
        forceHidePill: launcherItem.expanded || controlCenterItem.expanded || wallpaperSwitcherItem.expanded || colorSchemeSwitcherItem.expanded || powerMenuItem.expanded || polkitItem.expanded || notificationPopupItem.expanded || emojiPickerItem.expanded || settingsAppItem.expanded || cheatSheetItem.expanded || volumeOsdItem.isVisible

        onRequestCloseAll: {
            // A workspace switch happened and the pill is visible — dismiss any open popups
            closeAllExcept(workspacesItem);
        }
    }

    Launcher {
        id: launcherItem
        gameMode: topWindow.gameMode
        // x/y are computed as one atomic expression per axis instead of six independently
        // toggled anchor lines plus four margin lines, so a pillPos change can't leave this
        // item part-anchored to the old edge while the other axis has already moved to the new
        // one (that mismatch is what caused panels to render mid-screen, or with zero effective
        // size, right after a live position change).
        x: {
            if (topWindow.pillPos === "Left") return topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Right") return parent.width - width - topWindow.defaultEdgeMargin;
            return (parent.width - width) / 2;
        }
        y: {
            if (topWindow.pillPos === "Bottom") return parent.height - height - topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Left" || topWindow.pillPos === "Right") return (parent.height - height) / 2;
            return topWindow.defaultEdgeMargin;
        }
        width: 100
        height: 40
        focusWindow: topWindow

        onExpandedChanged: {
            if (expanded) {
                topWindow.popupOpened();
                closeAllExcept(launcherItem);
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
                _forceDropGrab = true;
                closeAllExcept(launcherItem);
                launcherItem.expanded = true;
                launcherItem.searchText = "";
                _forceDropGrab = false;
            }
        }
    }

    function toggleControlCenter() {
        if (!polkitItem.expanded) {
            let wasExpanded = controlCenterItem.expanded;
            if (wasExpanded) {
                controlCenterItem.expanded = false;
            } else {
                topWindow.popupOpened();
                _forceDropGrab = true;
                closeAllExcept(controlCenterItem);
                controlCenterItem.expanded = true;
                _forceDropGrab = false;
            }
        }
    }

    function toggleWallpaper() {
        if (!polkitItem.expanded) {
            let wasExpanded = wallpaperSwitcherItem.expanded;
            if (wasExpanded) {
                wallpaperSwitcherItem.expanded = false;
            } else {
                topWindow.popupOpened();
                _forceDropGrab = true;
                closeAllExcept(wallpaperSwitcherItem);
                wallpaperSwitcherItem.expanded = true;
                _forceDropGrab = false;
            }
        }
    }

    function toggleCheatSheet() {
        if (!polkitItem.expanded) {
            let wasExpanded = cheatSheetItem.expanded;
            if (wasExpanded) {
                cheatSheetItem.expanded = false;
            } else {
                topWindow.popupOpened();
                _forceDropGrab = true;
                closeAllExcept(cheatSheetItem);
                cheatSheetItem.expanded = true;
                _forceDropGrab = false;
            }
        }
    }

    function toggleColorScheme() {
        if (!polkitItem.expanded) {
            let wasExpanded = colorSchemeSwitcherItem.expanded;
            if (wasExpanded) {
                colorSchemeSwitcherItem.expanded = false;
            } else {
                topWindow.popupOpened();
                _forceDropGrab = true;
                closeAllExcept(colorSchemeSwitcherItem);
                colorSchemeSwitcherItem.expanded = true;
                _forceDropGrab = false;
            }
        }
    }

    function togglePowerMenu() {
        if (!polkitItem.expanded) {
            let wasExpanded = powerMenuItem.expanded;
            if (wasExpanded) {
                powerMenuItem.expanded = false;
            } else {
                topWindow.popupOpened();
                _forceDropGrab = true;
                closeAllExcept(powerMenuItem);
                powerMenuItem.expanded = true;
                _forceDropGrab = false;
            }
        }
    }

    function toggleEmojiPicker() {
        if (!polkitItem.expanded) {
            if (launcherItem.expanded && launcherItem.searchText === "/emoji ") {
                launcherItem.expanded = false;
            } else {
                topWindow.popupOpened();
                _forceDropGrab = true;
                closeAllExcept(launcherItem);
                launcherItem.expanded = true;
                launcherItem.searchText = "/emoji ";
                _forceDropGrab = false;
            }
        }
    }

    function toggleClipboard() {
        if (!polkitItem.expanded) {
            if (launcherItem.expanded && launcherItem.searchText === "/clipboard ") {
                launcherItem.expanded = false;
            } else {
                topWindow.popupOpened();
                _forceDropGrab = true;
                closeAllExcept(launcherItem);
                launcherItem.expanded = true;
                launcherItem.searchText = "/clipboard ";
                _forceDropGrab = false;
            }
        }
    }

    function toggleSettings() {
        if (!polkitItem.expanded) {
            let wasExpanded = settingsAppItem.expanded;
            if (wasExpanded) {
                settingsAppItem.expanded = false;
            } else {
                topWindow.popupOpened();
                _forceDropGrab = true;
                closeAllExcept(settingsAppItem);
                settingsAppItem.expanded = true;
                _forceDropGrab = false;
            }
        }
    }

    PowerMenu {
        id: powerMenuItem
        gameMode: topWindow.gameMode
        // x/y are computed as one atomic expression per axis instead of six independently
        // toggled anchor lines plus four margin lines, so a pillPos change can't leave this
        // item part-anchored to the old edge while the other axis has already moved to the new
        // one (that mismatch is what caused panels to render mid-screen, or with zero effective
        // size, right after a live position change).
        x: {
            if (topWindow.pillPos === "Left") return topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Right") return parent.width - width - topWindow.defaultEdgeMargin;
            return (parent.width - width) / 2;
        }
        y: {
            if (topWindow.pillPos === "Bottom") return parent.height - height - topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Left" || topWindow.pillPos === "Right") return (parent.height - height) / 2;
            return topWindow.defaultEdgeMargin;
        }
        width: 100
        height: 40
        focusWindow: topWindow

        onExpandedChanged: {
            if (expanded) {
                topWindow.popupOpened();
                closeAllExcept(powerMenuItem);
            }
        }
    }

    Rectangle {
        id: polkitScrim
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.5)
        opacity: polkitItem.expanded ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
        
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onClicked: {
                if (polkitItem.flow) {
                    polkitItem.flow.cancelAuthenticationRequest();
                }
            }
        }
    }

    PolkitDialog {
        id: polkitItem
        gameMode: topWindow.gameMode
        // x/y are computed as one atomic expression per axis instead of six independently
        // toggled anchor lines plus four margin lines, so a pillPos change can't leave this
        // item part-anchored to the old edge while the other axis has already moved to the new
        // one (that mismatch is what caused panels to render mid-screen, or with zero effective
        // size, right after a live position change).
        x: {
            if (topWindow.pillPos === "Left") return topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Right") return parent.width - width - topWindow.defaultEdgeMargin;
            return (parent.width - width) / 2;
        }
        y: {
            if (topWindow.pillPos === "Bottom") return parent.height - height - topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Left" || topWindow.pillPos === "Right") return (parent.height - height) / 2;
            return topWindow.defaultEdgeMargin;
        }
        width: polkitItem.panel.width
        height: polkitItem.panel.height
        focusWindow: topWindow

        onExpandedChanged: {
            if (expanded) {
                topWindow.popupOpened();
                closeAllExcept(polkitItem);
            }
        }
    }

    NotificationPopup {
        id: notificationPopupItem
        gameMode: topWindow.gameMode
        // x/y are computed as one atomic expression per axis instead of six independently
        // toggled anchor lines plus four margin lines, so a pillPos change can't leave this
        // item part-anchored to the old edge while the other axis has already moved to the new
        // one (that mismatch is what caused panels to render mid-screen, or with zero effective
        // size, right after a live position change).
        x: {
            if (topWindow.pillPos === "Left") return topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Right") return parent.width - width - topWindow.defaultEdgeMargin;
            return (parent.width - width) / 2;
        }
        y: {
            if (topWindow.pillPos === "Bottom") return parent.height - height - topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Left" || topWindow.pillPos === "Right") return (parent.height - height) / 2;
            return topWindow.defaultEdgeMargin;
        }
        width: 100
        height: 40
        focusWindow: topWindow

        onExpandedChanged: {
            if (expanded) {
                topWindow.popupOpened();
                closeAllExcept(notificationPopupItem);
            }
        }
    }

    ControlCenter {
        id: controlCenterItem
        gameMode: topWindow.gameMode
        // x/y are computed as one atomic expression per axis instead of six independently
        // toggled anchor lines plus four margin lines, so a pillPos change can't leave this
        // item part-anchored to the old edge while the other axis has already moved to the new
        // one (that mismatch is what caused panels to render mid-screen, or with zero effective
        // size, right after a live position change).
        x: {
            if (topWindow.pillPos === "Left") return topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Right") return parent.width - width - topWindow.defaultEdgeMargin;
            return (parent.width - width) / 2;
        }
        y: {
            if (topWindow.pillPos === "Bottom") return parent.height - height - topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Left" || topWindow.pillPos === "Right") return (parent.height - height) / 2;
            return topWindow.defaultEdgeMargin;
        }
        width: 100
        height: 40
        focusWindow: topWindow
        forceHidePill: launcherItem.expanded || volumeOsdItem.isVisible || wallpaperSwitcherItem.expanded || colorSchemeSwitcherItem.expanded || powerMenuItem.expanded || polkitItem.expanded || notificationPopupItem.expanded || emojiPickerItem.expanded || settingsAppItem.expanded || cheatSheetItem.expanded

        onExpandedChanged: {
            if (expanded) {
                topWindow.popupOpened();
                closeAllExcept(controlCenterItem);
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
            closeAll();
            Qt.callLater(() => { topWindow.openOverviewRequested(); });
        }

        onOpenGameLibraryRequested: {
            closeAll();
            Qt.callLater(() => { topWindow.openGameLibraryRequested(); });
        }

        onOpenCheatSheetRequested: {
            toggleCheatSheet();
        }
    }

    VolumeOsd {
        id: volumeOsdItem
        gameMode: topWindow.gameMode
        // x/y are computed as one atomic expression per axis instead of six independently
        // toggled anchor lines plus four margin lines, so a pillPos change can't leave this
        // item part-anchored to the old edge while the other axis has already moved to the new
        // one (that mismatch is what caused panels to render mid-screen, or with zero effective
        // size, right after a live position change).
        x: {
            if (topWindow.pillPos === "Left") return topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Right") return parent.width - width - topWindow.defaultEdgeMargin;
            return (parent.width - width) / 2;
        }
        y: {
            if (topWindow.pillPos === "Bottom") return parent.height - height - topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Left" || topWindow.pillPos === "Right") return (parent.height - height) / 2;
            return topWindow.defaultEdgeMargin;
        }
        preventShow: launcherItem.expanded || controlCenterItem.expanded || wallpaperSwitcherItem.expanded || colorSchemeSwitcherItem.expanded || powerMenuItem.expanded || polkitItem.expanded || notificationPopupItem.expanded || emojiPickerItem.expanded || settingsAppItem.expanded || cheatSheetItem.expanded || launcherItem.panel.width > 105 || controlCenterItem.panel.width > 105 || powerMenuItem.panel.width > 105 || polkitItem.panel.width > 105 || notificationPopupItem.panel.width > 105 || emojiPickerItem.panel.width > 105 || wallpaperSwitcherItem.panel.width > 105 || colorSchemeSwitcherItem.panel.width > 105 || settingsAppItem.panel.width > 105 || cheatSheetItem.panel.width > 105 || brightnessOsdItem.isVisible
    }

    BrightnessOsd {
        id: brightnessOsdItem
        gameMode: topWindow.gameMode
        // x/y are computed as one atomic expression per axis instead of six independently
        // toggled anchor lines plus four margin lines, so a pillPos change can't leave this
        // item part-anchored to the old edge while the other axis has already moved to the new
        // one (that mismatch is what caused panels to render mid-screen, or with zero effective
        // size, right after a live position change).
        x: {
            if (topWindow.pillPos === "Left") return topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Right") return parent.width - width - topWindow.defaultEdgeMargin;
            return (parent.width - width) / 2;
        }
        y: {
            if (topWindow.pillPos === "Bottom") return parent.height - height - topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Left" || topWindow.pillPos === "Right") return (parent.height - height) / 2;
            return topWindow.defaultEdgeMargin;
        }
        preventShow: launcherItem.expanded || controlCenterItem.expanded || wallpaperSwitcherItem.expanded || colorSchemeSwitcherItem.expanded || powerMenuItem.expanded || polkitItem.expanded || notificationPopupItem.expanded || emojiPickerItem.expanded || settingsAppItem.expanded || cheatSheetItem.expanded || launcherItem.panel.width > 105 || controlCenterItem.panel.width > 105 || powerMenuItem.panel.width > 105 || polkitItem.panel.width > 105 || notificationPopupItem.panel.width > 105 || emojiPickerItem.panel.width > 105 || wallpaperSwitcherItem.panel.width > 105 || colorSchemeSwitcherItem.panel.width > 105 || settingsAppItem.panel.width > 105 || cheatSheetItem.panel.width > 105 || volumeOsdItem.isVisible
    }

    WallpaperSwitcher {
        id: wallpaperSwitcherItem
        gameMode: topWindow.gameMode
        // x/y are computed as one atomic expression per axis instead of six independently
        // toggled anchor lines plus four margin lines, so a pillPos change can't leave this
        // item part-anchored to the old edge while the other axis has already moved to the new
        // one (that mismatch is what caused panels to render mid-screen, or with zero effective
        // size, right after a live position change).
        x: {
            if (topWindow.pillPos === "Left") return topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Right") return parent.width - width - topWindow.defaultEdgeMargin;
            return (parent.width - width) / 2;
        }
        y: {
            if (topWindow.pillPos === "Bottom") return parent.height - height - topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Left" || topWindow.pillPos === "Right") return (parent.height - height) / 2;
            return topWindow.defaultEdgeMargin;
        }
        focusWindow: topWindow
        forceHidePill: launcherItem.expanded || controlCenterItem.expanded || colorSchemeSwitcherItem.expanded || powerMenuItem.expanded || polkitItem.expanded || notificationPopupItem.expanded || emojiPickerItem.expanded || settingsAppItem.expanded || cheatSheetItem.expanded || volumeOsdItem.isVisible

        onExpandedChanged: {
            if (expanded) {
                topWindow.popupOpened();
                closeAllExcept(wallpaperSwitcherItem);
            }
        }

        onCloseRequested: expanded = false
    }

    EmojiPicker {
        id: emojiPickerItem
        gameMode: topWindow.gameMode
        // x/y are computed as one atomic expression per axis instead of six independently
        // toggled anchor lines plus four margin lines, so a pillPos change can't leave this
        // item part-anchored to the old edge while the other axis has already moved to the new
        // one (that mismatch is what caused panels to render mid-screen, or with zero effective
        // size, right after a live position change).
        x: {
            if (topWindow.pillPos === "Left") return topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Right") return parent.width - width - topWindow.defaultEdgeMargin;
            return (parent.width - width) / 2;
        }
        y: {
            if (topWindow.pillPos === "Bottom") return parent.height - height - topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Left" || topWindow.pillPos === "Right") return (parent.height - height) / 2;
            return topWindow.defaultEdgeMargin;
        }
        width: 100
        height: 40
        focusWindow: topWindow

        onExpandedChanged: {
            if (expanded) {
                topWindow.popupOpened();
                closeAllExcept(emojiPickerItem);
            }
        }
    }

    ColorSchemeSwitcher {
        id: colorSchemeSwitcherItem
        gameMode: topWindow.gameMode
        // x/y are computed as one atomic expression per axis instead of six independently
        // toggled anchor lines plus four margin lines, so a pillPos change can't leave this
        // item part-anchored to the old edge while the other axis has already moved to the new
        // one (that mismatch is what caused panels to render mid-screen, or with zero effective
        // size, right after a live position change).
        x: {
            if (topWindow.pillPos === "Left") return topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Right") return parent.width - width - topWindow.defaultEdgeMargin;
            return (parent.width - width) / 2;
        }
        y: {
            if (topWindow.pillPos === "Bottom") return parent.height - height - topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Left" || topWindow.pillPos === "Right") return (parent.height - height) / 2;
            return topWindow.defaultEdgeMargin;
        }
        focusWindow: topWindow
        forceHidePill: launcherItem.expanded || controlCenterItem.expanded || wallpaperSwitcherItem.expanded || powerMenuItem.expanded || polkitItem.expanded || notificationPopupItem.expanded || emojiPickerItem.expanded || settingsAppItem.expanded || cheatSheetItem.expanded || volumeOsdItem.isVisible

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
        // x/y are computed as one atomic expression per axis instead of six independently
        // toggled anchor lines plus four margin lines, so a pillPos change can't leave this
        // item part-anchored to the old edge while the other axis has already moved to the new
        // one (that mismatch is what caused panels to render mid-screen, or with zero effective
        // size, right after a live position change).
        x: {
            if (topWindow.pillPos === "Left") return topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Right") return parent.width - width - topWindow.defaultEdgeMargin;
            return (parent.width - width) / 2;
        }
        y: {
            if (topWindow.pillPos === "Bottom") return parent.height - height - topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Left" || topWindow.pillPos === "Right") return (parent.height - height) / 2;
            return topWindow.defaultEdgeMargin;
        }
        focusWindow: topWindow
        forceHidePill: launcherItem.expanded || controlCenterItem.expanded || wallpaperSwitcherItem.expanded || powerMenuItem.expanded || polkitItem.expanded || notificationPopupItem.expanded || emojiPickerItem.expanded || colorSchemeSwitcherItem.expanded || cheatSheetItem.expanded || volumeOsdItem.isVisible
        onDetachToggled: function(isFloating) {
            if (isFloating) topWindow.toggleFloatingSettings();
        }

        onExpandedChanged: {
            if (expanded) {
                topWindow.popupOpened();
                closeAllExcept(settingsAppItem);
            }
        }

        onOpenWallpaperSwitcherRequested: {
            toggleWallpaper();
        }

        onCloseRequested: expanded = false
    }

    KeybindCheatSheet {
        id: cheatSheetItem
        gameMode: topWindow.gameMode
        // x/y are computed as one atomic expression per axis instead of six independently
        // toggled anchor lines plus four margin lines, so a pillPos change can't leave this
        // item part-anchored to the old edge while the other axis has already moved to the new
        // one (that mismatch is what caused panels to render mid-screen, or with zero effective
        // size, right after a live position change).
        x: {
            if (topWindow.pillPos === "Left") return topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Right") return parent.width - width - topWindow.defaultEdgeMargin;
            return (parent.width - width) / 2;
        }
        y: {
            if (topWindow.pillPos === "Bottom") return parent.height - height - topWindow.defaultEdgeMargin;
            if (topWindow.pillPos === "Left" || topWindow.pillPos === "Right") return (parent.height - height) / 2;
            return topWindow.defaultEdgeMargin;
        }
        focusWindow: topWindow
        forceHidePill: launcherItem.expanded || controlCenterItem.expanded || wallpaperSwitcherItem.expanded || colorSchemeSwitcherItem.expanded || powerMenuItem.expanded || polkitItem.expanded || notificationPopupItem.expanded || emojiPickerItem.expanded || settingsAppItem.expanded || volumeOsdItem.isVisible

        onExpandedChanged: {
            if (expanded) {
                topWindow.popupOpened();
                closeAllExcept(cheatSheetItem);
            }
        }

        onCloseRequested: expanded = false
    }

    Repeater {
        model: [launcherItem, clockPill, workspacesItem, powerMenuItem, emojiPickerItem, colorSchemeSwitcherItem, wallpaperSwitcherItem, settingsAppItem, controlCenterItem, notificationPopupItem, polkitItem, volumeOsdItem, brightnessOsdItem, cheatSheetItem]
        delegate: Item {
            property var targetPanel: modelData
            property bool hasPanel: !!(targetPanel?.panel)
            property real px: (targetPanel?.x ?? 0) + (targetPanel?.panel?.x ?? 0)
            property real py: (targetPanel?.y ?? 0) + (targetPanel?.panel?.y ?? 0)
            property real pw: targetPanel?.panel?.width ?? targetPanel?.width ?? 0
            property real ph: targetPanel?.panel?.height ?? targetPanel?.height ?? 0
            property string pos: Vars.pillPosition || "Top"

            InvertedCorner {
                x: parent.pos === "Right" ? (parent.px + parent.pw - width) : (parent.pos === "Left" ? parent.px : parent.px - width)
                y: (parent.pos === "Right" || parent.pos === "Left") ? parent.py - height : (parent.pos === "Bottom" ? parent.py + parent.ph - height : parent.py)
                side: parent.pos === "Right" ? "bottom-right" : (parent.pos === "Left" ? "bottom-left" : (parent.pos === "Bottom" ? "bottom-right" : "top-right"))
                visible: Vars.panelStyle === "Attached" && opacity > 0 && parent.pw > 0 && parent.ph > 0
                color: (parent.targetPanel && parent.targetPanel.panel) ? parent.targetPanel.panel.color : "transparent"
                opacity: (parent.targetPanel && parent.targetPanel.panel ? parent.targetPanel.panel.opacity : 1.0) * (parent.targetPanel ? parent.targetPanel.opacity : 1.0)
                radius: Math.max(0, Math.min(currentRadiusExtraLarge, Math.min(parent.pw, parent.ph) / 2))
                antialiasing: true
            }
            InvertedCorner {
                x: (parent.pos === "Right" || parent.pos === "Left") ? (parent.pos === "Right" ? parent.px + parent.pw - width : parent.px) : parent.px + parent.pw
                y: (parent.pos === "Right" || parent.pos === "Left") ? parent.py + parent.ph : (parent.pos === "Bottom" ? parent.py + parent.ph - height : parent.py)
                side: parent.pos === "Right" ? "top-right" : (parent.pos === "Left" ? "top-left" : (parent.pos === "Bottom" ? "bottom-left" : "top-left"))
                visible: Vars.panelStyle === "Attached" && opacity > 0 && parent.pw > 0 && parent.ph > 0
                color: (parent.targetPanel && parent.targetPanel.panel) ? parent.targetPanel.panel.color : "transparent"
                opacity: (parent.targetPanel && parent.targetPanel.panel ? parent.targetPanel.panel.opacity : 1.0) * (parent.targetPanel ? parent.targetPanel.opacity : 1.0)
                radius: Math.max(0, Math.min(currentRadiusExtraLarge, Math.min(parent.pw, parent.ph) / 2))
                antialiasing: true
            }
        }
    }
}
