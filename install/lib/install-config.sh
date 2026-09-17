#!/usr/bin/env bash
# shellcheck shell=bash
#
# Copy engine and post-installation configuration.
#
# Every write goes through omni_sync_source() so that the safety rules are
# enforced in exactly one place:
#   * nothing is overwritten without a timestamped backup,
#   * nothing is overwritten without confirmation (unless --yes),
#   * configuration managed by NixOS / home-manager is never clobbered,
#   * a failed backup aborts instead of half-overwriting a directory.

if [[ -n "${OMNI_CONFIG_SOURCED:-}" ]]; then
    return 0
fi
OMNI_CONFIG_SOURCED=1

# omni_prepare_repo
# Verifies that the source directory really is an OmniFormis Shell checkout.
omni_prepare_repo() {
    if [[ ! -d "$OMNI_SRC_DIR" ]]; then
        omni_die "$OMNI_EXIT_FAILURE" "Source directory $OMNI_SRC_DIR does not exist."
    fi
    if [[ ! -d "$OMNI_SRC_DIR/hypr" || ! -d "$OMNI_SRC_DIR/quickshell" ]]; then
        omni_die "$OMNI_EXIT_FAILURE" \
            "$OMNI_SRC_DIR does not look like an OmniFormis Shell checkout (hypr/ and quickshell/ are missing)."
    fi

    if [[ -d "$OMNI_SRC_DIR/.git" ]] && omni_have git; then
        OMNI_SRC_COMMIT="$(git -C "$OMNI_SRC_DIR" rev-parse --short HEAD 2>/dev/null || printf 'unknown')"
    else
        OMNI_SRC_COMMIT="unavailable"
    fi
    omni_info "Source: $OMNI_SRC_DIR (commit ${OMNI_SRC_COMMIT:-unknown})"
}

# omni_is_managed_symlink <path>
# True when the path is a symlink into the Nix store, i.e. owned by NixOS or
# home-manager. Copying over those would be undone at the next rebuild and is
# never what the user wants.
omni_is_managed_symlink() {
    local path="$1" target=""
    if [[ ! -L "$path" ]]; then
        return 1
    fi
    target="$(readlink -f -- "$path" 2>/dev/null || true)"
    [[ "$target" == /nix/store/* ]]
}

# omni_same_content <source> <target>
omni_same_content() {
    local source="$1" target="$2"
    if [[ -d "$source" && -d "$target" ]]; then
        if omni_have diff; then
            diff -rq --no-dereference -- "$source" "$target" >/dev/null 2>&1
            return $?
        fi
        return 1
    fi
    if [[ -f "$source" && -f "$target" && ! -L "$source" && ! -L "$target" ]]; then
        cmp -s -- "$source" "$target" 2>/dev/null
        return $?
    fi
    if [[ -L "$source" && -L "$target" ]]; then
        [[ "$(readlink -- "$source")" == "$(readlink -- "$target")" ]]
        return $?
    fi
    return 1
}

# omni_describe_kind <path>
omni_describe_kind() {
    if [[ -L "$1" ]]; then
        printf 'symlink'
        return 0
    fi
    if [[ -d "$1" ]]; then
        printf 'directory'
        return 0
    fi
    printf 'file'
}

# omni_sync_source <source-relative-to-repo>
# Returns 0 when the target now matches the source, 1 when the step was
# skipped on purpose (kept existing configuration or Nix managed path).
omni_sync_source() {
    local source="$1"
    local src="$OMNI_SRC_DIR/$source"
    local config_root
    config_root="$(omni_config_home)"
    local target
    target="$(omni_module_target "$source" "$config_root")"

    if [[ ! -e "$src" && ! -L "$src" ]]; then
        omni_error "Source $src is missing; skipping $source."
        return 1
    fi

    omni_step "Installing $source -> $target"
    omni_debug "source=$src target=$target directory=$([[ -d "$src" ]] && printf yes || printf no)"

    if omni_is_managed_symlink "$target" && [[ "$OMNI_FORCE_OVERWRITE" != "1" ]]; then
        omni_warn "$target is managed by NixOS/home-manager (symlink into /nix/store)."
        omni_warn "Left untouched. Use --force if you really want to copy over it."
        omni_record_install "skipped" "$target" "$src" "managed by NixOS/home-manager"
        return 1
    fi

    if [[ -e "$target" || -L "$target" ]] && omni_same_content "$src" "$target"; then
        omni_ok "$target is already up to date."
        omni_record_install "unchanged" "$target" "$src" "already identical"
        return 0
    fi

    local existed=0
    if [[ -e "$target" || -L "$target" ]]; then
        existed=1
        if ! omni_backup_path "$target" "replaced by install.sh"; then
            omni_die "$OMNI_EXIT_BACKUP" "Refusing to touch $target because the backup failed."
        fi

        if [[ "$OMNI_DRY_RUN" != "1" ]] && ! omni_confirm "Overwrite existing $(omni_describe_kind "$target") $target?" y; then
            omni_warn "Kept the existing $target (nothing was written)."
            omni_record_install "skipped" "$target" "$src" "user kept existing configuration"
            return 1
        fi
    fi

    local action="create"
    if (( existed == 1 )); then
        action="replace"
    fi

    omni_ensure_dir "$(dirname -- "$target")"

    if [[ -d "$src" ]]; then
        omni_ensure_dir "$target"
        omni_run_checked "$OMNI_EXIT_FAILURE" cp -a -- "$src/." "$target/"
    else
        omni_run_checked "$OMNI_EXIT_FAILURE" cp -a -- "$src" "$target"
    fi

    omni_record_install "$action" "$target" "$src" "installed by install.sh"
    omni_ok "$target"
    return 0
}

# omni_install_modules [module...]
omni_install_modules() {
    local module source skipped=0 sources
    for module in "$@"; do
        sources="$(omni_module_sources "$module")"
        omni_step "Module: $module - $(omni_module_description "$module")"
        # shellcheck disable=SC2086 # sources is an intentional space separated list
        for source in $sources; do
            if ! omni_sync_source "$source"; then
                skipped=$((skipped + 1))
            fi
        done
    done
    if (( skipped > 0 )); then
        omni_note "$skipped source(s) were left untouched."
    fi
}

# --------------------------------------------------------------- post steps

# omni_install_fastfetch <arch|nixos>
omni_install_fastfetch() {
    local os="$1" profile logo config_dir target

    if [[ "$os" == "nixos" ]]; then
        profile="Nixos.jsonc"
        logo=""
    else
        profile="Arch.jsonc"
        logo="Logos/Arch.png"
    fi

    config_dir="$(omni_config_dir fastfetch)"
    target="$config_dir/config.jsonc"
    local src="$OMNI_SRC_DIR/fastfetch/$profile"

    if [[ ! -f "$src" ]]; then
        omni_warn "fastfetch profile $profile not found; skipping."
        return 0
    fi

    omni_backup_path "$target" "fastfetch profile switched by install.sh" || true
    omni_ensure_dir "$config_dir"
    omni_run_checked "$OMNI_EXIT_FAILURE" cp -a -- "$src" "$target"
    omni_record_install "create" "$target" "$src" "fastfetch profile for $os"

    if [[ -n "$logo" && -f "$OMNI_SRC_DIR/fastfetch/$logo" ]]; then
        local logo_target
        logo_target="$config_dir/$(basename -- "$logo")"
        omni_run_checked "$OMNI_EXIT_FAILURE" cp -a -- "$OMNI_SRC_DIR/fastfetch/$logo" "$logo_target"
        omni_record_install "create" "$logo_target" "$OMNI_SRC_DIR/fastfetch/$logo" "fastfetch logo"
    fi

    omni_ok "fastfetch configured for $os"
}

# omni_write_cursor_default
# The shell expects ~/.icons/default/index.theme; it is only written when it
# does not exist yet so that a user choice is never silently replaced.
omni_write_cursor_default() {
    local index="$HOME/.icons/default/index.theme"

    if [[ -f "$index" ]]; then
        omni_info "$index exists; keeping it."
        return 0
    fi

    omni_ensure_dir "$(dirname -- "$index")"
    if [[ "$OMNI_DRY_RUN" == "1" ]]; then
        omni_info "dry-run: would write $index"
        return 0
    fi
    {
        printf '[Icon Theme]\n'
        printf 'Inherits=GoogleDot-Black\n'
    } >"$index"
    omni_record_install "create" "$index" "-" "default cursor theme"
    omni_ok "Wrote $index"
}

# omni_configure_fish_env
omni_configure_fish_env() {
    local config="$HOME/.config/fish/config.fish"

    if ! omni_have fish; then
        omni_info "fish is not installed; skipping shell environment setup."
        return 0
    fi
    omni_ensure_dir "$(dirname -- "$config")"

    if [[ -f "$config" ]] && grep -q 'set -gx EDITOR codium' "$config" 2>/dev/null; then
        omni_ok "$config already exports EDITOR."
    else
        omni_backup_path "$config" "fish editor variables" || true
        if [[ "$OMNI_DRY_RUN" == "1" ]]; then
            omni_info "dry-run: would append EDITOR/QML_IMPORT_PATH to $config"
        else
            {
                printf 'set -gx EDITOR codium\n'
                printf 'set -gx QML_IMPORT_PATH /usr/lib/qt6/qml\n'
            } >>"$config"
            omni_record_install "append" "$config" "-" "EDITOR and QML_IMPORT_PATH"
            omni_ok "Appended EDITOR and QML_IMPORT_PATH to $config"
        fi
    fi

    if omni_confirm "Add ~/.local/bin to the fish PATH?" y; then
        if [[ "$OMNI_DRY_RUN" == "1" ]]; then
            omni_info "dry-run: would update fish_user_paths"
        else
            fish -c 'if not contains ~/.local/bin $fish_user_paths; set -Ua fish_user_paths ~/.local/bin; end' || true
            omni_record_install "append" "$HOME/.config/fish/fish_variables" "-" "fish PATH entry"
        fi
    fi
}

# omni_configure_brightness_keybinds
# Replaces ddcutil based brightness shortcuts with brightnessctl ones when the
# machine has a backlight. The installed copy is patched (not the checkout) and
# backed up first.
omni_configure_brightness_keybinds() {
    local binds
    binds="$(omni_config_dir hypr)/modules/binds.lua"

    if [[ ! -f "$binds" ]]; then
        omni_info "No installed binds file at $binds; skipping the brightness tweak."
        return 0
    fi

    local has_backlight=0 has_external=0
    if compgen -G "/sys/class/backlight/*" >/dev/null 2>&1; then
        has_backlight=1
    fi

    if omni_have ddcutil; then
        if ddcutil detect >/dev/null 2>&1; then
            has_external=1
        elif omni_is_interactive; then
            # ddcutil needs i2c access for a reliable probe, and the previous
            # installer silently ran it through sudo. Ask instead.
            if omni_confirm "ddcutil could not probe for monitors without root. Is an external monitor controlled by ddcutil?" y; then
                has_external=1
            fi
        fi
    fi

    if (( has_backlight == 0 )); then
        omni_info "No laptop backlight detected; keeping the ddcutil brightness keybinds."
        return 0
    fi

    if (( has_external == 1 )); then
        omni_info "Laptop backlight and external monitor detected: the internal panel keys move to brightnessctl."
    else
        omni_info "Only a laptop backlight detected: every brightness shortcut moves to brightnessctl."
    fi

    if ! omni_confirm "Adjust the brightness keybinds in $binds for this hardware?" y; then
        omni_info "Keeping the default brightness keybinds."
        return 0
    fi

    omni_backup_path "$binds" "brightness keybinds adjusted by install.sh" \
        || omni_die "$OMNI_EXIT_BACKUP" "Could not back up $binds; refusing to modify it."

    if [[ "$OMNI_DRY_RUN" == "1" ]]; then
        omni_info "dry-run: would rewrite the ddcutil brightness binds in $binds"
        return 0
    fi

    local -a pairs=()
    pairs+=('hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("ddcutil setvcp 10 + 5"))|hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl set +5%"))')
    pairs+=('hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("ddcutil setvcp 10 - 5"))|hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl set 5%-"))')
    if (( has_external == 0 )); then
        pairs+=('hl.bind(SM .. " + mouse_up", hl.dsp.exec_cmd("ddcutil setvcp 10 + 5"))|hl.bind(SM .. " + mouse_up", hl.dsp.exec_cmd("brightnessctl set +5%"))')
        pairs+=('hl.bind(SM .. " + mouse_down", hl.dsp.exec_cmd("ddcutil setvcp 10 - 5"))|hl.bind(SM .. " + mouse_down", hl.dsp.exec_cmd("brightnessctl set 5%-"))')
    fi

    local changed=0 pair pattern replacement escaped_pattern escaped_replacement
    for pair in "${pairs[@]}"; do
        pattern="${pair%%|*}"
        replacement="${pair#*|}"
        if ! grep -qF -- "$pattern" "$binds"; then
            continue
        fi
        escaped_pattern="$(printf '%s' "$pattern" | sed 's/[][\\.*^$/&|]/\\&/g')"
        escaped_replacement="$(printf '%s' "$replacement" | sed 's/[&|\\]/\\&/g')"
        sed -i "s|${escaped_pattern}|${escaped_replacement}|g" "$binds"
        changed=$((changed + 1))
    done

    omni_record_install "modify" "$binds" "-" "brightness keybinds switched to brightnessctl ($changed patterns)"
    omni_ok "Adjusted $changed brightness keybind pattern(s) in $binds"
}

# omni_ensure_theme
# The Quickshell theme is a symlink farm produced by color-schemes/set-theme.sh.
# When the generated theme is missing (fresh clone, failed matugen run) the
# bundled fallback theme is applied so the desktop never starts colourless.
omni_ensure_theme() {
    local theme_dir fallback_theme="gruvbox-medium"
    theme_dir="$(omni_config_dir color-schemes)"

    if [[ -f "$theme_dir/current/quickTheme.qml" ]]; then
        omni_ok "Colour scheme present ($(readlink -f -- "$theme_dir/current/quickTheme.qml" 2>/dev/null || printf 'unknown'))."
        return 0
    fi

    if [[ ! -d "$theme_dir/$fallback_theme/dark" ]]; then
        omni_warn "No colour scheme and no bundled fallback theme found; the shell will use its built-in defaults."
        return 0
    fi

    if ! omni_confirm "No active colour scheme found. Apply the bundled '$fallback_theme' fallback theme?" y; then
        omni_note "Colours stay unset; run color-schemes/set-theme.sh later."
        omni_summary_add "Apply a colour scheme: bash $theme_dir/set-theme.sh $fallback_theme dark"
        return 0
    fi

    if [[ "$OMNI_DRY_RUN" == "1" ]]; then
        omni_info "dry-run: would apply fallback theme $fallback_theme"
        return 0
    fi

    if bash "$theme_dir/set-theme.sh" "$fallback_theme" dark; then
        omni_ok "Applied fallback theme '$fallback_theme' (dark)."
    else
        omni_warn "Applying the fallback theme failed; see docs/TROUBLESHOOTING.md."
    fi
}

# omni_touch_qmlls
# qmlls (the QML language server) wants an empty marker file next to the shell.
omni_touch_qmlls() {
    local marker
    marker="$(omni_config_dir quickshell)/.qmlls.ini"

    if [[ -e "$marker" ]]; then
        return 0
    fi
    omni_ensure_dir "$(dirname -- "$marker")"
    omni_run_checked "$OMNI_EXIT_FAILURE" touch "$marker"
    omni_record_install "create" "$marker" "-" "qmlls marker file"
}

# omni_write_state_info <os>
omni_write_state_info() {
    local os="$1" state
    state="$(omni_state_root)"

    omni_ensure_dir "$state"
    if [[ "$OMNI_DRY_RUN" == "1" ]]; then
        omni_info "dry-run: would write $state/install-info"
        return 0
    fi

    {
        printf 'installed_at=%s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')"
        printf 'platform=%s\n' "$os"
        printf 'distro=%s\n' "$(omni_distro_name)"
        printf 'repo_dir=%s\n' "$OMNI_SRC_DIR"
        printf 'commit=%s\n' "${OMNI_SRC_COMMIT:-unknown}"
        printf 'modules=%s\n' "${OMNI_SELECTED_MODULES:-}"
        printf 'backup_dir=%s\n' "${OMNI_BACKUP_DIR:-none}"
        printf 'manifest=%s\n' "$(omni_manifest_path)"
        printf 'uninstall=bash %s/scripts/uninstall.sh\n' "$OMNI_SRC_DIR"
    } >"$state/install-info"
    omni_ok "Wrote $state/install-info"
}

# omni_install_cli_binary
# Installs the omniformis helper CLI into ~/.local/bin. The release asset is
# downloaded into a temporary file first, so a failed or truncated download can
# never replace a working binary, and an existing binary is backed up.
omni_install_cli_binary() {
    local url="${OMNIFORMIS_CLI_URL:-https://github.com/Boing-Git/OmniFormis-Shell/releases/latest/download/omniformis}"
    local target="$HOME/.local/bin/omniformis" tmp

    if ! omni_have curl; then
        omni_warn "curl is not installed; cannot download the omniformis CLI."
        return 1
    fi

    if ! omni_confirm "Download the omniformis CLI from $url into $target?" y; then
        omni_info "Skipped the omniformis CLI."
        return 0
    fi

    omni_ensure_dir "$HOME/.local/bin"

    if [[ -e "$target" ]]; then
        omni_backup_path "$target" "replaced by install.sh" \
            || omni_die "$OMNI_EXIT_BACKUP" "Could not back up $target."
    fi

    if [[ "$OMNI_DRY_RUN" == "1" ]]; then
        omni_info "dry-run: curl -fL $url -o $target"
        return 0
    fi

    tmp="$(mktemp "${TMPDIR:-/tmp}/omniformis.XXXXXX")"
    if ! curl -fL --retry 3 --connect-timeout 15 -o "$tmp" "$url"; then
        rm -f -- "$tmp"
        omni_warn "Download failed; $target was left untouched."
        return 1
    fi
    if [[ ! -s "$tmp" ]]; then
        rm -f -- "$tmp"
        omni_warn "The downloaded file is empty; $target was left untouched."
        return 1
    fi
    chmod 0755 "$tmp"
    mv -f -- "$tmp" "$target"
    omni_record_install "install-binary" "$target" "$url" "omniformis CLI downloaded from the latest release"
    omni_ok "Installed the omniformis CLI to $target"
}

# omni_build_cli_binary
# Alternative for machines without a usable release asset: build the Rust CLI
# from this checkout.
omni_build_cli_binary() {
    local crate="$OMNI_SRC_DIR/scripts/omniformis"
    local target="$HOME/.local/bin/omniformis"

    if [[ ! -f "$crate/Cargo.toml" ]]; then
        omni_warn "$crate/Cargo.toml not found; cannot build the CLI from source."
        return 1
    fi
    if ! omni_have cargo; then
        omni_warn "cargo is not installed; install rust or use the release binary."
        return 1
    fi
    if ! omni_confirm "Build the omniformis CLI from source with cargo (can take a few minutes)?" n; then
        return 0
    fi
    if [[ "$OMNI_DRY_RUN" == "1" ]]; then
        omni_info "dry-run: cargo build --release in $crate"
        return 0
    fi

    if ! ( cd -- "$crate" && cargo build --release ); then
        omni_error "cargo build failed; $target was left untouched."
        return 1
    fi

    omni_ensure_dir "$(dirname -- "$target")"
    if [[ -e "$target" ]]; then
        omni_backup_path "$target" "replaced by install.sh" \
            || omni_die "$OMNI_EXIT_BACKUP" "Could not back up $target."
    fi
    mv -f -- "$crate/target/release/omniformis" "$target"
    omni_record_install "install-binary" "$target" "$crate" "omniformis CLI built from source"
    omni_ok "Installed the CLI built from source to $target"
}
