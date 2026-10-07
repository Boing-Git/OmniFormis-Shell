fn main() {
    let re = regex::Regex::new(r"(?s)<\*\s*for\s+name\s*,\s*value\s+in\s+colors\s*\*>(.*?)<\*\s*endfor\s*>").unwrap();
    let text = r#"pragma Singleton
import QtQuick
import "variables.js" as Vars

QtObject {
    function withAlpha(hexString, alpha) {
        let col = Qt.color(hexString);
        return Qt.rgba(col.r, col.g, col.b, alpha);
    }
	<* for name, value in colors *>
		readonly property color {{name}}: "{{value.dark.hex}}"
	<* endfor *>
}
"#;
    println!("Matches: {}", re.is_match(text));
}
