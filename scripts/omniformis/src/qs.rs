use crate::utils::{
    die, dotfiles_dir, emit, expand_tilde, format_number, is_bogus_literal, no_side_effects,
    parse_bool, with_lock, write_atomic,
};
use regex::Regex;
use std::collections::BTreeMap;
use std::fs;
use std::path::PathBuf;
use std::process::Command;

const CURVE_VARS: [&str; 14] = [
    "m3Standard", "m3StandardDecelerate", "m3StandardAccelerate",
    "m3EmphasizedDecelerate", "m3EmphasizedAccelerate",
    "m3ExpressiveSpatialFast", "m3ExpressiveSpatialSlow",
    "customStandard", "customStandardDecelerate", "customStandardAccelerate",
    "customEmphasizedDecelerate", "customEmphasizedAccelerate",
    "customExpressiveSpatialFast", "customExpressiveSpatialSlow",
];

fn primary_path() -> PathBuf {
    dotfiles_dir().join("quickshell/theme/variables.js")
}

fn config_path() -> PathBuf {
    expand_tilde("~/.config/quickshell/theme/variables.js")
}

pub fn load_variables() -> String {
    for path in [primary_path(), config_path()] {
        if let Ok(content) = fs::read_to_string(&path) {
            if !content.trim().is_empty() {
                return content;
            }
        }
    }
    die("could not find a valid variables.js in the dotfiles or ~/.config/quickshell");
}

/// Write to the dotfiles copy and, when it is a different file, the ~/.config copy as well.
/// `~/.config/quickshell` is normally a symlink to the dotfiles, so the same file is written once.
pub fn save_variables(content: &str) {
    if content.trim().is_empty() {
        die("refusing to write an empty variables.js");
    }

    let mut written = Vec::new();
    for (i, path) in [primary_path(), config_path()].iter().enumerate() {
        let canon = fs::canonicalize(path).ok();
        if let Some(c) = &canon {
            if written.contains(c) {
                continue;
            }
        } else if !path.parent().map_or(false, |p| p.exists()) {
            continue;
        }
        match write_atomic(path, content) {
            Ok(()) => {
                if let Some(c) = canon {
                    written.push(c);
                }
            }
            // The first location is the source of truth, the second is a best-effort mirror
            // (it is read-only when the config is managed by Home Manager).
            Err(e) if i == 0 => die(&format!("failed to write {}: {}", path.display(), e)),
            Err(e) => eprintln!("Warning: could not mirror to {}: {}", path.display(), e),
        }
    }
    if written.is_empty() {
        die("no writable variables.js found");
    }
}

/// Split the text after `var x =` into (value, trailing comment). Quotes are respected so a `//`
/// or `;` inside a string is not mistaken for the end of the value.
fn split_value(raw: &str) -> (String, String) {
    let mut quote: Option<char> = None;
    let mut escaped = false;
    let chars: Vec<(usize, char)> = raw.char_indices().collect();
    let mut i = 0;
    while i < chars.len() {
        let (idx, c) = chars[i];
        if let Some(q) = quote {
            if escaped {
                escaped = false;
            } else if c == '\\' {
                escaped = true;
            } else if c == q {
                quote = None;
            }
        } else if c == '"' || c == '\'' {
            quote = Some(c);
        } else if c == ';' {
            return (raw[..idx].trim().to_string(), raw[idx + 1..].trim().to_string());
        } else if c == '/' && chars.get(i + 1).map_or(false, |&(_, n)| n == '/') {
            return (raw[..idx].trim().to_string(), raw[idx..].trim().to_string());
        }
        i += 1;
    }
    (raw.trim().to_string(), String::new())
}

fn var_line_regex() -> Regex {
    Regex::new(r"^var\s+([A-Za-z0-9_]+)\s*=\s*(.*)$").unwrap()
}

pub fn parse_all(content: &str) -> BTreeMap<String, String> {
    let re = var_line_regex();
    let mut variables = BTreeMap::new();
    for line in content.lines() {
        if let Some(cap) = re.captures(line) {
            let (value, _) = split_value(&cap[2]);
            variables.insert(cap[1].to_string(), value);
        }
    }
    variables
}

#[derive(Debug, PartialEq)]
enum Kind {
    Bool,
    Number,
    Str(char),
    Raw,
}

fn kind_of(value: &str) -> Kind {
    let v = value.trim();
    if v.starts_with('"') && v.ends_with('"') && v.len() >= 2 {
        Kind::Str('"')
    } else if v.starts_with('\'') && v.ends_with('\'') && v.len() >= 2 {
        Kind::Str('\'')
    } else if v == "true" || v == "false" {
        Kind::Bool
    } else if v.parse::<f64>().is_ok() {
        Kind::Number
    } else {
        Kind::Raw
    }
}

fn js_string(value: &str, quote: char) -> String {
    let mut out = String::with_capacity(value.len() + 2);
    out.push(quote);
    for c in value.chars() {
        match c {
            '\\' => out.push_str("\\\\"),
            '\n' => out.push_str("\\n"),
            '\r' => out.push_str("\\r"),
            '\t' => out.push_str("\\t"),
            c if c == quote => {
                out.push('\\');
                out.push(c);
            }
            c => out.push(c),
        }
    }
    out.push(quote);
    out
}

/// Turn user input into a valid JavaScript literal of the same type as the current value.
fn normalize(key: &str, old: &str, new: &str) -> Result<String, String> {
    match kind_of(old) {
        Kind::Bool => parse_bool(new)
            .map(|b| b.to_string())
            .ok_or_else(|| format!("'{}' is a boolean; use true/false (got '{}')", key, new)),
        Kind::Number => format_number(new)
            .ok_or_else(|| format!("'{}' is a number (got '{}')", key, new)),
        Kind::Str(quote) => {
            let mut raw = new;
            // Accept a value that was passed already quoted.
            if raw.len() >= 2
                && ((raw.starts_with('"') && raw.ends_with('"'))
                    || (raw.starts_with('\'') && raw.ends_with('\'')))
            {
                raw = &raw[1..raw.len() - 1];
            }
            if is_bogus_literal(raw) {
                return Err(format!(
                    "refusing to store '{}' in '{}' (looks like an unset JavaScript value)",
                    raw, key
                ));
            }
            Ok(js_string(raw, quote))
        }
        Kind::Raw => {
            if serde_json::from_str::<serde_json::Value>(old).is_err() {
                return Err(format!(
                    "'{}' holds an expression, not a plain value; edit variables.js directly",
                    key
                ));
            }
            serde_json::from_str::<serde_json::Value>(new)
                .map(|v| v.to_string())
                .map_err(|e| format!("'{}' expects JSON (got '{}'): {}", key, new, e))
        }
    }
}

pub fn update_var(content: &str, key: &str, value: &str) -> Result<String, String> {
    let re = var_line_regex();
    let mut lines: Vec<String> = content.split('\n').map(|s| s.to_string()).collect();
    for line in lines.iter_mut() {
        let Some(cap) = re.captures(line) else { continue };
        if &cap[1] != key {
            continue;
        }
        let (old_value, comment) = split_value(&cap[2]);
        let new_value = normalize(key, &old_value, value)?;
        *line = if comment.is_empty() {
            format!("var {} = {};", key, new_value)
        } else {
            format!("var {} = {}; {}", key, new_value, comment)
        };
        return Ok(lines.join("\n"));
    }
    Err(format!("variable '{}' not found", key))
}

pub fn list(json: bool) {
    let content = load_variables();
    let variables = parse_all(&content);
    let visible = variables
        .iter()
        .filter(|(k, _)| !CURVE_VARS.contains(&k.as_str()));

    if json {
        let map: serde_json::Map<String, serde_json::Value> = visible
            .map(|(k, v)| {
                let val = serde_json::from_str(v).unwrap_or_else(|_| serde_json::Value::String(v.clone()));
                (k.clone(), val)
            })
            .collect();
        emit(&serde_json::to_string_pretty(&map).unwrap());
    } else {
        for (k, v) in visible {
            emit(&format!("{}: {}", k, v));
        }
    }
}

pub fn get(key: &str, json: bool) {
    let content = load_variables();
    let variables = parse_all(&content);
    match variables.get(key) {
        Some(val) if json => {
            let parsed = serde_json::from_str(val).unwrap_or_else(|_| serde_json::Value::String(val.clone()));
            emit(&parsed.to_string());
        }
        Some(val) => emit(val),
        None => die(&format!("variable '{}' not found", key)),
    }
}

fn apply(key: &str, compute: impl FnOnce(&str) -> Result<String, String>) {
    let result = with_lock("qs-variables", || {
        let content = load_variables();
        let variables = parse_all(&content);
        let old = variables
            .get(key)
            .ok_or_else(|| format!("variable '{}' not found", key))?
            .clone();
        let value = compute(&old)?;
        let updated = update_var(&content, key, &value)?;
        if updated != content {
            save_variables(&updated);
        }
        let shown = parse_all(&updated).get(key).cloned().unwrap_or(value);
        Ok::<String, String>(shown)
    });
    match result {
        Ok(shown) => emit(&format!("Set '{}' to {}", key, shown)),
        Err(e) => die(&e),
    }
}

pub fn set(key: &str, value: &str) {
    apply(key, |_| Ok(value.to_string()));
}

pub fn toggle(key: &str) {
    apply(key, |old| {
        if kind_of(old) != Kind::Bool {
            return Err(format!("'{}' is not a boolean (current value: {})", key, old));
        }
        Ok((old.trim() != "true").to_string())
    });
}

pub fn kill() {
    if no_side_effects() {
        return;
    }
    emit("Killing Quickshell...");
    let _ = Command::new("sh")
        .arg("-c")
        .arg("pkill -9 quickshell; pkill -9 .quickshell-wra; pkill -f qs-watchdog")
        .status();
}

pub fn launch(detached: bool) {
    if no_side_effects() {
        return;
    }
    emit("Launching Quickshell...");
    let script = dotfiles_dir().join("quickshell/scripts/qs-watchdog.sh");
    if detached {
        let _ = Command::new("sh")
            .arg("-c")
            .arg("nohup bash \"$0\" > /dev/null 2>&1 &")
            .arg(&script)
            .spawn();
    } else {
        let _ = Command::new("bash").arg(&script).status();
    }
}

pub fn reload() {
    if no_side_effects() {
        return;
    }
    emit("Reloading Quickshell...");
    let script = dotfiles_dir().join("scripts/reload.sh");
    let _ = Command::new("bash").arg(&script).status();
}

#[cfg(test)]
mod tests {
    use super::*;

    const SAMPLE: &str = "var panelOpacity = 0.6;\nvar name = \"Google Sans\"; // font\nvar flag = true;\nvar list = [1, 2];\nfunction f() {\n    var panelOpacity = 1;\n}\n";

    #[test]
    fn number_is_validated() {
        assert!(update_var(SAMPLE, "panelOpacity", "abc").is_err());
        let out = update_var(SAMPLE, "panelOpacity", "0.8").unwrap();
        assert!(out.contains("var panelOpacity = 0.8;"));
        // the indented local inside the function must be untouched
        assert!(out.contains("    var panelOpacity = 1;"));
    }

    #[test]
    fn string_is_escaped_and_comment_kept() {
        let out = update_var(SAMPLE, "name", "A \"B\" \\ C").unwrap();
        assert!(out.contains(r#"var name = "A \"B\" \\ C"; // font"#));
        assert!(update_var(SAMPLE, "name", "undefined").is_err());
    }

    #[test]
    fn bool_and_json() {
        assert!(update_var(SAMPLE, "flag", "maybe").is_err());
        assert!(update_var(SAMPLE, "flag", "off").unwrap().contains("var flag = false;"));
        assert!(update_var(SAMPLE, "list", "[3,4]").unwrap().contains("var list = [3,4];"));
        assert!(update_var(SAMPLE, "list", "nope").is_err());
    }

    #[test]
    fn missing_key() {
        assert!(update_var(SAMPLE, "nope", "1").is_err());
    }

    #[test]
    fn parses_value_with_comment_and_semicolon_in_string() {
        let vars = parse_all("var a = \"x;y // z\"; // note\n");
        assert_eq!(vars["a"], "\"x;y // z\"");
    }
}
