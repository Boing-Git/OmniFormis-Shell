#!/usr/bin/env bash
#
# OmniFormis Shell installer - compatibility entry point.
#
# The real installer lives at the root of the repository (install.sh). This
# wrapper exists because
#   * the README and the v1/v2 release notes told people to run
#     ./scripts/install.sh,
#   * scripts/install.sh is published as a release asset, so it must also work
#     when it is downloaded on its own.
#
# It therefore bootstraps a checkout when needed and then hands over to
# install.sh, passing every argument through unchanged.
set -Eeuo pipefail

readonly OMNIFORMIS_REPO_URL="${OMNIFORMIS_REPO_URL:-https://github.com/Boing-Git/OmniFormis-Shell.git}"
: "${HOME:?HOME is not set}"
readonly OMNIFORMIS_DIR_DEFAULT="$HOME/Dotfiles"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

log()  { printf '==> %s\n' "$*"; }
warn() { printf '  !  %s\n' "$*" >&2; }
die()  { printf '  x  %s\n' "$*" >&2; exit 1; }

# 1. Running from a checkout: install.sh sits next to the scripts directory.
if [[ -x "$SCRIPT_DIR/../install.sh" ]]; then
    exec bash "$SCRIPT_DIR/../install.sh" "$@"
fi
if [[ -f "$SCRIPT_DIR/../install.sh" ]]; then
    exec bash "$SCRIPT_DIR/../install.sh" "$@"
fi

# 2. Downloaded on its own (release asset): find or create a checkout.
CHECKOUT="${OMNIFORMIS_DIR:-$OMNIFORMIS_DIR_DEFAULT}"

if [[ ! -f "$CHECKOUT/install.sh" ]]; then
    command -v git >/dev/null 2>&1 || die "git is required to fetch the OmniFormis Shell repository."
    warn "No checkout of OmniFormis-Shell was found; the installer needs one because"
    warn "the configuration lives in the repository (scripts/, hypr/, quickshell/, ...)."
    printf 'Clone %s into %s? [Y/n] ' "$OMNIFORMIS_REPO_URL" "$CHECKOUT"
    answer=""
    read -r answer || answer="y"
    case "${answer:-y}" in
        [Nn]*) die "Aborted: nothing was changed. Clone the repository manually and run install.sh." ;;
    esac
    mkdir -p -- "$(dirname -- "$CHECKOUT")"
    log "Cloning $OMNIFORMIS_REPO_URL into $CHECKOUT"
    git clone --depth 1 "$OMNIFORMIS_REPO_URL" "$CHECKOUT" || die "git clone failed."
fi

log "Using the checkout at $CHECKOUT"
exec bash "$CHECKOUT/install.sh" --dir "$CHECKOUT" "$@"
