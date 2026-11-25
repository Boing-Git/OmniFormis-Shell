# screenpilot: the daemon, the CLI, the overlay (share/screenpilot/overlay) and the tools they run.
# hyprctl and qs come from the system (the service's PATH has /run/current-system/sw/bin).
{ lib, python3Packages, grim, slurp, sway, piper-tts, pipewire, wl-clipboard, dbus }:

python3Packages.buildPythonApplication {
  pname = "screenpilot";
  version = "0.1.0";
  pyproject = true;
  src = ./.;

  build-system = [ python3Packages.setuptools ];
  dependencies = with python3Packages; [ anthropic httpx pillow evdev ];

  # the unit tests (no display, no network): STOP within 200 ms, the coordinate maths, parsing...
  checkPhase = ''
    runHook preCheck
    python -m unittest discover -s tests
    runHook postCheck
  '';

  postInstall = ''
    mkdir -p $out/share/screenpilot
    cp -r overlay $out/share/screenpilot/
  '';

  makeWrapperArgs = [
    "--prefix" "PATH" ":" (lib.makeBinPath [ grim slurp sway piper-tts pipewire wl-clipboard dbus ])
    "--set-default" "SCREENPILOT_OVERLAY" "${placeholder "out"}/share/screenpilot/overlay"
  ];

  meta = {
    description = "A screen-aware assistant for Hyprland: it sees, acts, speaks, and STOP always wins";
    mainProgram = "screenpilot";
  };
}
