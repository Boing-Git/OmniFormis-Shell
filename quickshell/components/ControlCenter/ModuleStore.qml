import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../Variables/variables.js" as Vars
import "../.."
import QtCore
import QtQml.Models

ColumnLayout {
    id: moduleStashContainer
    Layout.fillWidth: true
    Layout.topMargin: 16
    visible: isEditorMode
    spacing: 12

    property bool isEditorMode: false
    property var moduleGridRoot: null
    property var availableTiles: null
    property real baseCellWidth: 80

    Text {
        text: "Available Modules"
        font.family: Vars.fontFamily
        font.pixelSize: 14
        font.weight: Font.DemiBold
        color: Theme.on_surface_variant
    }

    DelegateModel {
        id: availableVisualModel
        model: availableTiles
        delegate: DropArea {
            id: availableDropArea
            width: GridView.view ? GridView.view.cellWidth : 80
            height: GridView.view ? GridView.view.cellHeight : 80
            keys: ["m3_module"]
            
            z: availDragArea.drag.active ? 100 : 1
            
            property int visualIndex: DelegateModel.itemsIndex
            property string dragMode: "available_module"
            property string moduleId: model.moduleId
            property var gridRoot: moduleStashContainer.moduleGridRoot

            onDropped: function(drop) {
                if (drop.source && drop.source.dragMode === "active_module") {
                    availableDropArea.gridRoot.deactivateModule(drop.source.moduleId);
                    drop.accept();
                }
            }

            onPositionChanged: function(drag) {
                if (!availableDropArea.gridRoot.isEditorMode) return;
                if (!drag.source) return;
                if (drag.source.dragMode !== "available_module") return;
                
                let from = drag.source.visualIndex;
                let hoverIndex = availableDropArea.visualIndex;
                
                if (from !== undefined && hoverIndex !== undefined && from !== hoverIndex && drag.source !== availableDropArea) {
                    let targetIndex = hoverIndex;
                    if (from < hoverIndex) targetIndex = hoverIndex - 1;
                    targetIndex = Math.max(0, targetIndex);
                    
                    if (from !== targetIndex) {
                        availableVisualModel.items.move(from, targetIndex);
                        drag.source.visualIndex = targetIndex;
                    }
                }
            }
            
            Rectangle {
                id: availDelegate
                x: (parent.width - width) / 2
                y: (parent.height - height) / 2
                width: moduleStashContainer.baseCellWidth
                height: 64
                radius: 16
                
                color: availDragArea.drag.active ? Theme.surface_container_highest : Theme.surface_container_high
                scale: availDragArea.drag.active ? 1.05 : 1.0
                
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                Behavior on color { ColorAnimation { duration: 150 } }
                
                border.color: availableDropArea.gridRoot.isEditorMode ? Theme.outline_variant : "transparent"
                border.width: 1
                Behavior on border.color { ColorAnimation { duration: 250 } }

                property string mIcon: moduleId === "wifi" ? availableDropArea.gridRoot.wifiIcon : moduleId === "bluetooth" ? availableDropArea.gridRoot.bluetoothIcon : moduleId === "audio" ? "\ue050" : moduleId === "display" ? "\ue30d" : moduleId === "peace" ? "\ue15c" : moduleId === "color" ? "palette" : moduleId === "wallpaper" ? "wallpaper" : moduleId === "overview" ? "grid_view" : ""
                
                Text {
                    anchors.centerIn: parent
                    width: 32
                    height: 32
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 24
                    color: Theme.on_surface_variant
                    text: availDelegate.mIcon
                }

                Rectangle {
                    anchors.fill: parent; radius: 16
                    color: availDragArea.drag.active ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.0) : (availDragArea.containsMouse ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : Qt.rgba(0, 0, 0, 0.1))
                    Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.m3EmphasizedDecelerate } }
                }

                Text {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.margins: 12
                    font.family: "Material Symbols Outlined"; font.pixelSize: 20
                    color: Theme.on_surface_variant
                    text: "drag_indicator"
                }

                MouseArea {
                    id: availDragArea
                    anchors.fill: parent
                    cursorShape: Qt.OpenHandCursor
                    drag.target: availDelegate

                    onPressed: { cursorShape = Qt.ClosedHandCursor; }
                    onReleased: {
                        cursorShape = Qt.OpenHandCursor;
                        availDelegate.Drag.drop();
                        availDelegate.x = Qt.binding(function() { return (availableDropArea.width - availDelegate.width) / 2 });
                        availDelegate.y = Qt.binding(function() { return (availableDropArea.height - availDelegate.height) / 2 });
                        availableDropArea.gridRoot.saveLayout();
                    }
                }
                
                Drag.active: availDragArea.drag.active
                Drag.source: availableDropArea
                Drag.keys: ["m3_module"]
            }
        }
    }

    DropArea {
        id: stashDropArea
        Layout.fillWidth: true
        Layout.preferredHeight: Math.max(96, Math.ceil((availableTiles ? availableTiles.count : 0) / 4) * (64 + 12) + 16)
        keys: ["m3_module"]

        onDropped: function(drop) {
            if (drop.source && drop.source.moduleId) {
                moduleStashContainer.moduleGridRoot.deactivateModule(drop.source.moduleId);
                drop.accept();
            }
            moduleStashContainer.moduleGridRoot.saveLayout();
        }

        Rectangle {
            anchors.fill: parent
            color: stashDropArea.containsDrag ? Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.08) : Theme.surface
            border.color: Theme.outline_variant
            border.width: 1
            radius: 16
            
            Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.OutCubic } }

            GridView {
                id: availableFlow
                anchors.fill: parent
                anchors.margins: 8
                
                cellWidth: moduleStashContainer.baseCellWidth + 12
                cellHeight: 64 + 12
                
                boundsBehavior: Flickable.StopAtBounds
                clip: !moduleStashContainer.isEditorMode

                move: Transition {
                    NumberAnimation { properties: "x,y"; duration: 250; easing.type: Easing.OutCubic }
                }
                
                model: availableVisualModel
            }
        }
    }
}
