# Dial-E's boot animation (Plymouth)

The shell's own M3E loading indicator (the same one the dials show while they load), so booting,
logging in and the desktop move the same way. Plymouth can't play video, so it is a frame
sequence: one morph cycle (139 frames of 240 px, about 1.7 MB) that `plymouth/dial-e/dial-e.script`
plays while turning it, at 50 Hz, two loops of their own so neither shows a seam. A password
asked at boot shows under it with a bead per letter. Preview: `docs/plymouth-preview.gif`
(GIF: ffmpeg isn't installed, so no mp4 / webm).

## Turn it on (NixOS, as root)

In your system config (e.g. `~/Nixos/modules/system/core/boot.nix`), with `inputs` in scope:

```nix
boot.plymouth = {
  enable = true;
  theme = "dial-e";
  themePackages = [
    (pkgs.runCommand "plymouth-dial-e" { } ''
      mkdir -p $out/share/plymouth/themes/dial-e
      cp ${inputs.omniformis}/plymouth/dial-e/{dial-e.plymouth,dial-e.script,frame-*.png} $out/share/plymouth/themes/dial-e/
      substituteInPlace $out/share/plymouth/themes/dial-e/dial-e.plymouth --replace-fail "@out@" "$out"
    '')
  ];
};

# a quiet boot, and Plymouth handing over smoothly to SDDM
boot.initrd.systemd.enable = true;
boot.kernelParams = [ "quiet" "splash" ];
boot.consoleLogLevel = 3;
```

Then:

```sh
nix flake update omniformis --flake ~/Nixos
sudo nixos-rebuild switch --flake ~/Nixos
```

and reboot. If the splash shows only late (or not at all) on the NVIDIA card, the driver loads
after Plymouth starts: adding `boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_drm" ];`
starts it earlier, at the cost of a much larger initrd. To check without rebooting:
`sudo plymouthd --debug --tty=/dev/tty3; sudo plymouth show-splash; sleep 5; sudo plymouth quit`.

To go back: remove `boot.plymouth` and the kernel parameters, rebuild.

## Colours

They are baked in when the frames are made: the indicator in the theme's primary and
primary-container, the background its surface. After changing the theme, run
`scripts/build-plymouth.sh` in the desktop session (a small window opens for about 20 s), commit,
and rebuild as above.

## Not tested

Plymouth isn't installed here, so the script has not run on a real boot yet; the first boot
after enabling it is the test. Nothing else depends on it: if it fails, the boot shows the
usual text.
