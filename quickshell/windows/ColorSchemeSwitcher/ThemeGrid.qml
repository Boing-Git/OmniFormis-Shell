import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../.."
import "../../theme"
import "../.."
import Quickshell
import "../../theme/variables.js" as Vars

GridView {
    id: root
    
    property string currentTheme: ""
    property var searchInput
    
    signal themeSelected(string themeName)
    signal escapePressed()

    clip: true
    cellWidth: Math.floor(parent.width / 4)
    cellHeight: cellWidth * 0.5625
    boundsBehavior: Flickable.StopAtBounds

    focus: true
    keyNavigationEnabled: true
    highlightFollowsCurrentItem: false
    onCurrentIndexChanged: positionViewAtIndex(currentIndex, GridView.Contain)
    
    highlight: Item {
        x: root.currentItem ? root.currentItem.x : 0
        y: root.currentItem ? root.currentItem.y : 0
        width: root.cellWidth
        height: root.cellHeight
        z: -1

        Behavior on x { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on y { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

        Rectangle {
            anchors.fill: parent
            anchors.margins: Vars.spacingSmall
            radius: Vars.radiusMedium
            color: root.activeFocus ? Theme.primary_container : "transparent"
            border.color: Theme.primary_container
            border.width: root.activeFocus ? 2 : 0
            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
            Behavior on border.width { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
        }
    }

    Keys.onEscapePressed: { root.escapePressed(); }
    Keys.onUpPressed: (event) => {
        if (currentIndex < 4) {
            if (searchInput) searchInput.forceActiveFocus();
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
        width: root.cellWidth
        height: root.cellHeight

        function triggerSelection() {
            root.themeSelected(themeName);
        }

        property bool isCurrentFocus: delegateItem.GridView.isCurrentItem && root.activeFocus
        
        Rectangle {
            anchors.fill: parent
            anchors.margins: Vars.spacingSmall
            radius: Vars.radiusMedium

            color: root.currentTheme === themeName ? Qt.rgba(Qt.color(themePrimary).r, Qt.color(themePrimary).g, Qt.color(themePrimary).b, 0.12) : (tileMouseArea.containsMouse ? Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08) : "transparent")
            border.color: themePrimary
            border.width: (root.currentTheme === themeName) ? 2 : 0
            clip: true

            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: Vars.spacingSmall
                spacing: Vars.spacingSmall

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: isCurrentFocus ? 4 : 0
                    clip: true
                    
                    Behavior on Layout.margins { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

                    Text {
                        anchors.centerIn: parent
                        text: "palette"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 48
                        color: isCurrentFocus ? Theme.on_primary_container : themePrimary
                        opacity: isCurrentFocus || root.currentTheme === themeName ? 1.0 : 0.6
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: themeName
                    font.family: Vars.fontFamily
                    color: isCurrentFocus ? Theme.on_primary_container : themePrimary
                    font.pixelSize: 16
                    font.weight: root.currentTheme === themeName ? Font.Bold : Font.Normal
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                    opacity: isCurrentFocus || root.currentTheme === themeName ? 1.0 : 0.6
                    
                    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                }
            }

            MouseArea {
                id: tileMouseArea
                anchors.fill: parent
                hoverEnabled: true
                preventStealing: false
                onClicked: {
                    root.currentIndex = index;
                    delegateItem.triggerSelection();
                    root.escapePressed(); // To close after selection
                }
            }
        }
    }
}
