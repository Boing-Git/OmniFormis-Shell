import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes
import "../../"
import Quickshell
import "../../Variables/variables.js" as Vars

Item {
    id: root
    width: 300
    height: 300

    property bool gameMode: false

    property int hours: 0
    property int minutes: 0
    property int seconds: 0

    // Timer to update time
    Timer {
        interval: 1000 // Update every second
        running: true
        repeat: true
        onTriggered: {
            var d = new Date();
            root.hours = d.getHours();
            root.minutes = d.getMinutes();
            root.seconds = d.getSeconds();
        }
        Component.onCompleted: triggered()
    }

    M3Shapes {
        id: m3
    }

    Image {
        id: clockFace
        anchors.fill: parent
        sourceSize.width: width
        sourceSize.height: height
        smooth: true
        antialiasing: true

        property color bg: Theme.surface_container_high
        property string pathColor: "rgb(" + Math.round(bg.r * 255) + "," + Math.round(bg.g * 255) + "," + Math.round(bg.b * 255) + ")"
        property color bc: Theme.outline_variant
        property string outlineColor: "rgb(" + Math.round(bc.r * 255) + "," + Math.round(bc.g * 255) + "," + Math.round(bc.b * 255) + ")"
        property real pathOpacity: Vars.translucent ? 0.85 : 1.0

        source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='" + m3.getPath('Gem') + "' fill='" + pathColor + "' fill-opacity='" + pathOpacity + "' stroke='" + outlineColor + "' stroke-width='1'/></svg>"

        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: !root.gameMode
            shadowBlur: 1.0
            shadowColor: Qt.rgba(0, 0, 0, 0.25)
            shadowVerticalOffset: 4
            shadowHorizontalOffset: 0
        }

        // Inner dial to constrain contents within the Sunny shape bounds
        Item {
            id: dial
            width: clockFace.width * 0.60
            height: clockFace.height * 0.60
            anchors.centerIn: parent

            // Center pivot for hands
            Item {
                anchors.centerIn: parent
                width: 0
                height: 0

                // Hour hand
                Item {
                    rotation: (root.hours % 12) * 30 + (root.minutes / 60) * 30

                    Behavior on rotation {
                        RotationAnimation {
                            direction: RotationAnimation.Shortest
                            duration: Vars.animationDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Vars.customStandard
                        }
                    }

                    Rectangle {
                        width: 15
                        height: dial.height * 0.20
                        color: Theme.primary
                        radius: width / 2 // Cleaner way to ensure a perfect pill shape

                        anchors.bottom: parent.verticalCenter
                        anchors.bottomMargin: -(width / 2) // <-- THE FIX: Pushes the pivot into the center of the curve
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                // Minute hand
                Item {
                    rotation: root.minutes * 6 + (root.seconds / 60) * 6

                    Behavior on rotation {
                        RotationAnimation {
                            direction: RotationAnimation.Shortest
                            duration: Vars.animationDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Vars.customStandard
                        }
                    }

                    Rectangle {
                        width: 15
                        height: dial.height * 0.30
                        color: Theme.secondary
                        radius: width / 2 // Cleaner way to ensure a perfect pill shape

                        anchors.bottom: parent.verticalCenter
                        anchors.bottomMargin: -(width / 2) // <-- THE FIX
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
                // Tick marks
                Repeater {
                    model: 12
                    Item {
                        width: dial.width
                        height: dial.height
                        anchors.centerIn: parent
                        rotation: index * 30

                        Rectangle {
                            width: index % 3 == 0 ? 4 : 2
                            height: index % 3 == 0 ? 20 : 10
                            color: index % 3 == 0 ? Theme.on_surface : Theme.on_surface_variant
                            radius: width / 2
                            anchors.top: parent.top
                            anchors.topMargin: 0
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
                // Expressive Second Hand (Orbiting Dot)
                Item {
                    // 360 degrees / 60 seconds = 6 degrees per tick
                    rotation: root.seconds * 6

                    // Keeps the snappy tick animation
                    Behavior on rotation {
                        RotationAnimation {
                            direction: RotationAnimation.Shortest
                            duration: 200
                            easing.type: Easing.OutBack
                        }
                    }

                    Rectangle {
                        width: 16 // Size of the dot
                        height: 16
                        radius: 100 // Fully rounded circle
                        color: Theme.tertiary

                        // Push the dot outward from the 0x0 center pivot
                        anchors.bottom: parent.verticalCenter
                        anchors.bottomMargin: dial.height * 0.40 // Distance from the center
                        anchors.horizontalCenter: parent.horizontalCenter

                        antialiasing: true
                    }
                }
            }
        }
    }
}
