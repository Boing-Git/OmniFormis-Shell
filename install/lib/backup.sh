#!/usr/bin/env bash
# shellcheck shell=bash
#
# Backup and manifest handling.
#
# Rules enforced here:
#   * an existing file is never overwritten without being copied into a
#     timestamped backup directory first;
#   * every file the installer creates, overwrites or deletes is recorded in a
#     manifest so that scripts/uninstall.sh can undo exactly those changes and
#     nothing else.

if [[ -n "${OMNI_BACKUP_SOURCED:-}" ]]; then
    return 0
fi
OMNI_BACKUP_SOURCED=1

OMNI_BACKUP_DIR="${OMNI_BACKUP_DIR:-}"
OMNI_MANIFEST_COUNT=0

# omni_manifest_path -> <state>/installed.tsv
omni_manifest_path() {
    printf '%s\n' "$(omni_state_root)/installed.tsv"
}

# omni_backup_root_dir -> <state>/backups
omni_backup_root_dir() {
    printf '%s\n' "$(omni_state_root)/backups"
}

# omni_backup_init
# Creates a fresh timestamped backup directory and its manifest.
omni_backup_init() {
    if [[ -n "$OMNI_BACKUP_DIR" ]]; then
        return 0
    fi

    if [[ "$OMNI_DRY_RUN" == "1" ]]; then
        OMNI_BACKUP_DIR="$(omni_backup_root_dir)/DRY-RUN"
        omni_info "dry-run: would create backup directory $OMNI_BACKUP_DIR"
        return 0
    fi

    local root stamp dir
    root="$(omni_backup_root_dir)"
    stamp="$(omni_timestamp)"
    dir="$root/$stamp"

    local suffix=1
    while [[ -e "$dir" ]]; do
        dir="$root/${stamp}-${suffix}"
        suffix=$((suffix + 1))
    done

    mkdir -p -- "$dir" || return "$OMNI_EXIT_BACKUP"
    OMNI_BACKUP_DIR="$dir"

    {
        printf 'OmniFormis Shell backup\n'
        printf 'created: %s\n' "$(date '+%Y-%m-%d %H:%M:%S %z')"
        printf 'host: %s\n' "$(uname -n)"
        printf 'environment: %s' "$(omni_describe_environment)"
        printf 'restore: bash scripts/uninstall.sh --restore %s\n' "$(basename "$dir")"
    } >"$dir/INFO.txt" 2>/dev/null || true

    omni_ok "Backup directory: $OMNI_BACKUP_DIR"
}

# omni_manifest_add <action> <target> <source> <backup> <hash> <note>
omni_manifest_add() {
    local action="$1" target="$2" source="${3:--}" backup="${4:--}" hash="${5:--}" note="${6:--}"

    # Tabs and newlines would corrupt the manifest; replace them.
    note="${note//$'\t'/ }"
    note="${note//$'\n'/ }"

    OMNI_MANIFEST_COUNT=$((OMNI_MANIFEST_COUNT + 1))

    if [[ "$OMNI_DRY_RUN" == "1" ]]; then
        omni_info "dry-run: manifest += $action $target (backup: $backup)"
        return 0
    fi

    local manifest line
    manifest="$(omni_manifest_path)"
    mkdir -p -- "$(dirname -- "$manifest")"
    line="$(printf '%s\t%s\t%s\t%s\t%s\t%s\t%s' \
        "$(date '+%Y-%m-%dT%H:%M:%S')" "$action" "$target" "$source" "$backup" "$hash" "$note")"
    printf '%s\n' "$line" >>"$manifest"

    if [[ -n "$OMNI_BACKUP_DIR" && -d "$OMNI_BACKUP_DIR" ]]; then
        printf '%s\n' "$line" >>"$OMNI_BACKUP_DIR/manifest.tsv"
    fi
}

# omni_backup_relative <path> -> path relative to the backup root
# $HOME content is stored as ".config/..." so a restore is a plain copy back.
# Anything outside $HOME goes into "__external__/<absolute path>".
omni_backup_relative() {
    local path="$1"
    if [[ "$path" == "$HOME"/* ]]; then
        printf '%s\n' "${path#"$HOME"/}"
        return 0
    fi
    printf '__external__%s\n' "$path"
}

# omni_state_init : create the state directory and start logging
omni_state_init() {
    local root
    root="$(omni_state_root)"
    omni_ensure_dir "$root"
    omni_init_logging "$root/logs"
}

# omni_backup_path <path> [reason]
# Copies an existing file/directory into the timestamped backup directory.
# Returns 0 when the path was backed up (or did not exist), non-zero when the
# backup itself failed - callers must not overwrite anything in that case.
omni_backup_path() {
    local path="$1" note="${2:-}"
    local is_symlink=0

    omni_backup_init

    if [[ ! -e "$path" && ! -L "$path" ]]; then
        return 0
    fi

    [[ -L "$path" ]] && is_symlink=1

    local rel dest
    rel="$(omni_backup_relative "$path")"
    dest="$OMNI_BACKUP_DIR/$rel"

    if [[ "$OMNI_DRY_RUN" == "1" ]]; then
        omni_info "dry-run: would back up $path -> $dest"
        return 0
    fi

    if ! mkdir -p -- "$(dirname -- "$dest")"; then
        omni_error "Could not create backup directory for $path"
        return "$OMNI_EXIT_BACKUP"
    fi

    # -a keeps permissions, timestamps and symlinks as they are.
    if ! cp -a -- "$path" "$dest" 2>>"${OMNI_LOG_FILE:-/dev/null}"; then
        omni_error "Backup of $path failed; nothing was changed."
        return "$OMNI_EXIT_BACKUP"
    fi

    local kind="file"
    if [[ "$is_symlink" == "1" ]]; then
        kind="symlink"
    elif [[ -d "$path" ]]; then
        kind="directory"
    fi
    omni_info "Backed up $path ($kind) -> $dest"

    local hash="-"
    if [[ "$kind" == "file" ]]; then
        hash="$(omni_hash "$path")"
        [[ -z "$hash" ]] && hash="-"
    fi

    omni_manifest_add "backup" "$path" "-" "$dest" "$hash" "${note:-pre-existing configuration}"
    return 0
}

# omni_record_install <action> <target> <source> <note>
# Records a path that the installer created or replaced (backup recorded
# separately by omni_backup_path).
omni_record_install() {
    local action="$1" target="$2" source="$3" note="${4:-}"
    local hash="-" backup="-"

    if [[ -f "$target" && ! -L "$target" ]]; then
        hash="$(omni_hash "$target")"
        [[ -z "$hash" ]] && hash="-"
    elif [[ -d "$target" ]]; then
        hash="$(omni_tree_hash "$target")"
        [[ -z "$hash" ]] && hash="dir"
    elif [[ -L "$target" ]]; then
        hash="symlink"
    fi

    if [[ -n "$OMNI_BACKUP_DIR" ]]; then
        local rel candidate
        rel="$(omni_backup_relative "$target")"
        candidate="$OMNI_BACKUP_DIR/$rel"
        if [[ -e "$candidate" || -L "$candidate" ]]; then
            backup="$candidate"
        fi
    fi

    omni_manifest_add "$action" "$target" "$source" "$backup" "$hash" "$note"
}

# omni_backup_list -> prints known backups, newest first
omni_backup_list() {
    local root
    root="$(omni_backup_root_dir)"
    if [[ ! -d "$root" ]]; then
        omni_note "No backups found in $root"
        return 0
    fi
    printf '%s\n' "Backups in $root:"
    find "$root" -maxdepth 1 -mindepth 1 -type d -printf '  %f\n' 2>/dev/null | sort -r
}

# omni_backup_resolve <timestamp|latest|path> -> absolute backup directory
omni_backup_resolve() {
    local wanted="$1" root
    root="$(omni_backup_root_dir)"

    if [[ -z "$wanted" || "$wanted" == "latest" ]]; then
        find "$root" -maxdepth 1 -mindepth 1 -type d -printf '%f\n' 2>/dev/null | sort -r | head -n1
        return 0
    fi
    if [[ -d "$wanted" ]]; then
        printf '%s\n' "$wanted"
        return 0
    fi
    if [[ -d "$root/$wanted" ]]; then
        printf '%s\n' "$root/$wanted"
        return 0
    fi
    printf '\n'
}
