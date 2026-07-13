import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import "../.."
import "../../Variables/variables.js" as Vars

GridView {
    id: gridView
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true
    cellWidth: Math.floor(parent.width / 4)
    cellHeight: cellWidth * 0.5625 + 48
    boundsBehavior: Flickable.StopAtBounds

    focus: true
    keyNavigationEnabled: true
    highlightFollowsCurrentItem: false
    onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)

    property var rootRef: null
    property var pathInputRef: null
    signal wallpaperSelected(string path)
    signal requestFocusSearch()

    Keys.onEscapePressed: if (rootRef) rootRef.expanded = false
    Keys.onUpPressed: (event) => {
        if (currentIndex < 4) {
            requestFocusSearch();
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
            gridView.wallpaperSelected(filePath);
        }

        property bool isCurrentFocus: delegateItem.GridView.isCurrentItem && gridView.activeFocus
        
        Rectangle {
            anchors.fill: parent
            anchors.margins: Vars.spacingSmall
            radius: Vars.radiusMedium

            color: isCurrentFocus ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : Theme.surface_container_low
            border.color: isCurrentFocus ? Theme.primary : (rootRef && rootRef.currentWallpaper === filePath ? Theme.primary : Theme.outline_variant)
            border.width: isCurrentFocus || (rootRef && rootRef.currentWallpaper === filePath) ? 2 : 1
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
                        font.weight: rootRef && rootRef.currentWallpaper === filePath ? Font.Bold : Font.Normal
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
                    if (rootRef) rootRef.expanded = false;
                }
            }
        }
    }
}
