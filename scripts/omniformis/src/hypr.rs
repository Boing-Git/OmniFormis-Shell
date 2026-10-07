use crate::utils::{
    die, dotfiles_dir, emit, expand_tilde, format_number, is_bogus_literal, no_side_effects,
    parse_bool, with_lock, write_atomic,
};
use regex::Regex;
use std::collections::HashMap;
use std::fs;
use std::path::PathBuf;
use std::process::Command;

/// The Lua files holding user variables. `variables.lua` has settings, `keybinds.lua` has one
/// full key combination per shortcut.
#[derive(Clone, Copy, PartialEq, Debug)]
pub enum Source {
    Variables,
    Keybinds,
}

impl Source {
    fn file_name(self) -> &'static str {
        match self {
            Source::Variables => "variables.lua",
            Source::Keybinds => "keybinds.lua",
        }
    }
}

fn primary_path(src: Source) -> PathBuf {
    dotfiles_dir().join("hypr/modules").join(src.file_name())
}

fn config_path(src: Source) -> PathBuf {
    expand_tilde("~/.config/hypr/modules").join(src.file_name())
}

pub fn read_source(src: Source) -> Option<String> {
    for path in [primary_path(src), config_path(src)] {
        if let Ok(content) = fs::read_to_string(&path) {
            if !content.trim().is_empty() {
                return Some(content);
            }
        }
    }
    None
}

pub fn write_source(src: Source, content: &str) {
    if content.trim().is_empty() {
        die(&format!("refusing to write an empty {}", src.file_name()));
    }
    // Write where the content was read from: the dotfiles copy, or the config copy when the
    // dotfiles checkout does not contain one.
    let path = if primary_path(src).exists() { primary_path(src) } else { config_path(src) };
    if let Err(e) = write_atomic(&path, content) {
        die(&format!("failed to write {}: {}", path.display(), e));
    }
}

pub fn read_file() -> String {
    read_source(Source::Variables).unwrap_or_else(|| die(&format!("{} not found", primary_path(Source::Variables).display())))
}

pub fn write_file(content: &str) {
    write_source(Source::Variables, content);
}

/// Every variable from every source. `variables.lua` wins if a name exists in both.
fn load_all() -> HashMap<String, (HyprVarInfo, Source)> {
    let mut all = HashMap::new();
    for src in [Source::Keybinds, Source::Variables] {
        if let Some(content) = read_source(src) {
            for (k, v) in parse_variables(&content) {
                all.insert(k, (v, src));
            }
        }
    }
    all
}

#[derive(Debug)]
pub struct HyprVarInfo {
    pub val_type: String,
    pub help: String,
    pub enums: Vec<String>,
    pub val: String,
    pub category: String,
}

pub fn parse_variables(content: &str) -> HashMap<String, HyprVarInfo> {
    let mut variables = HashMap::new();
    let mut current_comments = Vec::new();
    let mut current_category = String::from("General");
    
    let pattern = Regex::new(r#"^([a-zA-Z0-9_]+)[ \t]*=[ \t]*(?:"([^"]*)"|(true|false)|(-?\d+(?:\.\d+)?))(?:,?[ \t]*(--.*)?)?$"#).unwrap();
    let enum_pattern = Regex::new(r#"\((.*)\)"#).unwrap();
    let quotes_pattern = Regex::new(r#""([^"]+)""#).unwrap();

    for line in content.lines() {
        let stripped = line.trim();
        if stripped.starts_with("--") && !stripped.starts_with("---") {
            let c = stripped.trim_start_matches('-').trim();
            current_comments.push(c.to_string());
        } else if stripped.is_empty() || stripped.starts_with("---") {
            current_comments.clear();
        } else if let Some(caps) = pattern.captures(stripped) {
            let key = caps.get(1).unwrap().as_str().to_string();
            let str_val = caps.get(2).map(|m| m.as_str());
            let bool_val = caps.get(3).map(|m| m.as_str());
            let num_val = caps.get(4).map(|m| m.as_str());
            let comment = caps.get(5).map(|m| m.as_str());

            if current_comments.len() > 1 {
                current_category = current_comments[0].clone();
            }

            let help_text = if let Some(c) = comment {
                c.trim_start_matches("- ").to_string()
            } else if let Some(last) = current_comments.last() {
                last.clone()
            } else {
                format!("Set {}", key)
            };

            let (val_type, current_val) = if let Some(v) = str_val {
                ("string", v.to_string())
            } else if let Some(v) = bool_val {
                ("bool", v.to_string())
            } else if let Some(v) = num_val {
                ("number", v.to_string())
            } else {
                current_comments.clear();
                continue;
            };

            if key == "ColorScheme" {
                current_comments.clear();
                continue;
            }

            let mut enums = Vec::new();
            if val_type == "string" {
                let mut comments_to_check = Vec::new();
                if let Some(c) = comment {
                    comments_to_check.push(c.to_string());
                }
                comments_to_check.extend(current_comments.clone());

                for c in comments_to_check {
                    if let Some(m) = enum_pattern.captures(&c) {
                        for q in quotes_pattern.captures_iter(&m[1]) {
                            enums.push(q[1].to_string());
                        }
                    }
                }
            }

            variables.insert(key, HyprVarInfo {
                val_type: val_type.to_string(),
                help: help_text,
                enums,
                val: current_val,
                category: current_category.clone(),
            });

            current_comments.clear();
        } else {
            current_comments.clear();
        }
    }
    variables
}

/// Validate `value` for the variable's declared type and rewrite its line. Returns the new file.
pub fn update_var(content: &str, key: &str, value: &str, val_type: &str) -> Result<String, String> {
    let (re, replacement) = match val_type {
        "string" => {
            if value.contains('"') || value.contains('\\') || value.contains('\n') {
                return Err(format!(
                    "'{}' cannot contain quotes, backslashes or newlines (got {:?})",
                    key, value
                ));
            }
            if is_bogus_literal(value) {
                return Err(format!(
                    "refusing to store '{}' in '{}' (looks like an unset JavaScript value)",
                    value, key
                ));
            }
            (
                Regex::new(&format!(
                    r#"(?m)^([ \t]*{}[ \t]*=[ \t]*)"[^"]*"(,?[ \t]*(?:--.*)?)$"#,
                    regex::escape(key)
                )),
                format!("\"{}\"", value),
            )
        }
        "bool" => {
            let b = parse_bool(value)
                .ok_or_else(|| format!("'{}' is a boolean; use true/false (got '{}')", key, value))?;
            (
                Regex::new(&format!(
                    r"(?m)^([ \t]*{}[ \t]*=[ \t]*)(?:true|false)(,?[ \t]*(?:--.*)?)$",
                    regex::escape(key)
                )),
                b.to_string(),
            )
        }
        "number" => {
            let n = format_number(value)
                .ok_or_else(|| format!("'{}' is a number (got '{}')", key, value))?;
            (
                Regex::new(&format!(
                    r"(?m)^([ \t]*{}[ \t]*=[ \t]*)-?\d+(?:\.\d+)?(,?[ \t]*(?:--.*)?)$",
                    regex::escape(key)
                )),
                n,
            )
        }
        other => return Err(format!("unsupported type '{}' for '{}'", other, key)),
    };
    let re = re.map_err(|e| e.to_string())?;

    let mut modified = false;
    let result = re
        .replace(content, |caps: &regex::Captures| {
            modified = true;
            format!("{}{}{}", &caps[1], replacement, &caps[2])
        })
        .to_string();

    if modified {
        Ok(result)
    } else {
        Err(format!("could not find '{}' in variables.lua", key))
    }
}

const EXCLUDED: [&str; 7] = [
    "CustomStandard", "CustomStandardDecelerate", "CustomStandardAccelerate",
    "CustomEmphasizedDecelerate", "CustomEmphasizedAccelerate",
    "CustomExpressiveSpatialFast", "CustomExpressiveSpatialSlow",
];

fn json_value(info: &HyprVarInfo) -> serde_json::Value {
    match info.val_type.as_str() {
        "bool" => serde_json::Value::Bool(info.val == "true"),
        "number" => info
            .val
            .parse::<serde_json::Number>()
            .map(serde_json::Value::Number)
            .unwrap_or_else(|_| serde_json::Value::String(info.val.clone())),
        _ => serde_json::Value::String(info.val.clone()),
    }
}

pub fn list(json: bool) {
    let content = read_file();
    let variables = parse_variables(&content);

    let mut keys: Vec<_> = variables.keys().filter(|k| !EXCLUDED.contains(&k.as_str())).collect();
    keys.sort();

    if json {
        let entries: Vec<serde_json::Value> = keys
            .iter()
            .map(|key| {
                let info = &variables[*key];
                serde_json::json!({
                    "key": key,
                    "type": info.val_type,
                    "value": json_value(info),
                    "enums": info.enums,
                    "category": info.category,
                    "help": info.help,
                })
            })
            .collect();
        emit(&serde_json::to_string_pretty(&entries).unwrap());
        return;
    }

    for key in keys {
        let info = &variables[key];
        let type_str = if info.val_type == "bool" {
            "togglable bool".to_string()
        } else if !info.enums.is_empty() {
            format!("enum ({})", info.enums.join(", "))
        } else {
            info.val_type.clone()
        };

        let left_part = format!("{}: {}", key, type_str);
        let val_part = format!("[{}]", info.val);
        emit(&format!("{:<50} {:<15} - {} | {}", left_part, val_part, info.category, info.help));
    }
}

pub fn get(key: &str, json: bool) {
    let all = load_all();
    match all.get(key) {
        Some((info, _)) if json => emit(&json_value(info).to_string()),
        Some((info, _)) => emit(&info.val),
        None => die(&format!("variable '{}' not found", key)),
    }
}

fn game_mode_side_effects(enabled: bool) {
    if no_side_effects() {
        return;
    }
    // Game mode changes both configs and needs a full Quickshell restart to apply.
    let exe = std::env::current_exe()
        .map(|p| p.to_string_lossy().into_owned())
        .unwrap_or_else(|_| "omniformis".to_string());
    let _ = Command::new("sh")
        .arg("-c")
        .arg("\"$0\" qs set gameMode \"$1\"; hyprctl reload; \"$0\" qs kill; sleep 0.1; \"$0\" qs start -d")
        .arg(&exe)
        .arg(enabled.to_string())
        .spawn();
}

fn apply(key: &str, compute: impl FnOnce(&HyprVarInfo) -> Result<String, String>) {
    let result = with_lock("hypr-variables", || {
        let all = load_all();
        let (info, src) = all
            .get(key)
            .ok_or_else(|| format!("unknown variable '{}'", key))?;
        let src = *src;
        let content = read_source(src).ok_or_else(|| "config file vanished".to_string())?;
        let value = compute(info)?;

        // A shortcut must be a combination the engine can actually bind
        if src == Source::Keybinds {
            let variables_lua = read_source(Source::Variables).unwrap_or_default();
            crate::keybinds::validate(&variables_lua, &value)?;
        }

        if !info.enums.is_empty() && !info.enums.contains(&value) {
            eprintln!(
                "Warning: '{}' is not one of the documented values for '{}' ({})",
                value,
                key,
                info.enums.join(", ")
            );
        }
        let updated = update_var(&content, key, &value, &info.val_type)?;
        if updated != content {
            write_source(src, &updated);
        }
        Ok::<(String, String, Source), String>((value, info.val_type.clone(), src))
    });

    match result {
        Ok((value, val_type, src)) => {
            emit(&format!("Successfully updated {} to {}", key, value));
            if src == Source::Keybinds {
                let clashes = crate::keybinds::conflicts_for(key);
                if !clashes.is_empty() {
                    eprintln!("Warning: {} now shares its combination with {}", key, clashes.join(", "));
                }
            }
            if key == "GameMode" && val_type == "bool" {
                game_mode_side_effects(parse_bool(&value).unwrap_or(false));
            }
        }
        Err(e) => die(&e),
    }
}

pub fn set(key: &str, value: &str) {
    apply(key, |_| Ok(value.to_string()));
}

pub fn toggle(key: &str) {
    apply(key, |info| {
        if info.val_type != "bool" {
            return Err(format!("'{}' is not a boolean (current value: {})", key, info.val));
        }
        Ok((info.val != "true").to_string())
    });
}
