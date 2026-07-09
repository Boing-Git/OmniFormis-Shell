import QtQuick
import QtQuick.Effects
import ".."
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtCore

import "../Variables/variables.js" as Vars

Item {
    id: root
    
    Layout.preferredWidth: 100
    Layout.preferredHeight: 40
    
    property bool expanded: false
    property bool forceHidePill: false
    property var focusWindow: null
    property bool gameMode: false
    property alias panel: panel
    property alias panelMask: panelMask

    opacity: forceHidePill ? 0.0 : 1.0
    visible: opacity > 0

    property string wallpaperDir: settings.wallpaperDir || (Quickshell.env("HOME") + "/Pictures/Wallpapers")
    property string currentWallpaper: ""

    Settings {
        id: settings
        category: "WallpaperSwitcher"
        property string matugenScheme: "scheme-tonal-spot"
        property string wallpaperDir: ""
    }

    signal closeRequested()

    HyprlandFocusGrab {
        active: root.expanded && root.focusWindow !== null
        windows: root.focusWindow ? [root.focusWindow] : []
        onCleared: root.expanded = false
    }
    
    onExpandedChanged: {
        if (!expanded) {
            searchInput.text = "";
        } else {
            searchInput.forceActiveFocus();
        }
    }

    Item {
        id: panelMask
        anchors.centerIn: panel
        width: panel.width + 40
        height: panel.height + 40
    }

    Rectangle {
        id: panel
        layer.enabled: true
        layer.effect: MultiEffect { shadowEnabled: !root.gameMode; shadowBlur: 1.0; shadowColor: Qt.rgba(0,0,0,0.25); shadowVerticalOffset: 4; shadowHorizontalOffset: 0 }
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        
        width: root.expanded ? 900 : 100
        height: root.expanded ? 550 : 40
        
        color: Theme.surface_container_low
        radius: root.gameMode ? 0 : (root.expanded ? Vars.radiusExtraLarge : height / 2)
        
        opacity: root.expanded || panel.width > 105 ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on radius { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
        Behavior on width { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }
        Behavior on height { enabled: !root.gameMode; NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialSlow } }

        Item {
            anchors.fill: parent
            anchors.margins: Vars.spacingLarge
            
            opacity: root.expanded ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity { enabled: !root.gameMode; SequentialAnimation { PauseAnimation { duration: root.expanded ? Vars.animationDuration : 0 } NumberAnimation { duration: root.expanded ? Vars.animationDuration : Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: root.expanded ? Vars.m3StandardDecelerate : Vars.m3StandardAccelerate } } }

            ColumnLayout {
                anchors.fill: parent
                spacing: Vars.spacingMedium

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Vars.spacingMedium

                    RowLayout {
                        spacing: Vars.spacingMedium



                        Text {
                            text: "wallpaper"
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 28
                            color: Theme.on_surface
                        }

                        ColumnLayout {
                            spacing: 4
                            Text {
                                text: "Wallpaper Engine"
                                font.family: Vars.fontFamily
                                font.pixelSize: 22
                                font.bold: true
                                color: Theme.on_surface
                            }
                            Text {
                                text: root.currentWallpaper ? "Active: " + root.currentWallpaper.substring(root.currentWallpaper.lastIndexOf('/') + 1) : "Select a wallpaper"
                                font.family: Vars.fontFamily
                                font.pixelSize: 12
                                color: Theme.on_surface
                                opacity: 0.8
                                elide: Text.ElideMiddle
                                Layout.maximumWidth: 320
                            }
                        }
                    }

                    Rectangle {
                        id: searchBox
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        color: searchInput.activeFocus ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Theme.surface_container_high
                        border.color: searchInput.activeFocus ? Theme.primary : Theme.outline
                        border.width: searchInput.activeFocus ? 2 : 1
                        radius: Vars.radiusMedium

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Vars.spacingMedium
                            anchors.rightMargin: Vars.spacingMedium

                            Text {
                                text: "search"
                                font.family: "Material Symbols Outlined"
                                font.pixelSize: 20
                                color: Theme.on_surface
                                opacity: 0.7
                            }

                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                font.family: Vars.fontFamily
                                font.pixelSize: 14
                                color: Theme.on_surface
                                focus: true
                                selectByMouse: true

                                Text {
                                    text: "Search wallpapers..."
                                    font.family: Vars.fontFamily
                                    font.pixelSize: 14
                                    color: Theme.on_surface
                                    opacity: 0.6
                                    visible: !searchInput.text && !searchInput.activeFocus
                                }

                                Keys.onDownPressed: (event) => {
                                    pathInput.forceActiveFocus();
                                    event.accepted = true;
                                }
                                Keys.onReturnPressed: (event) => {
                                    gridView.forceActiveFocus();
                                    event.accepted = true;
                                }
                                Keys.onEscapePressed: root.expanded = false
                            }

                            Text {
                                text: "✕"
                                font.pixelSize: 14
                                color: Theme.on_surface
                                visible: searchInput.text.length > 0
                                Layout.alignment: Qt.AlignVCenter
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: searchInput.text = ""
                                }
                            }
                        }
                    }

                    Button {
                        id: refreshBtn
                        text: "Scan"
                        onClicked: loadWallpapersProc.running = true

                        background: Rectangle {
                            color: refreshBtn.down ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (refreshBtn.hovered ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                            border.width: 0
                            radius: Vars.radiusMedium
                        }
                        contentItem: RowLayout {
                            spacing: Vars.spacingSmall
                            Text {
                                text: "refresh"
                                font.family: "Material Symbols Outlined"
                                color: (refreshBtn.down || refreshBtn.hovered) ? Theme.primary : Theme.on_surface
                                font.pixelSize: 18
                            }
                            Text {
                                text: refreshBtn.text
                                font.family: Vars.fontFamily
                                color: (refreshBtn.down || refreshBtn.hovered) ? Theme.primary : Theme.on_surface
                                font.bold: true
                                font.pixelSize: 14
                            }
                        }
                    }

                    ComboBox {
                        id: schemeCombo
                        Layout.preferredHeight: 44
                        model: [
                            "scheme-content",
                            "scheme-expressive",
                            "scheme-fidelity",
                            "scheme-fruit-salad",
                            "scheme-monochrome",
                            "scheme-neutral",
                            "scheme-rainbow",
                            "scheme-tonal-spot"
                        ]
                        currentIndex: Math.max(0, model.indexOf(settings.matugenScheme))
                        onActivated: {
                            settings.matugenScheme = currentText;
                            if (root.currentWallpaper !== "") {
                                executeWallpaperChange(root.currentWallpaper);
                            }
                        }
                        
                        background: Rectangle {
                            implicitWidth: 160
                            color: schemeCombo.pressed ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12) : (schemeCombo.hovered ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
                            border.width: 0
                            radius: Vars.radiusMedium
                        }
                        contentItem: Text {
                            text: schemeCombo.currentText
                            font.family: Vars.fontFamily
                            color: Theme.on_surface
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                        }
                        delegate: ItemDelegate {
                            width: schemeCombo.width
                            height: 36
                            contentItem: Text {
                                text: modelData
                                font.family: Vars.fontFamily
                                color: parent.highlighted ? Theme.on_primary : Theme.on_surface
                                font.pixelSize: 13
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle {
                                color: parent.highlighted ? Theme.primary : "transparent"
                                radius: Vars.radiusSmall
                            }
                        }
                        popup: Popup {
                            y: schemeCombo.height - 1
                            width: schemeCombo.width
                            implicitHeight: contentItem.implicitHeight
                            padding: 1
                            contentItem: ListView {
                                clip: true
                                implicitHeight: contentHeight
                                model: schemeCombo.popup.visible ? schemeCombo.delegateModel : null
                                currentIndex: schemeCombo.highlightedIndex
                                boundsBehavior: Flickable.StopAtBounds
                            }
                            background: Rectangle {
                                color: Theme.surface_container_high
                                border.width: 0
                                radius: Vars.radiusSmall
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Vars.spacingMedium

                    Text {
                        text: "folder"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 20
                        color: Theme.on_surface
                    }

                    Text {
                        text: "Folder:"
                        font.family: Vars.fontFamily
                        color: Theme.on_surface
                        font.bold: true
                        font.pixelSize: 14
                    }

                    Rectangle {
                        id: pathInputContainer
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        color: pathInput.activeFocus ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Theme.surface_container_high
                        border.color: pathInput.activeFocus ? Theme.primary : "transparent"
                        border.width: pathInput.activeFocus ? 2 : 0
                        radius: Vars.radiusSmall

                        TextInput {
                            id: pathInput
                            anchors.fill: parent
                            anchors.leftMargin: Vars.spacingSmall
                            anchors.rightMargin: Vars.spacingSmall
                            font.family: Vars.fontFamily
                            font.pixelSize: 14
                            color: Theme.on_surface
                            verticalAlignment: Text.AlignVCenter
                            text: root.wallpaperDir
                            selectByMouse: true
                            onAccepted: {
                                settings.wallpaperDir = text;
                                root.wallpaperDir = text;
                                loadWallpapersProc.running = true;
                                autocompleteModel.clear();
                            }
                            onTextChanged: {
                                if (activeFocus && text.length > 0) {
                                    var p = text.replace(/^~/, Quickshell.env("HOME"));
                                    autocompleteProc.command = ["bash", "-c", "compgen -d " + p];
                                    autocompleteProc.running = true;
                                } else {
                                    autocompleteModel.clear();
                                }
                            }
                            Keys.onTabPressed: (event) => {
                                if (autocompleteModel.count > 0) {
                                    var completion = autocompleteModel.get(0).path;
                                    if (text.startsWith("~")) {
                                        completion = completion.replace(Quickshell.env("HOME"), "~");
                                    }
                                    text = completion + "/";
                                    cursorPosition = text.length;
                                    autocompleteModel.clear();
                                    event.accepted = true;
                                }
                            }
                            Keys.onDownPressed: (event) => {
                                if (autocompleteModel.count > 0) {
                                    autocompleteListView.forceActiveFocus();
                                    autocompleteListView.currentIndex = 0;
                                    event.accepted = true;
                                } else {
                                    gridView.forceActiveFocus();
                                    event.accepted = true;
                                }
                            }
                            Keys.onUpPressed: (event) => {
                                searchInput.forceActiveFocus();
                                event.accepted = true;
                            }
                            Keys.onEscapePressed: {
                                root.expanded = false;
                            }
                        }

                        Popup {
                            id: autocompletePopup
                            visible: (pathInput.activeFocus || autocompleteListView.activeFocus) && autocompleteModel.count > 0
                            y: pathInputContainer.height + 4
                            width: pathInputContainer.width
                            padding: 4
                            closePolicy: Popup.NoAutoClose
                            
                            background: Rectangle {
                                color: Theme.primary_container
                                border.color: Theme.on_surface
                                border.width: 1
                                radius: Vars.radiusSmall
                            }

                            contentItem: ListView {
                                id: autocompleteListView
                                clip: true
                                implicitHeight: Math.min(contentHeight, 150)
                                model: autocompleteModel
                                boundsBehavior: Flickable.StopAtBounds
                                
                                focus: true
                                keyNavigationEnabled: true
                                highlightFollowsCurrentItem: false
                                onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)
                                
                                highlight: Item {
                                    x: autocompleteListView.currentItem ? autocompleteListView.currentItem.x : 0
                                    y: autocompleteListView.currentItem ? autocompleteListView.currentItem.y : 0
                                    width: autocompleteListView.width
                                    height: 28
                                    z: -1
                                    
                                    Behavior on y { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: Vars.radiusSmall
                                        color: autocompleteListView.activeFocus ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.15) : "transparent"
                                        Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }
                                    }
                                }
                                
                                Keys.onEscapePressed: (event) => {
                                    pathInput.forceActiveFocus();
                                    event.accepted = true;
                                }
                                Keys.onUpPressed: (event) => {
                                    if (currentIndex === 0) {
                                        pathInput.forceActiveFocus();
                                        event.accepted = true;
                                    } else {
                                        decrementCurrentIndex();
                                        event.accepted = true;
                                    }
                                }
                                Keys.onDownPressed: (event) => {
                                    incrementCurrentIndex();
                                    event.accepted = true;
                                }
                                Keys.onReturnPressed: (event) => {
                                    if (currentItem) currentItem.triggerSelection();
                                    event.accepted = true;
                                }
                                
                                delegate: ItemDelegate {
                                    id: autoDelegate
                                    width: ListView.view.width
                                    height: 28
                                    
                                    property bool isCurrent: autoDelegate.ListView.isCurrentItem && autocompleteListView.activeFocus
                                    
                                    function triggerSelection() {
                                        var completion = model.path;
                                        if (pathInput.text.startsWith("~")) {
                                            completion = completion.replace(Quickshell.env("HOME"), "~");
                                        }
                                        pathInput.text = completion + "/";
                                        pathInput.forceActiveFocus();
                                        pathInput.cursorPosition = pathInput.text.length;
                                        autocompleteModel.clear();
                                    }
                                    
                                    contentItem: Item {
                                        Text {
                                            anchors.fill: parent
                                            anchors.leftMargin: isCurrent ? 8 : 4
                                            verticalAlignment: Text.AlignVCenter
                                            text: model.path.replace(Quickshell.env("HOME"), "~")
                                            font.family: Vars.fontFamily
                                            color: isCurrent ? Theme.primary : Theme.on_surface
                                            font.pixelSize: 12
                                            
                                            Behavior on anchors.leftMargin { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }
                                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }
                                        }
                                    }
                                    background: Rectangle {
                                        color: parent.hovered ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.1) : "transparent"
                                        radius: Vars.radiusSmall
                                    }
                                    onClicked: triggerSelection()
                                }
                            }
                        }
                    }
                }

                GridView {
                    id: gridView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    cellWidth: Math.floor(parent.width / 4)
                    cellHeight: cellWidth * 0.5625 + 48
                    model: sortFilterProxyModel.proxyModel
                    boundsBehavior: Flickable.StopAtBounds

                    focus: true
                    keyNavigationEnabled: true
                    highlightFollowsCurrentItem: false
                    onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)
                    
                    // highlight removed to prevent sliding bleed; handled entirely by delegate constraints

                    Keys.onEscapePressed: root.expanded = false
                    Keys.onUpPressed: (event) => {
                        if (currentIndex < 4) {
                            pathInput.forceActiveFocus();
                        } else {
                            moveCurrentIndexUp();
                        }
                        event.accepted = true;
                    }
                    Keys.onDownPressed: (event) => {
                        moveCurrentIndexDown();
                        event.accepted = true;
                    }
                    Keys.onLeftPressed: (event) => {
                        moveCurrentIndexLeft();
                        event.accepted = true;
                    }
                    Keys.onRightPressed: (event) => {
                        moveCurrentIndexRight();
                        event.accepted = true;
                    }
                    Keys.onReturnPressed: (event) => {
                        if (currentItem) currentItem.triggerSelection();
                        event.accepted = true;
                    }

                    delegate: Item {
                        id: delegateItem
                        width: gridView.cellWidth
                        height: gridView.cellHeight

                        function triggerSelection() {
                            executeWallpaperChange(filePath);
                        }

                        property bool isCurrentFocus: delegateItem.GridView.isCurrentItem && gridView.activeFocus
                        
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: Vars.spacingSmall
                            radius: Vars.radiusMedium

                            color: isCurrentFocus ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Theme.surface_container_low
                            border.color: isCurrentFocus ? Theme.primary : (root.currentWallpaper === filePath ? Theme.primary : Theme.outline_variant)
                            border.width: isCurrentFocus || (root.currentWallpaper === filePath) ? 2 : 1
                            clip: true

                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3Standard } }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 0
                                spacing: 0

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    Layout.margins: isCurrentFocus ? 4 : 0
                                    
                                    Behavior on Layout.margins { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }

                                    Loader {
                                        id: mediaLoader
                                        anchors.fill: parent
                                        asynchronous: true
                                        sourceComponent: filePath.toLowerCase().endsWith(".gif") ? animatedPreview : staticPreview
                                    }

                                    Component {
                                        id: staticPreview
                                        Image {
                                            anchors.fill: parent
                                            source: "file://" + filePath
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                            sourceSize.width: 400
                                            sourceSize.height: 400
                                            opacity: status === Image.Ready ? 1.0 : 0.0
                                            Behavior on opacity { NumberAnimation { duration: Vars.animationDuration } }
                                        }
                                    }

                                    Component {
                                        id: animatedPreview
                                        AnimatedImage {
                                            anchors.fill: parent
                                            source: "file://" + filePath
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                            playing: tileMouseArea.containsMouse || delegateItem.isCurrentFocus
                                            paused: !tileMouseArea.containsMouse && !delegateItem.isCurrentFocus
                                        }
                                    }

                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: 6
                                        width: 32
                                        height: 18
                                        radius: Math.floor(Vars.radiusSmall / 2)
                                        color: Theme.primary
                                        visible: filePath.toLowerCase().endsWith(".gif")
                                        Text {
                                            anchors.centerIn: parent
                                            text: "GIF"
                                            font.family: Vars.fontFamily
                                            font.bold: true
                                            font.pixelSize: 10
                                            color: Theme.on_primary
                                        }
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 52
                                    
                                    Text {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        text: fileName.replace(/^a_/, '').replace(/_/g, ' ').replace(/\b\w/g, c => c.toUpperCase())
                                        font.family: Vars.fontFamily
                                        color: isCurrentFocus ? Theme.primary : Theme.on_surface
                                        font.pixelSize: 14
                                        font.weight: root.currentWallpaper === filePath ? Font.Bold : Font.Normal
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        lineHeight: 1.1
                                        
                                        Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3ExpressiveSpatialFast } }
                                    }
                                }
                            }

                            MouseArea {
                                id: tileMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                preventStealing: false
                                onClicked: {
                                    gridView.currentIndex = index;
                                    delegateItem.triggerSelection();
                                    root.expanded = false;
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function executeWallpaperChange(filePath) {
        console.log("[USER ACTION] Wallpaper selected: " + filePath);
        root.currentWallpaper = filePath;

        matugenProc.command = ["matugen", "image", filePath, "-m", "light", "-t", settings.matugenScheme, "--source-color-index", "0"];
        matugenProc.running = true;
    }

    Process {
        id: matugenProc
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    console.log("[MATUGEN STDOUT]\n" + this.text);
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (this.text.trim().length > 0)
                    console.error("[MATUGEN STDERR]\n" + this.text);
            }
        }
        onExited: (code, status) => {
            Quickshell.execDetached({ command: ['bash', '-c', '.config/quickshell/sync_colors.py'] });
            Quickshell.execDetached({ command: ['bash', '-c', 'qs kill; sleep 0.1; qs'] });
        }
    }

    ListModel { id: wallpaperModel }

    QtObject {
        id: sortFilterProxyModel
        property string filterText: searchInput.text
        onFilterTextChanged: updateVisualGrid()
        function updateVisualGrid() {
            proxyModel.clear();
            for (var i = 0; i < wallpaperModel.count; i++) {
                var item = wallpaperModel.get(i);
                if (Vars.fuzzyMatch(filterText, item.fileName)) {
                    proxyModel.append({ "filePath": item.filePath, "fileName": item.fileName });
                }
            }
        }
        property ListModel proxyModel: ListModel {}
    }

    Process {
        id: loadWallpapersProc
        command: ["find", root.wallpaperDir.replace(/^~/, Quickshell.env("HOME")), "-maxdepth", "2", "-type", "f", "-regextype", "posix-extended", "-regex", ".*\\.(jpg|jpeg|png|gif)$"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                wallpaperModel.clear();
                var lines = this.text.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var path = lines[i].trim();
                    if (path.length > 0) {
                        var name = path.substring(path.lastIndexOf('/') + 1);
                        wallpaperModel.append({ "filePath": path, "fileName": name });
                    }
                }
                sortFilterProxyModel.updateVisualGrid();
            }
        }
    }

    ListModel { id: autocompleteModel }

    Process {
        id: autocompleteProc
        stdout: StdioCollector {
            onStreamFinished: {
                autocompleteModel.clear();
                var lines = this.text.split("\n");
                for (var i = 0; i < lines.length; i++) {
                    var path = lines[i].trim();
                    if (path.length > 0) {
                        autocompleteModel.append({ "path": path });
                    }
                }
            }
        }
    }
}
