#!/usr/bin/env bash
# shellcheck shell=bash
#
# NixOS specific installation steps.
#
# The configuration files in this repository are shared with Arch Linux, but
# NixOS owns the package set: packages, services and often the files inside
# ~/.config are declared in a flake / configuration.nix (or home-manager).
# Therefore this file
#   * never runs pacman style commands,
#   * refuses to overwrite home-manager managed (Nix store) symlinks unless
#     --force is given,
#   * treats the system wide `nixos-rebuild switch` as an explicit, confirmed
#     action instead of something that happens implicitly.
#
# Sourced by install.sh. Requires install/lib/common.sh and detect.sh.

OMNI_NIXOS_DEFAULT_REPO="https://github.com/Boing-Git/My-NixOs-Dotfiles"
OMNI_NIXOS_DIR="${OMNI_NIXOS_DIR:-$HOME/Nixos}"

# omni_nixos_require_support
omni_nixos_require_support() {
    omni_require_nixos
}

# omni_nixos_choose_packages
# Explains where packages come from on NixOS and records the flake location.
omni_nixos_choose_packages() {
    OMNI_NIXOS_REPO="${OMNI_NIXOS_REPO:-$OMNI_NIXOS_DEFAULT_REPO}"

    omni_step "NixOS package plan"
    omni_info "NixOS has no imperative package manager, so this installer does not install packages."
    omni_info "The declarative counterpart of this repository is the flake at:"
    omni_info "  $OMNI_NIXOS_REPO"
    omni_info "It is expected to be checked out at $OMNI_NIXOS_DIR and to provide every"
    omni_info "command listed in docs/DEPENDENCIES.md."
    omni_note "Set OMNIFORMIS_NIXOS_REPO to use your own fork instead."

    if ! omni_have nix; then
        omni_warn "The nix command was not found in PATH; flake handling will be skipped."
        return 1
    fi
    return 0
}

# omni_nixos_install_packages
# Checks out (or updates) the NixOS flake and - only with explicit consent -
# runs nixos-rebuild.
omni_nixos_install_packages() {
    local repo="${OMNI_NIXOS_REPO:-$OMNI_NIXOS_DEFAULT_REPO}"
    local dir="${OMNI_NIXOS_DIR}"

    if ! omni_have nix; then
        omni_warn "Skipping the NixOS flake steps because nix is unavailable."
        return 0
    fi

    if [[ -d "$dir/.git" ]]; then
        omni_step "Updating the NixOS flake in $dir"
        if ! omni_confirm "Run 'git pull' in $dir?" y; then
            omni_info "Keeping the flake as it is."
        fi
        if [[ "$OMNI_DRY_RUN" != "1" ]]; then
            if ! git -C "$dir" pull --ff-only; then
                omni_warn "git pull failed; the existing checkout is left untouched."
            fi
        fi
    else
        omni_step "Cloning the NixOS flake"
        if ! omni_confirm "Clone $repo into $dir?" y; then
            omni_info "Skipped the flake checkout; copy the configuration manually if you use a different setup."
            return 0
        fi
        omni_run_checked "$OMNI_EXIT_FAILURE" git clone --depth 1 "$repo" "$dir"
    fi

    # hardware-configuration.nix is machine specific and must not be shipped.
    if [[ -f /etc/nixos/hardware-configuration.nix && -d "$dir" ]]; then
        if omni_confirm "Copy /etc/nixos/hardware-configuration.nix into $dir?" y; then
            if [[ -f "$dir/hardware-configuration.nix" ]]; then
                omni_backup_path "$dir/hardware-configuration.nix" "hardware configuration replaced" || true
            fi
            omni_run_checked "$OMNI_EXIT_FAILURE" cp -f -- /etc/nixos/hardware-configuration.nix "$dir/hardware-configuration.nix"
        fi
    fi

    omni_note "This installer copies the shared configuration into ~/.config."
    omni_note "Files that home-manager owns are symlinks into /nix/store; they are left untouched."
    omni_note "To activate the declarative setup run, from $dir:"
    omni_note "  sudo nixos-rebuild switch --flake .#nixos"

    if ! omni_confirm "Run 'sudo nixos-rebuild switch --flake .#nixos' now (this rebuilds your system)?" n; then
        omni_summary_add "Run 'cd $dir && sudo nixos-rebuild switch --flake .#nixos' once you are happy with the configuration."
        return 0
    fi

    if [[ "$OMNI_DRY_RUN" == "1" ]]; then
        omni_info "dry-run: sudo nixos-rebuild switch --flake $dir#nixos"
        return 0
    fi

    if [[ "$(id -u)" -eq 0 ]]; then
        omni_die "$OMNI_EXIT_USAGE" "Refusing to run nixos-rebuild as root; run the installer as your normal user (it will ask for sudo)."
    fi

    ( cd -- "$dir" && sudo nixos-rebuild switch --flake .#nixos ) || omni_die "$OMNI_EXIT_FAILURE" "nixos-rebuild failed; the previous generation is still active."
    omni_ok "System rebuilt from the flake."
}

# omni_nixos_post_install
omni_nixos_post_install() {
    omni_note "NixOS specific notes:"
    omni_note "  * packages are declared in your NixOS/home-manager configuration, not by this installer"
    omni_note "  * ~/.config files managed by home-manager stay symlinks into /nix/store"
    omni_note "  * after changing the flake run: sudo nixos-rebuild switch --flake $OMNI_NIXOS_DIR#nixos"
    omni_summary_add "NixOS: keep packages in sync with docs/DEPENDENCIES.md (see the flake at $OMNI_NIXOS_DEFAULT_REPO)."
}
