import QtQuick
import QtQuick.Effects
import ".."
import "./Launcher" as LC
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../theme"
import "../core/primitives" as Primitives
import "../mascot" as Mascots
Item {
    id: root
    
    // Fixed layout footprint - never animates, no parent relayout
    Layout.preferredWidth: 100
    Layout.preferredHeight: 40
    
    property bool expanded: false
    property var focusWindow: null
    property bool gameMode: Vars.gameMode !== undefined ? Vars.gameMode : false
    
    // Expose panel for TopPills Wayland mask tracking
    property alias panel: panel
    property alias panelMask: panelMask
    property alias searchText: searchBar.text

    function setSearchText(t) {
        searchBar.text = t;
    }

    function forceSearchFocus() {
        searchBar.forceActiveFocus();
    }

    // Removed debounce timer for instant filtering
    onSearchTextChanged: {
        // Notify model directly or let binding handle it
    }

    signal appLaunched()
    signal openSettingsRequested()

    LC.LauncherModel {
        id: launcherModel
        filterText: root.searchText
    }


    
    // Clear search when closed, focus when opened
    onExpandedChanged: {
        if (!expanded) {
            MorphState.notifyClosed();
            searchBar.text = "";
        } else {
            MorphState.notifyOpened(500, panel.targetHeight, panel.targetRad, panel);
            launcherModel.refreshClipboard();
            innerUI.visible = true;
            searchBar.forceActiveFocus();
            innerUI.visible = Qt.binding(() => root.expanded || innerUI.opacity > 0);
        }
    }

    Item {
        id: panelMask
        // x/y are computed as one atomic expression per axis instead of six independently
        // toggled anchor lines plus four bleed-margin lines, so a pillPosition change can't
        // leave this item part-anchored to the old edge while the other axis has already moved
        // to the new one (that mismatch is what made expanded popups fail to render their
        // content after a live position change).
        property real _bleed: root.expanded ? -20 : 0
        x: {
            if (Vars.pillPosition === "Left") return _bleed;
            if (Vars.pillPosition === "Right") return parent.width - width - _bleed;
            return (parent.width - width) / 2;
        }
        y: {
            if (Vars.pillPosition === "Bottom") return parent.height - height - _bleed;
            if (Vars.pillPosition === "Left" || Vars.pillPosition === "Right") return (parent.height - height) / 2;
            return _bleed;
        }

        width: root.expanded ? 540 : 0
        height: root.expanded ? 490 : 0
    }

    // The visual panel that animates
    Primitives.SquircleMask {
        id: panel
        property bool isBackgroundActive: root.expanded || (MorphState.openCount === 0 && MorphState.activeItem === panel && panel.width > 105)
        layer.enabled: false
        layer.samples: Vars.layerSamples
        // x/y are computed as one atomic expression per axis instead of six independently
        // toggled anchor lines, so a pillPosition change can't leave this item part-anchored to
        // the old edge while the other axis has already moved to the new one (that mismatch is
        // what made expanded popups fail to render their content after a live position change).
        x: {
            if (Vars.pillPosition === "Left") return 0;
            if (Vars.pillPosition === "Right") return parent.width - width;
            return (parent.width - width) / 2;
        }
        y: {
            if (Vars.pillPosition === "Bottom") return parent.height - height;
            if (Vars.pillPosition === "Left" || Vars.pillPosition === "Right") return (parent.height - height) / 2;
            return 0;
        }
        
        onHeightChanged: console.log("[DEBUG] Launcher panel.height:", height, "implicit:", mainLayout.implicitHeight)
        property real targetHeight: root.expanded ? Math.max(80, Math.min(450, mainLayout.implicitHeight + (Vars.spacingLarge * 2))) : (MorphState.anyExpanded ? MorphState.targetHeight : 40)
        width: root.expanded ? 500 : (MorphState.anyExpanded ? MorphState.targetWidth : 100)
        height: targetHeight
        
        onTargetHeightChanged: {
            if (root.expanded) MorphState.updateDimensions(500, targetHeight, targetRad);
        }
        
        opacity: isBackgroundActive || innerUI.opacity > 0 ? 1.0 : 0.0
        // visible: opacity > 0 // Removed to preserve Behavior when hidden
        
        color: Vars.tColorActive(isBackgroundActive, Theme.surface, Vars.panelOpacity)
        property real targetRad: root.expanded ? Vars.radiusLarge : (MorphState.anyExpanded ? MorphState.targetRadius : height / 2)
        topLeftRadius: Vars.getTopLeftRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        topRightRadius: Vars.getTopRightRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        bottomLeftRadius: Vars.getBottomLeftRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)
        bottomRightRadius: Vars.getBottomRightRadius(Vars.panelStyle, Vars.pillPosition, false, targetRad)

        Behavior on width { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on height { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            hoverEnabled: true
            enabled: panel.opacity > 0
            onWheel: (wheel) => wheel.accepted = true
        }

        // EXPANDED UI
        Item {
            id: innerUI
            // Content must never draw outside the morphing panel
            clip: true
            anchors.fill: parent
            anchors.margins: Vars.spacingMedium
            
            opacity: root.expanded ? 1.0 : 0.0
            visible: root.expanded || opacity > 0
            Behavior on opacity { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.getFadeCurve(root.expanded) } }

            ColumnLayout {
                id: mainLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                spacing: 6

                SearchBar {
                    id: searchBar
                    expanded: root.expanded
                    placeholderText: "Search apps, or /ask Puffy..."
                    showIcon: true
                    containerPadding: Vars.spacingMedium
                    outerTopLeftRadius: panel.topLeftRadius
                    outerTopRightRadius: panel.topRightRadius
                    outerBottomLeftRadius: appList.count > 0 ? (4 + Vars.spacingMedium) : panel.bottomLeftRadius
                    outerBottomRightRadius: appList.count > 0 ? (4 + Vars.spacingMedium) : panel.bottomRightRadius
                    
                    Behavior on outerTopLeftRadius { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                    Behavior on outerTopRightRadius { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                    Behavior on outerBottomLeftRadius { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                    Behavior on outerBottomRightRadius { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                    // in /ask the AI is Puffy: it watches the letters, bobs while it thinks, is
                    // glad at an answer and sad at an error
                    Mascots.Mascot {
                        id: puffy
                        readonly property bool asking: searchBar.text.startsWith("/ask")
                        width: 36
                        height: 36
                        anchors.right: parent.right
                        // left of the bar's clear button
                        anchors.rightMargin: 52
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: asking && Vars.mascots && Vars.assistant !== false ? 1 : 0
                        visible: opacity > 0
                        Behavior on opacity { NumberAnimation { duration: 160 } }
                        kind: "puffy"
                        happyColor: Theme.tertiary_container
                        sadColor: Theme.secondary_container
                        angryColor: Theme.error_container
                        calm: Vars.reduceMotion
                        body: Theme.primary_container
                        ink: Theme.on_primary_container
                        eyeWhite: Theme.primary_fixed
                        pupil: Theme.on_primary_fixed
                        accent: Theme.primary
                        run: launcherModel.askBusy ? 0.7 : 0
                        look: launcherModel.askBusy ? Qt.point(-0.2, -1) : searchBar.text.length > 5 ? Qt.point(-1, 0.1) : Qt.point(0, -0.35)
                        Connections {
                            target: searchBar
                            function onTextChanged() { if (puffy.asking) puffy.react("type") }
                        }
                        Connections {
                            target: launcherModel
                            function onAnswered(ok) { puffy.react(ok ? "right" : "wrong") }
                        }
                    }

                    onDownPressed: {
                        if (appList.count > 0 && appList.currentIndex === -1) {
                            appList.currentIndex = 0;
                        }
                        appList.forceActiveFocus();
                    }
                    onReturnPressed: {
                        if (appList.count > 0 && appList.currentIndex === -1) {
                            appList.currentIndex = 0;
                        }
                        appList.forceActiveFocus();
                    }
                    onEscapePressed: {
                        if (appList.count > 0 && appList.currentIndex === -1) {
                            appList.currentIndex = 0;
                        }
                        appList.forceActiveFocus();
                    }
                }

                LC.AppList {
                    id: appList
                    launcherModel: launcherModel
                    searchText: searchBar.text
                    model: launcherModel.filteredModel
                    outerTopLeftRadius: panel.topLeftRadius
                    outerTopRightRadius: panel.topRightRadius
                    outerBottomLeftRadius: panel.bottomLeftRadius
                    outerBottomRightRadius: panel.bottomRightRadius
                    containerPadding: Vars.spacingMedium
                    
                    onAppLaunched: root.appLaunched()
                    onEscapePressed: root.expanded = false
                    onFocusSearchBar: searchBar.forceActiveFocus()
                    onOpenSettingsRequested: root.openSettingsRequested()
                    
                    onRequestSearchText: (t) => {
                        searchBar.text = t;
                    }
                }
            }
        }
    }
}