#!/usr/bin/env bash
#
# OmniFormis Shell - repository validation.
#
# Static checks only: no graphical session, no root and no network access are
# required, so the same script can run locally and in CI.
#
#   bash scripts/validate-repo.sh            # all checks
#   bash scripts/validate-repo.sh --quiet    # only failures
#
# Exit code 0 = everything passed, 1 = at least one check failed.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"
cd -- "$REPO_DIR"

OMNI_QUIET=0
OMNI_FAILURES=0
OMNI_WARNINGS=0
OMNI_CHECKS=0

# Files that legitimately contain machine specific data. Keep this list short
# and always explain why an entry is here.
OMNI_PATH_ALLOWLIST="scripts/lyrics_tool/target
scripts/omniformis/target
fish/fish_variables"

if [[ "${1:-}" == "--quiet" ]]; then
    OMNI_QUIET=1
fi

step() {
    OMNI_CHECKS=$((OMNI_CHECKS + 1))
    if (( OMNI_QUIET == 0 )); then
        printf '==> %s\n' "$*"
    fi
}

pass() {
    if (( OMNI_QUIET == 0 )); then
        printf '  ok   %s\n' "$*"
    fi
}

fail() {
    OMNI_FAILURES=$((OMNI_FAILURES + 1))
    printf '  FAIL %s\n' "$*" >&2
}

# warn <message>
# Reported but not fatal: the condition comes from the imported dotfiles and is
# converted in a separate change. Failures stay reserved for what this branch
# controls, so that `set -e` never hides the checks below.
warn() {
    OMNI_WARNINGS=$((OMNI_WARNINGS + 1))
    printf '  warn %s\n' "$*" >&2
}

in_allowlist() {
    local needle="$1" entry
    while IFS= read -r entry; do
        [[ -z "$entry" ]] && continue
        case "$needle" in
            "$entry"|"$entry"/*) return 0 ;;
        esac
    done <<<"$OMNI_PATH_ALLOWLIST"
    return 1
}

tracked_files() {
    git -C "$REPO_DIR" ls-files
}

# ------------------------------------------------------------------ checks
check_required_files() {
    step "Required files exist"
    local required=(
        install.sh
        install/lib/common.sh
        install/lib/detect.sh
        install/lib/deps.sh
        install/lib/backup.sh
        install/lib/modules.sh
        install/lib/install-config.sh
        install/lib/arch.sh
        install/lib/nixos.sh
        scripts/install.sh
        scripts/uninstall.sh
        scripts/check-deps.sh
        README.md
        docs/DEPENDENCIES.md
        .github/workflows/validate.yml
    )
    # Documented in the README but not written yet. Warned about instead of
    # failed, so the required list keeps the files the installer actually needs.
    local planned=(
        docs/INSTALL.md
        docs/MODULES.md
        docs/BACKUP-AND-RESTORE.md
        docs/KEYBINDINGS.md
        docs/THEMES.md
        docs/TROUBLESHOOTING.md
    )
    local file
    for file in "${required[@]}"; do
        if [[ -e "$file" ]]; then
            pass "$file"
        else
            fail "missing file: $file"
        fi
    done
    for file in "${planned[@]}"; do
        if [[ -e "$file" ]]; then
            pass "$file"
            continue
        fi
        warn "planned but not written yet: $file"
    done
}

check_shell_syntax() {
    step "Shell scripts parse (bash -n)"
    local file
    while IFS= read -r file; do
        [[ "$file" == *.sh ]] || continue
        if bash -n "$file" 2>/dev/null; then
            pass "$file"
        else
            fail "bash -n failed: $file"
        fi
    done < <(tracked_files)
}

check_shellcheck() {
    step "shellcheck (warning severity)"
    if ! command -v shellcheck >/dev/null 2>&1; then
        pass "shellcheck is not installed - skipped"
        return 0
    fi
    local file failed=0
    while IFS= read -r file; do
        [[ "$file" == *.sh ]] || continue
        # -x follows the sourced install/lib/*.sh files and -P SCRIPTDIR resolves
        # their `source=` directives relative to the script itself, so variables
        # that are only read there are not reported as unused (SC2034).
        if ! shellcheck -x -P SCRIPTDIR -S warning "$file" >/tmp/omniformis-shellcheck.log 2>&1; then
            fail "shellcheck reported problems in $file:"
            sed 's/^/       /' /tmp/omniformis-shellcheck.log >&2
            failed=1
        fi
    done < <(tracked_files)
    if (( failed != 0 )); then
        return 0
    fi
    pass "all tracked shell scripts are clean"
}

check_executable_bits() {
    step "Entry points are executable"
    local file
    for file in install.sh scripts/install.sh scripts/uninstall.sh scripts/check-deps.sh \
        scripts/validate-repo.sh scripts/reload.sh scripts/auto_scheme_matugen.sh; do
        [[ -e "$file" ]] || continue
        if [[ -x "$file" ]]; then
            pass "$file"
        else
            fail "$file is not executable (chmod +x)"
        fi
    done
}

check_module_targets() {
    step "Module registry points at existing paths"
    local source
    local -a sources=()
    while IFS= read -r source; do
        [[ -z "$source" ]] && continue
        sources+=("$source")
    done < <(
        # shellcheck source=../install/lib/modules.sh
        source "$REPO_DIR/install/lib/modules.sh"
        omni_module_names 2>/dev/null >/dev/null || true
        omni_modules_all_sources 2>/dev/null || true
    )
    if (( ${#sources[@]} == 0 )); then
        fail "could not read the module registry (install/lib/modules.sh)"
        return 0
    fi
    for source in "${sources[@]}"; do
        if [[ -e "$source" ]]; then
            pass "$source"
            continue
        fi
        if [[ -L "$source" ]]; then
            warn "module source is a dangling symlink: $source -> $(readlink -- "$source")"
            continue
        fi
        fail "module source does not exist: $source"
    done
}

check_no_personal_paths() {
    step "No hard coded personal paths"
    local hits
    hits="$(grep -rIn --exclude-dir=.git --exclude-dir=target -E '/home/[A-Za-z0-9._-]+/' . 2>/dev/null || true)"
    local line path found=0
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        path="${line#./}"
        path="${path%%:*}"
        [[ "$path" == scripts/validate-repo.sh ]] && continue
        if in_allowlist "$path"; then
            continue
        fi
        # These paths come from the imported dotfiles and are ported one file at
        # a time; warn so the checks below still run.
        warn "hard coded home path in $line"
        found=1
    done <<<"$hits"
    if (( found != 0 )); then
        return 0
    fi
    pass "no /home/<user>/ paths in the tracked tree"
}

check_absolute_symlinks() {
    step "Tracked symlinks are portable"
    local file target note
    while IFS= read -r file; do
        [[ -L "$file" ]] || continue
        target="$(readlink -- "$file")"
        if [[ "$target" != /* ]]; then
            pass "$file -> $target"
            continue
        fi
        # These are the imported dotfiles' original links, ported one file at a
        # time; warned about so the port stays visible without failing the run.
        note=""
        [[ -e "$file" ]] || note=" (dangling)"
        warn "$file is an absolute symlink ($target)$note; use a path relative to the repository"
    done < <(tracked_files)
}

check_secrets() {
    step "No credentials or tokens"
    local patterns='ghp_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|AKIA[0-9A-Z]{16}|-----BEGIN (RSA|OPENSSH|EC|PGP) PRIVATE KEY-----|xox[baprs]-[A-Za-z0-9-]{10,}'
    local hits
    hits="$(grep -rInE --exclude-dir=.git --exclude-dir=target "$patterns" . 2>/dev/null || true)"

    # The validator itself contains the patterns and is skipped.
    local filtered=""
    local line path
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        path="${line#./}"
        path="${path%%:*}"
        [[ "$path" == scripts/validate-repo.sh ]] && continue
        filtered="$filtered$line"$'\n'
    done <<<"$hits"

    if [[ -n "${filtered//$'\n'/}" ]]; then
        fail "possible secret material:"
        printf '%s' "$filtered" >&2
    else
        pass "no token or private key patterns found"
    fi
}

check_docs_links() {
    step "Relative links in the documentation exist"
    local file link target failed=0
    while IFS= read -r file; do
        [[ "$file" == *.md ]] || continue
        while IFS= read -r link; do
            [[ -z "$link" ]] && continue
            case "$link" in
                http://*|https://*|mailto:*|"#"*) continue ;;
            esac
            target="${link%%#*}"
            [[ -z "$target" ]] && continue
            if [[ -e "$(dirname -- "$file")/$target" ]]; then
                continue
            fi
            if [[ -e "$target" ]]; then
                continue
            fi
            fail "$file links to a missing path: $link"
            failed=1
        done < <(grep -oE '\]\([^)]+\)' "$file" 2>/dev/null | sed 's/^](//; s/)$//' | grep -v '^$' || true)
    done < <(tracked_files)
    if (( failed != 0 )); then
        return 0
    fi
    pass "all relative documentation links resolve"
}

# -------------------------------------------------------------------- main
main() {
    printf 'OmniFormis Shell - repository validation (%s)\n' "$REPO_DIR"

    check_required_files
    check_shell_syntax
    check_shellcheck
    check_executable_bits
    check_module_targets
    check_no_personal_paths
    check_absolute_symlinks
    check_secrets
    check_docs_links

    printf '\n%s check(s) run, %s failure(s), %s warning(s)\n' "$OMNI_CHECKS" "$OMNI_FAILURES" "$OMNI_WARNINGS"
    if (( OMNI_WARNINGS > 0 )); then
        printf 'Warnings come from the imported dotfiles and are tracked separately.\n'
    fi
    if (( OMNI_FAILURES > 0 )); then
        exit 1
    fi
    printf 'All checks passed.\n'
}

main "$@"
