#!/usr/bin/env bash
# shellcheck shell=bash
#
# Dependency inventory and detection.
#
# The tables below are the single source of truth for
#   * what the installer checks before touching anything,
#   * what docs/DEPENDENCIES.md documents,
#   * the actionable "how do I install this" hints.
#
# Record format:
#   command|level|module|arch-package|aur(0/1)|purpose
# level is either "required" (the base session does not start without it) or
# "optional" (only the matching feature is unavailable).

if [[ -n "${OMNI_DEPS_SOURCED:-}" ]]; then
    return 0
fi
OMNI_DEPS_SOURCED=1

OMNI_DEPENDENCY_TABLE=(
    "bash|required|core|bash|0|the installer and every helper script are bash"
    "git|required|core|git|0|clones and updates the repository"
    "curl|required|core|curl|0|downloads the omniformis CLI and the Rubik font"
    "jq|required|core|jq|0|the Quickshell settings app reads and writes settings with jq"
    "hyprctl|required|core|hyprland|0|Hyprland compositor; the session cannot start without it"
    "quickshell|required|core|quickshell-git|1|the shell itself"
    "matugen|optional|core|matugen-bin|1|generates Material You colours from the wallpaper"
    "convert|optional|core|imagemagick|0|matugen wrapper analyses the wallpaper (ImageMagick)"
    "bc|optional|core|bc|0|wallpaper metric comparisons in the matugen wrapper"
    "awww|optional|core|awww-git|1|wallpaper daemon started by hypr/modules/autostart.lua"
    "mpvpaper|optional|core|mpvpaper|1|video wallpapers"
    "wezterm|optional|terminal|wezterm|0|default terminal in the keybindings"
    "fish|optional|shell|fish|0|shell configuration shipped by this repository"
    "starship|optional|shell|starship|0|prompt used by the fish configuration"
    "nvim|optional|editor|neovim|0|Neovim configuration"
    "codium|optional|editor|vscodium-bin|1|VS Codium, the configured editor"
    "cliphist|optional|core|cliphist|0|clipboard history used by the launcher"
    "wl-paste|optional|core|wl-clipboard|0|clipboard watchers in autostart.lua"
    "hypridle|optional|core|hypridle|0|idle daemon configured by hypr/hypridle.conf"
    "hyprpm|optional|core|hyprland|0|Hyprland plugin manager (hyprglass)"
    "gtk-launch|optional|appearance|gtk3|0|launching desktop entries from the shell"
    "gsettings|optional|appearance|glib2|0|switches the GTK colour scheme with the theme"
    "nwg-look|optional|appearance|nwg-look|0|GTK settings shipped by this repository"
    "playerctl|optional|core|playerctl|0|media controls in the shell and keybindings"
    "cava|optional|monitors|cava|0|audio visualiser module"
    "fastfetch|optional|monitors|fastfetch|0|system information module"
    "btop|optional|monitors|btop|0|system monitor keybinding"
    "nvtop|optional|monitors|nvtop|0|GPU monitor keybinding"
    "ddcutil|optional|monitors|ddcutil|0|external monitor brightness keybindings"
    "brightnessctl|optional|monitors|brightnessctl|0|laptop brightness keybindings"
    "grim|optional|extras|grim|0|screenshots"
    "slurp|optional|extras|slurp|0|region selection for screenshots"
    "satty|optional|extras|satty|0|screenshot annotation"
    "swappy|optional|extras|swappy|0|screenshot editing"
    "hyprpicker|optional|extras|hyprpicker|0|colour picker keybinding"
    "xdg-open|optional|extras|xdg-utils|0|opening files and links from the launcher"
    "blanket|optional|extras|blanket|0|started together with the wallpaper daemon"
    "python3|optional|extras|python|0|extract_steam_games.py and the lens helper"
    "unzip|optional|extras|unzip|0|extracts the manually installed Rubik font"
    "fc-cache|optional|extras|fontconfig|0|rebuilds the font cache after installing fonts"
    "spicetify|optional|spotify|spicetify-cli|1|Spotify theming"
    "spotify|optional|spotify|spotify|1|Spotify client used by the local wrapper"
    "pavucontrol|optional|core|pavucontrol|0|audio control keybinding"
    "nmcli|optional|core|networkmanager|0|network module of the shell"
    "bluetoothctl|optional|core|bluez-utils|0|Bluetooth control centre"
    "adwaita-steam-gtk|optional|extras|adwaita-steam-gtk|1|reloads the Steam GTK theme"
)

# Record format: fontconfig-pattern|level|module|arch-package|aur(0/1)|purpose
OMNI_FONT_TABLE=(
    "Material Symbols Outlined|required|core|ttf-material-symbols-variable|1|icon font used by every Quickshell widget"
    "Google Sans Flex|optional|core|-|0|UI font set in quickshell/theme/variables.js; not packaged upstream"
    "Rubik|optional|core|ttf-rubik|0|font the installer can download manually"
    "JetBrainsMono Nerd Font|optional|extras|ttf-jetbrains-mono-nerd|0|monospace Nerd Font used by editors and prompts"
)

# Record format: unit|level|scope(user/system)|purpose
OMNI_SERVICE_TABLE=(
    "pipewire|optional|user|audio stack used by the volume module"
    "wireplumber|optional|user|session manager for pipewire"
    "NetworkManager|optional|system|network module of the shell"
    "bluetooth|optional|system|Bluetooth control centre"
    "libvirtd|optional|system|virtual machines installed by the installer"
)

# omni_dep_field <command> <field-number>
omni_dep_field() {
    local want="$1" index="$2" record command fields
    for record in "${OMNI_DEPENDENCY_TABLE[@]}"; do
        command="${record%%|*}"
        if [[ "$command" != "$want" ]]; then
            continue
        fi
        IFS='|' read -r -a fields <<<"$record"
        printf '%s\n' "${fields[$((index - 1))]}"
        return 0
    done
    return 1
}

omni_dep_known() {
    omni_dep_field "$1" 2 >/dev/null
}

omni_dep_level() {
    omni_dep_field "$1" 2
}

omni_dep_purpose() {
    omni_dep_field "$1" 6
}

# omni_aur_helper -> yay | paru | (empty)
omni_aur_helper() {
    if omni_have yay; then
        printf 'yay\n'
        return 0
    fi
    if omni_have paru; then
        printf 'paru\n'
        return 0
    fi
    printf '\n'
}

# omni_install_hint <command> <os> -> printable installation hint
omni_install_hint() {
    local command="$1" os="$2"
    local package aur helper

    if ! omni_dep_known "$command"; then
        printf 'no packaged dependency is known for %s\n' "$command"
        return 0
    fi

    package="$(omni_dep_field "$command" 4)"
    aur="$(omni_dep_field "$command" 5)"

    case "$os" in
        arch)
            if [[ "$package" == "-" ]]; then
                printf 'not packaged; see docs/DEPENDENCIES.md\n'
                return 0
            fi
            if [[ "$aur" == "1" ]]; then
                helper="$(omni_aur_helper)"
                if [[ -n "$helper" ]]; then
                    printf '%s -S %s   (AUR)\n' "$helper" "$package"
                else
                    printf 'AUR package %s   (install an AUR helper such as yay first)\n' "$package"
                fi
                return 0
            fi
            printf 'sudo pacman -S %s\n' "$package"
            ;;
        nixos)
            printf 'add %s to environment.systemPackages / home.packages (see docs/DEPENDENCIES.md)\n' "$package"
            ;;
        *)
            printf 'install the equivalent of %s for your distribution\n' "$package"
            ;;
    esac
}

# omni_missing_commands [--include-optional]
# Prints one "command|level|purpose" per missing command.
omni_missing_commands() {
    local include_optional="${1:-}"
    local record command level

    for record in "${OMNI_DEPENDENCY_TABLE[@]}"; do
        IFS='|' read -r command level _ _ _ _ <<<"$record"
        if [[ "$level" == "optional" && "$include_optional" != "--include-optional" ]]; then
            continue
        fi
        if ! omni_have "$command"; then
            printf '%s|%s|%s\n' "$command" "$level" "$(omni_dep_purpose "$command")"
        fi
    done
}

# omni_missing_fonts [--include-optional]
omni_missing_fonts() {
    local include_optional="${1:-}"
    local record pattern family level
    local font_list=""

    if omni_have fc-list; then
        font_list="$(fc-list 2>/dev/null)"
    fi

    for record in "${OMNI_FONT_TABLE[@]}"; do
        IFS='|' read -r family level _ _ _ _ <<<"$record"
        if [[ "$level" == "optional" && "$include_optional" != "--include-optional" ]]; then
            continue
        fi
        if [[ -z "$font_list" ]]; then
            printf '%s|%s|fontconfig is not available, cannot verify\n' "$family" "$level"
            continue
        fi
        pattern="${family// /.*}"
        if ! grep -qiE "$pattern" <<<"$font_list"; then
            printf '%s|%s|%s\n' "$family" "$level" "$(omni_font_purpose "$family")"
        fi
    done
}

omni_font_purpose() {
    local want="$1" record family
    for record in "${OMNI_FONT_TABLE[@]}"; do
        family="${record%%|*}"
        if [[ "$family" == "$want" ]]; then
            printf '%s\n' "$(cut -d'|' -f6 <<<"$record")"
            return 0
        fi
    done
    printf 'font\n'
}

# omni_missing_services [--include-optional]
omni_missing_services() {
    local include_optional="${1:-}"
    local record unit level scope purpose

    if ! omni_have systemctl; then
        return 0
    fi

    for record in "${OMNI_SERVICE_TABLE[@]}"; do
        IFS='|' read -r unit level scope purpose <<<"$record"
        if [[ "$level" == "optional" && "$include_optional" != "--include-optional" ]]; then
            continue
        fi
        if [[ "$scope" == "user" ]]; then
            systemctl --user is-active --quiet "$unit" 2>/dev/null && continue
        else
            systemctl is-active --quiet "$unit" 2>/dev/null && continue
        fi
        printf '%s|%s|%s|%s\n' "$unit" "$level" "$scope" "$purpose"
    done
}

# omni_check_dependencies [--include-optional] [--skip-fonts]
# Prints a report and returns the number of missing *required* commands
# (capped at 255 by the shell) so callers can decide what to do.
omni_check_dependencies() {
    local include_optional=0 skip_fonts=0 arg
    for arg in "$@"; do
        case "$arg" in
            --include-optional) include_optional=1 ;;
            --skip-fonts) skip_fonts=1 ;;
        esac
    done

    local os missing=0 command level purpose
    os="$(omni_detect_os)"

    omni_step "Checking required dependencies"
    while IFS='|' read -r command level purpose; do
        [[ -z "$command" ]] && continue
        omni_error "missing: $command - $purpose"
        omni_info  "         install with: $(omni_install_hint "$command" "$os")"
        missing=$((missing + 1))
    done < <(omni_missing_commands)

    if [[ "$missing" -eq 0 ]]; then
        omni_ok "All required commands are available."
    fi

    if [[ "$skip_fonts" -eq 0 ]]; then
        local family
        while IFS='|' read -r family level purpose; do
            [[ -z "$family" ]] && continue
            omni_error "missing font: $family - $purpose"
            omni_note  "         see docs/DEPENDENCIES.md for the package name on your distribution"
            [[ "$level" == "required" ]] && missing=$((missing + 1))
        done < <(omni_missing_fonts)
    fi

    if [[ "$include_optional" -eq 1 ]]; then
        omni_step "Checking optional dependencies"
        while IFS='|' read -r command level purpose; do
            [[ -z "$command" ]] && continue
            omni_warn "optional, not installed: $command - $purpose"
            omni_info "         install with: $(omni_install_hint "$command" "$os")"
        done < <(omni_missing_commands --include-optional | grep '|optional|')

        local unit scope service_purpose
        while IFS='|' read -r unit level scope service_purpose; do
            [[ -z "$unit" ]] && continue
            omni_warn "optional service not running: $unit ($scope) - $service_purpose"
        done < <(omni_missing_services --include-optional)
    fi

    return "$missing"
}

# omni_print_missing_hints [required|optional]
# Actionable "install it like this" list for the commands that are missing.
omni_print_missing_hints() {
    local level="${1:-required}" os command item_level purpose
    os="$(omni_detect_os)"
    while IFS='|' read -r command item_level purpose; do
        if [[ -z "$command" ]]; then
            continue
        fi
        if [[ "$level" == "required" && "$item_level" != "required" ]]; then
            continue
        fi
        omni_info "  $command  ->  $(omni_install_hint "$command" "$os")"
    done < <(omni_missing_commands --include-optional)
}

# omni_print_dependency_table : machine friendly listing of every dependency
omni_print_dependency_table() {
    local record command level module package aur purpose
    printf '%-22s %-9s %-12s %-30s %s\n' COMMAND LEVEL MODULE ARCH-PACKAGE PURPOSE
    for record in "${OMNI_DEPENDENCY_TABLE[@]}"; do
        IFS='|' read -r command level module package aur purpose <<<"$record"
        printf '%-22s %-9s %-12s %-30s %s\n' "$command" "$level" "$module" "$package" "$purpose"
    done
}

# omni_report_dependencies
# Full human readable report, used by scripts/check-deps.sh.
omni_report_dependencies() {
    local os
    os="$(omni_detect_os)"

    printf '\n'
    omni_step "Environment"
    omni_info "$(omni_distro_name) - detected platform: $os"
    omni_info "session: $(omni_session_type), user: $(id -un), home: $HOME"

    printf '\n'
    omni_step "Required commands"
    local record command level _purpose
    for record in "${OMNI_DEPENDENCY_TABLE[@]}"; do
        IFS='|' read -r command level _ _ _ _ <<<"$record"
        [[ "$level" != "required" ]] && continue
        if omni_have "$command"; then
            printf '   [ok]   %-14s %s\n' "$command" "$(omni_dep_purpose "$command")"
        else
            printf '   [miss] %-14s %s\n' "$command" "$(omni_dep_purpose "$command")"
            printf '          -> %s' "$(omni_install_hint "$command" "$os")"
        fi
    done

    printf '\n'
    omni_step "Optional commands"
    for record in "${OMNI_DEPENDENCY_TABLE[@]}"; do
        IFS='|' read -r command level _ _ _ _ <<<"$record"
        [[ "$level" != "optional" ]] && continue
        if omni_have "$command"; then
            printf '   [ok]   %-14s %s\n' "$command" "$(omni_dep_purpose "$command")"
        else
            printf '   [ -- ] %-14s %s\n' "$command" "$(omni_dep_purpose "$command")"
        fi
    done

    printf '\n'
    omni_step "Fonts"
    local font_list=""
    if omni_have fc-list; then
        font_list="$(fc-list 2>/dev/null)"
    fi
    local family
    for record in "${OMNI_FONT_TABLE[@]}"; do
        family="${record%%|*}"
        if [[ -z "$font_list" ]]; then
            printf '   [ ?  ] %-24s fontconfig (fc-list) is not available\n' "$family"
            continue
        fi
        if grep -qiE "${family// /.*}" <<<"$font_list"; then
            printf '   [ok]   %-24s %s\n' "$family" "$(omni_font_purpose "$family")"
        else
            printf '   [miss] %-24s %s\n' "$family" "$(omni_font_purpose "$family")"
        fi
    done

    printf '\n'
    omni_step "Services"
    local unit scope purpose _level
    if ! omni_have systemctl; then
        omni_note "systemctl is not available; skipping service checks."
        return 0
    fi
    for record in "${OMNI_SERVICE_TABLE[@]}"; do
        IFS='|' read -r unit _level scope purpose <<<"$record"
        local state="not running"
        if [[ "$scope" == "user" ]]; then
            systemctl --user is-active --quiet "$unit" 2>/dev/null && state="active"
        else
            systemctl is-active --quiet "$unit" 2>/dev/null && state="active"
        fi
        printf '   %-8s %-16s %s (%s)\n' "[$state]" "$unit" "$purpose" "$scope"
    done
}
