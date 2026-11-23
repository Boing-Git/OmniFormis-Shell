# The lyrics fetcher (scripts/lyrics_tool) the old shell's media player runs. Built here for
# the same reason as omniformis.nix: a cargo build from a nix-shell stops starting once the
# garbage collector removes that shell's glibc.
{ lib, rustPlatform }:

rustPlatform.buildRustPackage {
  pname = "lyrics-fetcher";
  version = "0.1.0";

  # only the sources: cargo's target/ next to them is hundreds of MB
  src = lib.fileset.toSource {
    root = ../scripts/lyrics_tool;
    fileset = lib.fileset.unions [
      ../scripts/lyrics_tool/Cargo.toml
      ../scripts/lyrics_tool/Cargo.lock
      ../scripts/lyrics_tool/main.rs
    ];
  };
  cargoLock.lockFile = ../scripts/lyrics_tool/Cargo.lock;

  meta.mainProgram = "lyrics-fetcher";
}
