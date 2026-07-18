import QtQuick
import QtQuick.Layouts
import Quickshell
import "../.."
import "../../Variables"
import ".."
import "../../Variables/variables.js" as Vars

ListView {
    id: root
    
    Layout.fillWidth: true
    Layout.fillHeight: true
    
    property var launcherModel
    property alias searchText: searchInputTextObj.text
    
    QtObject {
        id: searchInputTextObj
        property string text: ""
    }

    signal appLaunched()
    signal escapePressed()
    signal focusSearchBar()

    clip: true
    spacing: 4
    
    orientation: ListView.Vertical
    boundsBehavior: Flickable.StopAtBounds
    flickDeceleration: 1500
    maximumFlickVelocity: 3000


    focus: true
    // keyNavigationEnabled: true - removed to stop auto-scroll on hover
    highlightFollowsCurrentItem: false
    // Removed onCurrentIndexChanged: positionViewAtIndex(...) to avoid fighting mouse flicking
    
    // removed highlightRangeMode properties to prevent auto-snapping on mouse hover
    Keys.onReturnPressed: (event) => { if (currentItem) currentItem.triggerSelection(); event.accepted = true; }
    Keys.onSpacePressed: (event) => { if (currentItem) currentItem.triggerSelection(); event.accepted = true; }
    Keys.onEscapePressed: (event) => { root.escapePressed(); event.accepted = true; }
    
    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete) {
            if (currentItem && currentItem.deleteClipboardItem) {
                currentItem.deleteClipboardItem();
                event.accepted = true;
            }
        }
    }
    
    Keys.onUpPressed: (event) => {
        if (currentIndex <= 0) {
            root.focusSearchBar();
        } else {
            decrementCurrentIndex();
            positionViewAtIndex(currentIndex, ListView.Contain);
        }
        event.accepted = true;
    }
    Keys.onDownPressed: (event) => {
        if (currentIndex === -1 && count > 0) {
            currentIndex = 0;
            positionViewAtIndex(currentIndex, ListView.Contain);
        } else {
            incrementCurrentIndex();
            positionViewAtIndex(currentIndex, ListView.Contain);
        }
        event.accepted = true;
    }
    
    onModelChanged: {
        if (count > 0 && currentIndex === -1) {
            currentIndex = 0;
        }
    }

    delegate: Item {
        id: delegateItem
        width: root.width
        height: 48

        function triggerSelection() {
            if (modelData.command[0] === "INTERNAL:CLIPBOARD") {
                root.searchText = "/clipboard ";
                return;
            }
            if (modelData.command[0] === "INTERNAL:EMOJI") {
                root.searchText = "/emoji ";
                return;
            }
            if (modelData.command[0] === "INTERNAL:CLEAR_CLIPBOARD") {
                if (root.launcherModel) {
                    root.launcherModel.clearClipboard();
                    var oldText = root.searchText;
                    root.searchText = "";
                    root.searchText = oldText;
                }
                return;
            }
            
            Quickshell.execDetached({
                command: modelData.command,
                workingDirectory: modelData.workingDirectory
            });
            root.appLaunched();
            root.escapePressed();
        }

        property bool isCurrent: delegateItem.ListView.isCurrentItem && root.activeFocus
        
        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            color: isCurrent ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12) : "transparent"
            radius: Vars.radiusMedium
            border.color: Theme.primary
            border.width: isCurrent ? 2 : 0

            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
        }

        function deleteClipboardItem() {
            if (modelData.isClipboard && root.launcherModel) {
                root.launcherModel.deleteClipboardItem(modelData.clipId, modelData.fullLine);
                var oldText = root.searchText;
                root.searchText = "";
                root.searchText = oldText;
            }
        }

        MouseArea {
            id: itemMouseArea
            anchors.fill: parent
            hoverEnabled: true
            preventStealing: false
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            onEntered: {
                if (!root.moving && !root.dragging) {
                    root.currentIndex = index;
                }
            }

            onClicked: (mouse) => {
                root.currentIndex = index;
                if (mouse.button === Qt.RightButton && modelData.isClipboard) {
                    delegateItem.deleteClipboardItem();
                } else {
                    delegateItem.triggerSelection();
                }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16 + (isCurrent ? 8 : 0)
            anchors.rightMargin: 16
            spacing: 16

            Behavior on anchors.leftMargin { 
                NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } 
            }

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                color: "transparent"
                radius: Vars.radiusSmall
                clip: true

                Image {
                    anchors.fill: parent
                    source: (modelData.clipImagePath !== undefined && modelData.clipImagePath !== "") ? "file://" + modelData.clipImagePath : (modelData.icon ? "image://icon/" + modelData.icon : "image://icon/application-x-executable")
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: false
                    visible: (modelData.isFile !== true && modelData.isMath !== true && modelData.isSetting !== true && modelData.isClipboard !== true && modelData.isClearAll !== true) || (modelData.isClipboard === true && modelData.clipImagePath !== undefined && modelData.clipImagePath !== "")
                    
                    opacity: isCurrent ? 1.0 : (itemMouseArea.containsMouse ? 0.9 : 0.7)
                    Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                }

                Text {
                    anchors.centerIn: parent
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 24
                    text: modelData.isMath ? "calculate" : 
                          (modelData.isClipboard ? "content_copy" : 
                          (modelData.isSetting ? modelData.iconName : 
                          (modelData.isClearAll ? "delete" :
                          (modelData.isFile ? (modelData.isDir ? "folder" : "description") : ""))))
                    color: modelData.isClearAll ? Theme.error : (isCurrent ? Theme.primary : Theme.on_surface)
                    visible: (modelData.isFile === true || modelData.isMath === true || modelData.isSetting === true || modelData.isClipboard === true || modelData.isClearAll === true) && !(modelData.isClipboard && modelData.clipImagePath !== undefined && modelData.clipImagePath !== "")
                    
                    opacity: isCurrent ? 1.0 : (itemMouseArea.containsMouse ? 0.9 : 0.7)
                    Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                }
            }

            Text {
                Layout.fillWidth: true
                font.family: Vars.fontFamily
                font.pixelSize: 14
                font.weight: isCurrent ? Font.DemiBold : Font.Medium
                text: modelData.name
                
                color: modelData.isClearAll ? Theme.error : (isCurrent ? Theme.primary : Theme.on_surface)
                opacity: isCurrent ? 1.0 : (itemMouseArea.containsMouse ? 0.8 : 0.6)
                
                maximumLineCount: 1
                elide: Text.ElideRight
                
                Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
            }
        }
    }
}
