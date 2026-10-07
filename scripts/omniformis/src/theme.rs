use crate::utils::expand_tilde;
use regex::Regex;
use std::collections::HashMap;
use std::fs;
use std::path::Path;
use std::process::{Command, exit};

fn parse_qml_theme(filepath: &str) -> (HashMap<String, String>, String, bool) {
    let mut c = HashMap::new();
    let mut name = String::new();
    let mut found_from_comment = false;

    let content = fs::read_to_string(filepath).unwrap_or_else(|e| {
        eprintln!("Error reading {}: {}", filepath, e);
        exit(1);
    });

    let re = Regex::new(r#"readonly property color (\w+):\s*["']([^"']+)["']"#).unwrap();

    for line in content.lines() {
        let line = line.trim();
        if line.starts_with("//") && !found_from_comment {
            let comment_name = line.trim_start_matches('/').trim();
            if !comment_name.is_empty() {
                name = comment_name.to_string();
                found_from_comment = true;
            }
        }
        if line.is_empty() || line.starts_with("//") {
            continue;
        }
        if let Some(caps) = re.captures(line) {
            c.insert(caps[1].to_string(), caps[2].to_string());
        }
    }

    if !found_from_comment || name.is_empty() {
        let base_name = Path::new(filepath).file_stem().unwrap().to_str().unwrap();
        name = base_name.to_string();
    }

    let re_remove = Regex::new(r"(?i)[-\s]*(light|dark)[-\s]*").unwrap();
    name = re_remove.replace_all(&name, " ").to_string();
    name = name.replace('-', " ").replace('_', " ");
    let mut title_case = String::new();
    for word in name.split_whitespace() {
        let mut chars = word.chars();
        if let Some(first) = chars.next() {
            title_case.push_str(&first.to_uppercase().to_string());
            title_case.push_str(&chars.as_str().to_lowercase());
            title_case.push(' ');
        }
    }
    name = title_case.trim().to_string();

    if name.is_empty() {
        name = "AutoTheme".to_string();
    }

    (c, name, found_from_comment)
}

fn hex_to_rgb(hex: &str) -> (f32, f32, f32) {
    let hex = hex.trim_start_matches('#');
    let r = u8::from_str_radix(&hex.get(0..2).unwrap_or("00"), 16).unwrap_or(0) as f32 / 255.0;
    let g = u8::from_str_radix(&hex.get(2..4).unwrap_or("00"), 16).unwrap_or(0) as f32 / 255.0;
    let b = u8::from_str_radix(&hex.get(4..6).unwrap_or("00"), 16).unwrap_or(0) as f32 / 255.0;
    (r, g, b)
}

fn rgb_to_hsl(r: f32, g: f32, b: f32) -> (f32, f32, f32) {
    let max = r.max(g).max(b);
    let min = r.min(g).min(b);
    let l = (max + min) / 2.0;

    if max == min {
        (0.0, 0.0, l)
    } else {
        let d = max - min;
        let s = if l > 0.5 { d / (2.0 - max - min) } else { d / (max + min) };
        let h = if max == r {
            (g - b) / d + (if g < b { 6.0 } else { 0.0 })
        } else if max == g {
            (b - r) / d + 2.0
        } else {
            (r - g) / d + 4.0
        };
        (h / 6.0, s, l)
    }
}

fn hue_to_rgb(p: f32, q: f32, mut t: f32) -> f32 {
    if t < 0.0 { t += 1.0; }
    if t > 1.0 { t -= 1.0; }
    if t < 1.0/6.0 { return p + (q - p) * 6.0 * t; }
    if t < 1.0/2.0 { return q; }
    if t < 2.0/3.0 { return p + (q - p) * (2.0/3.0 - t) * 6.0; }
    p
}

fn hsl_to_rgb(h: f32, s: f32, l: f32) -> (f32, f32, f32) {
    if s == 0.0 {
        (l, l, l)
    } else {
        let q = if l < 0.5 { l * (1.0 + s) } else { l + s - l * s };
        let p = 2.0 * l - q;
        let r = hue_to_rgb(p, q, h + 1.0/3.0);
        let g = hue_to_rgb(p, q, h);
        let b = hue_to_rgb(p, q, h - 1.0/3.0);
        (r, g, b)
    }
}

fn rgb_to_hex(r: f32, g: f32, b: f32) -> String {
    format!("#{:02x}{:02x}{:02x}", (r * 255.0).round() as u8, (g * 255.0).round() as u8, (b * 255.0).round() as u8)
}

fn apply_filters(hex: &str, filters: &str, is_dark: bool) -> String {
    if filters.trim().is_empty() {
        return hex.to_string();
    }
    
    let (r, g, b) = hex_to_rgb(hex);
    let (h, mut s, mut l) = rgb_to_hsl(r, g, b);
    
    for filter in filters.split('|') {
        let filter = filter.trim();
        if filter.starts_with("saturate:") {
            let parts: Vec<&str> = filter.split(',').collect();
            let val_str = parts[0].trim_start_matches("saturate:").trim();
            if let Ok(val) = val_str.parse::<f32>() {
                s = (s + val / 100.0).clamp(0.0, 1.0);
            }
        } else if filter.starts_with("auto_lightness:") {
            let val_str = filter.trim_start_matches("auto_lightness:").trim();
            if let Ok(val) = val_str.parse::<f32>() {
                if is_dark {
                    l = (l - val / 100.0).clamp(0.0, 1.0);
                } else {
                    l = (l + val / 100.0).clamp(0.0, 1.0);
                }
            }
        }
    }
    
    let (nr, ng, nb) = hsl_to_rgb(h, s, l);
    rgb_to_hex(nr, ng, nb)
}

fn process_template(
    mut template_content: String,
    light_map: &HashMap<String, String>,
    dark_map: &HashMap<String, String>,
    is_dark_mode: bool,
) -> String {
    let pattern_hex = Regex::new(r"\{\{\s*colors\.([a-zA-Z0-9_]+)\.(light|dark)\.hex\b([^\}]*)\}\}").unwrap();
    let pattern_stripped = Regex::new(r"\{\{\s*colors\.([a-zA-Z0-9_]+)\.(light|dark)\.hex_stripped([^\}]*)\}\}").unwrap();
    
    template_content = pattern_hex.replace_all(&template_content, |caps: &regex::Captures| {
        let color_name = &caps[1];
        let mode = &caps[2];
        let filter_str = &caps[3];
        let mapping = if mode == "light" { light_map } else { dark_map };
        let hex = mapping.get(color_name).cloned().unwrap_or_else(|| "#000000".to_string());
        apply_filters(&hex, filter_str, is_dark_mode)
    }).to_string();

    template_content = pattern_stripped.replace_all(&template_content, |caps: &regex::Captures| {
        let color_name = &caps[1];
        let mode = &caps[2];
        let filter_str = &caps[3];
        let mapping = if mode == "light" { light_map } else { dark_map };
        let hex = mapping.get(color_name).cloned().unwrap_or_else(|| "#000000".to_string());
        apply_filters(&hex, filter_str, is_dark_mode).trim_start_matches('#').to_string()
    }).to_string();

    let img_pattern = Regex::new(r"\{\{\s*image\s*\}\}").unwrap();
    template_content = img_pattern.replace_all(&template_content, "/tmp/wallpaper.png").to_string();

    let loop_pattern = Regex::new(r"(?s)<\*\s*for\s+name\s*,\s*value\s+in\s+colors\s*\*>(.*?)<\*\s*endfor\s*\*>").unwrap();
    
    template_content = loop_pattern.replace_all(&template_content, |caps: &regex::Captures| {
        let inner_template = &caps[1];
        let mut result = String::new();
        
        let map_to_use = if inner_template.contains("value.dark") {
            dark_map
        } else if inner_template.contains("value.light") {
            light_map
        } else if is_dark_mode {
            dark_map
        } else {
            light_map
        };

        let val_hex_re = Regex::new(r"\{\{\s*value\.(light|dark)\.hex\b([^\}]*)\}\}").unwrap();
        let val_stripped_re = Regex::new(r"\{\{\s*value\.(light|dark)\.hex_stripped([^\}]*)\}\}").unwrap();

        for (color_name, hex_val) in map_to_use {
            let mut s = inner_template.replace("{{name}}", color_name);
            
            s = val_hex_re.replace_all(&s, |caps2: &regex::Captures| {
                apply_filters(hex_val, &caps2[2], is_dark_mode)
            }).to_string();

            s = val_stripped_re.replace_all(&s, |caps2: &regex::Captures| {
                apply_filters(hex_val, &caps2[2], is_dark_mode).trim_start_matches('#').to_string()
            }).to_string();
            
            result.push_str(&s);
        }
        result
    }).to_string();

    template_content
}

pub fn generate(light_file: &str, dark_file: Option<&str>) {
    let (light_map, light_name, light_has_comment) = parse_qml_theme(light_file);
    let (dark_map, dark_name, dark_has_comment) = if let Some(d) = dark_file {
        parse_qml_theme(d)
    } else {
        (light_map.clone(), light_name.clone(), light_has_comment)
    };

    let theme_name = if light_has_comment {
        light_name.clone()
    } else if dark_has_comment {
        dark_name.clone()
    } else if light_name.len() >= dark_name.len() {
        light_name.clone()
    } else {
        dark_name.clone()
    };

    let dir_name = theme_name.to_lowercase().replace(' ', "-");

    let config_path = expand_tilde("~/.config/matugen/config.toml");
    if !config_path.exists() {
        eprintln!("Error: {:?} not found.", config_path);
        exit(1);
    }

    let config_content = fs::read_to_string(&config_path).unwrap();
    let mut templates = Vec::new();
    let mut current_template: Option<HashMap<String, String>> = None;

    for line in config_content.lines() {
        let line = line.trim();
        if line.is_empty() || line.starts_with('#') {
            continue;
        }
        if line.starts_with("[templates.") {
            if let Some(t) = current_template.take() {
                templates.push(t);
            }
            current_template = Some(HashMap::new());
            continue;
        }
        if line.contains('=') {
            if let Some(t) = current_template.as_mut() {
                let parts: Vec<&str> = line.splitn(2, '=').collect();
                let k = parts[0].trim();
                let v = parts[1].trim().trim_matches(|c| c == '\'' || c == '"');
                t.insert(k.to_string(), v.to_string());
            }
        }
    }
    if let Some(t) = current_template {
        templates.push(t);
    }

    let matugen_dir = expand_tilde("~/.config/matugen/");
    for tmpl in templates {
        let input_p = tmpl.get("input_path");
        let output_p = tmpl.get("output_path");
        if input_p.is_none() || output_p.is_none() {
            continue;
        }

        let in_path = matugen_dir.join(input_p.unwrap().replace("./", ""));
        let out_path_str = expand_tilde(output_p.unwrap()).to_string_lossy().replace("material-you", &dir_name);
        let out_path = Path::new(&out_path_str);

        if !in_path.exists() {
            println!("Warning: template not found {:?}", in_path);
            continue;
        }

        let content = fs::read_to_string(&in_path).unwrap();
        let is_dark = in_path.to_string_lossy().contains("dark");
        let new_content = process_template(content, &light_map, &dark_map, is_dark);

        if let Some(parent) = out_path.parent() {
            fs::create_dir_all(parent).unwrap();
        }
        fs::write(out_path, new_content).unwrap();
        println!("Generated {:?}", out_path);
    }

    println!("Theme '{}' generated successfully!", theme_name);
}

pub fn list() {
    let theme_dir = expand_tilde("~/.config/color-schemes/");
    if !theme_dir.exists() {
        eprintln!("Error: {:?} not found.", theme_dir);
        exit(1);
    }

    let mut themes = Vec::new();
    if let Ok(entries) = fs::read_dir(&theme_dir) {
        for entry in entries.flatten() {
            if entry.path().is_dir() {
                let name = entry.file_name().to_string_lossy().to_string();
                if name != "current" && name != "currect" {
                    themes.push(name);
                }
            }
        }
    }

    if themes.is_empty() {
        println!("No themes found.");
        return;
    }

    themes.sort();
    println!("Available Themes:");
    for t in themes {
        println!("  - {}", t);
    }
}

pub fn toggle() {
    let current_link = expand_tilde("~/.config/color-schemes/current/quickTheme.qml");
    if !current_link.exists() {
        eprintln!("No current theme linked.");
        exit(1);
    }

    let real_path = fs::read_link(&current_link).unwrap_or(current_link);
    let real_path_str = real_path.to_string_lossy();
    let parts: Vec<&str> = real_path_str.split('/').collect();

    if parts.len() < 3 {
        eprintln!("Invalid theme path structure.");
        exit(1);
    }

    let current_mode = parts[parts.len() - 2];
    let current_theme = parts[parts.len() - 3];

    let new_mode = if current_mode == "dark" { "light" } else { "dark" };
    let set_script = expand_tilde("~/.config/color-schemes/set-theme.sh");

    println!("Toggling to {} ({})", current_theme, new_mode);
    let _ = Command::new(set_script)
        .arg(current_theme)
        .arg(new_mode)
        .spawn();
}

pub fn set(name: &str, mode: Option<&str>) {
    let mode_str = if let Some(m) = mode {
        m.to_string()
    } else {
        let current_link = expand_tilde("~/.config/color-schemes/current/quickTheme.qml");
        if current_link.exists() {
            if let Ok(real_path) = std::fs::read_link(&current_link) {
                let real_path_str = real_path.to_string_lossy();
                let parts: Vec<&str> = real_path_str.split('/').collect();
                if parts.len() >= 3 {
                    parts[parts.len() - 2].to_string()
                } else {
                    "dark".to_string()
                }
            } else {
                "dark".to_string()
            }
        } else {
            "dark".to_string()
        }
    };

    let set_script = expand_tilde("~/.config/color-schemes/set-theme.sh");

    println!("Setting theme to {} ({})", name, mode_str);
    let _ = Command::new(set_script)
        .arg(name)
        .arg(&mode_str)
        .spawn();
}
