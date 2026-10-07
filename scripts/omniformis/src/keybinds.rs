//! Keybind combinations.
//!
//! A shortcut is stored as one string holding the whole combination, for example
//! `"$MM + $TM + T"`. This module mirrors `hypr/modules/keybind_engine.lua`: the same
//! variables are expanded in the same way, so what the CLI and the settings app report is
//! exactly what Hyprland ends up binding.

use crate::hypr::{self, HyprVarInfo, Source};
use crate::utils::{die, emit};
use regex::Regex;
use std::collections::{BTreeMap, HashMap, HashSet};

/// Modifier spellings Hyprland understands and the name they normalise to.
const MODIFIERS: [(&str, &str); 14] = [
    ("SUPER", "SUPER"),
    ("WIN", "SUPER"),
    ("LOGO", "SUPER"),
    ("META", "SUPER"),
    ("MOD4", "SUPER"),
    ("CTRL", "CTRL"),
    ("CONTROL", "CTRL"),
    ("ALT", "ALT"),
    ("MOD1", "ALT"),
    ("SHIFT", "SHIFT"),
    ("CAPS", "CAPS"),
    ("MOD2", "MOD2"),
    ("MOD3", "MOD3"),
    ("MOD5", "MOD5"),
];

/// Values `{n}` expands to when checking a combination for conflicts.
const PLACEHOLDER_VALUES: [&str; 10] = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"];

pub fn canonical_modifier(word: &str) -> Option<&'static str> {
    let upper = word.to_uppercase();
    MODIFIERS.iter().find(|(name, _)| *name == upper).map(|(_, c)| *c)
}

pub struct Resolver {
    vars: HashMap<String, String>,
    var_ref: Regex,
    placeholder: Regex,
}

impl Resolver {
    /// Builds the variable table from the contents of `variables.lua`.
    pub fn from_variables(variables_lua: &str) -> Self {
        let parsed = hypr::parse_variables(variables_lua);
        let mut vars: HashMap<String, String> = HashMap::new();

        // Directional keys: the home row with vim keys on, the arrow keys otherwise
        let vim = parsed.get("vimkeys").map_or(true, |v| v.val != "false");
        let pick = |key: &str, default: &str| -> String {
            parsed.get(key).map_or_else(|| default.to_string(), |v| v.val.clone())
        };
        vars.insert("left".into(), if vim { pick("VimLeftKey", "m") } else { "left".into() });
        vars.insert("right".into(), if vim { pick("VimRightKey", "i") } else { "right".into() });
        vars.insert("up".into(), if vim { pick("VimUpKey", "e") } else { "up".into() });
        vars.insert("down".into(), if vim { pick("VimDownKey", "n") } else { "down".into() });

        // Every string in variables.lua can be used as $name and may override the above
        for (name, info) in &parsed {
            if info.val_type == "string" {
                vars.insert(name.clone(), info.val.clone());
            }
        }

        Resolver {
            vars,
            var_ref: Regex::new(r"^\$\{?([A-Za-z0-9_]+)\}?$").unwrap(),
            placeholder: Regex::new(r"\{([A-Za-z0-9]+)\}").unwrap(),
        }
    }

    pub fn variables(&self) -> &HashMap<String, String> {
        &self.vars
    }

    fn expand(&self, spec: &str, subs: &HashMap<&str, &str>, depth: usize) -> Result<Vec<String>, String> {
        if depth > 8 {
            return Err(format!("variables nest too deeply in '{}'", spec));
        }
        let mut out = Vec::new();
        for raw in spec.split('+') {
            let token = raw.trim();
            if token.is_empty() {
                continue;
            }
            let mut name = self.var_ref.captures(token).map(|c| c[1].to_string());
            // A bare word only counts as a variable when it holds a modifier (MM -> SUPER)
            if name.is_none() {
                if let Some(value) = self.vars.get(token) {
                    if canonical_modifier(value).is_some() {
                        name = Some(token.to_string());
                    }
                }
            }

            if let Some(name) = name {
                let value = self
                    .vars
                    .get(&name)
                    .ok_or_else(|| format!("unknown variable ${}", name))?;
                out.extend(self.expand(value, subs, depth + 1)?);
            } else {
                let mut missing = None;
                let replaced = self.placeholder.replace_all(token, |caps: &regex::Captures| {
                    match subs.get(&caps[1]) {
                        Some(v) => v.to_string(),
                        None => {
                            missing = Some(caps[1].to_string());
                            caps[0].to_string()
                        }
                    }
                });
                if let Some(m) = missing {
                    return Err(format!("no value given for {{{}}}", m));
                }
                out.push(replaced.to_string());
            }
        }
        Ok(out)
    }

    /// `"$MM + $TM + T"` becomes `"SUPER + SHIFT + T"`.
    pub fn resolve(&self, spec: &str, subs: &HashMap<&str, &str>) -> Result<String, String> {
        let tokens = self.expand(spec, subs, 0)?;
        let mut mods: Vec<&str> = Vec::new();
        let mut key: Option<String> = None;
        for token in &tokens {
            if let Some(canonical) = canonical_modifier(token) {
                if !mods.contains(&canonical) {
                    mods.push(canonical);
                }
            } else if let Some(existing) = &key {
                return Err(format!("'{}' has more than one key ({}, {})", spec, existing, token));
            } else {
                key = Some(token.clone());
            }
        }
        let key = key.ok_or_else(|| format!("'{}' has no key", spec))?;
        let mut parts: Vec<String> = mods.iter().map(|m| m.to_string()).collect();
        parts.push(key);
        Ok(parts.join(" + "))
    }

    /// Every concrete combination a bind can produce: one, or ten when it uses `{n}`.
    pub fn resolve_all(&self, spec: &str) -> Result<Vec<String>, String> {
        if self.placeholder.is_match(spec) {
            PLACEHOLDER_VALUES
                .iter()
                .map(|n| self.resolve(spec, &HashMap::from([("n", *n)])))
                .collect()
        } else {
            self.resolve(spec, &HashMap::new()).map(|r| vec![r])
        }
    }
}

/// Rejects a combination that the engine would not be able to bind.
pub fn validate(variables_lua: &str, spec: &str) -> Result<(), String> {
    if spec.trim().is_empty() {
        return Ok(()); // an empty combination disables the shortcut
    }
    Resolver::from_variables(variables_lua).resolve_all(spec).map(|_| ())
}

/// Order, category and description of every entry of `keybinds.lua`, straight from the file.
fn ordered_binds(keybinds_lua: &str) -> Vec<String> {
    let line = Regex::new(r"^\s*([A-Za-z0-9_]+)\s*=\s*\x22").unwrap();
    keybinds_lua
        .lines()
        .filter_map(|l| line.captures(l).map(|c| c[1].to_string()))
        .collect()
}

/// Two binds clash when they resolve to the same modifiers and key.
fn signature(resolved: &str) -> String {
    let mut mods: Vec<String> = Vec::new();
    let mut key = String::new();
    for part in resolved.split('+').map(|p| p.trim()) {
        if canonical_modifier(part).is_some() {
            mods.push(canonical_modifier(part).unwrap_or("").to_string());
        } else {
            key = part.to_lowercase();
        }
    }
    mods.sort();
    format!("{}|{}", mods.join("+"), key)
}

pub struct Entry {
    pub key: String,
    pub category: String,
    pub description: String,
    pub combo: String,
    pub resolved: Vec<String>,
    pub error: Option<String>,
    pub active: bool,
}

/// A variable that feeds the shortcuts: a modifier such as `MM`, or a navigation key.
pub struct Setting {
    pub key: String,
    pub category: String,
    pub description: String,
    pub value: String,
    /// "modifier" when the value is a modifier name, otherwise "key"
    pub kind: &'static str,
}

pub struct Analysis {
    pub resolver: Resolver,
    pub settings: Vec<Setting>,
    pub layout: String,
    pub entries: Vec<Entry>,
    /// entry index -> keys of the binds it clashes with
    pub conflicts: BTreeMap<usize, Vec<String>>,
}

pub fn analyze() -> Analysis {
    let variables_lua = hypr::read_source(Source::Variables)
        .unwrap_or_else(|| die("variables.lua not found"));
    let keybinds_lua = hypr::read_source(Source::Keybinds)
        .unwrap_or_else(|| die("keybinds.lua not found"));

    let resolver = Resolver::from_variables(&variables_lua);
    let parsed: HashMap<String, HyprVarInfo> = hypr::parse_variables(&keybinds_lua);
    let variables = hypr::parse_variables(&variables_lua);
    let layout = variables.get("Layout").map(|v| v.val.to_lowercase()).unwrap_or_default();

    let mut entries: Vec<Entry> = Vec::new();
    for key in ordered_binds(&keybinds_lua) {
        let Some(info) = parsed.get(&key) else { continue };
        let (resolved, error) = if info.val.trim().is_empty() {
            (Vec::new(), None)
        } else {
            match resolver.resolve_all(&info.val) {
                Ok(r) => (r, None),
                Err(e) => (Vec::new(), Some(e)),
            }
        };
        // Layout binds only exist while their layout is the active one
        let active = match info.category.strip_prefix("Layout ") {
            Some(name) => name.to_lowercase() == layout,
            None => true,
        };
        entries.push(Entry {
            key: key.clone(),
            category: info.category.clone(),
            description: info.help.clone(),
            combo: info.val.clone(),
            resolved,
            error,
            active,
        });
    }

    // Clashes only matter between binds that are actually registered
    let mut owners: HashMap<String, Vec<usize>> = HashMap::new();
    for (i, e) in entries.iter().enumerate().filter(|(_, e)| e.active) {
        let mut seen = HashSet::new();
        for r in &e.resolved {
            let sig = signature(r);
            if seen.insert(sig.clone()) {
                owners.entry(sig).or_default().push(i);
            }
        }
    }
    let mut conflicts: BTreeMap<usize, Vec<String>> = BTreeMap::new();
    for indexes in owners.values().filter(|v| v.len() > 1) {
        for &i in indexes {
            let others = indexes.iter().filter(|&&j| j != i).map(|&j| entries[j].key.clone());
            conflicts.entry(i).or_default().extend(others);
        }
    }
    for names in conflicts.values_mut() {
        names.sort();
        names.dedup();
    }

    // The variables shortcuts are built from, found by their category in variables.lua
    let mut settings = Vec::new();
    for key in ordered_binds(&variables_lua) {
        let Some(info) = variables.get(&key) else { continue };
        if info.val_type == "string" && (info.category == "Modifiers" || info.category == "Navigation Keys") {
            settings.push(Setting {
                key: key.clone(),
                category: info.category.clone(),
                description: info.help.clone(),
                value: info.val.clone(),
                kind: if canonical_modifier(&info.val).is_some() { "modifier" } else { "key" },
            });
        }
    }

    Analysis { resolver, settings, layout, entries, conflicts }
}

/// The binds `key` currently clashes with, empty when it is free.
pub fn conflicts_for(key: &str) -> Vec<String> {
    let a = analyze();
    a.entries
        .iter()
        .position(|e| e.key == key)
        .and_then(|i| a.conflicts.get(&i).cloned())
        .unwrap_or_default()
}

pub fn list(json: bool) {
    let Analysis { resolver, settings, layout, entries, conflicts } = analyze();

    if json {
        let mut vars: BTreeMap<&String, &String> = BTreeMap::new();
        for (k, v) in resolver.variables() {
            vars.insert(k, v);
        }
        let binds: Vec<serde_json::Value> = entries
            .iter()
            .enumerate()
            .map(|(i, e)| {
                let c = conflicts.get(&i).cloned().unwrap_or_default();
                serde_json::json!({
                    "key": e.key,
                    "category": e.category,
                    "description": e.description,
                    "combo": e.combo,
                    "resolved": e.resolved,
                    "conflicts": c,
                    "active": e.active,
                    "error": e.error,
                })
            })
            .collect();
        let settings: Vec<serde_json::Value> = settings
            .iter()
            .map(|st| {
                serde_json::json!({
                    "key": st.key,
                    "category": st.category,
                    "description": st.description,
                    "value": st.value,
                    "kind": st.kind,
                })
            })
            .collect();
        let out = serde_json::json!({ "layout": layout, "variables": vars, "settings": settings, "binds": binds });
        emit(&serde_json::to_string_pretty(&out).unwrap());
        return;
    }

    let mut last_category = String::new();
    for (i, e) in entries.iter().enumerate() {
        if e.category != last_category {
            emit(&format!("\n{}", e.category));
            last_category = e.category.clone();
        }
        let shown = if let Some(err) = &e.error {
            format!("! {}", err)
        } else if e.resolved.is_empty() {
            "(disabled)".to_string()
        } else if e.resolved.len() > 1 {
            format!("{} ... {}", e.resolved[0], e.resolved[e.resolved.len() - 1])
        } else {
            e.resolved[0].clone()
        };
        let mut note = String::new();
        if !e.active {
            note.push_str("  [inactive layout]");
        }
        if let Some(names) = conflicts.get(&i) {
            note.push_str(&format!("  [conflicts with {}]", names.join(", ")));
        }
        emit(&format!("  {:<30} {:<34}{}", e.key, shown, note));
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    const VARS: &str = "return {\n    vimkeys = true,\n    MM = \"SUPER\",\n    SM = \"ALT\",\n    TM = \"SHIFT\",\n    QM = \"CTRL\",\n    VimLeftKey = \"m\",\n    VimRightKey = \"i\",\n    VimUpKey = \"e\",\n    VimDownKey = \"n\",\n}\n";

    fn r(spec: &str) -> Result<String, String> {
        Resolver::from_variables(VARS).resolve(spec, &HashMap::from([("n", "3")]))
    }

    #[test]
    fn expands_variables_like_the_lua_engine() {
        assert_eq!(r("$MM + $TM + T").unwrap(), "SUPER + SHIFT + T");
        assert_eq!(r("MM + SM + $left").unwrap(), "SUPER + ALT + m");
        assert_eq!(r("SUPER + shift + F").unwrap(), "SUPER + SHIFT + F");
        assert_eq!(r("$MM + {n}").unwrap(), "SUPER + 3");
        assert_eq!(r("XF86AudioPlay").unwrap(), "XF86AudioPlay");
        assert_eq!(r("$QM + $MM + $QM + 5").unwrap(), "CTRL + SUPER + 5");
    }

    #[test]
    fn bare_words_are_keys_unless_they_hold_a_modifier() {
        // `left` is the arrow key, `$left` the directional variable
        assert_eq!(r("$MM + left").unwrap(), "SUPER + left");
        assert_eq!(r("$MM + $left").unwrap(), "SUPER + m");
    }

    #[test]
    fn arrow_keys_when_vim_keys_are_off() {
        let off = VARS.replace("vimkeys = true", "vimkeys = false");
        let res = Resolver::from_variables(&off);
        assert_eq!(res.resolve("$MM + $left", &HashMap::new()).unwrap(), "SUPER + left");
    }

    #[test]
    fn rejects_bad_combinations() {
        assert!(r("$MM + $nope + T").unwrap_err().contains("unknown variable"));
        assert!(r("T + Y").unwrap_err().contains("more than one key"));
        assert!(r("$MM").unwrap_err().contains("no key"));
        assert!(Resolver::from_variables(VARS).resolve("$MM + {n}", &HashMap::new()).is_err());
    }

    #[test]
    fn placeholder_binds_expand_for_conflict_checks() {
        let all = Resolver::from_variables(VARS).resolve_all("$QM + {n}").unwrap();
        assert_eq!(all.len(), 10);
        assert_eq!(all[0], "CTRL + 0");
    }

    #[test]
    fn empty_combination_disables_the_bind() {
        assert!(validate(VARS, "").is_ok());
        assert!(validate(VARS, "$MM + $bogus + T").is_err());
    }

    #[test]
    fn signature_ignores_order_and_case() {
        assert_eq!(signature("SUPER + SHIFT + F"), signature("shift + super + f"));
        assert_ne!(signature("SUPER + F"), signature("SUPER + SHIFT + F"));
    }
}
