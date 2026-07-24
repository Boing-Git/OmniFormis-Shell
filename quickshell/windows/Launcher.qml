import QtQuick
import QtQuick.Effects
import ".."
import "./Launcher" as LC
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "../theme/variables.js" as Vars

Item {
    id: root
    
    // Fixed layout footprint - never animates, no parent relayout
    Layout.preferredWidth: 100
    Layout.preferredHeight: 40
    
    property bool expanded: false
    property var focusWindow: null
    property bool gameMode: false
    
    // Expose panel for TopPills Wayland mask tracking
    property alias panel: panel
    property alias panelMask: panelMask
    property alias searchText: searchBar.text

    function setSearchText(t) {
        searchBar.text = t;
    }

    signal appLaunched()
    signal openSettingsRequested()

    LC.LauncherModel {
        id: launcherModel
        filterText: searchBar.text
    }

    HyprlandFocusGrab {
        active: root.expanded && root.focusWindow !== null
        windows: root.focusWindow ? [root.focusWindow] : []
        onCleared: root.expanded = false
    }
    
    // Clear search when closed, focus when opened
    onExpandedChanged: {
        if (!expanded) {
            searchBar.text = "";
        } else {
            // Refresh clipboard history when opened
            launcherModel.refreshClipboard();
            searchBar.forceActiveFocus();
        }
    }

    Item {
        id: panelMask
        anchors.centerIn: panel
        width: panel.width + 40
        height: panel.height + 40
    }

    // The visual panel that animates
    Rectangle {
        id: panel
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: !root.gameMode; shadowBlur: 1.0; shadowColor: Qt.rgba(0,0,0,0.25); shadowVerticalOffset: 4; shadowHorizontalOffset: 0 }
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        
        width: root.expanded ? 500 : 100
        height: root.expanded ? Math.max(80, Math.min(450, mainLayout.implicitHeight + (Vars.spacingLarge * 2))) : 40
        
        opacity: root.expanded || panel.width > 105 ? 1.0 : 0.0
        visible: opacity > 0
        
        color: Vars.translucent ? Qt.rgba(Theme.surface.r, Theme.surface.g, Theme.surface.b, 0.85) : Theme.surface
        topLeftRadius: root.gameMode || Vars.panelStyle === "Attached" || Vars.panelStyle === "Framed" ? 0 : (root.expanded ? Vars.radiusExtraLarge : height / 2)
        topRightRadius: root.gameMode || Vars.panelStyle === "Attached" || Vars.panelStyle === "Framed" ? 0 : (root.expanded ? Vars.radiusExtraLarge : height / 2)
        bottomLeftRadius: root.gameMode ? 0 : (root.expanded ? Vars.radiusExtraLarge : height / 2)
        bottomRightRadius: root.gameMode ? 0 : (root.expanded ? Vars.radiusExtraLarge : height / 2)

        Behavior on radius { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on width { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on height { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

        // EXPANDED UI
        Item {
            anchors.fill: parent
            anchors.margins: Vars.spacingLarge
            
            opacity: root.expanded ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { enabled: !root.gameMode; SequentialAnimation { PauseAnimation { duration: root.expanded ? Vars.animationDuration : 0 } NumberAnimation { duration: root.expanded ? Vars.animationDuration : Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.expanded ? Vars.customEmphasizedDecelerate : Vars.customEmphasizedAccelerate } } }

            ColumnLayout {
                id: mainLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                spacing: Vars.spacingMedium

                // Header removed per user request

                LC.SearchBar {
                    id: searchBar
                    expanded: root.expanded
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
                        root.expanded = false;
                    }
                }

                LC.AppList {
                    id: appList
                    launcherModel: launcherModel
                    searchText: searchBar.text
                    model: launcherModel.filteredModel
                    
                    onAppLaunched: root.appLaunched()
                    onEscapePressed: root.expanded = false
                    onFocusSearchBar: searchBar.forceActiveFocus()
                    onOpenSettingsRequested: root.openSettingsRequested()
                    
                    onSearchTextChanged: {
                        searchBar.text = searchText;
                    }
                }
            }
        }
    }
}