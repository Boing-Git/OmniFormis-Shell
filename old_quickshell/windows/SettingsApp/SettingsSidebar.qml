import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import "../.."
import "../../theme"
import Quickshell.Networking
import Quickshell.Bluetooth

ColumnLayout {
    id: rootSidebar
    
    M3Shapes { id: m3Shapes }
    
    property string currentSection: "quick"


    Layout.fillWidth: true
    spacing: 4

    FontLoader {
        id: filledIconFont
        source: "../../theme/assets/MaterialSymbolsRounded-Filled.ttf"
    }

    property var navItems: []

    ListView {
        id: navList
        Layout.fillWidth: true
        Layout.preferredHeight: contentHeight
        interactive: false
        
        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customEmphasizedDecelerate }
                NumberAnimation { property: "x"; from: 30; to: 0; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customEmphasizedDecelerate }
            }
        }
        remove: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; to: 0; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customEmphasizedAccelerate }
                NumberAnimation { property: "x"; to: -30; duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customEmphasizedAccelerate }
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

        model: navItems
        
        delegate: Item {
            id: outerDelegate
            width: navList.width
            property int extraMargin: (modelData.isFirst && index !== 0) ? 16 : 0
            height: 72 + extraMargin + 4
            // z needs to live on THIS item, not the inner delegateItem below: ListView stacks
            // delegates against each other by comparing the z of each delegate's own root item
            // (this one), which is what's actually a sibling of every other row. Setting z on
            // delegateItem — one level further in, with no sibling delegates of its own to be
            // compared against — was a no-op for cross-row stacking, which is why a scaled-up row
            // still rendered underneath its neighbors at the overlap.
            z: navHover.pressed ? 1 : 0

            Item {
                id: delegateItem
                // A small permanent side gutter instead of filling edge-to-edge: the sidebar's
                // own Flickable clips (correctly, so scrolled-out content doesn't bleed past the
                // viewport), so a row anchored flush to both edges had nowhere to grow into when
                // it scaled up on press — the scaled edges just got clipped off by the Flickable's
                // own bounds.
                //
                // Sized as a fraction of the row's own (unscaled) width rather than a fixed pixel
                // value, so it stays exactly big enough to fit the full 1.08 scale below at ANY
                // sidebar width (it's user-resizable, 200-600px), instead of only covering one
                // particular width and still clipping once the sidebar's dragged wider. For a
                // scale factor s, a margin of width*(s-1)/(2*s) on each side is the exact amount
                // that keeps the scaled-up row's edges from passing the unscaled row's own edges;
                // 0.04 here is that value for s=1.08 (0.037) rounded up slightly for safety.
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: parent.width * 0.04
                anchors.rightMargin: parent.width * 0.04
                anchors.top: parent.top
                anchors.topMargin: parent.extraMargin
                height: 72

                property bool isSelected: rootSidebar.currentSection === modelData.id

                // Determine target color (which may contain alpha)
                property color targetColor: isSelected ? (Vars.tColorSelected(Theme.primary_container)) : (navHover.containsMouse ? (Vars.tColor(Theme.surface_container_highest, Vars.componentOpacity)) : (Vars.tColor(Theme.surface_container_high, Vars.componentOpacity)))
                Behavior on targetColor { ColorAnimation { duration: Vars.animationDuration } }

                scale: navHover.pressed ? 1.08 : 1.0
                Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }


                Item {
                    anchors.fill: parent
                    opacity: delegateItem.targetColor.a

                    Rectangle {
                        antialiasing: true
                        anchors.fill: parent
                        color: Qt.rgba(delegateItem.targetColor.r, delegateItem.targetColor.g, delegateItem.targetColor.b, 1.0)
                        
                        property real baseRadius: Vars.radiusLarge
                        property real edgeRadius: 4
                        
                        topLeftRadius: delegateItem.isSelected ? height / 2 : (modelData.isFirst ? baseRadius : edgeRadius)
                        topRightRadius: delegateItem.isSelected ? height / 2 : (modelData.isFirst ? baseRadius : edgeRadius)
                        bottomLeftRadius: delegateItem.isSelected ? height / 2 : (modelData.isLast ? baseRadius : edgeRadius)
                        bottomRightRadius: delegateItem.isSelected ? height / 2 : (modelData.isLast ? baseRadius : edgeRadius)

                        Behavior on topLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                        Behavior on topRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                        Behavior on bottomLeftRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                        Behavior on bottomRightRadius { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customExpressiveSpatialSlow } }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    spacing: 16
                    
                    Item {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48
                        
                        property color containerColor: {
                            var colors = [
                                Theme.primary,
                                Theme.secondary,
                                Theme.tertiary
                            ];
                            return colors[index % colors.length];
                        }
                        property color onContainerColor: {
                            var onColors = [
                                Theme.on_primary,
                                Theme.on_secondary,
                                Theme.on_tertiary
                            ];
                            return onColors[index % onColors.length];
                        }
                        
                        Image {
                            anchors.fill: parent
                            sourceSize.width: width * 2
                            sourceSize.height: height * 2
                            smooth: true
                            antialiasing: true
                            mipmap: true
                            
                            source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='" + m3Shapes.getPath(modelData.shape) + "' fill='" + parent.containerColor.toString() + "'/></svg>"
                        }

                        // Outlined (Empty) Icon
                        QsText {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.family: "Material Symbols Outlined"
                            font.pixelSize: 24
                            color: parent.onContainerColor
                            opacity: delegateItem.isSelected ? 0.0 : 1.0
                            scale: delegateItem.isSelected ? 0.8 : 1.0
                            
                            Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.InOutQuad } }
                            Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }
                        }

                        // Filled Icon
                        QsText {
                            anchors.centerIn: parent
                            text: modelData.icon
                            font.family: filledIconFont.name
                            font.pixelSize: 24
                            color: parent.onContainerColor
                            opacity: delegateItem.isSelected ? 1.0 : 0.0
                            scale: delegateItem.isSelected ? 1.0 : 0.5
                            
                            Behavior on opacity { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.InOutQuad } }
                            Behavior on scale { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutBack } }
                        }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        QsText {
                            text: modelData.name
                            font.family: Vars.fontFamily
                            font.pixelSize: 16
                            setWeight: delegateItem.isSelected ? 500 : 400
                            color: delegateItem.isSelected ? Theme.on_primary_container : Theme.on_surface
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignLeft
                            elide: Text.ElideRight
                        }
                        QsText {
                            text: modelData.subtitle
                            font.family: Vars.fontFamily
                            font.pixelSize: 12
                            color: delegateItem.isSelected ? Theme.on_primary_container : Theme.on_surface_variant
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignLeft
                            opacity: 0.9
                            elide: Text.ElideRight
                        }
                    }
                }
                
                MouseArea {
                    id: navHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: rootSidebar.currentSection = modelData.id
                }
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 160
        visible: navList.count === 0
        
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 12
            QsText {
                text: "search_off"
                font.family: "Material Symbols Outlined"
                font.pixelSize: 48
                color: Theme.on_surface_variant
                Layout.alignment: Qt.AlignHCenter
            }
            QsText {
                text: "No pages match your search"
                font.family: Vars.fontFamily
                font.pixelSize: 16
                color: Theme.on_surface_variant
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }
}
