import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../.."
import "../../theme"
import "../.."
import Quickshell
import Quickshell.Io
import "../../theme"

GridView {
    id: root
    
    property string currentTheme: ""
    property var searchInput
    
    signal themeSelected(string themeName)
    signal escapePressed()

    clip: true
    cellWidth: Math.floor(parent.width / 4)
    cellHeight: cellWidth * 0.66
    boundsBehavior: Flickable.StopAtBounds

    focus: true
    keyNavigationEnabled: true
    highlightFollowsCurrentItem: false
    onCurrentIndexChanged: scrollToCurrentIndex()

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
        target: root
        property: "contentY"
        duration: Vars.animationDuration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Vars.customExpressiveSpatialSlow
    }
    
    highlight: Item {
        x: root.currentItem ? root.currentItem.x : 0
        y: root.currentItem ? root.currentItem.y : 0
        width: root.cellWidth
        height: root.cellHeight
        z: 2

        Behavior on x { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
        Behavior on y { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }

        Rectangle {
            anchors.fill: parent
            anchors.margins: Vars.spacingSmall - 3
            radius: Vars.radiusLarge + 3
            antialiasing: true
            color: "transparent"
            border.color: Theme.primary
            border.width: root.activeFocus ? 3 : 0
            Behavior on border.width { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
        }
    }

    add: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customEmphasizedDecelerate }
            NumberAnimation { property: "scale"; from: 0.9; to: 1; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customEmphasizedDecelerate }
        }
    }
    remove: Transition {
        ParallelAnimation {
            NumberAnimation { property: "opacity"; to: 0; duration: Vars.animationDuration * 0.6; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customEmphasizedAccelerate }
            NumberAnimation { property: "scale"; to: 0.9; duration: Vars.animationDuration * 0.6; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customEmphasizedAccelerate }
        }
    }
    displaced: Transition {
        NumberAnimation { properties: "x,y"; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow }
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
    Keys.onSpacePressed: (event) => {
        if (currentItem) currentItem.triggerSelection();
        event.accepted = true;
    }

    property bool vimKeysEnabled: false
    Process {
        id: vimKeysChecker
        command: ["bash", "-c", 'for f in "$HOME/Dotfiles/hypr/modules/variables.lua" "$HOME/.config/hypr/modules/variables.lua"; do [ -f "$f" ] && grep -qiE "vimkeys[[:space:]]*=[[:space:]]*true" "$f" && { echo true; exit; }; done; echo false']
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.vimKeysEnabled = (this.text.trim() === 'true');
            }
        }
    }

    // Colemak-DH home-row navigation (matches the Hyprland binds): m = left, n = down, e = up, i = right
    Keys.onPressed: (event) => {
        if (!root.vimKeysEnabled) return;
        if (event.key === Qt.Key_M) {
            moveCurrentIndexLeft();
            event.accepted = true;
        } else if (event.key === Qt.Key_I) {
            moveCurrentIndexRight();
            event.accepted = true;
        } else if (event.key === Qt.Key_E) {
            if (currentIndex < 4) {
                if (searchInput) searchInput.forceActiveFocus();
            } else {
                moveCurrentIndexUp();
            }
            event.accepted = true;
        } else if (event.key === Qt.Key_N) {
            moveCurrentIndexDown();
            event.accepted = true;
        }
    }

    delegate: Item {
        id: delegateItem
        width: root.cellWidth
        height: root.cellHeight

        function triggerSelection() {
            root.themeSelected(themeName);
        }

        readonly property bool isActive: root.currentTheme === themeName
        readonly property color surfaceCol: Qt.color(themeSurface)
        readonly property color onSurfaceCol: Qt.color(themeOnSurface)
        readonly property color primaryCol: Qt.color(themePrimary)

        Item {
            id: tile
            anchors.fill: parent
            anchors.margins: Vars.spacingSmall
            scale: tileMouseArea.pressed ? 0.96 : (tileMouseArea.containsMouse ? 1.03 : 1.0)
            Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }

            // The tile is painted with the scheme's own surface so it previews the real look
            Rectangle {
                id: card
                anchors.fill: parent
                radius: Vars.radiusLarge
                antialiasing: true
                color: delegateItem.surfaceCol
                border.width: delegateItem.isActive ? 3 : 1
                border.color: delegateItem.isActive ? delegateItem.primaryCol : Qt.rgba(delegateItem.onSurfaceCol.r, delegateItem.onSurfaceCol.g, delegateItem.onSurfaceCol.b, 0.18)
                Behavior on border.width { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                Behavior on border.color { ColorAnimation { duration: Vars.animationDuration } }

                // Hover wash in the scheme's own text colour
                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    antialiasing: true
                    color: delegateItem.onSurfaceCol
                    opacity: tileMouseArea.containsMouse ? 0.06 : 0.0
                    Behavior on opacity { NumberAnimation { duration: Vars.animationDuration } }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Vars.spacingMedium
                    spacing: Vars.spacingSmall

                    // Colour swatches: primary, secondary, tertiary
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        Row {
                            anchors.centerIn: parent
                            spacing: -Math.round(parent.height * 0.14)

                            Repeater {
                                model: [themePrimary, themeSecondary, themeTertiary]
                                delegate: Rectangle {
                                    required property string modelData
                                    required property int index
                                    readonly property real d: Math.min(card.height * 0.42, card.width * 0.26) * (index === 0 ? 1.0 : 0.82)
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: d
                                    height: d
                                    radius: d / 2
                                    antialiasing: true
                                    color: Qt.color(modelData)
                                    z: 3 - index
                                    // ring in the surface colour so overlapping swatches stay separated
                                    border.width: 3
                                    border.color: delegateItem.surfaceCol
                                }
                            }
                        }
                    }

                    QsText {
                        Layout.fillWidth: true
                        text: themeName
                        font.family: Vars.fontFamily
                        color: delegateItem.onSurfaceCol
                        font.pixelSize: 15
                        setWeight: delegateItem.isActive ? Font.Bold : Font.Medium
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                    }
                }

                // Active-scheme badge
                Rectangle {
                    anchors.top: parent.top
                    anchors.right: parent.right
                    anchors.margins: Vars.spacingSmall
                    width: 24
                    height: 24
                    radius: 12
                    antialiasing: true
                    color: delegateItem.primaryCol
                    opacity: delegateItem.isActive ? 1.0 : 0.0
                    scale: delegateItem.isActive ? 1.0 : 0.4
                    visible: opacity > 0
                    Behavior on opacity { NumberAnimation { duration: Vars.animationDuration } }
                    Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }

                    QsText {
                        anchors.centerIn: parent
                        text: "check"
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 16
                        color: delegateItem.surfaceCol
                    }
                }
            }

            MouseArea {
                id: tileMouseArea
                anchors.fill: parent
                hoverEnabled: true
                preventStealing: false
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.currentIndex = index;
                    delegateItem.triggerSelection();
                }
            }
        }
    }
}
