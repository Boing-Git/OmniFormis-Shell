import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Bluetooth
import QtCore
import "../theme"
import "../core/primitives" as Primitives
import "SettingsApp"
import ".."

Item {
    id: root

    Settings {
        id: settings
        category: "SettingsApp"
        property int sidebarWidth: 280
    }

    Layout.preferredWidth: 100
    Layout.preferredHeight: 40

    property bool expanded: false
    property bool forceHidePill: false
    property var focusWindow: null
    property bool gameMode: Vars.gameMode !== undefined ? Vars.gameMode : false
    property var allVars: []
    property alias panel: panel
    property alias panelMask: panelMask

    property bool isFloatingInstance: false
    signal detachToggled(bool isFloating)

    property string currentSection: "quick"
    property string globalSearchText: globalSearchBar.text

    // Extracted navigation properties mapped from the sidebar
    readonly property var baseNavItems: [
        // Presets & Quick Settings
        {
            id: "quick",
            name: "Quick & Presets",
            subtitle: "Presets, wallpaper, panel style & position",
            icon: "\ue41d",
            section: "Presets & Customization",
            hue: 0.80,
            shape: "Puffy"
        },

        // Connections
        {
            id: "wifi",
            name: "Wi-Fi",
            subtitle: "Wi-Fi, ethernet",
            icon: root.wifiIcon,
            section: "Connections",
            hue: 0.60,
            shape: "Puffy"
        },
        {
            id: "bluetooth",
            name: "Connected devices",
            subtitle: "Bluetooth, devices, pairing",
            icon: root.bluetoothIcon,
            section: "Connections",
            hue: 0.65,
            shape: "Puffy"
        },

        // System & Input
        {
            id: "General",
            name: "System & Apps",
            subtitle: "Default apps, environment, gaming",
            icon: "\ue8b8",
            section: "System & Input",
            hue: 0.70,
            shape: "Puffy"
        },
        {
            id: "Input",
            name: "Input Devices",
            subtitle: "Keyboard layout, mouse, gestures",
            icon: "\ue312",
            section: "System & Input",
            hue: 0.75,
            shape: "Puffy"
        },
        {
            id: "Keybinds",
            name: "Shortcuts & Modifiers",
            subtitle: "System shortcuts, hotkeys, modifiers",
            icon: "\ue31c",
            section: "System & Input",
            hue: 0.80,
            shape: "Puffy"
        },

        // Desktop & Windows
        {
            id: "Desktop",
            name: "Desktop & Widgets",
            subtitle: "Wallpaper mask, clock, calendar, overview",
            icon: "\ue871",
            section: "Desktop & Windows",
            hue: 0.85,
            shape: "Puffy"
        },
        {
            id: "Layout",
            name: "Window Gaps & Layout",
            subtitle: "Window gaps, border size, spacing, padding",
            icon: "\ue8f1",
            section: "Desktop & Windows",
            hue: 0.90,
            shape: "Puffy"
        },

        // Appearance & Animations
        {
            id: "Theme",
            name: "Visuals & Effects",
            subtitle: "Rounding, opacity, blur, shadow, font family",
            icon: "\ue3b7",
            section: "Appearance & Animations",
            hue: 0.95,
            shape: "Puffy"
        },
        {
            id: "Animations",
            name: "Animation & Physics",
            subtitle: "Animation style, durations, scroll physics",
            icon: "\ue410",
            section: "Appearance & Animations",
            hue: 0.00,
            shape: "Puffy"
        },
        {
            id: "bezier",
            name: "Curve Editor",
            subtitle: "Interactive custom bezier creator",
            icon: "\ue71c",
            section: "Appearance & Animations",
            hue: 0.06,
            shape: "Puffy"
        },

        // System Monitor & Info
        {
            id: "taskmanager",
            name: "Task Manager",
            subtitle: "System resources, processes",
            icon: "\ue85c",
            section: "System Info",
            hue: 0.12,
            shape: "Puffy"
        },
        {
            id: "about",
            name: "About",
            subtitle: "Omniformis Shell info",
            icon: "\ue88e",
            section: "System Info",
            hue: 0.18,
            shape: "Puffy"
        }
    ]

    function navMatchesSearch(navItem, searchText) {
        if (!searchText)
            return true;
        var terms = searchText.toLowerCase().trim().replace(/-/g, "").split(/\s+/);
        if (terms.length === 0 || terms[0] === "")
            return true;

        var searchableText = navItem.name + " " + navItem.subtitle + " " + navItem.id + " " + (navItem.section || "");

        var unifiedCategories = ["General", "Input", "Keybinds", "Desktop", "Layout", "Theme", "Animations"];
        if (unifiedCategories.includes(navItem.id)) {
            var vars = unifiedPage.allVars;
            if (vars) {
                for (var i = 0; i < vars.length; i++) {
                    var v = vars[i];
                    if (v.category === navItem.id) {
                        if (v.key)
                            searchableText += " " + v.key;
                        if (v.title)
                            searchableText += " " + v.title;
                        if (v.help)
                            searchableText += " " + v.help;
                        if (v.source)
                            searchableText += " " + v.source;
                    }
                }
            }
        }

        searchableText = searchableText.toLowerCase().replace(/-/g, "");
        for (var t = 0; t < terms.length; t++) {
            if (!searchableText.includes(terms[t])) {
                return false;
            }
        }

        return true;
    }

    function filterNavItems(searchText) {
        var filtered = [];
        var currentSectionGroups = {};

        // First pass: collect matching items
        for (var i = 0; i < baseNavItems.length; i++) {
            var item = baseNavItems[i];
            if (navMatchesSearch(item, searchText)) {
                filtered.push(Object.assign({}, item));
            }
        }

        // Second pass: compute isFirst and isLast by section
        for (var j = 0; j < filtered.length; j++) {
            var cur = filtered[j];
            var sec = cur.section;
            if (!currentSectionGroups[sec]) {
                currentSectionGroups[sec] = [];
            }
            currentSectionGroups[sec].push(cur);
        }

        for (var s in currentSectionGroups) {
            var group = currentSectionGroups[s];
            for (var k = 0; k < group.length; k++) {
                group[k].isFirst = (k === 0);
                group[k].isLast = (k === group.length - 1);
            }
        }

        return filtered;
    }

    property var navItems: filterNavItems(globalSearchText)

    property var currentNavItem: navItems ? (navItems.find(i => i.id === currentSection) || navItems[0]) : null
    property int currentNavIndex: navItems ? Math.max(0, navItems.findIndex(i => i.id === currentSection)) : 0
    property color currentNavColor: {
        var colors = [Theme.primary, Theme.secondary, Theme.tertiary];
        return colors[currentNavIndex % 3];
    }
    property color currentNavOnColor: {
        var colors = [Theme.on_primary, Theme.on_secondary, Theme.on_tertiary];
        return colors[currentNavIndex % 3];
    }

    signal openWallpaperSwitcherRequested

    // Wi-Fi
    property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
    property var activeNet: wifiDevice ? wifiDevice.networks.values.find(n => n.connected) : null
    property var wifiSignal: activeNet ? activeNet.signalStrength : 0

    readonly property string wifiIcon: {
        if (!Networking.wifiEnabled)
            return "\ue1da";
        if (!activeNet)
            return "\uf067";
        let tier = Math.min(Math.floor(wifiSignal / 25), 3);
        let icons = ["\ue1ba", "\uebe4", "\uebd6", "\uebe1"];
        return icons[tier];
    }

    // Bluetooth
    property var adapter: Bluetooth.defaultAdapter
    property bool adapterState: adapter ? adapter.enabled : false
    property var connectDevice: adapter ? adapter.devices.values.find(d => d.connected) : null

    readonly property string bluetoothIcon: {
        if (!adapterState)
            return "\ue1a9";
        if (!connectDevice)
            return "\ue1a7";
        return "\ue1a8";
    }

    opacity: forceHidePill ? 0.0 : 1.0
    visible: opacity > 0
    signal closeRequested
    onExpandedChanged: {
        if (expanded) {
            MorphState.notifyOpened(root.isFloatingInstance ? root.width : 1440, root.isFloatingInstance ? root.height : 740, panel.targetRad, panel);
            root.forceActiveFocus();
        } else {
            MorphState.notifyClosed();
        }
    }

    Item {
        id: panelMask
        anchors.top: (!Vars.pillPosition || Vars.pillPosition === "Top") ? parent.top : undefined
        anchors.bottom: Vars.pillPosition === "Bottom" ? parent.bottom : undefined
        anchors.left: Vars.pillPosition === "Left" ? parent.left : undefined
        anchors.right: Vars.pillPosition === "Right" ? parent.right : undefined
        anchors.horizontalCenter: (Vars.pillPosition === "Left" || Vars.pillPosition === "Right") ? undefined : parent.horizontalCenter
        anchors.verticalCenter: (Vars.pillPosition === "Left" || Vars.pillPosition === "Right") ? parent.verticalCenter : undefined

        anchors.topMargin: root.expanded ? -20 : 0
        anchors.bottomMargin: root.expanded ? -20 : 0
        anchors.leftMargin: root.expanded ? -20 : 0
        anchors.rightMargin: root.expanded ? -20 : 0
        width: root.expanded ? 740 : 0
        height: root.expanded ? 540 : 0
    }

    Primitives.SquircleMask {
        id: panel
        property bool isBackgroundActive: root.expanded || (MorphState.openCount === 0 && MorphState.activeItem === panel && panel.width > 105)
        layer.enabled: false
        layer.samples: Vars.layerSamples
        anchors.top: (!Vars.pillPosition || Vars.pillPosition === "Top" || root.isFloatingInstance) ? parent.top : undefined
        anchors.bottom: (!root.isFloatingInstance && Vars.pillPosition === "Bottom") ? parent.bottom : undefined
        anchors.left: (!root.isFloatingInstance && Vars.pillPosition === "Left") ? parent.left : undefined
        anchors.right: (!root.isFloatingInstance && Vars.pillPosition === "Right") ? parent.right : undefined
        anchors.horizontalCenter: (!root.isFloatingInstance && (Vars.pillPosition !== "Left" && Vars.pillPosition !== "Right")) ? parent.horizontalCenter : undefined
        anchors.verticalCenter: (!root.isFloatingInstance && (Vars.pillPosition === "Left" || Vars.pillPosition === "Right")) ? parent.verticalCenter : undefined

        width: root.expanded ? (root.isFloatingInstance ? root.width : 1440) : (MorphState.anyExpanded ? MorphState.targetWidth : 100)
        height: root.expanded ? (root.isFloatingInstance ? root.height : 740) : (MorphState.anyExpanded ? MorphState.targetHeight : 40)

        color: Vars.tColorActive(isBackgroundActive, Theme.surface_container_low, Vars.panelOpacity)
        property real targetRad: (root.expanded || root.isFloatingInstance) ? Vars.radiusExtraLarge : (MorphState.anyExpanded ? MorphState.targetRadius : height / 2)
        topLeftRadius: Vars.getTopLeftRadius(Vars.panelStyle, Vars.pillPosition, root.isFloatingInstance, targetRad)
        topRightRadius: Vars.getTopRightRadius(Vars.panelStyle, Vars.pillPosition, root.isFloatingInstance, targetRad)
        bottomLeftRadius: Vars.getBottomLeftRadius(Vars.panelStyle, Vars.pillPosition, root.isFloatingInstance, targetRad)
        bottomRightRadius: Vars.getBottomRightRadius(Vars.panelStyle, Vars.pillPosition, root.isFloatingInstance, targetRad)

        opacity: isBackgroundActive || innerUI.opacity > 0 ? 1.0 : 0.0
        // visible: opacity > 0 // Removed to preserve Behavior when hidden

        Behavior on width {
            enabled: !root.gameMode
            NumberAnimation {
                duration: Vars.animationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customExpressiveSpatialSlow
            }
        }
        Behavior on height {
            enabled: !root.gameMode
            NumberAnimation {
                duration: Vars.animationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customExpressiveSpatialSlow
            }
        }

        Item {
            id: innerUI
            anchors.centerIn: parent
            width: Math.max(1, parent.width - Vars.spacingLarge * 2)
            height: Math.max(1, parent.height - Vars.spacingLarge * 2)

            opacity: root.expanded ? 1.0 : 0.0
            visible: root.expanded || opacity > 0
            clip: true
            Behavior on opacity {
                enabled: !root.gameMode
                NumberAnimation {
                    duration: Vars.animationDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Vars.getFadeCurve(root.expanded)
                }
            }

            property alias sidebarWidth: settings.sidebarWidth

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // Sidebar
                Item {
                    Layout.preferredWidth: innerUI.sidebarWidth
                    Layout.minimumWidth: 200
                    Layout.maximumWidth: 600
                    Layout.fillHeight: true
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: Vars.spacingMedium

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Primitives.SearchBar {
                                id: globalSearchBar
                                Layout.fillWidth: true
                                placeholderText: "Search settings..."
                                showIcon: true
                                iconText: "search"
                                defaultHeight: 48
                                defaultColor: Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)
                                activeColor: Vars.tColorSelected(Theme.primary)
                                defaultTextColor: Theme.on_surface_variant
                                activeTextColor: Theme.on_primary
                                defaultPlaceholderColor: Theme.on_surface_variant
                                activePlaceholderColor: Qt.rgba(Theme.on_primary.r, Theme.on_primary.g, Theme.on_primary.b, 0.7)
                                borderWidth: 0
                                fontWeight: Font.Bold

                                topLeftRadius: Math.max(0, panel.topLeftRadius - Vars.spacingLarge)
                                // Nothing touches the row from below, so its lower outer corner is fully rounded
                                bottomLeftRadius: Vars.radiusLarge
                                property real innerRadius: globalSearchBar.isActiveFocus ? 20 : 4
                                Behavior on innerRadius {
                                    NumberAnimation {
                                        duration: Vars.animationDuration
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: Vars.customStandard
                                    }
                                }
                                topRightRadius: innerRadius
                                bottomRightRadius: innerRadius
                            }

                            // Detach Button
                            Rectangle {
                                antialiasing: true
                                width: 48
                                height: 48
                                color: detachHover.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (detachHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : Vars.tColor(Theme.surface_container_high, Vars.componentOpacity))

                                property real rHover: detachHover.containsMouse ? 20 : 4
                                Behavior on rHover {
                                    NumberAnimation {
                                        duration: Vars.animationDuration
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: Vars.customStandard
                                    }
                                }
                                topLeftRadius: rHover
                                bottomLeftRadius: rHover
                                topRightRadius: rHover
                                bottomRightRadius: rHover

                                QsText {
                                    anchors.centerIn: parent
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 20
                                    color: detachHover.containsMouse ? Theme.on_surface : Theme.on_surface_variant
                                    text: root.isFloatingInstance ? "\ue5ce" : "\ue89b"
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Vars.animationDuration
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: Vars.customStandard
                                        }
                                    }
                                }
                                MouseArea {
                                    id: detachHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.expanded = false;
                                        root.detachToggled(!root.isFloatingInstance);
                                    }
                                }
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Vars.animationDuration
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: Vars.customStandard
                                    }
                                }
                            }

                            // Close Button
                            Rectangle {
                                antialiasing: true
                                width: 48
                                height: 48
                                color: backHover.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (backHover.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : Vars.tColor(Theme.surface_container_high, Vars.componentOpacity))

                                property real rHover: backHover.containsMouse ? 20 : 4
                                Behavior on rHover {
                                    NumberAnimation {
                                        duration: Vars.animationDuration
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: Vars.customStandard
                                    }
                                }
                                topLeftRadius: rHover
                                bottomLeftRadius: rHover
                                topRightRadius: Math.max(0, panel.topRightRadius - Vars.spacingLarge)
                                bottomRightRadius: Vars.radiusLarge

                                QsText {
                                    anchors.centerIn: parent
                                    font.family: "Material Symbols Outlined"
                                    font.pixelSize: 20
                                    color: backHover.containsMouse ? Theme.on_surface : Theme.on_surface_variant
                                    text: "\ue5cd"
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: Vars.animationDuration
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: Vars.customStandard
                                        }
                                    }
                                }
                                MouseArea {
                                    id: backHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.expanded = false
                                }
                                Behavior on color {
                                    ColorAnimation {
                                        duration: Vars.animationDuration
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: Vars.customStandard
                                    }
                                }
                            }
                        }

                        Item {
                            Layout.preferredHeight: Vars.spacingSmall
                        }

                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentHeight: sidebar.implicitHeight
                            clip: true
                            interactive: true

                            SettingsSidebar {
                                id: sidebar
                                width: parent.width
                                currentSection: root.currentSection
                                navItems: root.navItems
                                onCurrentSectionChanged: {
                                    if (root.currentSection !== currentSection) {
                                        root.currentSection = currentSection;
                                    }
                                }
                            }
                        }
                    }
                }

                // Draggable Divider
                Item {
                    Layout.preferredWidth: Vars.spacingLarge
                    Layout.fillHeight: true

                    Rectangle {
                        anchors.centerIn: parent
                        width: 2
                        height: parent.height
                        color: dividerArea.pressed ? Theme.primary : (dividerArea.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.4) : Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.2))
                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                    }

                    MouseArea {
                        id: dividerArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.SizeHorCursor
                        property real pressX: 0
                        property int pressWidth: 0
                        onPressed: mouse => {
                            pressX = mapToItem(innerUI, mouse.x, 0).x;
                            pressWidth = innerUI.sidebarWidth;
                        }
                        onPositionChanged: mouse => {
                            if (pressed) {
                                var dx = mapToItem(innerUI, mouse.x, 0).x - pressX;
                                innerUI.sidebarWidth = Math.min(600, Math.max(200, pressWidth + dx));
                            }
                        }
                    }
                }

                // Content Area
                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: {
                        if (root.currentSection === "quick")
                            return 0;
                        if (root.currentSection === "bezier")
                            return 2;
                        if (root.currentSection === "wifi")
                            return 3;
                        if (root.currentSection === "bluetooth")
                            return 4;
                        if (root.currentSection === "about")
                            return 5;
                        if (root.currentSection === "taskmanager")
                            return 6;
                        if (root.currentSection === "Keybinds")
                            return 7;
                        return 1;
                    }

                    QuickPage {
                        id: quickPage
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        pageTitle: root.currentNavItem ? root.currentNavItem.name : ""
                        pageIcon: root.currentNavItem ? root.currentNavItem.icon : ""
                        pageShape: root.currentNavItem ? root.currentNavItem.shape : "Circle"
                        pageColor: root.currentNavColor
                        pageOnColor: root.currentNavOnColor
                        onOpenWallpaperSwitcher: {
                            root.openWallpaperSwitcherRequested();
                        }
                    }

                    UnifiedSettingsPage {
                        id: unifiedPage
                        activeCategory: (root.currentSection === "General" || root.currentSection === "Input" || root.currentSection === "Keybinds" || root.currentSection === "Desktop" || root.currentSection === "Layout" || root.currentSection === "Theme" || root.currentSection === "Animations") ? root.currentSection : "General"
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        pageTitle: root.currentNavItem ? root.currentNavItem.name : ""
                        pageIcon: root.currentNavItem ? root.currentNavItem.icon : ""
                        pageShape: root.currentNavItem ? root.currentNavItem.shape : "Circle"
                        pageColor: root.currentNavColor
                        pageOnColor: root.currentNavOnColor
                        searchText: root.globalSearchText
                    }

                    BezierEditorPage {
                        id: bezierPage
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        pageTitle: root.currentNavItem ? root.currentNavItem.name : ""
                        pageIcon: root.currentNavItem ? root.currentNavItem.icon : ""
                        pageShape: root.currentNavItem ? root.currentNavItem.shape : "Circle"
                        pageColor: root.currentNavColor
                        pageOnColor: root.currentNavOnColor
                        searchText: root.globalSearchText
                        onSettingsChanged: {
                            unifiedPage.loadSettings();
                        }
                    }

                    WifiPage {
                        id: wifiPage
                        wifiDevice: root.wifiDevice
                        panelRef: root.panel
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        pageTitle: root.currentNavItem ? root.currentNavItem.name : ""
                        pageIcon: root.currentNavItem ? root.currentNavItem.icon : ""
                        pageShape: root.currentNavItem ? root.currentNavItem.shape : "Circle"
                        pageColor: root.currentNavColor
                        pageOnColor: root.currentNavOnColor
                        searchText: root.globalSearchText
                    }

                    BluetoothPage {
                        id: bluetoothPage
                        adapter: root.adapter
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        pageTitle: root.currentNavItem ? root.currentNavItem.name : ""
                        pageIcon: root.currentNavItem ? root.currentNavItem.icon : ""
                        pageShape: root.currentNavItem ? root.currentNavItem.shape : "Circle"
                        pageColor: root.currentNavColor
                        pageOnColor: root.currentNavOnColor
                        searchText: root.globalSearchText
                    }

                    AboutPage {
                        id: aboutPage
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        pageTitle: root.currentNavItem ? root.currentNavItem.name : ""
                        pageIcon: root.currentNavItem ? root.currentNavItem.icon : ""
                        pageShape: root.currentNavItem ? root.currentNavItem.shape : "Circle"
                        pageColor: root.currentNavColor
                        pageOnColor: root.currentNavOnColor
                        searchText: root.globalSearchText
                    }

                    TaskManagerPage {
                        id: taskManagerPage
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        pageTitle: root.currentNavItem ? root.currentNavItem.name : ""
                        pageIcon: root.currentNavItem ? root.currentNavItem.icon : ""
                        pageShape: root.currentNavItem ? root.currentNavItem.shape : "Circle"
                        pageColor: root.currentNavColor
                        pageOnColor: root.currentNavOnColor
                        searchText: root.globalSearchText
                    }

                    KeybindsPage {
                        id: keybindsPage
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        pageTitle: root.currentNavItem ? root.currentNavItem.name : ""
                        pageIcon: root.currentNavItem ? root.currentNavItem.icon : ""
                        pageShape: root.currentNavItem ? root.currentNavItem.shape : "Circle"
                        pageColor: root.currentNavColor
                        pageOnColor: root.currentNavOnColor
                        searchText: root.globalSearchText
                    }
                }
            }
        }
    }
}
