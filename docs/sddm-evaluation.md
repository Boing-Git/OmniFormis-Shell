# An M3E SDDM theme: worth building?

## Verdict: no new theme. Make the one you have follow the desktop instead.

A login theme from scratch costs a lot for a screen you see for a few seconds per boot, and you
already run a good one: **pixie** (a Material-You-style SDDM theme from a flake input) on SDDM's
Qt 6 build. What it lacks is the desktop's colours and wallpaper, and that is a small change.

## What was checked

| Criterion | Finding |
|---|---|
| SDDM and Qt 6 here | `pkgs.kdePackages.sddm` (Qt 6), Wayland greeter under kwin, layer-shell. A new theme would be QML on Qt 6: fine, but tested only through `sddm-greeter-qt6 --test-mode`, not the real greeter. |
| Maintenance | A custom greeter breaks quietly on SDDM / Qt updates, and when the login screen breaks you're locked out of the desktop. pixie is maintained upstream. |
| Multi-monitor | One monitor today; pixie handles more. |
| Keyboard layout | The greeter needs Colemak-DH for the password (pixie uses SDDM's keyboard model; set it with `services.xserver.xkb`). |
| Session and power menu | pixie has both. |
| Accessibility | pixie keeps SDDM's standard focus and keyboard navigation; a custom theme would have to redo it. |
| Security | The greeter runs as `sddm`, not you: it can't read your home folder (the wallpaper) or your theme files. Anything synced must be copied somewhere it can read. |
| Effort vs value | A full M3E theme: days, for seconds a day. Colour sync for pixie: one Nix change and one hook. |
| matugen colours | pixie has `autoColor=true` (it takes its colours from its background) and plain `accentColor` / `backgroundColor` / `textColor`. Give it the current wallpaper and it follows matugen's source by itself. |

## The small change (needs a rebuild, as root)

1. A folder the greeter can read and you can write, once:
   ```nix
   systemd.tmpfiles.rules = [ "d /var/lib/sddm-wallpaper 0775 root users -" ];
   ```
2. pixie pointed at it (in `modules/system/desktop/graphics.nix`, replacing the package line):
   ```nix
   (inputs.pixie-sddm.packages.${pkgs.stdenv.hostPlatform.system}.pixie-sddm.overrideAttrs (old: {
     postInstall = (old.postInstall or "") + ''
       sed -i 's|^background=.*|background=/var/lib/sddm-wallpaper/current.jpg|; s|^autoColor=.*|autoColor=true|' \
         $out/share/sddm/themes/pixie/theme.conf
     '';
   }))
   ```
   (check the theme's path inside the package with `ls $(nix build --print-out-paths ...)`.)
3. Every wallpaper change copies it there: one line at the end of `scripts/theme-apply.sh`'s
   loop, `magick "$image" -resize 1920x1080^ -gravity center -extent 1920x1080 /var/lib/sddm-wallpaper/current.jpg`.
   Not added yet: it would fail until step 1 exists.

Then the greeter shows your wallpaper and its colours, every boot, with no theme to maintain.

## If you still want an M3E greeter of your own

Build it from Dial-E's lock rather than from scratch: the same whole-circle dial, the same
password ring, the same Mascot, as an SDDM theme (SDDM themes are QML; Dial-E's primitives need
only Qt Quick and Shapes). That keeps one design for "locked" and "logged out", which is the
part worth having. Effort: two or three days, plus testing in `--test-mode` with the real
keyboard layout before switching `services.displayManager.sddm.theme`.
