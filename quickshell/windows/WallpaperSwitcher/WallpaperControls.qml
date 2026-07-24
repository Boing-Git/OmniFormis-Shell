import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import "../.."
import "../../theme/variables.js" as Vars
import QtCore

ColumnLayout {
    id: controlsRoot
    spacing: Vars.spacingMedium
    Layout.fillWidth: true

    property var rootRef: null
    property var settingsRef: null
    property var loadWallpapersProcRef: null
    property var gridViewRef: null
    property var autocompleteProcRef: null
    property var autocompleteModelRef: null
    property alias filterText: searchInput.text

    function focusSearch() { searchInput.forceActiveFocus(); }
    function clearSearch() { searchInput.text = ""; }

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
                    text: rootRef && rootRef.currentWallpaper ? "Active: " + rootRef.currentWallpaper.substring(rootRef.currentWallpaper.lastIndexOf('/') + 1) : "Select a wallpaper"
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
                    objectName: "searchInput"
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
                        if (gridViewRef) gridViewRef.forceActiveFocus();
                        event.accepted = true;
                    }
                    Keys.onEscapePressed: if (rootRef) rootRef.expanded = false
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
            onClicked: if (loadWallpapersProcRef) loadWallpapersProcRef.running = true

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
            currentIndex: settingsRef ? Math.max(0, model.indexOf(settingsRef.matugenScheme)) : 0
            onActivated: {
                if (settingsRef) settingsRef.matugenScheme = currentText;
                if (rootRef && rootRef.currentWallpaper !== "") {
                    rootRef.executeWallpaperChange(rootRef.currentWallpaper);
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
                    // boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: Vars.flickDeceleration
                    maximumFlickVelocity: Vars.maximumFlickVelocity
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
                objectName: "pathInput"
                anchors.fill: parent
                anchors.leftMargin: Vars.spacingSmall
                anchors.rightMargin: Vars.spacingSmall
                font.family: Vars.fontFamily
                font.pixelSize: 14
                color: Theme.on_surface
                verticalAlignment: Text.AlignVCenter
                text: rootRef ? rootRef.wallpaperDir : ""
                selectByMouse: true
                onAccepted: {
                    if (settingsRef) settingsRef.wallpaperDir = text;
                    if (rootRef) rootRef.wallpaperDir = text;
                    if (loadWallpapersProcRef) loadWallpapersProcRef.running = true;
                    if (autocompleteModelRef) autocompleteModelRef.clear();
                }
                onTextChanged: {
                    if (activeFocus && text.length > 0) {
                        var p = text.replace(/^~/, Quickshell.env("HOME"));
                        if (autocompleteProcRef) {
                            autocompleteProcRef.command = ["bash", "-c", "compgen -d " + p];
                            autocompleteProcRef.running = true;
                        }
                    } else {
                        if (autocompleteModelRef) autocompleteModelRef.clear();
                    }
                }
                Keys.onTabPressed: (event) => {
                    if (autocompleteModelRef && autocompleteModelRef.count > 0) {
                        var completion = autocompleteModelRef.get(0).path;
                        if (text.startsWith("~")) {
                            completion = completion.replace(Quickshell.env("HOME"), "~");
                        }
                        text = completion + "/";
                        cursorPosition = text.length;
                        autocompleteModelRef.clear();
                        event.accepted = true;
                    }
                }
                Keys.onDownPressed: (event) => {
                    if (autocompleteModelRef && autocompleteModelRef.count > 0) {
                        autocompleteListView.forceActiveFocus();
                        autocompleteListView.currentIndex = 0;
                        event.accepted = true;
                    } else {
                        if (gridViewRef) gridViewRef.forceActiveFocus();
                        event.accepted = true;
                    }
                }
                Keys.onUpPressed: (event) => {
                    searchInput.forceActiveFocus();
                    event.accepted = true;
                }
                Keys.onEscapePressed: {
                    if (rootRef) rootRef.expanded = false;
                }
            }

            Popup {
                id: autocompletePopup
                visible: (pathInput.activeFocus || autocompleteListView.activeFocus) && autocompleteModelRef && autocompleteModelRef.count > 0
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
                    model: autocompleteModelRef
                    // boundsBehavior: Flickable.StopAtBounds
                    flickDeceleration: Vars.flickDeceleration
                    maximumFlickVelocity: Vars.maximumFlickVelocity
                    
                    focus: true
                    // keyNavigationEnabled: true - removed to stop auto-scroll on hover
                    highlightFollowsCurrentItem: false
                    // Removed onCurrentIndexChanged to prevent mouse hover fighting
                    
                    highlight: Item {
                        x: autocompleteListView.currentItem ? autocompleteListView.currentItem.x : 0
                        y: autocompleteListView.currentItem ? autocompleteListView.currentItem.y : 0
                        width: autocompleteListView.width
                        height: 28
                        z: -1
                        
                        Behavior on y { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

                        Rectangle {
                            anchors.fill: parent
                            radius: Vars.radiusSmall
                            color: autocompleteListView.activeFocus ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.15) : "transparent"
                            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
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
                            positionViewAtIndex(currentIndex, ListView.Contain);
                            event.accepted = true;
                        }
                    }
                    Keys.onDownPressed: (event) => {
                        incrementCurrentIndex();
                        positionViewAtIndex(currentIndex, ListView.Contain);
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
                            if (autocompleteModelRef) autocompleteModelRef.clear();
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
                                
                                Behavior on anchors.leftMargin { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
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
}
