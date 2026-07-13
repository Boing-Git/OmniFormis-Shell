import QtQuick
import QtQuick.Window

Window {
    visible: true; width: 200; height: 200
    ListModel { id: m; ListElement { a: 1 } }
    ListView {
        model: m
        anchors.fill: parent
        delegate: Rectangle {
            width: 100; height: 50; color: "red"
            Text { text: model.a }
            MouseArea {
                anchors.fill: parent
                onClicked: model.a = 2
            }
        }
    }
}
