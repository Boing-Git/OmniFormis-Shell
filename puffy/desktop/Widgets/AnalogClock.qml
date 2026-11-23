import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Shapes
import "../../"
import Quickshell
import "../../theme"

Item {
    id: root
    width: 300
    height: 300

    property bool gameMode: Vars.gameMode !== undefined ? Vars.gameMode : false

    property int hours: 0
    property int minutes: 0
    property int seconds: 0
    property string dateString: ""

    // Current clock shape — read from Vars and polled for live updates
    property string currentClockShape: Vars.clockShape !== undefined ? Vars.clockShape : "Sunny"
    property bool currentShowTicks: Vars.clockShowTicks !== undefined ? Vars.clockShowTicks : true
    property bool currentShowCenterDot: Vars.clockShowCenterDot !== undefined ? Vars.clockShowCenterDot : true
    property int currentAnimDuration: Vars.animationDuration !== undefined ? Vars.animationDuration : 240
    property bool currentTranslucent: Vars.isTranslucent()

    property bool currentShowDate: Vars.clockShowDate !== undefined ? Vars.clockShowDate : true
    property string currentSecondHandStyle: Vars.clockSecondHandStyle !== undefined ? Vars.clockSecondHandStyle : "Orbiting Dot"
    property real currentHandThickness: Vars.clockHandThickness !== undefined ? Vars.clockHandThickness : 15

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
            var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
            root.dateString = days[d.getDay()] + " " + d.getDate();
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
        mipmap: true

        property color bg: Theme.surface_container_high
        property string pathColor: "rgb(" + Math.round(bg.r * 255) + "," + Math.round(bg.g * 255) + "," + Math.round(bg.b * 255) + ")"
        property color bc: Theme.outline_variant
        property string outlineColor: "rgb(" + Math.round(bc.r * 255) + "," + Math.round(bc.g * 255) + "," + Math.round(bc.b * 255) + ")"
        property real pathOpacity: root.currentTranslucent ? Vars.panelOpacity : 1.0

        property string currentPathName: root.currentClockShape
        property string currentPath: m3.getPath(currentPathName)

        source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='" + currentPath + "' fill='" + pathColor + "' fill-opacity='" + pathOpacity + "' stroke='" + outlineColor + "' stroke-width='1'/></svg>"

        onCurrentPathNameChanged: {
            if (clockFace.status === Image.Ready) {
                shapeAnim.restart();
            } else {
                clockFace.updateSource();
            }
        }

        SequentialAnimation {
            id: shapeAnim
            NumberAnimation {
                target: clockFace
                property: "scale"
                to: 0.01
                duration: 250
                easing.type: Easing.InBack
            }
            ScriptAction {
                script: clockFace.updateSource()
            }
            NumberAnimation {
                target: clockFace
                property: "scale"
                to: 1.0
                duration: 550
                easing.type: Easing.OutElastic
            }
        }

        function updateSource() {
            clockFace.source = "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='" + clockFace.currentPath + "' fill='" + clockFace.pathColor + "' fill-opacity='" + clockFace.pathOpacity + "' stroke='" + clockFace.outlineColor + "' stroke-width='1'/></svg>";
        }


        // Inner dial to constrain contents within the shape bounds
        // Dial size adapts to the shape — more compact shapes get a tighter dial
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
                        width: root.currentHandThickness
                        height: dial.height * 0.20
                        color: Theme.primary
                        radius: width / 2 // Cleaner way to ensure a perfect pill shape
                        antialiasing: true

                        anchors.bottom: parent.verticalCenter
                        anchors.bottomMargin: -(width / 2) // Pushes the pivot into the center of the curve
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        Behavior on width { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutCubic } }
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
                        width: root.currentHandThickness
                        height: dial.height * 0.30
                        color: Theme.secondary
                        radius: width / 2 // Cleaner way to ensure a perfect pill shape
                        antialiasing: true

                        anchors.bottom: parent.verticalCenter
                        anchors.bottomMargin: -(width / 2) // THE FIX
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        Behavior on width { NumberAnimation { duration: Vars.animationDuration; easing.type: Easing.OutCubic } }
                    }
                }

                // Center Dot
                Rectangle {
                    visible: opacity > 0
                    opacity: root.currentShowCenterDot ? 1.0 : 0.0
                    width: 12
                    height: 12
                    radius: width / 2
                    antialiasing: true
                    color: Theme.on_surface
                    anchors.centerIn: parent
                    z: 10
                    Behavior on opacity { NumberAnimation { duration: root.currentAnimDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                }

                // Tick marks
                Item {
                    anchors.fill: parent
                    visible: opacity > 0
                    opacity: root.currentShowTicks ? 1.0 : 0.0
                    Behavior on opacity { NumberAnimation { duration: root.currentAnimDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.customStandard } }
                    
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
                                antialiasing: true
                                anchors.top: parent.top
                                anchors.topMargin: 0
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
                // Expressive Second Hand (Orbiting Dot) or Traditional Line
                Item {
                    // 360 degrees / 60 seconds = 6 degrees per tick
                    rotation: root.seconds * 6
                    visible: root.currentSecondHandStyle !== "Hidden"
                    
                    Behavior on rotation {
                        RotationAnimation {
                            direction: RotationAnimation.Shortest
                            duration: 200
                            easing.type: Easing.OutBack
                        }
                    }

                    // Orbiting Dot
                    Rectangle {
                        visible: root.currentSecondHandStyle === "Orbiting Dot"
                        width: 16 // Size of the dot
                        height: 16
                        radius: 100 // Fully rounded circle
                        antialiasing: true
                        color: Theme.tertiary

                        // Push the dot outward from the 0x0 center pivot
                        anchors.bottom: parent.verticalCenter
                        anchors.bottomMargin: dial.height * 0.40 // Distance from the center
                        anchors.horizontalCenter: parent.horizontalCenter

                    }
                    
                    // Traditional Line
                    Rectangle {
                        visible: root.currentSecondHandStyle === "Traditional Line"
                        width: Math.max(2, root.currentHandThickness * 0.3)
                        height: dial.height * 0.38
                        color: Theme.tertiary
                        radius: width / 2
                        antialiasing: true

                        anchors.bottom: parent.verticalCenter
                        anchors.bottomMargin: -(width / 2) // Center pivot
                        anchors.horizontalCenter: parent.horizontalCenter

                    }
                }
                
                // Orbiting Date Text (180 degrees from Second Dot)
                Item {
                    id: dateOrbit
                    rotation: (root.seconds * 6) + 180
                    visible: root.currentShowDate

                    Behavior on rotation {
                        RotationAnimation {
                            direction: RotationAnimation.Shortest
                            duration: 200
                            easing.type: Easing.OutBack
                        }
                    }

                    Repeater {
                        model: root.dateString.length
                        Item {
                            // Degrees of separation per character, wide enough that adjacent bold
                            // 18px glyphs don't overlap along the dial's inner arc (~81px radius,
                            // so each degree is only ~1.4px of arc length) — 7deg used to pack
                            // characters closer than their own glyph width, smearing the date into
                            // an illegible blob instead of readable curved text.
                            property real charSpacing: 11
                            property real totalAngle: (root.dateString.length - 1) * charSpacing
                            rotation: (index * charSpacing) - (totalAngle / 2)
                            anchors.centerIn: parent

                            QsText {
                                text: root.dateString[index]
                                font.pixelSize: 18 // Increased font size
                                setWeight: 800 // Bold
                                color: Theme.on_surface
                                opacity: 1.0 // Fully opaque as requested
                                layer.enabled: false // Disable layer to prevent pixelation when rotated
                                layer.samples: Vars.layerSamples
                                antialiasing: true

                                // Push the characters outward from the center along the circumference
                                anchors.bottom: parent.verticalCenter
                                anchors.bottomMargin: dial.height * 0.45 // Decreased distance
                                anchors.horizontalCenter: parent.horizontalCenter

                                // Cancels out dateOrbit's own rotation (which only exists to carry the
                                // text's circumference position around with the second hand), leaving
                                // just the small per-character curve tilt above. Without this each
                                // letter inherited the full orbit angle directly, so the date read
                                // upside-down for half of every minute whenever that angle passed
                                // through the 90-270deg range.
                                rotation: -dateOrbit.rotation
                            }
                        }
                    }
                }
            }
        }
    }
}
