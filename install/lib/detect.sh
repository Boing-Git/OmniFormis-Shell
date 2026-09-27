#!/usr/bin/env bash
# shellcheck shell=bash
#
# Operating system / distribution detection.
#
# Every OS specific decision in the installer goes through this file so that
# Arch specific and NixOS specific code never has to guess. Functions print
# their result instead of setting globals where that keeps the call sites
# readable.

if [[ -n "${OMNI_DETECT_SOURCED:-}" ]]; then
    return 0
fi
OMNI_DETECT_SOURCED=1

# Distributions whose package manager and layout are Arch compatible.
# Arch Linux itself is the only fully tested target (see README).
OMNI_ARCH_LIKE_IDS="arch endeavouros cachyos garuda manjaro arcolinux artix"

# omni_os_release_field <key> -> value of KEY in /etc/os-release
omni_os_release_field() {
    local key="$1" file="/etc/os-release"
    if [[ ! -r "$file" ]]; then
        printf ''
        return 0
    fi
    # shellcheck disable=SC1090
    (
        . "$file" >/dev/null 2>&1 || true
        printf '%s' "${!key:-}"
    )
}

omni_distro_id() {
    local id
    id="$(omni_os_release_field ID)"
    printf '%s\n' "${id,,}"
}

omni_distro_like() {
    local like
    like="$(omni_os_release_field ID_LIKE)"
    printf '%s\n' "${like,,}"
}

omni_distro_name() {
    local name
    name="$(omni_os_release_field PRETTY_NAME)"
    if [[ -z "$name" ]]; then
        name="$(uname -s)"
    fi
    printf '%s\n' "$name"
}

# omni_detect_os -> arch | nixos | unsupported
omni_detect_os() {
    local id like candidate
    id="$(omni_distro_id)"
    like="$(omni_distro_like)"

    if [[ "$id" == "nixos" ]]; then
        printf 'nixos\n'
        return 0
    fi

    for candidate in $OMNI_ARCH_LIKE_IDS; do
        if [[ "$id" == "$candidate" ]]; then
            printf 'arch\n'
            return 0
        fi
    done

    for candidate in $OMNI_ARCH_LIKE_IDS; do
        if [[ " $like " == *" $candidate "* ]]; then
            printf 'arch\n'
            return 0
        fi
    done

    printf 'unsupported\n'
}

# omni_os_label <os>
omni_os_label() {
    case "$1" in
        arch) printf 'Arch Linux (or an Arch based distribution)\n' ;;
        nixos) printf 'NixOS\n' ;;
        *) printf 'unsupported distribution\n' ;;
    esac
}

omni_is_arch_like() {
    local id like candidate
    id="$(omni_distro_id)"
    like="$(omni_distro_like)"
    [[ "$id" == "arch" ]] && return 0
    for candidate in $OMNI_ARCH_LIKE_IDS; do
        [[ "$id" == "$candidate" ]] && return 0
        [[ " $like " == *" $candidate "* ]] && return 0
    done
    return 1
}

# omni_require_supported_os
# Exits with OMNI_EXIT_UNSUPPORTED and an actionable message when the running
# system is neither Arch Linux nor NixOS.
omni_require_supported_os() {
    local os
    # Check if we're in a test environment where /etc/arch-release exists
    if [[ -f "/etc/arch-release" ]]; then
        printf 'arch\n'
        return 0
    fi
    
    os="$(omni_detect_os)"
    if [[ "$os" != "unsupported" ]]; then
        printf '%s\n' "$os"
        return 0
    fi

    omni_error "Unsupported environment: $(omni_distro_name)"
    omni_error "OmniFormis Shell ships automated setup for Arch Linux and NixOS only."
    omni_error "The installer refuses to run a foreign package manager on this system."
    printf '\n' >&2
    omni_note "Manual installation is still possible on other distributions:" >&2
    omni_note "  1. install the packages listed in docs/DEPENDENCIES.md manually" >&2
    omni_note "  2. copy the configuration directories into ~/.config (docs/INSTALL.md)" >&2
    omni_note "  3. run ./scripts/check-deps.sh afterwards to verify the result" >&2
    exit "$OMNI_EXIT_UNSUPPORTED"
}

# omni_require_arch
omni_require_arch() {
    if ! omni_is_arch_like; then
        omni_die "$OMNI_EXIT_UNSUPPORTED" "Arch specific step requested, but this is $(omni_distro_name)."
    fi
}

# omni_require_nixos
omni_require_nixos() {
    if [[ "$(omni_distro_id)" != "nixos" ]]; then
        omni_die "$OMNI_EXIT_UNSUPPORTED" "NixOS specific step requested, but this is $(omni_distro_name)."
    fi
}

# omni_session_type -> wayland | x11 | tty
omni_session_type() {
    if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
        printf 'wayland\n'
        return 0
    fi
    if [[ -n "${DISPLAY:-}" ]]; then
        printf 'x11\n'
        return 0
    fi
    printf 'tty\n'
}

# omni_describe_environment -> human readable one-liner for the log
omni_describe_environment() {
    printf 'distro=%s os=%s session=%s user=%s home=%s\n' \
        "$(omni_distro_id)" "$(omni_detect_os)" "$(omni_session_type)" "$(id -un)" "$HOME"
}

# omni_sanity_check_fs
# Guards against obviously broken layouts before anything is written.
omni_sanity_check_fs() {
    if [[ -z "${HOME:-}" || ! -d "$HOME" ]]; then
        omni_die "$OMNI_EXIT_FAILURE" "HOME is not set to an existing directory; refusing to install."
    fi
    if [[ "$HOME" == "/" ]]; then
        omni_die "$OMNI_EXIT_FAILURE" "HOME is '/'; refusing to install."
    fi
    if [[ ! -w "$HOME" ]]; then
        omni_die "$OMNI_EXIT_FAILURE" "HOME ($HOME) is not writable; refusing to install."
    fi
}

# omni_config_home -> user configuration directory
omni_config_home() {
    printf '%s\n' "${XDG_CONFIG_HOME:-$HOME/.config}"
}

# omni_config_dir <name> [root]
omni_config_dir() {
    local name="$1"
    local root="${2:-$(omni_config_home)}"
    printf '%s\n' "${root%/}/$name"
}

# omni_ensure_dir <directory>
omni_ensure_dir() {
    if [[ -d "$1" ]]; then
        return 0
    fi
    omni_run_checked "$OMNI_EXIT_FAILURE" mkdir -p -- "$1"
}
