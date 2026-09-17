#!/usr/bin/env bash
#
# OmniFormis Shell - dependency check.
#
# Reports what is missing before the shell is started, so that problems show up
# as an actionable list instead of as an obscure runtime error inside QML.
#
# Usage:
#   scripts/check-deps.sh              # full report, exit 3 when something
#                                      # required is missing
#   scripts/check-deps.sh --hints      # only the "install it like this" list
#   scripts/check-deps.sh --quiet      # no output, only the exit code (CI)
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd -P)"

if [[ ! -f "$REPO_DIR/install/lib/deps.sh" ]]; then
    printf 'error: scripts/check-deps.sh needs the repository (install/lib is missing).\n' >&2
    exit 1
fi

# shellcheck source=../install/lib/common.sh
source "$REPO_DIR/install/lib/common.sh"
# shellcheck source=../install/lib/detect.sh
source "$REPO_DIR/install/lib/detect.sh"
# shellcheck source=../install/lib/deps.sh
source "$REPO_DIR/install/lib/deps.sh"

OMNI_MODE="report"

usage() {
    cat <<'EOF'
OmniFormis Shell - dependency check

Usage: scripts/check-deps.sh [options]

Options:
  --report          full report (default)
  --hints           only print how to install what is missing
  --quiet           no output, exit code only
  --optional        also report optional dependencies
  --no-fonts        skip the font checks
  -h, --help        this help

Exit codes: 0 everything required is present, 3 something required is missing.
EOF
}

main() {
    local optional=0 skip_fonts=0
    while (( $# > 0 )); do
        case "$1" in
            --report)
                OMNI_MODE="report"
                shift
                ;;
            --hints)
                OMNI_MODE="hints"
                shift
                ;;
            --quiet)
                OMNI_MODE="quiet"
                shift
                ;;
            --optional)
                optional=1
                shift
                ;;
            --no-fonts)
                skip_fonts=1
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

    local args=()
    (( optional == 1 )) && args+=(--include-optional)
    (( skip_fonts == 1 )) && args+=(--skip-fonts)

    if [[ "$OMNI_MODE" == "quiet" ]]; then
        if omni_check_dependencies "${args[@]}" >/dev/null 2>&1; then
            exit "$OMNI_EXIT_OK"
        fi
        exit "$OMNI_EXIT_DEPENDENCY"
    fi

    if [[ "$OMNI_MODE" == "hints" ]]; then
        omni_step "How to install what is missing"
        omni_print_missing_hints required
        if (( optional == 1 )); then
            omni_print_missing_hints optional
        fi
    else
        omni_report_dependencies
        if (( optional == 1 )); then
            omni_step "Optional features that are currently unavailable"
            omni_print_missing_hints optional
        fi
    fi

    if omni_check_dependencies "${args[@]}" >/dev/null 2>&1; then
        exit "$OMNI_EXIT_OK"
    fi
    exit "$OMNI_EXIT_DEPENDENCY"
}

main "$@"
