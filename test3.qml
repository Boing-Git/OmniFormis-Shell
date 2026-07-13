import QtQuick
Item {
    id: root
    property string testProp: "hello"
    ListView {
        model: 1
        delegate: MouseArea {
            onPressed: console.log(root.testProp)
        }
    }
}
