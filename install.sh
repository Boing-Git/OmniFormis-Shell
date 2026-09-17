#!/usr/bin/env bash
#
# OmniFormis Shell installer.
#
# Safety rules (see docs/INSTALL.md for the full contract):
#   * nothing is installed before the environment is detected and the plan is
#     confirmed,
#   * existing configuration is copied into a timestamped backup first,
#   * configuration managed by NixOS/home-manager is never overwritten,
#   * every destructive or system wide step is opt in,
#   * --dry-run prints the plan without touching the system,
#   * --non-interactive never asks and never does anything optional.
#
# Exit codes: 0 ok, 1 usage, 2 unsupported OS, 3 missing dependency,
#             4 aborted by the user, 5 backup failure, 6 installation failure.

set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"

OMNI_INSTALLER_VERSION="1.0.0"

# shellcheck source=install/lib/common.sh
source "$SCRIPT_DIR/install/lib/common.sh"
# shellcheck source=install/lib/detect.sh
source "$SCRIPT_DIR/install/lib/detect.sh"
# shellcheck source=install/lib/deps.sh
source "$SCRIPT_DIR/install/lib/deps.sh"
# shellcheck source=install/lib/backup.sh
source "$SCRIPT_DIR/install/lib/backup.sh"
# shellcheck source=install/lib/modules.sh
source "$SCRIPT_DIR/install/lib/modules.sh"
# shellcheck source=install/lib/install-config.sh
source "$SCRIPT_DIR/install/lib/install-config.sh"

# Arch and NixOS specific code lives in separate files. They are sourced here
# but only ever called from the matching branch of omni_run_platform().
# shellcheck source=install/lib/arch.sh
source "$SCRIPT_DIR/install/lib/arch.sh"
# shellcheck source=install/lib/nixos.sh
source "$SCRIPT_DIR/install/lib/nixos.sh"

omni_usage() {
    cat <<'USAGE'
OmniFormis Shell installer

Usage: ./install.sh [options]

Target selection
  --os <auto|arch|nixos>   Platform to install for (default: auto detect)
  --dir <path>             Repository to install from (default: this checkout)
  --modules <a,b,...>      Components to install (default: ask, or core)
  --all-modules            Install every component
  --groups <a,b,...>       Arch package groups to install (see --list-groups)

Behaviour
  -y, --yes                Answer yes to confirmations (still never deletes system files)
  --non-interactive        Never prompt; install defaults only, skip optional steps
  --dry-run                Print what would happen without changing anything
  --force                  Copy over Nix managed symlinks and skip "keep" answers
  --skip-packages          Do not install system packages
  --skip-config            Do not copy configuration files
  --skip-cli               Do not install the omniformis CLI
  --skip-plugins           Do not run hyprpm
  --skip-brightness-tweak  Leave the brightness keybinds untouched
  --allow-missing-deps     Finish even when required commands are missing
  --backup-dir <path>      Back up configuration here (default: state/backups)

Information
  --check-deps             Report missing dependencies and exit
  --list-modules           List installation components
  --list-groups            List Arch package groups
  --list-deps              List every dependency and exit
  -v, --verbose            Extra output
  -h, --help               This help
  -V, --version            Installer version
USAGE
}

omni_banner() {
    printf '\n%sOmniFormis Shell installer%s %s\n' "$OMNI_C_BOLD" "$OMNI_C_RESET" "$OMNI_INSTALLER_VERSION"
    printf '%sA Hyprland + Quickshell desktop configuration.%s\n\n' "$OMNI_C_DIM" "$OMNI_C_RESET"
}

# --------------------------------------------------------------- arguments

omni_parse_args() {
    OMNI_TARGET_OS="auto"
    OMNI_MODULES_ARG=""
    OMNI_ARCH_GROUPS_OVERRIDE=""
    OMNI_SKIP_PACKAGES=0
    OMNI_SKIP_CONFIG=0
    OMNI_SKIP_CLI=0
    OMNI_SKIP_PLUGINS=0
    OMNI_SKIP_BRIGHTNESS=0
    OMNI_ALLOW_MISSING_DEPS=0
    OMNI_MODE="install"

    while (( $# > 0 )); do
        case "$1" in
            --os)
                OMNI_TARGET_OS="${2:-}"
                if [[ -z "$OMNI_TARGET_OS" ]]; then
                    omni_die "$OMNI_EXIT_USAGE" "--os needs a value (auto, arch or nixos)."
                fi
                shift 2
                ;;
            --dir)
                OMNI_SRC_DIR="${2:-}"
                if [[ -z "$OMNI_SRC_DIR" ]]; then
                    omni_die "$OMNI_EXIT_USAGE" "--dir needs a path."
                fi
                shift 2
                ;;
            --modules)
                OMNI_MODULES_ARG="${2:-}"
                shift 2
                ;;
            --all-modules)
                OMNI_MODULES_ARG="all"
                shift
                ;;
            --groups)
                OMNI_ARCH_GROUPS_OVERRIDE="${2:-}"
                shift 2
                ;;
            -y|--yes)
                OMNI_ASSUME_YES=1
                shift
                ;;
            --non-interactive)
                OMNI_NON_INTERACTIVE=1
                shift
                ;;
            --dry-run)
                OMNI_DRY_RUN=1
                shift
                ;;
            --force)
                OMNI_FORCE_OVERWRITE=1
                shift
                ;;
            --skip-packages)
                OMNI_SKIP_PACKAGES=1
                shift
                ;;
            --skip-config)
                OMNI_SKIP_CONFIG=1
                shift
                ;;
            --skip-cli)
                OMNI_SKIP_CLI=1
                shift
                ;;
            --skip-plugins)
                OMNI_SKIP_PLUGINS=1
                shift
                ;;
            --skip-brightness-tweak)
                OMNI_SKIP_BRIGHTNESS=1
                shift
                ;;
            --allow-missing-deps)
                OMNI_ALLOW_MISSING_DEPS=1
                shift
                ;;
            --backup-dir)
                OMNI_BACKUP_ROOT="${2:-}"
                if [[ -z "$OMNI_BACKUP_ROOT" ]]; then
                    omni_die "$OMNI_EXIT_USAGE" "--backup-dir needs a path."
                fi
                shift 2
                ;;
            --check-deps)
                OMNI_MODE="check-deps"
                shift
                ;;
            --list-modules)
                OMNI_MODE="list-modules"
                shift
                ;;
            --list-groups)
                OMNI_MODE="list-groups"
                shift
                ;;
            --list-deps)
                OMNI_MODE="list-deps"
                shift
                ;;
            -v|--verbose)
                OMNI_VERBOSE=1
                shift
                ;;
            -h|--help)
                OMNI_MODE="help"
                shift
                ;;
            -V|--version)
                OMNI_MODE="version"
                shift
                ;;
            *)
                omni_error "Unknown option: $1"
                omni_usage
                exit "$OMNI_EXIT_USAGE"
                ;;
        esac
    done
}

omni_print_plan() {
    local os="$1" config_root
    config_root="$(omni_config_home)"

    omni_step "Installation plan"
    omni_info "Platform        : $os ($(omni_distro_name))"
    omni_info "Source          : $OMNI_SRC_DIR"
    omni_info "Configuration   : $config_root"
    omni_info "Components      : ${OMNI_SELECTED_MODULES[*]:-none}"
    omni_info "Backup          : ${OMNI_BACKUP_DIR:-none}"
    omni_info "Manifest        : $(omni_manifest_path)"
    omni_info "Packages        : $([[ "$OMNI_SKIP_PACKAGES" == "1" ]] && printf 'skipped (--skip-packages)' || printf 'as selected below')"
    if [[ "$OMNI_DRY_RUN" == "1" ]]; then
        omni_warn "Dry run: nothing will be written."
    fi
}

# omni_select_modules
omni_select_modules() {
    OMNI_SELECTED_MODULES=()

    if [[ "$OMNI_MODULES_ARG" == "all" ]]; then
        while IFS= read -r name; do
            OMNI_SELECTED_MODULES+=("$name")
        done < <(omni_module_names)
        return 0
    fi

    if [[ -n "$OMNI_MODULES_ARG" ]]; then
        omni_module_select "$OMNI_MODULES_ARG"
        return 0
    fi

    if [[ "$OMNI_ASSUME_YES" == "1" ]] || ! omni_is_interactive; then
        omni_module_select "$(omni_module_required_names | tr '\n' ',')"
        omni_info "Non-interactive run: installing the required components only (use --modules all for everything)."
        return 0
    fi

    omni_step "Components"
    omni_module_print_table
    omni_note "'core' is required; the other components can be deselected."
    local name
    while IFS= read -r name; do
        if omni_module_is_required "$name"; then
            OMNI_SELECTED_MODULES+=("$name")
            continue
        fi
        if omni_confirm "Install component '$name' ($(omni_module_description "$name"))?" y; then
            OMNI_SELECTED_MODULES+=("$name")
        fi
    done < <(omni_module_names)
}

# omni_check_required_dependencies <phase>
omni_check_required_dependencies() {
    local phase="$1" missing

    missing="$(omni_missing_commands | wc -l)"
    if [[ -z "$missing" || "$missing" == "0" ]]; then
        omni_ok "All required commands are available."
        return 0
    fi

    if [[ "$phase" == "before" ]]; then
        omni_warn "$missing required command(s) are missing; the installer will offer to install them next."
        return 0
    fi

    omni_error "$missing required command(s) are still missing:"
    omni_print_missing_hints required
    omni_summary_add "Install the missing dependencies: bash scripts/check-deps.sh --hints"

    if [[ "$OMNI_ALLOW_MISSING_DEPS" == "1" ]]; then
        omni_warn "Continuing because --allow-missing-deps was given; the session may not start."
        return 0
    fi

    omni_die "$OMNI_EXIT_DEPENDENCY" \
        "The session needs these commands. Install them and run the installer again."
}

# omni_install_cli
omni_install_cli() {
    if [[ "$OMNI_SKIP_CLI" == "1" ]]; then
        omni_info "Skipping the omniformis CLI (--skip-cli)."
        return 0
    fi
    if ! omni_confirm "Install the omniformis CLI into ~/.local/bin?" y; then
        omni_info "Skipped the CLI."
        return 0
    fi
    omni_install_cli_binary
}

# omni_run_platform <os>
omni_run_platform() {
    local os="$1"
    case "$os" in
        arch)
            omni_arch_require_support
            if [[ "$OMNI_SKIP_PACKAGES" != "1" ]]; then
                omni_arch_choose_groups
            else
                omni_info "Skipping packages (--skip-packages)."
            fi
            ;;
        nixos)
            omni_nixos_require_support
            if [[ "$OMNI_SKIP_PACKAGES" != "1" ]]; then
                omni_nixos_choose_packages
            else
                omni_info "Skipping package handling (--skip-packages)."
            fi
            ;;
        *)
            omni_die "$OMNI_EXIT_UNSUPPORTED" "No platform handler for '$os'."
            ;;
    esac
}

omni_run_platform_packages() {
    local os="$1"
    case "$os" in
        arch)
            if [[ "$OMNI_SKIP_PACKAGES" == "1" ]]; then
                return 0
            fi
            omni_arch_install_packages
            omni_arch_install_rubik_font
            ;;
        nixos)
            if [[ "$OMNI_SKIP_PACKAGES" == "1" ]]; then
                return 0
            fi
            omni_nixos_install_packages
            ;;
    esac
    return 0
}

omni_run_platform_configure() {
    local os="$1"
    case "$os" in
        arch)
            omni_arch_post_install
            ;;
        nixos)
            omni_nixos_post_install
            ;;
    esac
    return 0
}

omni_configure_brightness() {
    if [[ "$OMNI_SKIP_BRIGHTNESS" == "1" ]]; then
        omni_info "Brightness keybinds left untouched (--skip-brightness-tweak)."
        return 0
    fi
    omni_configure_brightness_keybinds
}

# omni_finish <os>
omni_finish() {
    local os="$1"

    omni_write_state_info "$os"
    omni_check_required_dependencies after
    omni_step "Done"
    omni_summary_print
    printf '\n%sInstallation finished.%s\n' "$OMNI_C_BOLD" "$OMNI_C_RESET"
    omni_info "Backups:    ${OMNI_BACKUP_DIR:-none}"
    omni_info "Manifest:   $(omni_manifest_path)"
    omni_info "Uninstall:  bash $OMNI_SRC_DIR/scripts/uninstall.sh --list"
    omni_note "Log out and back in (or reboot) so Hyprland picks up the new configuration."
}

# ------------------------------------------------------------------- main

main() {
    omni_parse_args "$@"

    case "$OMNI_MODE" in
        help)
            omni_usage
            exit "$OMNI_EXIT_OK"
            ;;
        version)
            printf '%s\n' "$OMNI_INSTALLER_VERSION"
            exit "$OMNI_EXIT_OK"
            ;;
        check-deps)
            if omni_check_dependencies --include-optional; then
                exit "$OMNI_EXIT_OK"
            fi
            exit "$OMNI_EXIT_DEPENDENCY"
            ;;
        list-deps)
            omni_print_dependency_table
            exit "$OMNI_EXIT_OK"
            ;;
        list-groups)
            omni_arch_print_groups
            exit "$OMNI_EXIT_OK"
            ;;
        list-modules)
            omni_module_print_table
            exit "$OMNI_EXIT_OK"
            ;;
    esac

    OMNI_SRC_DIR="${OMNI_SRC_DIR:-$SCRIPT_DIR}"
    OMNI_SRC_DIR="$(cd -- "$OMNI_SRC_DIR" && pwd -P)"

    omni_detect_os
    omni_banner
    local os
    os="$(omni_require_supported_os)"
    omni_prepare_repo
    omni_state_init
    omni_backup_init

    omni_select_modules
    omni_print_plan "$os"

    if ! omni_confirm "Proceed with the installation?" y; then
        omni_die "$OMNI_EXIT_ABORTED" "Aborted on request; nothing was changed."
    fi

    omni_check_required_dependencies before

    if [[ "$OMNI_SKIP_PACKAGES" != "1" ]]; then
        omni_run_platform "$os"
    fi

    if [[ "$OMNI_SKIP_CONFIG" != "1" ]]; then
        omni_install_modules "${OMNI_SELECTED_MODULES[@]}"
        omni_install_fastfetch "$os"
        omni_touch_qmlls
        omni_write_cursor_default
        if omni_module_selected shell; then
            omni_configure_fish_env
        fi
        omni_configure_brightness
        omni_ensure_theme
    else
        omni_info "Skipping configuration files (--skip-config)."
    fi

    if [[ "$OMNI_SKIP_PACKAGES" != "1" ]]; then
        omni_run_platform_packages "$os"
    fi

    omni_install_cli
    omni_run_platform_configure "$os"
    omni_finish "$os"
}

main "$@"
