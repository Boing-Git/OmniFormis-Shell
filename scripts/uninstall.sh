#!/usr/bin/env bash
#
# OmniFormis Shell - uninstall and restore.
#
# Everything this script touches comes from the manifest that install.sh wrote
# to ${XDG_STATE_HOME:-~/.local/state}/omniformis/installed.tsv:
#   * entries with a backup are restored from the timestamped backup directory,
#   * entries this project created (and that the user did not modify since) can
#     be removed,
#   * anything that is not in the manifest is never touched.
#
# Usage:
#   scripts/uninstall.sh --list                 # what was installed
#   scripts/uninstall.sh --sessions             # available backup sets
#   scripts/uninstall.sh --restore              # restore the newest backup set
#   scripts/uninstall.sh --restore 20260917-111500
#   scripts/uninstall.sh --remove               # remove files created by install.sh
#   scripts/uninstall.sh --remove --dry-run
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"

if [[ ! -f "$REPO_DIR/install/lib/common.sh" ]]; then
    printf 'error: scripts/uninstall.sh needs the repository (install/lib is missing).\n' >&2
    printf '       clone https://github.com/Boing-Git/OmniFormis-Shell and run it from there.\n' >&2
    exit 1
fi

# shellcheck source=../install/lib/common.sh
source "$REPO_DIR/install/lib/common.sh"
# shellcheck source=../install/lib/detect.sh
source "$REPO_DIR/install/lib/detect.sh"
# shellcheck source=../install/lib/backup.sh
source "$REPO_DIR/install/lib/backup.sh"

OMNI_MODE="list"
OMNI_SESSION="latest"
OMNI_ACTION="restore"
OMNI_PURGE=0
OMNI_RESTORED=0
OMNI_REMOVED=0
OMNI_KEPT=0

usage() {
    cat <<'EOF'
OmniFormis Shell - uninstall and restore

Usage: scripts/uninstall.sh [options]

Options:
  --list                 show the installation manifest (default)
  --sessions             list the timestamped backup directories
  --restore [SESSION]    restore every backed up file (SESSION defaults to latest)
  --remove [SESSION]     restore the backup and remove files created by install.sh
  --purge                also delete the state directory (manifest and backups)
  --dry-run              only show what would happen
  -y, --yes              do not ask for confirmation
  --force                overwrite files that changed since the installation
  -h, --help             this help

Exit codes: 0 ok, 1 usage, 4 aborted, 5 backup problem, 6 failure.
EOF
}

# ---------------------------------------------------------------- manifest io
omni_manifest_exists() {
    [[ -f "$(omni_manifest_path)" ]]
}

omni_manifest_read() {
    if ! omni_manifest_exists; then
        return 1
    fi
    cat -- "$(omni_manifest_path)"
}

# omni_manifest_sessions -> backup session names, newest last
omni_manifest_sessions() {
    local root
    root="$(omni_backup_root_dir)"
    if [[ ! -d "$root" ]]; then
        return 0
    fi
    find "$root" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort || true
}

omni_latest_session() {
    local sessions
    sessions="$(omni_manifest_sessions)"
    if [[ -z "$sessions" ]]; then
        printf '\n'
        return 0
    fi
    printf '%s\n' "$sessions" | tail -n 1
}

# omni_target_unmodified <path> <recorded-hash>
omni_target_unmodified() {
    local path="$1" recorded="$2" current
    case "$recorded" in
        ''|'-'|'dir'|'symlink') return 0 ;;
    esac
    if [[ ! -e "$path" && ! -L "$path" ]]; then
        return 0
    fi
    if [[ -d "$path" ]]; then
        current="$(omni_tree_hash "$path")"
    elif [[ -L "$path" ]]; then
        return 0
    else
        current="$(omni_hash "$path")"
    fi
    [[ "$current" == "$recorded" ]]
}

# omni_remove_path <path> - refuses anything that is not inside $HOME
omni_remove_path() {
    local path="$1"
    if [[ -z "$path" || "$path" == "/" || "$path" == "$HOME" || "$path" == "$HOME/" ]]; then
        omni_error "refusing to remove '$path'"
        return 1
    fi
    case "$path" in
        "$HOME"/*) ;;
        *)
            omni_error "refusing to remove '$path': only paths inside \$HOME are managed by this project"
            return 1
            ;;
    esac
    omni_run_checked "$OMNI_EXIT_FAILURE" rm -rf -- "$path"
}

# ------------------------------------------------------------------- actions
omni_do_list() {
    local ts action target source backup hash note
    if ! omni_manifest_exists; then
        omni_warn "No manifest at $(omni_manifest_path); nothing has been installed by install.sh."
        return 0
    fi
    omni_step "Installed by install.sh (manifest: $(omni_manifest_path))"
    printf '%-20s %-14s %-44s %-12s %s\n' TIMESTAMP ACTION TARGET BACKUP NOTE
    while IFS=$'\t' read -r ts action target source backup hash note; do
        [[ -z "${target:-}" ]] && continue
        printf '%-20s %-14s %-44s %-12s %s\n' \
            "$ts" "$action" "$target" "${backup:--}" "${note:--}"
    done <<<"$(omni_manifest_read || true)"
}

omni_do_sessions() {
    local root session
    root="$(omni_backup_root_dir)"
    omni_step "Backup directories under $root"
    while IFS= read -r session; do
        [[ -z "$session" ]] && continue
        printf '  %s\n' "$session"
    done < <(omni_manifest_sessions)
}

# omni_restore_session <session> <also-remove-created>
omni_restore_session() {
    local session="$1" also_remove="$2"
    local ts action target source backup hash note
    local found=0

    if [[ "$session" == "latest" ]]; then
        session="$(omni_latest_session)"
    fi
    if [[ -z "$session" ]]; then
        omni_die "$OMNI_EXIT_BACKUP" "No backup directory found; nothing to restore."
    fi
    if [[ ! -d "$(omni_backup_root_dir)/$session" ]]; then
        omni_die "$OMNI_EXIT_USAGE" "Unknown backup session '$session'. Use --sessions to list them."
    fi

    omni_step "Restoring backup set $session"
    while IFS=$'\t' read -r ts action target source backup hash note; do
        [[ -z "${target:-}" ]] && continue
        [[ "$backup" == *"/$session/"* ]] || continue
        found=$((found + 1))
        if ! omni_target_unmodified "$target" "$hash" && [[ "$OMNI_FORCE_OVERWRITE" != "1" ]]; then
            omni_warn "$target changed after the installation; keeping the current version."
            omni_note "  restore it manually with: cp -a -- '$backup' '$target'"
            omni_note "  or re-run with --force"
            OMNI_KEPT=$((OMNI_KEPT + 1))
            continue
        fi
        if ! omni_confirm "Restore $target?" y; then
            OMNI_KEPT=$((OMNI_KEPT + 1))
            continue
        fi
        omni_remove_path "$target" || continue
        omni_run_checked "$OMNI_EXIT_FAILURE" cp -a -- "$backup" "$target"
        omni_ok "restored $target"
        OMNI_RESTORED=$((OMNI_RESTORED + 1))
    done <<<"$(omni_manifest_read || true)"

    if [[ "$also_remove" == "1" ]]; then
        omni_remove_created
    fi

    if (( found == 0 )); then
        omni_warn "The manifest has no entry for session $session."
    fi
}

# omni_remove_created
# Removes only the files this project created (no backup existed) and that are
# still exactly as they were installed.
omni_remove_created() {
    local ts action target source backup hash note
    omni_step "Removing files created by install.sh"

    while IFS=$'\t' read -r ts action target source backup hash note; do
        [[ -z "${target:-}" ]] && continue
        [[ "$backup" == "-" ]] || continue
        [[ "$action" == "create" || "$action" == "install-binary" ]] || continue

        if ! omni_target_unmodified "$target" "$hash"; then
            omni_warn "$target was modified since the installation; keeping it."
            OMNI_KEPT=$((OMNI_KEPT + 1))
            continue
        fi
        if ! omni_confirm "Remove $target?" y; then
            OMNI_KEPT=$((OMNI_KEPT + 1))
            continue
        fi
        if omni_remove_path "$target"; then
            omni_ok "removed $target"
            OMNI_REMOVED=$((OMNI_REMOVED + 1))
        fi
    done <<<"$(omni_manifest_read || true)"
}

omni_do_purge() {
    local root
    root="$(omni_state_root)"
    if ! omni_confirm "Delete $root (manifest and every backup)?" n; then
        omni_note "Kept $root"
        return 0
    fi
    omni_remove_path "$root" && omni_ok "removed $root"
}

# ---------------------------------------------------------------------- main
main() {
    while (( $# > 0 )); do
        case "$1" in
            --list)
                OMNI_MODE="list"
                shift
                ;;
            --sessions)
                OMNI_MODE="sessions"
                shift
                ;;
            --restore)
                OMNI_MODE="restore"
                if [[ "${2:-}" != "" && "${2:0:2}" != "--" ]]; then
                    OMNI_SESSION="$2"
                    shift
                fi
                shift
                ;;
            --remove)
                OMNI_MODE="restore"
                OMNI_ACTION="remove"
                if [[ "${2:-}" != "" && "${2:0:2}" != "--" ]]; then
                    OMNI_SESSION="$2"
                    shift
                fi
                shift
                ;;
            --purge)
                OMNI_PURGE=1
                shift
                ;;
            --dry-run)
                OMNI_DRY_RUN=1
                shift
                ;;
            -y|--yes)
                OMNI_ASSUME_YES=1
                shift
                ;;
            --force)
                OMNI_FORCE_OVERWRITE=1
                shift
                ;;
            -h|--help)
                usage
                exit "$OMNI_EXIT_OK"
                ;;
            *)
                omni_die "$OMNI_EXIT_USAGE" "Unknown option '$1' (see --help)."
                ;;
        esac
    done

    omni_init_logging "$(omni_state_root)/logs"

    case "$OMNI_MODE" in
        list)
            omni_do_list
            ;;
        sessions)
            omni_do_sessions
            ;;
        restore)
            local also_remove=0
            if [[ "$OMNI_ACTION" == "remove" ]]; then
                also_remove=1
            fi
            omni_restore_session "$OMNI_SESSION" "$also_remove"
            ;;
    esac

    if (( OMNI_PURGE == 1 )); then
        omni_do_purge
    fi

    printf '\n'
    omni_step "Summary"
    printf '  restored: %s\n' "$OMNI_RESTORED"
    printf '  removed:  %s\n' "$OMNI_REMOVED"
    printf '  kept:     %s\n' "$OMNI_KEPT"
    omni_note "System packages installed by install.sh are not removed automatically."
    omni_note "See docs/BACKUP-AND-RESTORE.md for the package removal hints."
}

main "$@"
