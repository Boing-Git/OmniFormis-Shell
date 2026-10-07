import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import "../.."
import "../../theme"
import "../../core/primitives" as Primitives
import Quickshell.Io

GridView {
    id: gridView
    Layout.preferredWidth: 1052
    Layout.minimumWidth: 1052
    Layout.fillHeight: true
    clip: true
    cellWidth: Math.floor(1052 / 3)
    cellHeight: cellWidth * 0.5625 + (Vars.spacingSmall !== undefined ? Vars.spacingSmall : 8)
    maximumFlickVelocity: Vars.maximumFlickVelocity


    focus: true
    highlightFollowsCurrentItem: false
    highlight: Item {}

    property var rootRef: null
    property var pathInputRef: null
    signal wallpaperSelected(string path)
    signal requestFocusSearch

    function scrollToCurrentIndex() {
        if (currentIndex < 0) return;
        var cols = Math.floor(width / cellWidth);
        var row = Math.floor(currentIndex / cols);
        var itemY = row * cellHeight;
        var itemBottom = itemY + cellHeight;
        
        var targetY = contentY;
        if (itemY < contentY) {
            targetY = itemY;
        } else if (itemBottom > contentY + height) {
            targetY = itemBottom - height;
        }
        
        if (targetY !== contentY) {
            scrollAnim.to = targetY;
            scrollAnim.restart();
        }
    }

    NumberAnimation {
        id: scrollAnim
        target: gridView
        property: "contentY"
        duration: Vars.animationDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Vars.customExpressiveSpatialSlow
    }

    Keys.onEscapePressed: if (rootRef)
        rootRef.expanded = false
    Keys.onUpPressed: event => {
        if (currentIndex < 3) {
            requestFocusSearch();
        } else {
            moveCurrentIndexUp();
            scrollToCurrentIndex();
        }
        event.accepted = true;
    }
    Keys.onDownPressed: event => {
        moveCurrentIndexDown();
        scrollToCurrentIndex();
        event.accepted = true;
    }
    Keys.onLeftPressed: event => {
        moveCurrentIndexLeft();
        scrollToCurrentIndex();
        event.accepted = true;
    }
    Keys.onRightPressed: event => {
        moveCurrentIndexRight();
        scrollToCurrentIndex();
        event.accepted = true;
    }
    Keys.onReturnPressed: event => {
        if (currentItem)
            currentItem.triggerSelection();
        event.accepted = true;
    }
    Keys.onSpacePressed: event => {
        if (currentItem)
            currentItem.triggerSelection();
        event.accepted = true;
    }

    add: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customEmphasizedDecelerate }
            NumberAnimation { property: "scale"; from: 0.8; to: 1; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customEmphasizedDecelerate }
        }
    }
    remove: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; to: 0; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customEmphasizedAccelerate }
            NumberAnimation { property: "scale"; to: 0.8; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customEmphasizedAccelerate }
        }
    }
    displaced: Transition {
        PropertyAction { property: "z"; value: 0 }
        ParallelAnimation {
            NumberAnimation { properties: "x,y"; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow }
            SequentialAnimation {
                NumberAnimation { property: "opacity"; to: 0.2; duration: Vars.animationDuration * 0.3 }
                NumberAnimation { property: "opacity"; to: 1.0; duration: Vars.animationDuration * 0.7 }
            }
        }
    }
    removeDisplaced: Transition {
        PropertyAction { property: "z"; value: 0 }
        ParallelAnimation {
            NumberAnimation { properties: "x,y"; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow }
            SequentialAnimation {
                NumberAnimation { property: "opacity"; to: 0.2; duration: Vars.animationDuration * 0.3 }
                NumberAnimation { property: "opacity"; to: 1.0; duration: Vars.animationDuration * 0.7 }
            }
        }
    }
    move: Transition {
        PropertyAction { property: "z"; value: 100 }
        NumberAnimation { properties: "x,y"; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow }
        PropertyAction { property: "z"; value: 0 }
    }
    moveDisplaced: Transition {
        PropertyAction { property: "z"; value: 0 }
        ParallelAnimation {
            NumberAnimation { properties: "x,y"; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow }
            SequentialAnimation {
                NumberAnimation { property: "opacity"; to: 0.2; duration: Vars.animationDuration * 0.3 }
                NumberAnimation { property: "opacity"; to: 1.0; duration: Vars.animationDuration * 0.7 }
            }
        }
    }
    populate: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customEmphasizedDecelerate }
            NumberAnimation { property: "scale"; from: 0.8; to: 1; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customEmphasizedDecelerate }
        }
    }

    property bool vimKeysEnabled: false
    Process {
        id: vimKeysChecker
        command: ["bash", "-c", "grep -qi 'vimkeys[ \t]*=[ \t]*true' /home/boing/Dotfiles/hypr/modules/variables.lua && echo 'true' || echo 'false'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                gridView.vimKeysEnabled = (this.text.trim() === 'true');
            }
        }
    }

    Keys.onPressed: (event) => {
        if (vimKeysEnabled) {
            if (event.key === Qt.Key_H || event.text === "a" || event.key === Qt.Key_A) {
                moveCurrentIndexLeft();
                scrollToCurrentIndex();
                event.accepted = true;
                return;
            } else if (event.key === Qt.Key_L || event.text === "f" || event.key === Qt.Key_F) {
                moveCurrentIndexRight();
                positionViewAtIndex(currentIndex, GridView.Contain);
                event.accepted = true;
                return;
            } else if (event.key === Qt.Key_K || event.text === "d" || event.key === Qt.Key_D) {
                if (currentIndex < 3) {
                    requestFocusSearch();
                } else {
                    moveCurrentIndexUp();
                    positionViewAtIndex(currentIndex, GridView.Contain);
                }
                event.accepted = true;
                return;
            } else if (event.key === Qt.Key_J || event.text === "s" || event.key === Qt.Key_S) {
                moveCurrentIndexDown();
                positionViewAtIndex(currentIndex, GridView.Contain);
                event.accepted = true;
                return;
            }
        }
    }

    delegate: Item {
        id: delegateItem
        width: gridView.cellWidth
        height: gridView.cellHeight

        function triggerSelection() {
            gridView.wallpaperSelected(filePath);
        }

        property bool isCurrentFocus: delegateItem.GridView.isCurrentItem && gridView.activeFocus

        Rectangle {
            anchors.fill: parent
            anchors.margins: isCurrentFocus ? 0 : Vars.spacingSmall
            radius: Vars.radiusMedium
            antialiasing: true

            color: isCurrentFocus ? (Vars.tColorSelected(Theme.primary_container)) : (tileMouseArea.containsMouse ? (Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)) : (Vars.tColor(Theme.surface_container_low, Vars.componentOpacity)))

            Rectangle {
                id: tileMask
                anchors.fill: parent
                radius: parent.radius
                antialiasing: true
                color: "black"
                visible: false
                layer.enabled: true
                layer.smooth: true
                layer.samples: Vars.layerSamples
            }

            layer.enabled: true
            layer.smooth: true
            layer.samples: Vars.layerSamples
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: tileMask
            }
            Behavior on anchors.margins { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

            Behavior on color {
                ColorAnimation {
                    duration: Vars.animationDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Vars.customStandard
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 0
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: isCurrentFocus ? 4 : 0

                    Behavior on Layout.margins {
                        NumberAnimation {
                            duration: Vars.animationDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Vars.customExpressiveSpatialSlow
                        }
                    }

                    Loader {
                        id: mediaLoader
                        anchors.fill: parent
                        asynchronous: true
                        sourceComponent: filePath.toLowerCase().endsWith(".gif") ? animatedPreview : staticPreview
                    }

                    // True from the moment the tile is created until its image has actually decoded
                    readonly property bool mediaLoading: mediaLoader.status === Loader.Loading
                        || (mediaLoader.status === Loader.Ready && mediaLoader.item !== null && mediaLoader.item.status === Image.Loading)

                    Primitives.LoadingIndicator {
                        anchors.centerIn: parent
                        width: Math.max(32, Math.min(56, Math.min(parent.width, parent.height) * 0.3))
                        height: width
                        running: parent.mediaLoading
                        z: 2
                    }

                    Component {
                        id: staticPreview
                        Image {
                            anchors.fill: parent
                            source: "file://" + filePath
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                            sourceSize.width: 600
                            sourceSize.height: 600
                            opacity: status === Image.Ready ? 1.0 : 0.0
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: Vars.animationDuration
                                }
                            }
                        }
                    }

                    Component {
                        id: animatedPreview
                        AnimatedImage {
                            anchors.fill: parent
                            source: "file://" + filePath
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
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
                        antialiasing: true
                        color: Theme.primary
                        visible: filePath.toLowerCase().endsWith(".gif")
                        QsText {
                            anchors.centerIn: parent
                            text: "GIF"
                            font.family: Vars.fontFamily
                            font.bold: true
                            font.pixelSize: 10
                            color: Theme.on_primary
                        }
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                antialiasing: true
                color: "transparent"
                border.color: isCurrentFocus ? Theme.primary : (rootRef && rootRef.currentWallpaper === filePath ? Theme.primary : Theme.outline_variant)
                border.width: isCurrentFocus || (rootRef && rootRef.currentWallpaper === filePath) ? 2 : 1
                
                Behavior on border.color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                Behavior on border.width { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
            }

            Behavior on radius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

            MouseArea {
                id: tileMouseArea
                anchors.fill: parent
                hoverEnabled: true
                preventStealing: false
                cursorShape: Qt.PointingHandCursor
                onEntered: {
                    if (!gridView.moving && !gridView.dragging) {
                        gridView.currentIndex = index;
                    }
                }
                onClicked: {
                    gridView.currentIndex = index;
                    delegateItem.triggerSelection();
                    if (rootRef)
                        rootRef.expanded = false;
                }
            }
        }
    }
}
