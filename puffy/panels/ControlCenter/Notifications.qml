import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import "../../theme"
import "../.."

Item {
    id: notificationsRoot
    Layout.fillWidth: true
    implicitHeight: mainLayout.implicitHeight

    // The model only holds ids; the notification objects (with their callbacks) live in dataMap.
    // Syncing incrementally keeps existing delegates alive, so add / remove / reorder animate
    // instead of the whole list being torn down and rebuilt on every change.
    property var dataMap: ({})
    property int count: historyModel.count

    property int draggedIndex: -1
    property real draggedX: 0

    ListModel { id: historyModel }

    function syncModel() {
        var list = Vars.notificationHistory || [];
        var map = {};
        for (var i = 0; i < list.length; i++)
            map[list[i].seqId] = list[i];
        dataMap = map;

        for (var r = historyModel.count - 1; r >= 0; r--) {
            if (!map.hasOwnProperty(historyModel.get(r).seqId))
                historyModel.remove(r);
        }
        for (var t = 0; t < list.length; t++) {
            var id = list[t].seqId;
            if (t < historyModel.count && historyModel.get(t).seqId === id)
                continue;
            var found = -1;
            for (var j = t + 1; j < historyModel.count; j++) {
                if (historyModel.get(j).seqId === id) { found = j; break; }
            }
            if (found >= 0)
                historyModel.move(found, t, 1);
            else
                historyModel.insert(t, { seqId: id });
        }
    }

    Component.onCompleted: syncModel()

    Connections {
        target: Vars
        function onHistoryUpdatedChanged() { notificationsRoot.syncModel(); }
    }

    ColumnLayout {
        id: mainLayout
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 2

        // Empty State
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            Layout.topMargin: Vars.spacingSmall
            radius: Vars.radiusLarge
            antialiasing: true
            color: Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)
            opacity: notificationsRoot.count === 0 ? 1.0 : 0.0
            visible: opacity > 0
            Behavior on opacity {
                NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard }
            }

            QsText {
                text: "No new notifications"
                font.family: Vars.fontFamily; font.pixelSize: 14; color: Theme.on_surface_variant
                anchors.centerIn: parent
            }
        }

        ListView {
            id: historyView
            Layout.fillWidth: true
            Layout.preferredHeight: contentHeight
            interactive: false
            spacing: 2
            model: historyModel
            // Rows are sized by their cards; no clipping so the drop shadow and scale animations show
            clip: false
            reuseItems: false

            add: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customEmphasizedDecelerate }
                    NumberAnimation { property: "scale"; from: 0.92; to: 1; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customEmphasizedDecelerate }
                }
            }
            remove: Transition {
                ParallelAnimation {
                    NumberAnimation { property: "opacity"; to: 0; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customEmphasizedAccelerate }
                    NumberAnimation { property: "scale"; to: 0.92; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customEmphasizedAccelerate }
                }
            }
            // A card that is pushed aside while it is still fading in would keep its half-finished
            // opacity and scale (Qt aborts the add animation), so a move always finishes both.
            displaced: Transition {
                ParallelAnimation {
                    NumberAnimation { properties: "y"; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow }
                    NumberAnimation { property: "opacity"; to: 1.0; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard }
                    NumberAnimation { property: "scale"; to: 1.0; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard }
                }
            }

            delegate: Item {
                id: row
                required property int index
                required property var model

                width: ListView.view.width
                height: card.height

                // Keep the last known notification while the row plays its remove animation
                readonly property var liveData: notificationsRoot.dataMap[row.model.seqId]
                property var itemData: liveData
                onLiveDataChanged: { if (liveData !== undefined) itemData = liveData; }

                NotificationCard {
                    id: card
                    modelData: row.itemData
                    isPopup: false
                    fontName: Vars.fontFamily
                    width: parent.width

                    listIndex: row.index
                    listCount: notificationsRoot.count

                    activeDragIndex: notificationsRoot.draggedIndex
                    activeDragX: notificationsRoot.draggedX

                    onDragStarted: (idx) => { notificationsRoot.draggedIndex = idx; }
                    onDragMoved: (idx, dx) => { if (notificationsRoot.draggedIndex === idx) notificationsRoot.draggedX = dx; }
                    onDragEnded: (idx) => {
                        if (notificationsRoot.draggedIndex === idx) {
                            notificationsRoot.draggedIndex = -1;
                            notificationsRoot.draggedX = 0;
                        }
                    }
                }
            }
        }

        Item {
            Layout.preferredHeight: 80
            Layout.fillWidth: true
            visible: notificationsRoot.count > 0
        }
    }

    // Floating action bar
    Rectangle {
        id: fabContainer
        
        property color opaqueSecondary: Vars.tColor(Theme.secondary_container, Vars.componentOpacity)
        property color opaqueSurface: Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)

        
        function getFlickable(item) {
            let p = item.parent;
            while (p) {
                if (p.toString().includes("Flickable")) return p;
                p = p.parent;
            }
            return item;
        }
        
        // Reparent to Flickable so it floats above the scrolling content
        parent: getFlickable(notificationsRoot)
        
        width: notificationsRoot.width
        height: 64
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 8
        x: notificationsRoot.mapToItem(parent, 0, 0).x
        
        color: "transparent"
        opacity: notificationsRoot.count > 0 ? 1.0 : 0.0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard }
        }
        z: 100
        
        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 16
            spacing: 8
            
            // Snooze button
            Rectangle {
                property real targetWidth: snoozeHover.pressed ? 82 : (clearAllHover.pressed ? 46 : 64)
                Layout.preferredWidth: targetWidth
                Behavior on targetWidth { NumberAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }

                Layout.preferredHeight: 48
                radius: 24
                antialiasing: true
                
                color: snoozeHover.pressed ? Qt.tint(fabContainer.opaqueSecondary, Qt.rgba(Theme.on_secondary_container.r, Theme.on_secondary_container.g, Theme.on_secondary_container.b, 0.12)) : (snoozeHover.containsMouse ? Qt.tint(fabContainer.opaqueSecondary, Qt.rgba(Theme.on_secondary_container.r, Theme.on_secondary_container.g, Theme.on_secondary_container.b, 0.08)) : fabContainer.opaqueSecondary)
                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                
                QsText {
                    anchors.centerIn: parent
                    text: "\ue8b5" // schedule/snooze icon
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: Theme.on_secondary_container
                }
                MouseArea {
                    id: snoozeHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    // No-op for now, as requested
                }
            }

            // Clear all button
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: 24
                antialiasing: true
                
                color: clearAllHover.pressed ? Qt.tint(fabContainer.opaqueSurface, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.12)) : (clearAllHover.containsMouse ? Qt.tint(fabContainer.opaqueSurface, Qt.rgba(Theme.on_surface.r, Theme.on_surface.g, Theme.on_surface.b, 0.08)) : fabContainer.opaqueSurface)
                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                
                QsText {
                    anchors.centerIn: parent
                    text: "Clear all"
                    font.family: Vars.fontFamily
                    font.pixelSize: 14
                    setWeight: 600
                    color: Theme.on_surface
                }
                MouseArea {
                    id: clearAllHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Vars.clearNotifications()
                }
            }

            // Settings button
            Rectangle {
                property real targetWidth: settingsHover.pressed ? 82 : (clearAllHover.pressed ? 46 : 64)
                Layout.preferredWidth: targetWidth
                Behavior on targetWidth { NumberAnimation { duration: 150; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }

                Layout.preferredHeight: 48
                radius: 24
                antialiasing: true
                
                color: settingsHover.pressed ? Qt.tint(fabContainer.opaqueSecondary, Qt.rgba(Theme.on_secondary_container.r, Theme.on_secondary_container.g, Theme.on_secondary_container.b, 0.12)) : (settingsHover.containsMouse ? Qt.tint(fabContainer.opaqueSecondary, Qt.rgba(Theme.on_secondary_container.r, Theme.on_secondary_container.g, Theme.on_secondary_container.b, 0.08)) : fabContainer.opaqueSecondary)
                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                
                QsText {
                    anchors.centerIn: parent
                    text: "\ue8b8" // settings icon
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 20
                    color: Theme.on_secondary_container
                }
                MouseArea {
                    id: settingsHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    // Mock button for now
                }
            }
        }
    }
}
