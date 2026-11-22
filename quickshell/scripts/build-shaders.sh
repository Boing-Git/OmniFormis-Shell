#!/bin/sh
# Compiles the shell's shaders (primitive/shaders/*.vert, *.frag) into the .qsb files a
# ShaderEffect loads (Qt 6 takes no GLSL source). Run it after editing a shader; the .qsb
# files are kept next to their sources.
#
# Needs qsb (Qt Shader Tools); without it on PATH it runs itself again inside
# `nix shell nixpkgs#qt6.qtshadertools`.
set -e
if ! command -v qsb >/dev/null 2>&1; then
    [ -n "$QSB_NIX_SHELL" ] && { echo "qsb not found" >&2; exit 1; }
    QSB_NIX_SHELL=1 exec nix shell nixpkgs#qt6.qtshadertools -c "$0" "$@"
fi
cd "$(dirname "$0")/../primitive/shaders"

# GLSL for every OpenGL / GLES Qt may pick, plus SPIR-V (Vulkan), which qsb always adds
for f in *.vert *.frag; do
    qsb --glsl "100 es,300 es,120,150,330" -o "$f.qsb" "$f"
    echo "built $f.qsb"
done
