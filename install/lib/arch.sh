#!/usr/bin/env bash
# shellcheck shell=bash
#
# Arch Linux specific installation steps.
#
# Everything in this file is Arch only. Nothing here may be called on NixOS;
# install.sh dispatches on the detected platform and the shared code in
# common.sh / install-config.sh never references pacman or an AUR helper.
#
# Package groups mirror what the previous installer installed, but each group
# can be declined instead of being installed unconditionally.

if [[ -n "${OMNI_ARCH_SOURCED:-}" ]]; then
    return 0
fi
OMNI_ARCH_SOURCED=1

# group|default(yes/no)|description|pacman packages|AUR packages
OMNI_ARCH_GROUP_TABLE=(
    "core|yes|Hyprland session, Quickshell runtime, colours, keybind tooling|git bash curl jq hyprland hypridle hyprpicker qt6-base qt6-declarative xkeyboard-config gtk3 gsettings-desktop-schemas dconf fontconfig networkmanager pipewire wl-clipboard cliphist playerctl cava ffmpeg fftw aubio inotify-tools starship fish wezterm base-devel cmake ninja pkgconf tk python python-gobject gobject-introspection cairo pango desktop-file-utils lua fastfetch ddcutil brightnessctl|quickshell-git ttf-material-symbols-variable matugen-bin awww-git"
    "apps|yes|Desktop applications used by the keybindings and launcher|nautilus file-roller loupe vlc zed neovim pavucontrol btop eza zoxide tree cbonsai fuzzel ncdu lm_sensors libqalculate unzip|python-emoji nitch upscayl-bin github-desktop-bin zen-browser mpvpaper app2unit pipes.sh hexecute-git python-pywebview python-flask"
    "fonts|yes|Fonts and icon themes used by the shell|papirus-icon-theme ttf-space-mono-nerd ttf-cascadia-code-nerd ttf-dejavu|papirus-folders googledot-cursor-theme ttf-space-mono"
    "screenshots|yes|Screenshot and annotation tools|grim slurp swappy satty xdg-utils blanket|"
    "virtualization|yes|Virtual machines (adds the user to libvirt and kvm)|qemu-desktop libvirt swtpm|"
    "gaming|yes|Game mode and the game launcher|gamemode prismlauncher|"
    "dev|yes|Editor tooling and Nix language servers|github-cli|vscodium-bin github-desktop-bin nixfmt nixd antigravity"
    "spotify|yes|Spotify with Spicetify theming|spotify|spicetify-cli"
)

# omni_arch_group_field <group> <field-number>
omni_arch_group_field() {
    local want="$1" index="$2" record name fields
    for record in "${OMNI_ARCH_GROUP_TABLE[@]}"; do
        IFS='|' read -r name _ _ _ _ <<<"$record"
        if [[ "$name" == "$want" ]]; then
            fields="$record"
            printf '%s' "$(cut -d'|' -f"$index" <<<"$fields")"
            return 0
        fi
    done
    return 1
}

omni_arch_group_names() {
    local record name
    for record in "${OMNI_ARCH_GROUP_TABLE[@]}"; do
        IFS='|' read -r name _ <<<"$record"
        printf '%s\n' "$name"
    done
}

# omni_arch_print_groups
omni_arch_print_groups() {
    local group description pacman_pkgs aur_pkgs pacman_count aur_count
    printf '%-16s %-7s %-46s %s\n' GROUP DEFAULT DESCRIPTION 'PACKAGES (repo+aur)'
    while IFS= read -r group; do
        description="$(omni_arch_group_field "$group" 3)"
        pacman_pkgs="$(omni_arch_group_field "$group" 4)"
        aur_pkgs="$(omni_arch_group_field "$group" 5)"
        pacman_count="$(wc -w <<<"$pacman_pkgs")"
        aur_count="$(wc -w <<<"$aur_pkgs")"
        printf '%-16s %-7s %-46s %s+%s\n' "$group" \
            "$(omni_arch_group_field "$group" 2)" "$description" "$pacman_count" "$aur_count"
    done < <(omni_arch_group_names)
}

# omni_arch_require_support
omni_arch_require_support() {
    omni_require_arch
    if [[ ! -f /etc/pacman.conf ]]; then
        omni_die "$OMNI_EXIT_UNSUPPORTED" "This does not look like a pacman based system."
    fi
    if [[ "$(omni_distro_id)" != "arch" ]]; then
        omni_warn "$(omni_distro_name) is Arch based; only plain Arch Linux is tested, so package names or paths may differ."
    fi
}

# omni_arch_ensure_helper -> prints the AUR helper to use
omni_arch_ensure_helper() {
    local helper=""

    if omni_have yay; then
        helper="yay"
    elif omni_have paru; then
        helper="paru"
    fi

    if [[ -n "$helper" ]]; then
        printf '%s\n' "$helper"
        return 0
    fi

    omni_warn "Neither yay nor paru is installed; the AUR packages in this installer need one of them."
    omni_warn "Requested packages: $(omni_arch_group_field core 5)"

    if [[ "$OMNI_DRY_RUN" == "1" ]]; then
        omni_info "dry-run: would install yay from the AUR"
        printf 'yay\n'
        return 0
    fi

    if ! omni_confirm "Build and install yay from the AUR now?" y; then
        omni_die "$OMNI_EXIT_ABORTED" "An AUR helper is required to continue. Aborting on request."
    fi

    local build_dir
    build_dir="$(mktemp -d -t omniformis-yay-XXXXXX)"
    # shellcheck disable=SC2064 # expand build_dir now, not when the trap fires
    trap "omni_remove_tmpdir '$build_dir'" EXIT

    omni_run_checked "$OMNI_EXIT_FAILURE" sudo pacman -S --needed --noconfirm git base-devel
    omni_run_checked "$OMNI_EXIT_FAILURE" git clone https://aur.archlinux.org/yay.git "$build_dir/yay"
    omni_run_checked "$OMNI_EXIT_FAILURE" bash -c "cd '$build_dir/yay' && makepkg -si --noconfirm"
    omni_remove_tmpdir "$build_dir"
    trap - EXIT

    if ! omni_have yay; then
        omni_die "$OMNI_EXIT_FAILURE" "yay installation failed."
    fi
    omni_ok "yay installed."
    printf 'yay\n'
}

# omni_remove_tmpdir <dir> : only ever removes a directory inside the temp root
omni_remove_tmpdir() {
    local dir="${1:-}"
    if [[ -z "$dir" || "$dir" != /tmp/* || "$dir" == "/tmp/" ]]; then
        omni_warn "Refusing to remove unexpected path '${dir}'."
        return 1
    fi
    if [[ "$OMNI_DRY_RUN" == "1" ]]; then
        omni_info "dry-run: would remove $dir"
        return 0
    fi
    rm -rf -- "$dir"
}

# omni_arch_choose_groups -> sets OMNI_ARCH_SELECTED_GROUPS
omni_arch_choose_groups() {
    OMNI_ARCH_SELECTED_GROUPS=()
    local group description default
    omni_step "System packages (pacman + AUR)"

    if [[ -n "${OMNI_ARCH_GROUPS_OVERRIDE:-}" ]]; then
        local requested
        IFS=',' read -r -a requested <<<"$OMNI_ARCH_GROUPS_OVERRIDE"
        local candidate
        for candidate in "${requested[@]}"; do
            if ! omni_arch_group_field "$candidate" 1 >/dev/null; then
                omni_die "$OMNI_EXIT_USAGE" "Unknown package group '${candidate}'. Valid groups: $(omni_arch_group_names | tr '\n' ' ')"
            fi
            OMNI_ARCH_SELECTED_GROUPS+=("$candidate")
        done
        omni_info "Package groups from --groups: ${OMNI_ARCH_SELECTED_GROUPS[*]:-none}"
        return 0
    fi

    if [[ "$OMNI_ASSUME_YES" == "1" ]] || ! omni_is_interactive; then
        while IFS= read -r group; do
            OMNI_ARCH_SELECTED_GROUPS+=("$group")
        done < <(omni_arch_group_names)
        omni_info "Non-interactive run: installing every package group (pass --groups to narrow this down)."
        return 0
    fi

    omni_note "Decline a group to skip it; nothing is installed without your consent."
    while IFS= read -r group; do
        description="$(omni_arch_group_field "$group" 3)"
        default="y"
        if omni_confirm "Install package group '$group' ($description)?" "$default"; then
            OMNI_ARCH_SELECTED_GROUPS+=("$group")
        fi
    done < <(omni_arch_group_names)
}

# omni_arch_install_packages
omni_arch_install_packages() {
    local helper group pacman_pkgs aur_pkgs
    local -a pacman_list=() aur_list=() group_pacman=() group_aur=()

    if (( ${#OMNI_ARCH_SELECTED_GROUPS[@]} == 0 )); then
        omni_note "No package group selected; skipping package installation."
        return 0
    fi

    for group in "${OMNI_ARCH_SELECTED_GROUPS[@]}"; do
        read -r -a group_pacman <<<"$(omni_arch_group_field "$group" 4)" || true
        read -r -a group_aur <<<"$(omni_arch_group_field "$group" 5)" || true
        pacman_list+=("${group_pacman[@]}")
        aur_list+=("${group_aur[@]}")
    done

    omni_step "Packages to install: ${#pacman_list[@]} from the official repositories, ${#aur_list[@]} from the AUR"
    if ! omni_confirm "Install these system packages now (requires sudo)?" y; then
        omni_note "Skipped package installation; the configuration files are still installed."
        omni_summary_add "Install the packages later: bash scripts/check-deps.sh --hints"
        return 0
    fi

    if ! omni_have sudo; then
        omni_die "$OMNI_EXIT_DEPENDENCY" "sudo is not available; install the packages manually (see docs/DEPENDENCIES.md)."
    fi

    if (( ${#pacman_list[@]} > 0 )); then
        omni_run_checked "$OMNI_EXIT_FAILURE" sudo pacman -S --needed --noconfirm "${pacman_list[@]}"
    fi

    if (( ${#aur_list[@]} == 0 )); then
        return 0
    fi

    helper="$(omni_arch_ensure_helper)"
    omni_run_checked "$OMNI_EXIT_FAILURE" "$helper" -S --needed --noconfirm \
        --answerclean None --answerdiff None --answeredit None "${aur_list[@]}"
}

# omni_arch_install_rubik_font
omni_arch_install_rubik_font() {
    local font_dir="$HOME/.local/share/fonts/Rubik"
    local zip="$font_dir/Rubik.zip"

    if omni_have fc-list && fc-list 2>/dev/null | grep -qi 'rubik'; then
        omni_ok "Rubik font already installed."
        return 0
    fi

    if ! omni_confirm "Download the Rubik font family from Google Fonts into $font_dir?" y; then
        omni_note "Rubik is optional; Quickshell falls back to the configured fallback fonts."
        return 0
    fi

    omni_ensure_dir "$font_dir"

    if [[ "$OMNI_DRY_RUN" == "1" ]]; then
        omni_info "dry-run: would download and extract Rubik into $font_dir"
        return 0
    fi

    if ! curl -fL --retry 3 --connect-timeout 15 \
        "https://fonts.google.com/download?family=Rubik" -o "$zip"; then
        omni_warn "Downloading Rubik failed (Google Fonts may have changed the URL)."
        omni_summary_add "Install Rubik manually: https://fonts.google.com/specimen/Rubik"
        rm -f -- "$zip"
        return 1
    fi

    if ! omni_have unzip; then
        omni_warn "unzip is not installed; leaving $zip in place."
        omni_summary_add "Install unzip and run: unzip -o '$zip' -d '$font_dir'"
        return 1
    fi

    unzip -o -- "$zip" -d "$font_dir" >/dev/null
    rm -f -- "$zip"
    omni_record_install "create" "$font_dir" "-" "Rubik font files"

    if omni_have fc-cache; then
        fc-cache -f >/dev/null 2>&1 || true
    fi
    omni_ok "Rubik font installed."
}

# omni_arch_install_virtualization
omni_arch_install_virtualization() {
    local group
    for group in "${OMNI_ARCH_SELECTED_GROUPS[@]}"; do
        if [[ "$group" != "virtualization" ]]; then
            continue
        fi
        if ! omni_confirm "Add $USER to the libvirt and kvm groups and enable libvirtd?" y; then
            omni_note "Skipped virtualization setup."
            omni_summary_add "Enable virtualization later: sudo usermod -aG libvirt,kvm $USER && sudo systemctl enable --now libvirtd"
            return 0
        fi
        omni_run_checked "$OMNI_EXIT_FAILURE" sudo usermod -aG libvirt,kvm "$USER"
        omni_run_checked "$OMNI_EXIT_FAILURE" sudo systemctl enable --now libvirtd
        omni_record_install "service" "libvirtd" "-" "enabled by install.sh"
        omni_note "Group changes take effect after you log out and back in."
    done
    return 0
}

# omni_arch_install_codium_extensions
omni_arch_install_codium_extensions() {
    if ! omni_have codium; then
        return 0
    fi
    if ! omni_confirm "Install the VS Codium extensions used by this setup?" y; then
        return 0
    fi
    local extension
    for extension in jnoortheen.nix-ide mvllow.rose-pine haikalllp.matugen-theme; do
        omni_run_checked "$OMNI_EXIT_FAILURE" codium --install-extension "$extension"
    done
}

# omni_arch_setup_spicetify
omni_arch_setup_spicetify() {
    local local_spotify="$HOME/.local/share/spotify-spicetify"

    if ! omni_have spicetify; then
        omni_info "spicetify is not installed; skipping the Spotify integration."
        return 0
    fi
    if ! omni_confirm "Set up the local Spotify copy used by Spicetify (backs up the previous copy)?" y; then
        omni_note "Skipped Spicetify setup."
        return 0
    fi

    if [[ -d "$local_spotify" ]]; then
        if ! omni_backup_path "$local_spotify" "recreated by install.sh (Spicetify)"; then
            omni_die "$OMNI_EXIT_BACKUP" "Refusing to replace $local_spotify because the backup failed."
        fi
    fi

    omni_run_checked "$OMNI_EXIT_FAILURE" mkdir -p "$local_spotify"

    if [[ -d /opt/spotify ]]; then
        omni_run_checked "$OMNI_EXIT_FAILURE" cp -a -- /opt/spotify/. "$local_spotify/"
    else
        omni_arch_copy_spotify_from_path "$local_spotify"
    fi

    omni_run_checked "$OMNI_EXIT_FAILURE" chmod -R a+wr "$local_spotify"
    omni_record_install "create" "$local_spotify" "/opt/spotify" "local Spotify copy for Spicetify"

    local wrapper_src="$OMNI_SRC_DIR/scripts/spotify-wrapper.sh"
    local wrapper_target="$HOME/.local/bin/spotify"
    if [[ -f "$wrapper_src" ]]; then
        omni_backup_path "$wrapper_target" "installed spotify wrapper" || omni_die "$OMNI_EXIT_BACKUP" "Backup of $wrapper_target failed."
        omni_ensure_dir "$HOME/.local/bin"
        omni_run_checked "$OMNI_EXIT_FAILURE" cp -a -- "$wrapper_src" "$wrapper_target"
        omni_run_checked "$OMNI_EXIT_FAILURE" chmod +x "$wrapper_target"
        omni_record_install "create" "$wrapper_target" "$wrapper_src" "Spotify/Spicetify wrapper"
    fi

    omni_arch_refresh_spotify_desktop_entry
    omni_run_checked "$OMNI_EXIT_FAILURE" spicetify config extensions adblockify.js beautifulLyrics.js popupLyrics.js spicyLyrics.js fullAppDisplay.js
    omni_run_checked "$OMNI_EXIT_FAILURE" spicetify backup apply
}

# omni_arch_copy_spotify_from_path <target>
omni_arch_copy_spotify_from_path() {
    local target="$1" binary share
    if ! omni_have spotify; then
        omni_warn "Spotify is not installed; skipping the local copy."
        return 0
    fi
    binary="$(readlink -f -- "$(command -v spotify)")"
    share="$(dirname -- "$binary")"
    if [[ "$share" == */bin ]]; then
        share="$(dirname -- "$share")/share/spotify"
    fi
    if [[ -d "$share" ]]; then
        omni_run_checked "$OMNI_EXIT_FAILURE" cp -a -- "$share/." "$target/"
        return 0
    fi
    omni_warn "Could not find the Spotify application directory next to $binary."
}

# omni_arch_refresh_spotify_desktop_entry
omni_arch_refresh_spotify_desktop_entry() {
    local source_entry="" applications="$HOME/.local/share/applications"
    local candidate
    for candidate in /usr/share/applications/spotify.desktop \
        /run/current-system/sw/share/applications/spotify.desktop; do
        if [[ -f "$candidate" ]]; then
            source_entry="$candidate"
            break
        fi
    done

    if [[ -z "$source_entry" ]]; then
        return 0
    fi

    omni_ensure_dir "$applications"
    omni_backup_path "$applications/spotify.desktop" "spotify desktop entry" || omni_die "$OMNI_EXIT_BACKUP" "Backup of the desktop entry failed."
    omni_run_checked "$OMNI_EXIT_FAILURE" cp -a -- "$source_entry" "$applications/spotify.desktop"
    if [[ "$OMNI_DRY_RUN" != "1" ]]; then
        sed -i "s|^Exec=spotify|Exec=$HOME/.local/bin/spotify|" "$applications/spotify.desktop"
    fi
    omni_record_install "create" "$applications/spotify.desktop" "$source_entry" "Spotify launcher pointing at the local copy"
}

# omni_arch_legacy_hacks
# The upstream installer applied these unconditionally. They either delete
# system files or replace a configuration this installer just wrote, so they
# are now opt in and every one of them is described before it runs.
omni_arch_legacy_hacks() {
    omni_step "Legacy tweaks from the original installer (all optional)"

    if [[ -f /usr/share/applications/antigravity.desktop ]]; then
        if omni_confirm "Add a scaled (2x) launcher entry for Antigravity?" n; then
            local applications="$HOME/.local/share/applications"
            omni_ensure_dir "$applications"
            omni_backup_path "$applications/antigravity-scaled.desktop" "antigravity launcher" || omni_die "$OMNI_EXIT_BACKUP" "Backup failed."
            omni_run_checked "$OMNI_EXIT_FAILURE" cp -a -- /usr/share/applications/antigravity.desktop "$applications/antigravity-scaled.desktop"
            if [[ "$OMNI_DRY_RUN" != "1" ]]; then
                sed -i 's/^Name=Antigravity/Name=Antigravity (Scaled)/' "$applications/antigravity-scaled.desktop"
                sed -i 's|^Exec=antigravity|Exec=antigravity --force-device-scale-factor=2|g' "$applications/antigravity-scaled.desktop"
            fi
            omni_record_install "create" "$applications/antigravity-scaled.desktop" "/usr/share/applications/antigravity.desktop" "scaled launcher"
        fi
    fi

    if [[ -d "$HOME/.local/share/caelestia/btop" ]]; then
        if omni_confirm "Point ~/.config/btop at ~/.local/share/caelestia/btop (replaces the btop config just installed)?" n; then
            omni_backup_path "$HOME/.config/btop" "replaced by the caelestia symlink" || omni_die "$OMNI_EXIT_BACKUP" "Backup failed."
            if [[ "$OMNI_DRY_RUN" != "1" ]]; then
                rm -rf -- "$HOME/.config/btop"
                ln -sfn "$HOME/.local/share/caelestia/btop" "$HOME/.config/btop"
            fi
            omni_record_install "symlink" "$HOME/.config/btop" "$HOME/.local/share/caelestia/btop" "upstream btop symlink hack"
        fi
    fi

    if [[ -d /usr/share/icons/Papirus-Light ]]; then
        omni_warn "The original installer deleted /usr/share/icons/Papirus-Light (owned by papirus-icon-theme)."
        omni_warn "That file belongs to a package and cannot be restored without reinstalling it."
        if omni_confirm "Delete /usr/share/icons/Papirus-Light now?" n; then
            omni_run_checked "$OMNI_EXIT_FAILURE" sudo rm -rf -- /usr/share/icons/Papirus-Light
            omni_summary_add "Restore the icons with: sudo pacman -S papirus-icon-theme"
        fi
    fi
}

# omni_arch_set_default_shell
omni_arch_set_default_shell() {
    if ! omni_have fish || ! omni_have chsh; then
        return 0
    fi
    if [[ "${SHELL:-}" == */fish ]]; then
        return 0
    fi
    if ! omni_confirm "Change $USER's login shell to fish? (the original installer did this without asking)" n; then
        omni_note "Login shell unchanged."
        return 0
    fi
    omni_run_checked "$OMNI_EXIT_FAILURE" chsh -s "$(command -v fish)" "$USER"
    omni_record_install "service" "login-shell" "$(command -v fish)" "changed by install.sh"
}

# omni_arch_post_install
omni_arch_post_install() {
    omni_arch_install_virtualization
    omni_arch_setup_spicetify
    omni_arch_install_codium_extensions
    omni_arch_legacy_hacks
    omni_arch_set_default_shell

    if [[ "$OMNI_SKIP_PLUGINS" == "1" ]]; then
        return 0
    fi
    if ! omni_have hyprpm; then
        omni_note "hyprpm is not available; skipping the hyprglass plugin."
        return 0
    fi
    if ! omni_confirm "Install the hyprglass Hyprland plugin with hyprpm?" y; then
        return 0
    fi
    omni_run_checked "$OMNI_EXIT_FAILURE" hyprpm update
    omni_run_checked "$OMNI_EXIT_FAILURE" hyprpm add https://github.com/hyprnux/hyprglass
    omni_run_checked "$OMNI_EXIT_FAILURE" hyprpm enable hyprglass
}
