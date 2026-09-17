#!/usr/bin/env bash
# shellcheck shell=bash
#
# Shared helpers for the OmniFormis Shell installer.
#
# This file is *sourced* by install.sh, scripts/install.sh, scripts/uninstall.sh
# and scripts/check-deps.sh - it is never executed directly.

if [[ -n "${OMNI_COMMON_SOURCED:-}" ]]; then
    return 0
fi
OMNI_COMMON_SOURCED=1

# --------------------------------------------------------------- exit codes
# These codes are part of the installer's public interface and are documented
# in docs/INSTALL.md. Automation can rely on them.
# Exit codes used by every entry point. Some are only consumed by sourcing
# scripts, which shellcheck cannot see.
OMNI_EXIT_OK=0           # finished, nothing left to do
OMNI_EXIT_USAGE=1       # bad command line arguments
OMNI_EXIT_UNSUPPORTED=2 # the operating system / distribution is not supported
OMNI_EXIT_DEPENDENCY=3  # a required dependency is missing
OMNI_EXIT_ABORTED=4     # the user declined a step that is required to proceed
OMNI_EXIT_BACKUP=5      # backing up existing configuration failed
OMNI_EXIT_FAILURE=6     # an installation step failed

# Exported so that entry points, sourced modules and CI all share the same
# values (and so that shellcheck sees them as used).
export OMNI_EXIT_OK OMNI_EXIT_USAGE OMNI_EXIT_UNSUPPORTED OMNI_EXIT_DEPENDENCY
export OMNI_EXIT_ABORTED OMNI_EXIT_BACKUP OMNI_EXIT_FAILURE

# ------------------------------------------------------------ global options
# Defaults are provided so that every helper can rely on them even when it is
# sourced by a small wrapper such as scripts/check-deps.sh.
OMNI_ASSUME_YES="${OMNI_ASSUME_YES:-0}"
OMNI_NON_INTERACTIVE="${OMNI_NON_INTERACTIVE:-0}"
OMNI_DRY_RUN="${OMNI_DRY_RUN:-0}"
OMNI_VERBOSE="${OMNI_VERBOSE:-0}"
OMNI_FORCE_OVERWRITE="${OMNI_FORCE_OVERWRITE:-0}"
OMNI_LOG_FILE="${OMNI_LOG_FILE:-}"

# ------------------------------------------------------------------- output
# Colour is only used when it cannot confuse a log or a pipe.
if [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-dumb}" != "dumb" ]]; then
    OMNI_C_RESET=$'\033[0m'
    OMNI_C_BOLD=$'\033[1m'
    OMNI_C_DIM=$'\033[2m'
    OMNI_C_RED=$'\033[31m'
    OMNI_C_GREEN=$'\033[32m'
    OMNI_C_YELLOW=$'\033[33m'
    OMNI_C_BLUE=$'\033[34m'
    OMNI_C_CYAN=$'\033[36m'
else
    OMNI_C_RESET=''
    OMNI_C_BOLD=''
    OMNI_C_DIM=''
    OMNI_C_RED=''
    OMNI_C_GREEN=''
    OMNI_C_YELLOW=''
    OMNI_C_BLUE=''
    OMNI_C_CYAN=''
fi

OMNI_SUMMARY=()

_omni_emit() {
    local tag="$1" colour="$2" stream="$3"
    shift 3
    if [[ "$stream" == "err" ]]; then
        printf '%s%s%s %s\n' "$colour" "$tag" "$OMNI_C_RESET" "$*" >&2
    else
        printf '%s%s%s %s\n' "$colour" "$tag" "$OMNI_C_RESET" "$*"
    fi
    if [[ -n "$OMNI_LOG_FILE" ]]; then
        printf '%s [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$tag" "$*" >>"$OMNI_LOG_FILE" 2>/dev/null || true
    fi
}

omni_info()  { _omni_emit '  ·  ' "$OMNI_C_DIM" out "$@"; }
omni_step()  { _omni_emit ' ==> ' "$OMNI_C_BOLD$OMNI_C_BLUE" out "$@"; }
omni_ok()    { _omni_emit '  ok ' "$OMNI_C_GREEN" out "$@"; }
omni_note()  { _omni_emit '  i  ' "$OMNI_C_CYAN" out "$@"; }
omni_warn()  { _omni_emit '  !  ' "$OMNI_C_YELLOW" err "$@"; }
omni_error() { _omni_emit '  x  ' "$OMNI_C_RED" err "$@"; }

# omni_debug <message> : only printed with -v / --verbose
omni_debug() {
    if [[ "$OMNI_VERBOSE" == "1" ]]; then
        _omni_emit 'debug' "$OMNI_C_DIM" "$*"
    fi
}

# omni_die <exit-code> <message...>
omni_die() {
    local code="$1"
    shift
    omni_error "$@"
    exit "$code"
}

# ------------------------------------------------------------ summary & log
omni_summary_add() {
    OMNI_SUMMARY+=("$1")
}

omni_summary_print() {
    if ((${#OMNI_SUMMARY[@]} == 0)); then
        return 0
    fi
    printf '\n'
    omni_step "Manual steps you may still want to perform"
    local line
    for line in "${OMNI_SUMMARY[@]}"; do
        printf '   - %s\n' "$line"
    done
}

omni_init_logging() {
    local dir="$1"
    if [[ "$OMNI_DRY_RUN" == "1" ]]; then
        OMNI_LOG_FILE=""
        return 0
    fi
    mkdir -p -- "$dir"
    OMNI_LOG_FILE="$dir/install-$(date '+%Y%m%d-%H%M%S').log"
    : >"$OMNI_LOG_FILE"
    omni_info "Logging to $OMNI_LOG_FILE"
}

# ---------------------------------------------------------------- utilities
omni_have() {
    command -v "$1" >/dev/null 2>&1
}

omni_is_interactive() {
    [[ "$OMNI_NON_INTERACTIVE" != "1" && -t 0 && -t 1 ]]
}

# omni_run <command...>
# Runs a command, or only reports it in --dry-run mode. Failures propagate to
# the caller, which decides whether they are fatal.
omni_run() {
    if [[ "$OMNI_DRY_RUN" == "1" ]]; then
        omni_info "dry-run: $*"
        return 0
    fi
    "$@"
}

# omni_run_checked <exit-code> <command...>
omni_run_checked() {
    local code="$1"
    shift
    if ! omni_run "$@"; then
        omni_die "$code" "Command failed: $*"
    fi
}

# omni_confirm <question> [y|n]
# Returns 0 for "yes" and 1 for "no".
#   --yes            answers yes without prompting
#   --non-interactive answers the default (never prompts, so unattended runs
#                    do exactly what the same command line did last time)
omni_confirm() {
    local question="$1"
    local default="${2:-n}"
    local answer="" hint="[y/N]"

    if [[ "$OMNI_ASSUME_YES" == "1" ]]; then
        omni_info "yes: $question (--yes)"
        return 0
    fi
    if ! omni_is_interactive; then
        omni_info "$default: $question (non-interactive)"
        [[ "$default" == "y" ]]
        return
    fi
    if [[ "$default" == "y" ]]; then
        hint="[Y/n]"
    fi
    while true; do
        read -r -p "? ${question} ${hint} " answer || answer=""
        answer="${answer:-$default}"
        case "${answer,,}" in
            y|yes) return 0 ;;
            n|no) return 1 ;;
            *) omni_info "Please answer 'y' or 'n'." ;;
        esac
    done
}

# omni_prompt <question> [default] -> prints the chosen value
omni_prompt() {
    local question="$1"
    local default="${2:-}"
    local answer=""
    if ! omni_is_interactive; then
        printf '%s\n' "$default"
        return 0
    fi
    read -r -p "? ${question}${default:+ [$default]}: " answer || answer=""
    printf '%s\n' "${answer:-$default}"
}

# omni_require_commands <command> [<command>...]
# Used for commands the installer itself needs (not for the desktop session).
omni_require_commands() {
    local missing=() cmd
    for cmd in "$@"; do
        if ! omni_have "$cmd"; then
            missing+=("$cmd")
        fi
    done
    if ((${#missing[@]} > 0)); then
        omni_error "Missing required commands: ${missing[*]}"
        omni_error "Install them first, then re-run the installer."
        exit "$OMNI_EXIT_DEPENDENCY"
    fi
}

# omni_timestamp -> 20260917-111500
omni_timestamp() {
    date '+%Y%m%d-%H%M%S'
}

# omni_hash <file> -> sha256 of a regular file, empty for other types
omni_hash() {
    local path="$1"
    if [[ ! -f "$path" || -L "$path" ]]; then
        printf ''
        return 0
    fi
    if omni_have sha256sum; then
        sha256sum -- "$path" | cut -d' ' -f1
        return 0
    fi
    if omni_have shasum; then
        shasum -a 256 -- "$path" | cut -d' ' -f1
        return 0
    fi
    printf ''
}

# omni_tree_hash <directory> -> hash over the sorted "path hash" listing
omni_tree_hash() {
    local dir="$1" file
    if [[ ! -d "$dir" ]]; then
        printf ''
        return 0
    fi
    {
        while IFS= read -r -d '' file; do
            printf '%s %s\n' "${file#"$dir"/}" "$(omni_hash "$file")"
        done < <(find "$dir" -type f -print0 | sort -z)
    } | { if omni_have sha256sum; then sha256sum | cut -d' ' -f1; else printf ''; fi; }
}

# omni_backup_root -> ${XDG_STATE_HOME:-$HOME/.local/state}/omniformis
omni_state_root() {
    printf '%s\n' "${XDG_STATE_HOME:-$HOME/.local/state}/omniformis"
}
