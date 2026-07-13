import QtQuick
import QtQuick.Window

Window {
    visible: true; width: 200; height: 200
    Rectangle {
        anchors.fill: parent
        color: "blue"
        MouseArea {
            anchors.fill: parent
            onPressed: console.log("Pressed")
            onPressAndHold: console.log("Hold")
        }
    }
}
