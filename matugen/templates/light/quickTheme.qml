pragma Singleton
import QtQuick

QtObject {
	<* for name, value in colors *>
		readonly property color {{name}}: "{{value.dark.hex}}"
	<* endfor *>
}