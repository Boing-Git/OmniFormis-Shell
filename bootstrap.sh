#!/usr/bin/env bash
#
# OmniFormis Shell - one line installer.
#
#   curl -fsSL https://raw.githubusercontent.com/Boing-Git/OmniFormis-Shell/main/bootstrap.sh | bash
#   curl -fsSL <url> | bash -s -- --dry-run --non-interactive
#
# The configuration lives in the repository (hypr/, quickshell/, scripts/, ...),
# so the repository is fetched first and the run is then handed over to
# install.sh. Written to be piped into bash, this script never looks at its own
# location: unlike scripts/install.sh it never searches the current working
# directory for a checkout, and it restores the terminal as stdin so the
# installer can still prompt (a piped stdin would make it run unattended).
#
# Environment
#   OMNIFORMIS_REPO_URL    repository to clone (default: the upstream repository)
#   OMNIFORMIS_REF         branch or tag to check out (default: remote default)
#   OMNIFORMIS_DIR         checkout location (default: $HOME/Dotfiles)
#   OMNIFORMIS_UPDATE=1    run "git pull --ff-only" in an existing checkout
#   OMNIFORMIS_ALLOW_ROOT=1  skip the "do not run as root" guard
#
# Every argument other than --bootstrap-* is forwarded to install.sh, so all of
# its options work. OMNIFORMIS_REF is fetched when it is not known yet, and an
# existing checkout only switches branch when git can do so without touching
# local work; a checkout is never rewritten.
#
# Exit codes mirror install/lib/common.sh so that automation can treat the
# bootstrap as part of the installer: 0 ok, 1 usage / prerequisite,
# 3 missing dependency, 6 failure.

set -Eeuo pipefail

# Only the codes this script can return.
OMNI_EXIT_USAGE=1
OMNI_EXIT_DEPENDENCY=3
OMNI_EXIT_FAILURE=6

# Colour follows install/lib/common.sh: only when it cannot confuse a log.
if [[ -t 1 && -z "${NO_COLOR:-}" && "${TERM:-dumb}" != "dumb" ]]; then
    OMNI_C_RESET=$'\033[0m'
    OMNI_C_BOLD=$'\033[1m'
    OMNI_C_DIM=$'\033[2m'
    OMNI_C_RED=$'\033[31m'
    OMNI_C_GREEN=$'\033[32m'
    OMNI_C_YELLOW=$'\033[33m'
    OMNI_C_BLUE=$'\033[34m'
else
    OMNI_C_RESET=''
    OMNI_C_BOLD=''
    OMNI_C_DIM=''
    OMNI_C_RED=''
    OMNI_C_GREEN=''
    OMNI_C_YELLOW=''
    OMNI_C_BLUE=''
fi

omni_log()  { printf '%s==>%s %s\n' "$OMNI_C_BOLD$OMNI_C_BLUE" "$OMNI_C_RESET" "$*"; }
omni_info() { printf '  ·  %s%s%s\n' "$OMNI_C_DIM" "$*" "$OMNI_C_RESET"; }
omni_ok()   { printf '  ok %s%s%s\n' "$OMNI_C_GREEN" "$*" "$OMNI_C_RESET"; }
omni_warn() { printf '  !  %s%s%s\n' "$OMNI_C_YELLOW" "$*" "$OMNI_C_RESET" >&2; }

# omni_die <exit-code> <message...>
omni_die() {
    local code="$1"
    shift
    printf '  x  %s%s%s\n' "$OMNI_C_RED" "$*" "$OMNI_C_RESET" >&2
    exit "$code"
}

# omni_run <command...>
# Reported instead of executed with --bootstrap-dry-run: a dry run must not
# clone anything either.
omni_run() {
    if [[ "$OMNIFORMIS_DRY_RUN" == "1" ]]; then
        omni_info "dry-run: $*"
        return 0
    fi
    "$@"
}

omni_usage() {
    cat <<'USAGE'
OmniFormis Shell bootstrap

Usage: curl -fsSL <bootstrap.sh url> | bash -s -- [options]

  Everything except the switches below is passed to install.sh unchanged, so
  --dry-run, --non-interactive, --modules, ... work as documented there
  (./install.sh --help).

Bootstrap options
  --bootstrap-dry-run    Do not clone or install; only report what would happen
  --bootstrap-help       Show this help and exit

Environment
  OMNIFORMIS_REPO_URL    Repository to clone (default: the upstream repository)
  OMNIFORMIS_REF         Branch or tag to check out (default: remote default)
  OMNIFORMIS_DIR         Checkout location (default: $HOME/Dotfiles)
  OMNIFORMIS_UPDATE=1    Fast-forward an existing checkout before installing
  OMNIFORMIS_ALLOW_ROOT=1  Skip the "do not run as root" guard
USAGE
}

# omni_parse_args
# Only the bootstrap's own switches are consumed here; everything else is kept
# for install.sh.
omni_parse_args() {
    OMNIFORMIS_DRY_RUN=0
    local -a forwarded=()
    local arg
    for arg in "$@"; do
        case "$arg" in
            --bootstrap-dry-run) OMNIFORMIS_DRY_RUN=1 ;;
            --bootstrap-help)
                omni_usage
                exit 0
                ;;
            *) forwarded+=("$arg") ;;
        esac
    done
    OMNIFORMIS_FORWARD=("${forwarded[@]+"${forwarded[@]}"}")
}

# omni_check_environment
# Cheap local preflight. The authoritative operating system gate lives in
# install/lib/detect.sh and runs once the checkout exists, so this script never
# duplicates the list of supported distributions.
omni_check_environment() {
    if [[ -z "${HOME:-}" || ! -d "$HOME" ]]; then
        omni_die "$OMNI_EXIT_FAILURE" "HOME is not set to an existing directory; refusing to install."
    fi
    if [[ "$HOME" == "/" ]]; then
        omni_die "$OMNI_EXIT_FAILURE" "HOME is '/'; refusing to install."
    fi
    if [[ ! -w "$HOME" ]]; then
        omni_die "$OMNI_EXIT_FAILURE" "HOME ($HOME) is not writable; refusing to install."
    fi
    if (( BASH_VERSINFO[0] < 4 )); then
        omni_die "$OMNI_EXIT_USAGE" "bash 4 or newer is required (found $BASH_VERSION)."
    fi
    if [[ "$EUID" -eq 0 && "${OMNIFORMIS_ALLOW_ROOT:-0}" != "1" ]]; then
        omni_die "$OMNI_EXIT_USAGE" \
            "Do not run the installer as root. Run it as your normal user; sudo is only used when the installer asks for it."
    fi
    if ! command -v git >/dev/null 2>&1; then
        omni_die "$OMNI_EXIT_DEPENDENCY" "git is required to fetch the OmniFormis Shell repository."
    fi
    if [[ "$OMNIFORMIS_REF" == -* ]]; then
        omni_die "$OMNI_EXIT_USAGE" "OMNIFORMIS_REF must be a branch or tag name, not an option."
    fi
}

# omni_directory_is_empty <dir>
omni_directory_is_empty() {
    local dir="$1" entry
    local -a entries=("$dir"/* "$dir"/.[!.]* "$dir"/..?*)
    for entry in "${entries[@]}"; do
        if [[ -e "$entry" || -L "$entry" ]]; then
            return 1
        fi
    done
    return 0
}

# omni_clone <dest>
omni_clone() {
    local dest="$1"
    # --no-single-branch keeps the normal fetch refspec, so a later run can
    # switch OMNIFORMIS_REF without reconfiguring the checkout.
    local -a args=(--depth 1 --no-single-branch)
    if [[ -n "$OMNIFORMIS_REF" ]]; then
        args+=(--branch "$OMNIFORMIS_REF")
    fi
    omni_log "Cloning $OMNIFORMIS_REPO_URL${OMNIFORMIS_REF:+ (ref $OMNIFORMIS_REF)} into $dest"
    if ! omni_run git clone "${args[@]}" -- "$OMNIFORMIS_REPO_URL" "$dest"; then
        omni_die "$OMNI_EXIT_FAILURE" "git clone failed; nothing was installed."
    fi
}

# omni_ref_exists <dest> <ref>
# True when git could resolve the name as a branch, a remote tracking branch
# (git checkout creates the local branch then) or a tag.
omni_ref_exists() {
    local dest="$1" ref="$2"
    git -C "$dest" rev-parse --verify --quiet "refs/heads/$ref" >/dev/null \
        || git -C "$dest" rev-parse --verify --quiet "refs/remotes/origin/$ref" >/dev/null \
        || git -C "$dest" rev-parse --verify --quiet "refs/tags/$ref" >/dev/null
}

# omni_reuse <dest>
# An existing checkout is never rewritten: the branch only moves when git can do
# it without touching local work, and the optional update is a fast-forward.
omni_reuse() {
    local dest="$1"
    omni_log "Using the existing checkout at $dest"

    if [[ -n "$OMNIFORMIS_REF" ]]; then
        # A ref that is not known yet is fetched first; fetching never touches
        # the working tree.
        if [[ "$OMNIFORMIS_DRY_RUN" != "1" ]] && ! omni_ref_exists "$dest" "$OMNIFORMIS_REF"; then
            git -C "$dest" fetch origin >/dev/null 2>&1 || true
        fi
        if ! omni_ref_exists "$dest" "$OMNIFORMIS_REF"; then
            omni_warn "Ref '$OMNIFORMIS_REF' is not part of this checkout; keeping the current branch."
            omni_warn "Set OMNIFORMIS_DIR to a new path for a fresh checkout of that ref."
        elif [[ "$OMNIFORMIS_DRY_RUN" == "1" ]]; then
            omni_info "dry-run: git -C $dest checkout $OMNIFORMIS_REF"
        elif ! git -C "$dest" checkout "$OMNIFORMIS_REF" >/dev/null 2>&1; then
            omni_warn "Could not switch to '$OMNIFORMIS_REF'; local changes are never overwritten."
            omni_warn "Set OMNIFORMIS_DIR to a new path for a fresh checkout of that ref."
        fi
    fi

    if [[ "$OMNIFORMIS_UPDATE" == "1" ]]; then
        omni_log "Updating $dest (git pull --ff-only)"
        if ! omni_run git -C "$dest" pull --ff-only; then
            omni_die "$OMNI_EXIT_FAILURE" "git pull --ff-only failed; the checkout is left untouched."
        fi
    fi
}

# omni_prepare_checkout <dest>
omni_prepare_checkout() {
    local dest="$1"

    if [[ -e "$dest" && ! -d "$dest" ]]; then
        omni_die "$OMNI_EXIT_FAILURE" "$dest exists but is not a directory."
    fi

    if [[ -d "$dest" ]] && ! omni_directory_is_empty "$dest"; then
        if [[ ! -f "$dest/install.sh" ]]; then
            omni_die "$OMNI_EXIT_FAILURE" \
                "$dest is not an OmniFormis Shell checkout (install.sh is missing). Set OMNIFORMIS_DIR to another path."
        fi
        omni_reuse "$dest"
        return 0
    fi

    omni_run mkdir -p -- "$(dirname -- "$dest")"
    omni_clone "$dest"
}

# omni_start_installer <dest> [<installer argument>...]
omni_start_installer() {
    local dest="$1"
    shift

    if [[ "$OMNIFORMIS_DRY_RUN" == "1" ]]; then
        omni_ok "Dry run: nothing was cloned or installed."
        omni_info "Would run: bash $dest/install.sh --dir $dest${*:+ $*}"
        return 0
    fi

    if [[ ! -f "$dest/install.sh" ]]; then
        omni_die "$OMNI_EXIT_FAILURE" "$dest/install.sh is missing; the checkout is incomplete."
    fi
    omni_ok "Checkout ready: $dest"
    omni_log "Starting the OmniFormis Shell installer"

    # Piped into bash, stdin is the download rather than the terminal, and
    # install.sh would treat the run as unattended and skip every prompt.
    # The terminal is opened first because /dev/tty can exist while there is no
    # controlling terminal, which would otherwise abort the exec.
    if [[ ! -t 0 ]] && { : </dev/tty; } 2>/dev/null; then
        exec bash "$dest/install.sh" --dir "$dest" "$@" </dev/tty
    fi
    exec bash "$dest/install.sh" --dir "$dest" "$@"
}

main() {
    omni_parse_args "$@"

    OMNIFORMIS_REPO_URL="${OMNIFORMIS_REPO_URL:-https://github.com/Boing-Git/OmniFormis-Shell.git}"
    OMNIFORMIS_REF="${OMNIFORMIS_REF:-}"
    OMNIFORMIS_UPDATE="${OMNIFORMIS_UPDATE:-0}"

    # Before OMNIFORMIS_DIR: it is the only default that reads $HOME.
    omni_check_environment

    OMNIFORMIS_DIR="${OMNIFORMIS_DIR:-$HOME/Dotfiles}"
    omni_prepare_checkout "$OMNIFORMIS_DIR"
    omni_start_installer "$OMNIFORMIS_DIR" ${OMNIFORMIS_FORWARD[@]+"${OMNIFORMIS_FORWARD[@]}"}
}

main "$@"
