use crate::utils::expand_tilde;
use regex::Regex;
use std::collections::HashMap;
use std::fs;
use std::process::{Command, exit};

fn get_variables_path() -> std::path::PathBuf {
    expand_tilde("~/Dotfiles/quickshell/theme/variables.js")
}

pub fn load_variables() -> String {
    let path = get_variables_path();
    fs::read_to_string(&path).unwrap_or_else(|_| {
        eprintln!("Error: Could not find variables.js at {:?}", path);
        exit(1);
    })
}

pub fn save_variables(content: &str) {
    let path = get_variables_path();
    fs::write(path, content).expect("Failed to write variables");
}

pub fn parse_all(content: &str) -> HashMap<String, String> {
    let re = Regex::new(r"(?m)^var\s+([a-zA-Z0-9_]+)\s*=\s*(.*?);?$").unwrap();
    let mut variables = HashMap::new();
    for cap in re.captures_iter(content) {
        variables.insert(cap[1].to_string(), cap[2].trim().to_string());
    }
    variables
}

pub fn list() {
    let content = load_variables();
    let variables = parse_all(&content);

    let exclude = [
        "m3Standard", "m3StandardDecelerate", "m3StandardAccelerate",
        "m3EmphasizedDecelerate", "m3EmphasizedAccelerate",
        "m3ExpressiveSpatialFast", "m3ExpressiveSpatialSlow",
        "customStandard", "customStandardDecelerate", "customStandardAccelerate",
        "customEmphasizedDecelerate", "customEmphasizedAccelerate",
        "customExpressiveSpatialFast", "customExpressiveSpatialSlow",
    ];

    for (k, v) in variables {
        if !exclude.contains(&k.as_str()) {
            println!("{}: {}", k, v);
        }
    }
}

pub fn get(key: &str) {
    let content = load_variables();
    let variables = parse_all(&content);
    if let Some(val) = variables.get(key) {
        println!("{}", val);
    } else {
        eprintln!("Error: Variable '{}' not found.", key);
        exit(1);
    }
}

pub fn update_var(content: &str, key: &str, value: &str) -> String {
    let mut new_value_str = value.to_string();

    let pattern_get = format!(r"(?m)^(var\s+{}\s*=\s*)(.*?)(;?)$", regex::escape(key));
    let re_get = Regex::new(&pattern_get).unwrap();

    if let Some(caps) = re_get.captures(content) {
        let old_value = &caps[2];
        if old_value.starts_with('"') && old_value.ends_with('"') {
            if !(new_value_str.starts_with('"') && new_value_str.ends_with('"')) {
                new_value_str = format!("\"{}\"", new_value_str);
            }
        } else if old_value.starts_with('\'') && old_value.ends_with('\'') {
            if !(new_value_str.starts_with('\'') && new_value_str.ends_with('\'')) {
                new_value_str = format!("'{}'", new_value_str);
            }
        }
    }

    let repl = format!("${{1}}{}${{3}}", new_value_str);
    re_get.replace(content, repl).to_string()
}

pub fn set(key: &str, value: &str) {
    let content = load_variables();
    let variables = parse_all(&content);
    
    if !variables.contains_key(key) {
        eprintln!("Error: Variable '{}' not found.", key);
        exit(1);
    }

    let new_content = update_var(&content, key, value);
    save_variables(&new_content);
    println!("Set '{}' to {}", key, value);
}

pub fn kill() {
    println!("Killing Quickshell...");
    let _ = Command::new("sh")
        .arg("-c")
        .arg("pkill -9 quickshell; pkill -9 .quickshell-wra")
        .status();
}

pub fn start(detached: bool) {
    println!("Starting Quickshell...");
    if detached {
        let _ = Command::new("sh")
            .arg("-c")
            .arg("quickshell > /dev/null 2>&1 &")
            .spawn();
    } else {
        let _ = Command::new("quickshell").status();
    }
}
