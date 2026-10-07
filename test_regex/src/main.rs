use regex::Regex;
fn main() {
    let re = Regex::new(r"(?s)<\*\s*for\s+name\s*,\s*value\s+in\s+colors\s*\*>(.*?)<\*\s*endfor\s*\*>").unwrap();
    let text = r#"	<* for name, value in colors *>
		readonly property color {{name}}: "{{value.dark.hex}}"
	<* endfor *>"#;
    println!("Regex matches: {}", re.is_match(text));
}
