#!/usr/bin/env bash
# shellcheck shell=bash
#
# Module (component) registry.
#
# The repository already splits the desktop into directories which map 1:1 to
# directories under ~/.config. This registry makes that mapping explicit so
# that the installer can offer individual components, check only the
# dependencies a component needs, and document what each one does.
#
# Record format:
#   name|required|source-directories(comma separated)|external commands|description

if [[ -n "${OMNI_MODULES_SOURCED:-}" ]]; then
    return 0
fi
OMNI_MODULES_SOURCED=1

OMNI_MODULES=(
    "core|yes|hypr,quickshell,color-schemes,matugen|hyprctl,quickshell,jq|Hyprland session, Quickshell shell, colour engine and matugen templates"
    "shell|no|fish,starship.toml|fish|Fish shell configuration and Starship prompt"
    "terminal|no|wezterm|wezterm|WezTerm terminal emulator configuration"
    "editor|no|nvim|nvim|Neovim configuration"
    "monitors|no|btop,nvtop,cava,fastfetch|fastfetch|System monitor, GPU monitor, audio visualiser and fastfetch"
    "appearance|no|nwg-look,qt5ct,qt6ct,qtengine||GTK and Qt appearance settings"
    "spotify|no|spicetify|spicetify|Spotify theming through Spicetify"
)

# Files that live directly in ~/.config instead of in a directory of their own.
omni_module_target_name() {
    case "$1" in
        starship.toml) printf 'starship.toml\n' ;;
        *) printf '%s\n' "$(basename -- "$1")" ;;
    esac
}

# omni_module_names -> one module name per line, in registry order
omni_module_names() {
    local record
    for record in "${OMNI_MODULES[@]}"; do
        printf '%s\n' "${record%%|*}"
    done
}

# omni_module_field <name> <field-number>  (1=name 2=required 3=sources 4=commands 5=description)
omni_module_field() {
    local want="$1" index="$2" record name fields
    for record in "${OMNI_MODULES[@]}"; do
        name="${record%%|*}"
        if [[ "$name" != "$want" ]]; then
            continue
        fi
        IFS='|' read -r -a fields <<<"$record"
        printf '%s\n' "${fields[$((index - 1))]}"
        return 0
    done
    return 1
}

omni_module_exists() {
    local want="$1" name
    while IFS= read -r name; do
        if [[ "$name" == "$want" ]]; then
            return 0
        fi
    done < <(omni_module_names)
    return 1
}

omni_module_is_required() {
    [[ "$(omni_module_field "$1" 2)" == "yes" ]]
}

omni_module_sources() {
    local raw
    raw="$(omni_module_field "$1" 3)"
    printf '%s\n' "${raw//,/ }"
}

omni_module_commands() {
    local raw
    raw="$(omni_module_field "$1" 4)"
    printf '%s\n' "${raw//,/ }"
}

omni_module_description() {
    omni_module_field "$1" 5
}

# omni_module_print_table
omni_module_print_table() {
    local name mark
    printf '%-12s %-9s %s\n' "MODULE" "REQUIRED" "DESCRIPTION"
    while IFS= read -r name; do
        if omni_module_is_required "$name"; then
            mark="yes"
        else
            mark="optional"
        fi
        printf '%-12s %-9s %s\n' "$name" "$mark" "$(omni_module_description "$name")"
    done < <(omni_module_names)
}

# omni_module_validate_selection <space separated names>
# Prints the unknown names (empty when everything is valid).
omni_module_validate_selection() {
    local name
    for name in $1; do
        if ! omni_module_exists "$name"; then
            printf '%s\n' "$name"
        fi
    done
}

# omni_module_selection_contains <name>
# Uses OMNI_SELECTED_MODULES (set by install.sh).
omni_module_selected() {
    local name="$1" candidate
    for candidate in ${OMNI_SELECTED_MODULES:-}; do
        if [[ "$candidate" == "$name" ]]; then
            return 0
        fi
    done
    return 1
}

# omni_module_has_source <module> <source-directory>
omni_module_owns_source() {
    local module="$1" source="$2" candidate
    for candidate in $(omni_module_sources "$module"); do
        if [[ "$candidate" == "$source" ]]; then
            return 0
        fi
    done
    return 1
}

# omni_module_for_source <source-directory> -> module name or empty
omni_module_for_source() {
    local source="$1" name
    while IFS= read -r name; do
        if omni_module_owns_source "$name" "$source"; then
            printf '%s\n' "$name"
            return 0
        fi
    done < <(omni_module_names)
    printf '\n'
}

# omni_module_target <source-relative-to-repo> [config-root]
omni_module_target() {
    local source="$1" root="${2:-$(omni_config_home)}"
    printf '%s\n' "${root%/}/$(omni_module_target_name "$source")"
}

# omni_modules_resolve_sources -> every source directory of every module
omni_modules_all_sources() {
    local name source
    while IFS= read -r name; do
        for source in $(omni_module_sources "$name"); do
            printf '%s\n' "$source"
        done
    done < <(omni_module_names)
}

# omni_module_required_names -> modules that cannot be deselected
omni_module_required_names() {
    local name
    while IFS= read -r name; do
        if omni_module_is_required "$name"; then
            printf '%s\n' "$name"
        fi
    done < <(omni_module_names)
}

# omni_module_select <comma or space separated names>
# Validates the selection, always keeps the required modules and stores the
# result in OMNI_SELECTED_MODULES (used by install.sh and uninstall.sh).
omni_module_select() {
    local raw="${1:-}" token required candidate existing seen
    local -a requested=()
    local -a unique=()

    IFS=', ' read -r -a requested <<<"$raw"
    OMNI_SELECTED_MODULES=()

    for token in "${requested[@]}"; do
        if [[ -z "$token" ]]; then
            continue
        fi
        if ! omni_module_exists "$token"; then
            omni_die "$OMNI_EXIT_USAGE" "Unknown component '$token'. Valid components: $(omni_module_names | tr '\n' ' ')"
        fi
        OMNI_SELECTED_MODULES+=("$token")
    done

    while IFS= read -r required; do
        omni_module_selected "$required" || OMNI_SELECTED_MODULES+=("$required")
    done < <(omni_module_required_names)

    for candidate in "${OMNI_SELECTED_MODULES[@]}"; do
        seen=0
        for existing in "${unique[@]}"; do
            if [[ "$existing" == "$candidate" ]]; then
                seen=1
            fi
        done
        if (( seen == 0 )); then
            unique+=("$candidate")
        fi
    done
    OMNI_SELECTED_MODULES=("${unique[@]}")
}
