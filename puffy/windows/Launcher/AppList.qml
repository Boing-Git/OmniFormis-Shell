import QtQuick
import QtQuick.Layouts
import Quickshell
import "../.."
import "../../theme"
import "../.."
import "../../theme"
import Quickshell.Io

ListView {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true
    implicitHeight: contentHeight

    property var launcherModel
    property alias searchText: searchInputTextObj.text
    property real outerTopLeftRadius: Vars.radiusExtraLarge
    property real outerTopRightRadius: Vars.radiusExtraLarge
    property real outerBottomLeftRadius: Vars.radiusExtraLarge
    property real outerBottomRightRadius: Vars.radiusExtraLarge
    property real containerPadding: Vars.spacingLarge

    QtObject {
        id: searchInputTextObj
        property string text: ""
    }

    signal appLaunched
    signal escapePressed
    signal focusSearchBar
    signal openSettingsRequested
    signal requestSearchText(string text)

    property real lastTypingTime: 0
    property int dynamicAnimationDuration: Vars.animationDuration

    onSearchTextChanged: {
        // let now = Date.now();
        // if (lastTypingTime > 0) {
        //     let diff = now - lastTypingTime;
        //     let targetDuration = Math.min(Vars.animationDuration, Math.max(25, diff * 1.5));
        //     if (targetDuration < dynamicAnimationDuration) {
        //         dynamicAnimationDuration = targetDuration;
        //     } else {
        //         dynamicAnimationDuration = (dynamicAnimationDuration * 0.2 + targetDuration * 0.8);
        //     }
        // } else {
        //     dynamicAnimationDuration = Vars.animationDuration;
        // }
        // lastTypingTime = now;
        // typingResetTimer.restart();
    }

    Timer {
        id: typingResetTimer
        interval: 300
        onTriggered: {
            root.dynamicAnimationDuration = Vars.animationDuration;
            root.lastTypingTime = 0;
        }
    }

    clip: true
    spacing: 4

    orientation: ListView.Vertical
    flickDeceleration: Vars.flickDeceleration
    maximumFlickVelocity: Vars.maximumFlickVelocity

    focus: false
    // keyNavigationEnabled: true - removed to stop auto-scroll on hover
    highlightFollowsCurrentItem: false
    // Removed onCurrentIndexChanged: positionViewAtIndex(...) to avoid fighting mouse flicking

    // removed highlightRangeMode properties to prevent auto-snapping on mouse hover
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
    Keys.onEscapePressed: event => {
        root.escapePressed();
        event.accepted = true;
    }

    add: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: root.dynamicAnimationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customEmphasizedDecelerate
            }
            NumberAnimation {
                property: "x"
                from: 30
                to: 0
                duration: root.dynamicAnimationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customEmphasizedDecelerate
            }
        }
    }
    remove: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                to: 0
                duration: root.dynamicAnimationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customEmphasizedAccelerate
            }
            NumberAnimation {
                property: "x"
                to: -30
                duration: root.dynamicAnimationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customEmphasizedAccelerate
            }
        }
    }
    displaced: Transition {
        PropertyAction {
            property: "z"
            value: 0
        }
        ParallelAnimation {
            NumberAnimation {
                properties: "x,y"
                duration: root.dynamicAnimationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customExpressiveSpatialSlow
            }
            SequentialAnimation {
                NumberAnimation {
                    property: "opacity"
                    to: 0.2
                    duration: root.dynamicAnimationDuration * 0.3
                }
                NumberAnimation {
                    property: "opacity"
                    to: 1.0
                    duration: root.dynamicAnimationDuration * 0.7
                }
            }
        }
    }
    removeDisplaced: Transition {
        PropertyAction {
            property: "z"
            value: 0
        }
        ParallelAnimation {
            NumberAnimation {
                properties: "x,y"
                duration: root.dynamicAnimationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customExpressiveSpatialSlow
            }
            SequentialAnimation {
                NumberAnimation {
                    property: "opacity"
                    to: 0.2
                    duration: root.dynamicAnimationDuration * 0.3
                }
                NumberAnimation {
                    property: "opacity"
                    to: 1.0
                    duration: root.dynamicAnimationDuration * 0.7
                }
            }
        }
    }
    move: Transition {
        PropertyAction {
            property: "z"
            value: 100
        }
        NumberAnimation {
            properties: "x,y"
            duration: root.dynamicAnimationDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Vars.customExpressiveSpatialSlow
        }
        PropertyAction {
            property: "z"
            value: 0
        }
    }
    moveDisplaced: Transition {
        PropertyAction {
            property: "z"
            value: 0
        }
        ParallelAnimation {
            NumberAnimation {
                properties: "x,y"
                duration: root.dynamicAnimationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customExpressiveSpatialSlow
            }
            SequentialAnimation {
                NumberAnimation {
                    property: "opacity"
                    to: 0.2
                    duration: root.dynamicAnimationDuration * 0.3
                }
                NumberAnimation {
                    property: "opacity"
                    to: 1.0
                    duration: root.dynamicAnimationDuration * 0.7
                }
            }
        }
    }
    populate: Transition {
        ParallelAnimation {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: Vars.animationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customEmphasizedDecelerate
            }
            NumberAnimation {
                property: "x"
                from: 30
                to: 0
                duration: Vars.animationDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Vars.customEmphasizedDecelerate
            }
        }
    }
    property bool vimKeysEnabled: false
    Process {
        id: vimKeysChecker
        command: ["bash", "-c", "grep -qi 'vimkeys[ \t]*=[ \t]*true' /home/boing/Dotfiles/hypr/modules/variables.lua && echo 'true' || echo 'false'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.vimKeysEnabled = (this.text.trim() === 'true');
            }
        }
    }

    function scrollToCurrentIndex() {
        if (currentIndex < 0)
            return;
        var itemY = currentIndex * 52;
        var itemBottom = itemY + 48;

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
        target: root
        property: "contentY"
        duration: Vars.animationDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Vars.customExpressiveSpatialSlow
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Backspace || event.key === Qt.Key_Delete) {
            if (currentItem && currentItem.deleteClipboardItem) {
                currentItem.deleteClipboardItem();
                event.accepted = true;
                return;
            }
        }

        if (event.key === Qt.Key_Space) {
            if (currentItem)
                currentItem.triggerSelection();
            event.accepted = true;
            return;
        }

        if (root.vimKeysEnabled && (event.text === "s" || event.key === Qt.Key_S || event.text === "j" || event.key === Qt.Key_J)) {
            if (currentIndex === -1 && count > 0) {
                currentIndex = 0;
                scrollToCurrentIndex();
            } else {
                incrementCurrentIndex();
                scrollToCurrentIndex();
            }
            event.accepted = true;
            return;
        }

        if (root.vimKeysEnabled && (event.text === "d" || event.key === Qt.Key_D || event.text === "k" || event.key === Qt.Key_K)) {
            if (currentIndex <= 0) {
                root.focusSearchBar();
            } else {
                decrementCurrentIndex();
                scrollToCurrentIndex();
            }
            event.accepted = true;
            return;
        }

        if (root.vimKeysEnabled && (event.text === "l" || event.key === Qt.Key_L || event.text === "f" || event.key === Qt.Key_F)) {
            if (currentItem)
                currentItem.triggerSelection();
            event.accepted = true;
            return;
        }

        if (root.vimKeysEnabled && (event.text === "h" || event.key === Qt.Key_H || event.text === "a" || event.key === Qt.Key_A)) {
            root.focusSearchBar();
            event.accepted = true;
            return;
        }
    }

    Keys.onUpPressed: event => {
        if (currentIndex <= 0) {
            root.focusSearchBar();
        } else {
            decrementCurrentIndex();
            scrollToCurrentIndex();
        }
        event.accepted = true;
    }
    Keys.onDownPressed: event => {
        if (currentIndex === -1 && count > 0) {
            currentIndex = 0;
            scrollToCurrentIndex();
        } else {
            incrementCurrentIndex();
            scrollToCurrentIndex();
        }
        event.accepted = true;
    }

    onActiveFocusChanged: console.log("[DEBUG] AppList activeFocus changed to:", activeFocus)
    onCurrentIndexChanged: console.log("[DEBUG] AppList currentIndex changed to:", currentIndex)
    onModelChanged: {
        console.log("[DEBUG] AppList onModelChanged. count:", count)
        // if (count > 0 && currentIndex === -1) {
        //     currentIndex = 0;
        // }
    }

    delegate: Item {
        id: delegateItem
        width: root.width
        height: 48

        property var itemData: typeof modelData !== 'undefined' ? modelData : model

        function triggerSelection() {
            var cmdArray = [];
            try {
                cmdArray = JSON.parse(itemData.commandStr);
            } catch (e) {
                console.log("Failed to parse commandStr: " + itemData.commandStr);
                return;
            }

            if (cmdArray[0] === "INTERNAL:SETTINGS") {
                root.openSettingsRequested();
                root.escapePressed();
                return;
            }
            if (cmdArray[0] === "INTERNAL:CLIPBOARD") {
                root.requestSearchText("/clipboard ");
                root.focusSearchBar();
                return;
            }
            if (cmdArray[0] === "INTERNAL:EMOJI") {
                root.requestSearchText("/emoji ");
                root.focusSearchBar();
                return;
            }
            if (cmdArray[0] === "INTERNAL:CALCULATOR") {
                root.requestSearchText("=");
                root.focusSearchBar();
                return;
            }
            if (cmdArray[0] === "INTERNAL:WEB_SEARCH") {
                root.requestSearchText("/web ");
                root.focusSearchBar();
                return;
            }
            // /ask: the launcher stays open while the AI works (LauncherModel.qml)
            // (a second word starts the question: "make an automation that ")
            if (cmdArray[0] === "INTERNAL:ASK_MODE") {
                root.requestSearchText("/ask " + (cmdArray[1] || ""));
                root.focusSearchBar();
                return;
            }
            // /run: automations (LauncherModel.qml); the launcher stays open to show the run
            if (cmdArray[0] === "INTERNAL:RUN_MODE") {
                root.requestSearchText("/run ");
                root.focusSearchBar();
                return;
            }
            if (cmdArray[0] === "INTERNAL:RUN") {
                if (root.launcherModel) root.launcherModel.runAutomation(cmdArray[1]);
                return;
            }
            if (cmdArray[0] === "INTERNAL:ASK") {
                if (root.launcherModel) root.launcherModel.ask(cmdArray[1]);
                return;
            }
            if (cmdArray[0] === "INTERNAL:ASK_YES" || cmdArray[0] === "INTERNAL:ASK_NO") {
                if (root.launcherModel) root.launcherModel.askConfirmed(cmdArray[0] === "INTERNAL:ASK_YES");
                return;
            }
            if (cmdArray[0] === "INTERNAL:NOOP")
                return;
            if (cmdArray[0] === "INTERNAL:CLEAR_CLIPBOARD") {
                if (root.launcherModel) {
                    root.launcherModel.clearClipboard();
                    var oldText = root.searchText;
                    root.requestSearchText("");
                    root.requestSearchText(oldText);
                }
                return;
            }

            Quickshell.execDetached({
                command: cmdArray,
                workingDirectory: itemData.workingDirectory
            });
            root.appLaunched();
            root.escapePressed();
        }

        property bool isCurrent: delegateItem.ListView.isCurrentItem && root.activeFocus
        property bool isEffectivelyLast: index === root.count - 1
        property bool isEffectivelyFirst: index === 0

        property real r2TopLeft: Math.max(0, root.outerTopLeftRadius - root.containerPadding)
        property real r2TopRight: Math.max(0, root.outerTopRightRadius - root.containerPadding)
        property real r2BottomLeft: Math.max(0, root.outerBottomLeftRadius - root.containerPadding)
        property real r2BottomRight: Math.max(0, root.outerBottomRightRadius - root.containerPadding)

        Rectangle {
            antialiasing: true
            anchors.fill: parent
            anchors.margins: 0
            color: isCurrent ? (Vars.tColorSelected(Theme.primary_container)) : (itemMouseArea.containsMouse ? (Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)) : (Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)))

            topLeftRadius: isCurrent ? height / 2 : 4
            topRightRadius: isCurrent ? height / 2 : 4
            bottomLeftRadius: isCurrent ? height / 2 : (isEffectivelyLast ? r2BottomLeft : 4)
            bottomRightRadius: isCurrent ? height / 2 : (isEffectivelyLast ? r2BottomRight : 4)

            border.color: Theme.primary
            border.width: 0

            Behavior on color {
                ColorAnimation {
                    duration: Vars.animationDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Vars.customStandard
                }
            }
            Behavior on topLeftRadius {
                NumberAnimation {
                    duration: Vars.animationDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Vars.customExpressiveSpatialSlow
                }
            }
            Behavior on topRightRadius {
                NumberAnimation {
                    duration: Vars.animationDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Vars.customExpressiveSpatialSlow
                }
            }
            Behavior on bottomLeftRadius {
                NumberAnimation {
                    duration: Vars.animationDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Vars.customExpressiveSpatialSlow
                }
            }
            Behavior on bottomRightRadius {
                NumberAnimation {
                    duration: Vars.animationDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Vars.customExpressiveSpatialSlow
                }
            }
            Behavior on anchors.margins {
                NumberAnimation {
                    duration: Vars.animationDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Vars.customExpressiveSpatialSlow
                }
            }
        }

        function deleteClipboardItem() {
            if (itemData.isClipboard && root.launcherModel) {
                root.launcherModel.deleteClipboardItem(itemData.clipId, itemData.fullLine);
                var oldText = root.searchText;
                root.requestSearchText("");
                root.requestSearchText(oldText);
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

            onClicked: mouse => {
                root.currentIndex = index;
                if (mouse.button === Qt.RightButton && itemData.isClipboard) {
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
                NumberAnimation {
                    duration: Vars.animationDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Vars.customExpressiveSpatialSlow
                }
            }

            Rectangle {
                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                color: "transparent"
                radius: Vars.radiusSmall
                antialiasing: true
                clip: true

                Image {
                    anchors.fill: parent
                    source: (itemData.clipImagePath !== undefined && itemData.clipImagePath !== "") ? "file://" + itemData.clipImagePath : (itemData.icon ? "image://icon/" + itemData.icon : "image://icon/application-x-executable")
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 48
                    sourceSize.height: 48
                    // Decoded off the UI thread and cached (the pixmap cache is keyed by source
                    // URL+size, so repeated icons across filtered results are decoded only once).
                    // A synchronous, uncached decode per delegate was stalling the UI thread on
                    // every keystroke, which is what made the search feel slow and eat keystrokes.
                    cache: true
                    asynchronous: true
                    visible: (itemData.isFile !== true && itemData.isMath !== true && itemData.isSetting !== true && itemData.isClipboard !== true && itemData.isClearAll !== true) || (itemData.isClipboard === true && itemData.clipImagePath !== undefined && itemData.clipImagePath !== "")

                    opacity: isCurrent ? 1.0 : (itemMouseArea.containsMouse ? 0.9 : 0.7)
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Vars.animationDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Vars.customExpressiveSpatialSlow
                        }
                    }
                }

                QsText {
                    anchors.centerIn: parent
                    font.family: "Material Symbols Outlined"
                    font.pixelSize: 24
                    text: itemData.isMath ? "calculate" : (itemData.isClipboard ? "content_copy" : (itemData.isSetting ? itemData.iconName : (itemData.isClearAll ? "delete" : (itemData.isFile ? (itemData.isDir ? "folder" : "description") : ""))))
                    color: itemData.isClearAll ? Theme.error : (isCurrent ? Theme.on_primary_container : Theme.on_surface)
                    visible: (itemData.isFile === true || itemData.isMath === true || itemData.isSetting === true || itemData.isClipboard === true || itemData.isClearAll === true) && !(itemData.isClipboard && itemData.clipImagePath !== undefined && itemData.clipImagePath !== "")

                    opacity: isCurrent ? 1.0 : (itemMouseArea.containsMouse ? 0.9 : 0.7)
                    Behavior on opacity {
                        NumberAnimation {
                            duration: Vars.animationDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Vars.customExpressiveSpatialSlow
                        }
                    }
                    Behavior on color {
                        ColorAnimation {
                            duration: Vars.animationDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Vars.customExpressiveSpatialSlow
                        }
                    }
                }
            }

            QsText {
                Layout.fillWidth: true
                font.family: Vars.fontFamily
                font.pixelSize: 14
                setWeight: isCurrent ? Font.DemiBold : Font.Medium
                text: itemData.name

                color: itemData.isClearAll ? Theme.error : (isCurrent ? Theme.on_primary_container : Theme.on_surface)
                opacity: isCurrent ? 1.0 : (itemMouseArea.containsMouse ? 0.8 : 0.6)

                maximumLineCount: 1
                elide: Text.ElideRight

                Behavior on opacity {
                    NumberAnimation {
                        duration: Vars.animationDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Vars.customExpressiveSpatialSlow
                    }
                }
                Behavior on color {
                    ColorAnimation {
                        duration: Vars.animationDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Vars.customExpressiveSpatialSlow
                    }
                }
            }
        }
    }
}
