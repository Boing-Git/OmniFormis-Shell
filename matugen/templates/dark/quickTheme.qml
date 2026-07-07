pragma Singleton
import QtQuick

QtObject {
	<* for name, value in colors *>
		readonly property color {{name}}: "{{value.light.hex}}"
	<* endfor *>
}