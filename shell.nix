{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    cargo
    rustc
    rustfmt
    clippy
    # Add any other required C libraries or tools below
    # pkg-config
    # openssl
  ];

  shellHook = ''
    echo "OmniFormis dev shell loaded. Cargo is ready to use!"
  '';
}
