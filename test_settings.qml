import QtQuick
import QtCore
import Quickshell

ShellRoot {
    Settings {
        id: settings
        category: "Test"
        property string foo: "bar"
    }
    Component.onCompleted: {
        console.log("Settings properties: " + Object.keys(settings));
        Quickshell.exit();
    }
}
