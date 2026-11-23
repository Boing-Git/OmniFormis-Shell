# shared

QML used by more than one shell, linked into each (a shell can't import above its own folder):

- `Mascot.qml`: the shells' mascots (Dial-E, Puffy, Droplet). Linked as
  `quickshell/primitive/Mascot.qml`, `droplet/Mascot.qml`, `puffy/mascot/Mascot.qml`.
- `SpringValue.qml`: a number that moves like a spring. Droplet's (`droplet/SpringValue.qml`) and
  Puffy's mascot's; Dial-E has its own, which follows its Bounce setting.

Edit them here; every shell picks the change up.
