import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../theme"

Item {
    id: root

    property alias text: searchInput.text
    property alias searchInput: searchInput
    property bool isActiveFocus: searchInput.activeFocus
    property bool expanded: false
    property bool keepFocus: expanded
    property string placeholderText: "Search..."
    property string iconText: "search"
    property bool showIcon: false
    property int defaultHeight: 48
    property color defaultColor: Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)
    property color activeColor: Vars.tColor(Theme.primary_container, Vars.componentOpacity)
    property color defaultTextColor: Theme.on_surface
    property color activeTextColor: Theme.on_primary_container
    property color defaultPlaceholderColor: Theme.on_surface_variant
    property color activePlaceholderColor: Qt.rgba(activeTextColor.r, activeTextColor.g, activeTextColor.b, 0.7)
    property int borderWidth: searchInput.activeFocus ? 2 : 0
    property color borderColor: Theme.primary
    property int fontWeight: -1
    property real outerTopLeftRadius: Vars.radiusExtraLarge
    property real outerTopRightRadius: Vars.radiusExtraLarge
    property real outerBottomLeftRadius: Vars.radiusExtraLarge
    property real outerBottomRightRadius: Vars.radiusExtraLarge
    property real containerPadding: Vars.spacingLarge

    property real topLeftRadius: Math.max(0, outerTopLeftRadius - containerPadding)
    property real topRightRadius: Math.max(0, outerTopRightRadius - containerPadding)
    property real bottomLeftRadius: Math.max(0, outerBottomLeftRadius - containerPadding)
    property real bottomRightRadius: Math.max(0, outerBottomRightRadius - containerPadding)

    signal downPressed(var event)
    signal returnPressed(var event)
    signal escapePressed(var event)
    signal upPressed(var event)

    Layout.fillWidth: true
    Layout.preferredHeight: defaultHeight
    Layout.minimumHeight: defaultHeight
    Layout.maximumHeight: defaultHeight

    Rectangle {
        antialiasing: true
        anchors.fill: parent
        color: searchInput.activeFocus ? activeColor : defaultColor
        border.color: root.borderColor
        border.width: root.borderWidth

        topLeftRadius: root.topLeftRadius
        topRightRadius: root.topRightRadius
        bottomLeftRadius: root.bottomLeftRadius
        bottomRightRadius: root.bottomRightRadius

        Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.IBeamCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onPressed: (mouse) => {
                searchInput.forceActiveFocus();
                mouse.accepted = true;
            }
        }
    }

    function forceActiveFocus() {
        searchInput.forceActiveFocus();
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: Vars.spacingMedium
        anchors.rightMargin: Vars.spacingMedium
        spacing: Vars.spacingMedium

        QsText {
            text: root.iconText
            font.family: "Material Symbols Outlined"
            font.pixelSize: 24
            color: searchInput.activeFocus ? root.activeTextColor : root.defaultTextColor
            visible: root.showIcon
            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
        }

        TextInput {
            id: searchInput
            Layout.fillWidth: true
            font.family: Vars.fontFamily
            font.pixelSize: 16
            font.weight: root.fontWeight >= 0 ? root.fontWeight : Font.Normal
            color: searchInput.activeFocus ? root.activeTextColor : root.defaultTextColor
            focus: root.keepFocus
            selectByMouse: true
            verticalAlignment: TextInput.AlignVCenter
            clip: true

            property bool _deliberateFocusLoss: false

            onActiveFocusChanged: {
                if (activeFocus) {
                    _deliberateFocusLoss = false;
                    Qt.inputMethod.reset();
                    Qt.inputMethod.update(Qt.ImEnabled | Qt.ImQueryInput);
                }
            }

            QsText {
                text: root.placeholderText
                font.family: Vars.fontFamily
                font.pixelSize: searchInput.font.pixelSize
                setWeight: root.fontWeight >= 0 ? root.fontWeight : Font.Normal
                color: searchInput.activeFocus ? root.activePlaceholderColor : root.defaultPlaceholderColor
                opacity: 0.8
                visible: !searchInput.text && !searchInput.activeFocus
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
            }

            Keys.onDownPressed: (event) => {
                searchInput._deliberateFocusLoss = true;
                root.downPressed(event);
            }
            Keys.onUpPressed: (event) => {
                searchInput._deliberateFocusLoss = true;
                root.upPressed(event);
            }
            Keys.onReturnPressed: (event) => {
                searchInput._deliberateFocusLoss = true;
                root.returnPressed(event);
            }
            Keys.onEscapePressed: (event) => {
                searchInput._deliberateFocusLoss = true;
                root.escapePressed(event);
            }
        }

        QsText {
            id: clearIcon
            text: "✕"
            font.pixelSize: 14
            color: searchInput.activeFocus ? root.activeTextColor : root.defaultTextColor
            visible: searchInput.text.length > 0
            Layout.alignment: Qt.AlignVCenter
            Behavior on color { ColorAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    searchInput.text = ""
                    searchInput.forceActiveFocus()
                }
            }
        }
    }
}
