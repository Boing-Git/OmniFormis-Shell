{
  description = "OmniFormis-Shell Nix Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
    in
    {
      homeManagerModules = {
        default = import ./nix/module.nix;
        omniformis = import ./nix/module.nix;
      };

      # the keyboard layout of the login screen and the consoles, from Hyprland's KeyboardLayout
      nixosModules.keyboard = import ./nix/keyboard.nix;

      # screenpilot (screenpilot/README.md): the screen-aware assistant, its user service and settings
      nixosModules.screenpilot = import ./screenpilot/module.nix;
      packages.x86_64-linux.screenpilot = pkgs.callPackage ./screenpilot/package.nix { };
      devShells.x86_64-linux.screenpilot = pkgs.mkShell {
        packages = [
          (pkgs.python3.withPackages (ps: with ps; [ anthropic httpx pillow evdev ]))
          pkgs.grim pkgs.slurp pkgs.sway pkgs.piper-tts pkgs.wl-clipboard
        ];
      };
    };
}
