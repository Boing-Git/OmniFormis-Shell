# The keyboard layout outside Hyprland: the login screen (SDDM's kwin greeter reads it through
# systemd-localed, which reads services.xserver.xkb) and the text consoles (console.useXkbConfig).
# It comes from the one KeyboardLayout setting Hyprland uses too (hypr/modules/variables.lua,
# e.g. "us(colemak_dh)" or "us(colemak_dh),de"), so the layout is one setting everywhere.
# A change applies to Hyprland at once; here after `nix flake update omniformis` and a rebuild.
#
#   modules = [ inputs.omniformis.nixosModules.keyboard ];
#
# shortcut: reads the repo's variables.lua; an install without dotfilesDir (settings baked in by
# Home Manager) would need hyprland.settings.KeyboardLayout passed here instead, if one appears.
{ lib, ... }:
let
  lines = lib.splitString "\n" (builtins.readFile ../hypr/modules/variables.lua);

  # the value of the first `KeyboardLayout = "..."` line (comment lines start with --, so
  # they never match)
  line = lib.findFirst (l: builtins.match "[[:space:]]*KeyboardLayout[[:space:]]*=.*" l != null) null lines;
  value = if line == null then "us" else builtins.head (builtins.match "[^\"]*\"([^\"]*)\".*" line);

  # "us(colemak_dh)" -> { layout = "us"; variant = "colemak_dh"; }, "de" -> { layout = "de"; variant = ""; }
  parse = item:
    let m = builtins.match "([A-Za-z0-9_-]+)[[:space:]]*(\\(([A-Za-z0-9_-]*)\\))?" (lib.trim item);
    in if m == null then throw "KeyboardLayout: can't read '${item}' (it is like us or us(colemak_dh))"
       else { layout = builtins.elemAt m 0; variant = if builtins.elemAt m 2 == null then "" else builtins.elemAt m 2; };
  parsed = map parse (lib.splitString "," value);
in
{
  services.xserver.xkb.layout = lib.mkDefault (lib.concatMapStringsSep "," (p: p.layout) parsed);
  services.xserver.xkb.variant = lib.mkDefault (lib.concatMapStringsSep "," (p: p.variant) parsed);
  console.useXkbConfig = lib.mkDefault true;
}
