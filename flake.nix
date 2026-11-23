{
  description = "OmniFormis-Shell Nix Flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    homeManagerModules = {
      default = import ./nix/module.nix;
      omniformis = import ./nix/module.nix;
    };

    # the keyboard layout of the login screen and the consoles, from Hyprland's KeyboardLayout
    nixosModules.keyboard = import ./nix/keyboard.nix;
  };
}
