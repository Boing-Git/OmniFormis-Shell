#[cfg(test)]
mod tests {
    use regex::Regex;

    #[test]
    fn test_regex() {
        let loop_pattern = Regex::new(r"(?s)<\*\s*for\s+name\s*,\s*value\s+in\s+colors\s*\*>(.*?)<\*\s*endfor\s*>").unwrap();
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
        assert!(loop_pattern.is_match(text), "Regex did not match!");
    }
}
