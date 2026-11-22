# The omniformis CLI (scripts/omniformis). Built here instead of with cargo in a nix-shell:
# such a binary points at that shell's glibc, the garbage collector removes it later, and
# the CLI then fails with "required file not found" (the Settings page's Hyprland group
# went dead that way).
{ lib, rustPlatform }:

rustPlatform.buildRustPackage {
  pname = "omniformis";
  version = "0.1.0";

  # only the sources: cargo's target/ next to them is gigabytes
  src = lib.fileset.toSource {
    root = ../scripts/omniformis;
    fileset = lib.fileset.unions [
      ../scripts/omniformis/Cargo.toml
      ../scripts/omniformis/Cargo.lock
      ../scripts/omniformis/src
    ];
  };
  cargoLock.lockFile = ../scripts/omniformis/Cargo.lock;

  meta.mainProgram = "omniformis";
}
