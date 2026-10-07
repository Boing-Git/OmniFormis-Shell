use std::fs;
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::process::exit;
use std::thread::sleep;
use std::time::{Duration, SystemTime};

pub fn expand_tilde<P: AsRef<Path>>(path: P) -> PathBuf {
    let p = path.as_ref();
    if !p.starts_with("~") {
        return p.to_path_buf();
    }

    let mut expanded = dirs::home_dir().unwrap_or_else(|| PathBuf::from("/"));
    if p != Path::new("~") {
        expanded.push(p.strip_prefix("~").unwrap());
    }
    expanded
}

/// Root of the dotfiles checkout. `OMNIFORMIS_DOTFILES` overrides the default `~/Dotfiles`.
pub fn dotfiles_dir() -> PathBuf {
    match std::env::var_os("OMNIFORMIS_DOTFILES") {
        Some(p) if !p.is_empty() => PathBuf::from(p),
        _ => expand_tilde("~/Dotfiles"),
    }
}

/// True when side effects (restarting Quickshell, reloading Hyprland) must be skipped.
pub fn no_side_effects() -> bool {
    std::env::var_os("OMNIFORMIS_NO_SIDE_EFFECTS").map_or(false, |v| !v.is_empty() && v != "0")
}

/// Print a line to stdout and exit quietly when the reader went away (`omniformis ... | head`).
pub fn emit(line: &str) {
    if writeln!(io::stdout(), "{}", line).is_err() {
        exit(0);
    }
}

/// Print an error to stderr and exit with a non-zero status.
pub fn die(msg: &str) -> ! {
    eprintln!("Error: {}", msg);
    exit(1);
}

/// Write `content` to `path` atomically (temp file + rename) so a concurrent reader such as
/// Quickshell's file watcher never sees a half-written file. Symlinks are followed so the link
/// itself is preserved.
pub fn write_atomic(path: &Path, content: &str) -> io::Result<()> {
    let target = fs::canonicalize(path).unwrap_or_else(|_| path.to_path_buf());
    let dir = target.parent().unwrap_or_else(|| Path::new("."));
    let name = target
        .file_name()
        .map(|n| n.to_string_lossy().into_owned())
        .unwrap_or_else(|| "file".into());
    let tmp = dir.join(format!(".{}.omniformis.{}.tmp", name, std::process::id()));

    let result = (|| {
        let mut f = fs::File::create(&tmp)?;
        f.write_all(content.as_bytes())?;
        f.sync_all()?;
        if let Ok(meta) = fs::metadata(&target) {
            let _ = fs::set_permissions(&tmp, meta.permissions());
        }
        fs::rename(&tmp, &target)
    })();

    if result.is_err() {
        let _ = fs::remove_file(&tmp);
    }
    result
}

/// Run `f` while holding an advisory lock so parallel `omniformis` calls (the settings UI fires
/// several at once) cannot overwrite each other's read-modify-write cycles.
pub fn with_lock<T>(name: &str, f: impl FnOnce() -> T) -> T {
    let base = std::env::var_os("XDG_RUNTIME_DIR")
        .map(PathBuf::from)
        .unwrap_or_else(std::env::temp_dir);
    let lock_path = base.join(format!("omniformis-{}.lock", name));

    let mut acquired = false;
    for _ in 0..200 {
        match fs::OpenOptions::new().write(true).create_new(true).open(&lock_path) {
            Ok(_) => {
                acquired = true;
                break;
            }
            Err(_) => {
                // A crashed process must not block the CLI forever.
                let stale = fs::metadata(&lock_path)
                    .and_then(|m| m.modified())
                    .ok()
                    .and_then(|t| SystemTime::now().duration_since(t).ok())
                    .map_or(false, |age| age > Duration::from_secs(10));
                if stale {
                    let _ = fs::remove_file(&lock_path);
                } else {
                    sleep(Duration::from_millis(25));
                }
            }
        }
    }

    let out = f();
    if acquired {
        let _ = fs::remove_file(&lock_path);
    }
    out
}

/// Parse a boolean the way people actually type it.
pub fn parse_bool(value: &str) -> Option<bool> {
    match value.trim().to_lowercase().as_str() {
        "true" | "1" | "yes" | "y" | "on" | "t" => Some(true),
        "false" | "0" | "no" | "n" | "off" | "f" => Some(false),
        _ => None,
    }
}

/// Format a number without a spurious `.0` when an integer was given.
pub fn format_number(value: &str) -> Option<String> {
    let num: f64 = value.trim().parse().ok()?;
    if !num.is_finite() {
        return None;
    }
    if num.fract() == 0.0 && !value.contains('.') && !value.to_lowercase().contains('e') {
        Some((num as i64).to_string())
    } else {
        Some(num.to_string())
    }
}

/// Reject the strings a JavaScript caller produces when a property was never declared.
/// This is how `liquidGlassPreset = "undefined"` ended up in the Hyprland config.
pub fn is_bogus_literal(value: &str) -> bool {
    matches!(value.trim(), "undefined" | "null" | "NaN")
}
