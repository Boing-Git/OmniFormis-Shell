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

    // Divided into fixed-size "zones" — one screenful of rows each — instead of gating the whole
    // grid as a single unit. Each zone tracks its own pending-tile count independently, shows one
    // big shared indicator over itself while any of its own tiles are still decoding, and reveals
    // only once that whole zone is ready. Scrolling into a new, not-yet-loaded zone therefore
    // shows a loading state for just that zone, instead of tiles popping in individually or the
    // whole grid waiting on far-off, not-yet-visible content.
    //
    // `_zonePending` is a plain JS object (zoneKey -> pending count), which QML bindings can't
    // observe mutating on their own — `_zoneEpoch` is a dummy counter bumped on every mutation and
    // read (but not otherwise used) inside isZoneReady(), purely so any binding that calls it
    // re-evaluates whenever a zone's count actually changes.
    //
    // Fixed at 3 columns x 3 rows rather than derived from `width / cellWidth`: this view's width
    // is already hardcoded elsewhere in this file (cellWidth itself is `1052 / 3`, not reactive to
    // `width`), and a reactive itemsPerZone would let a delegate's zoneIndex shift to a different
    // zone sometime after it already registered its pending count under the old one — leaving a
    // zone's counter stuck above 0 forever, spinning its indicator and never revealing its tiles.
    readonly property int itemsPerZone: 9
    property var _zonePending: ({})
    property int _zoneEpoch: 0
    // The lowest-indexed zone that still has anything pending, or -1 once nothing does. Used to
    // stop the user from scrolling past a zone that hasn't finished loading yet — see the
    // Connections block below.
    property int firstPendingZoneIndex: -1

    function _zoneKey(zoneIndex) { return "z" + zoneIndex; }
    function _recomputeFirstPendingZone() {
        var minZ = -1;
        for (var k in _zonePending) {
            if (_zonePending[k] > 0) {
                var zi = parseInt(k.substring(1), 10);
                if (minZ === -1 || zi < minZ) minZ = zi;
            }
        }
        firstPendingZoneIndex = minZ;
    }
    function _registerZonePending(zoneIndex) {
        var k = _zoneKey(zoneIndex);
        _zonePending[k] = (_zonePending[k] || 0) + 1;
        _zoneEpoch++;
        _recomputeFirstPendingZone();
    }
    function _markZoneItemDone(zoneIndex) {
        var k = _zoneKey(zoneIndex);
        if (_zonePending[k] > 0) _zonePending[k]--;
        _zoneEpoch++;
        _recomputeFirstPendingZone();
    }
    function isZoneReady(zoneIndex) {
        void _zoneEpoch;
        return (_zonePending[_zoneKey(zoneIndex)] || 0) === 0;
    }

    // Hard scroll boundary at the bottom edge of the first still-loading zone: the user can
    // scroll far enough to see that zone (and its indicator) but not past it into zones that
    // haven't even started loading yet. A Connections block rather than this file's own
    // onContentYChanged, so it layers on top of whatever onContentYChanged a consumer attaches at
    // the instantiation site (WallpaperSwitcher.qml already uses one, for the sticky search bar)
    // instead of silently replacing it — QML signal handlers at an instance site override a
    // type's own internal one of the same name rather than chaining with it.
    Connections {
        target: gridView
        function onContentYChanged() {
            if (gridView.firstPendingZoneIndex < 0) return;
            var maxY = Math.max(0, (gridView.firstPendingZoneIndex * 3 + 3) * gridView.cellHeight - gridView.height);
            if (gridView.contentY > maxY) {
                gridView.contentY = maxY;
            }
        }
    }

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

        // Which zone this tile belongs to, and whether it's the zone's designated indicator
        // anchor — the tile nearest the zone's geometric center, so the one big indicator per
        // zone lands roughly in the middle of its block instead of off to one side.
        property int zoneIndex: Math.floor(index / gridView.itemsPerZone)
        property int zoneStart: zoneIndex * gridView.itemsPerZone
        property int zoneItemCount: Math.min(gridView.itemsPerZone, gridView.count - zoneStart)
        property int indexInZone: index - zoneStart
        property bool isZoneIndicatorAnchor: indexInZone === Math.floor(zoneItemCount / 2)

        Rectangle {
            anchors.fill: parent
            anchors.margins: isCurrentFocus ? 0 : Vars.spacingSmall
            radius: Vars.radiusMedium
            antialiasing: true

            // Kept separate from delegateItem's own opacity (which GridView's add/remove
            // transitions already animate) so the two don't fight over the same property —
            // this one just masks the tile until its zone has finished decoding.
            opacity: gridView.isZoneReady(zoneIndex) ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    duration: Vars.animationDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Vars.customEmphasizedDecelerate
                }
            }

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

                    // Reports into its zone's shared pending count instead of showing its own
                    // spinner — see the zone-based reveal comment on gridView.itemsPerZone. The
                    // zone is captured at registration time rather than read live off
                    // delegateItem.zoneIndex, so that if GridView ever recycles this delegate for
                    // a different row (and thus a different zone) before it resolves, the eventual
                    // decrement still lands on the same zone it incremented — never on whatever
                    // zone the delegate happens to belong to by then.
                    property bool _countedPending: false
                    property int _countedPendingZone: -1
                    function _markDone() {
                        if (_countedPending) {
                            _countedPending = false;
                            gridView._markZoneItemDone(_countedPendingZone);
                        }
                    }
                    Component.onCompleted: {
                        _countedPending = true;
                        _countedPendingZone = delegateItem.zoneIndex;
                        gridView._registerZonePending(_countedPendingZone);
                        if (!mediaLoading) _markDone();
                    }
                    onMediaLoadingChanged: if (!mediaLoading) _markDone()
                    Component.onDestruction: _markDone()

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

        // The one big indicator for this tile's whole zone — rendered only by the zone's anchor
        // tile, and a sibling of (not nested inside) the Rectangle above so it stays visible while
        // that Rectangle itself is opacity-gated to 0 during loading.
        //
        // Held back for 500ms before actually appearing: a zone that finishes loading quickly
        // should just reveal its tiles together with no indicator ever flashing on screen — only a
        // zone that's genuinely slow (over 500ms) shows one, so a fast load doesn't get a jarring
        // spinner-flash-then-gone and a slow one still gets clear feedback.
        Primitives.LoadingIndicator {
            id: zoneIndicator
            anchors.centerIn: parent
            width: 64
            height: 64

            property bool zoneLoading: delegateItem.isZoneIndicatorAnchor && !gridView.isZoneReady(delegateItem.zoneIndex)
            property bool shouldShow: false

            onZoneLoadingChanged: {
                if (zoneLoading) {
                    showDelayTimer.restart();
                } else {
                    showDelayTimer.stop();
                    shouldShow = false;
                }
            }
            Component.onCompleted: if (zoneLoading) showDelayTimer.restart()

            Timer {
                id: showDelayTimer
                interval: 500
                onTriggered: zoneIndicator.shouldShow = true
            }

            running: shouldShow
            visible: opacity > 0
            opacity: shouldShow ? 1 : 0
            z: 20
            Behavior on opacity {
                NumberAnimation {
                    duration: Vars.animationDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Vars.customEmphasizedAccelerate
                }
            }
        }
    }
}
