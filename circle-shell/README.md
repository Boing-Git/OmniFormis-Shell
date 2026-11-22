# Circle shell

A shell where everything is a circle, and you get things done by dragging one circle onto
the next.

At rest there is nothing on screen, and passing the mouse over the edge does nothing.
Press on the right edge and pull: a drop is drawn out of the edge on a neck of liquid,
and once you have pulled it far enough it comes free. That is the seed, and the first
circles bud out round it. The drop is still in your hand: drag it onto a circle and the
two join. The drop swings back to its place, you now hold the circle you dragged it onto,
and the circles inside that one bud out. Go on, each circle onto the next, until you drag
one onto a task (the tinted circles): the chain lights up from the seed to the task, and
it is done.

    edge → seed → Control center → Wi-Fi → Cafe upstairs → (type the password) → Connect

- Nothing joins by clicking. Clicking a circle on offer only makes the circle you should
  drag pulse, and the words at the top say so.
- You don't have to hold the button the whole way. Let go and the circle you held swings
  back to its place; press on it to pick it up again.
- Pick up an earlier circle of the chain, or drag a circle back onto the one before it,
  to go back. Right-click, Backspace or a click on the empty screen goes back one. Esc, a
  click on the seed, or pushing the seed back into the edge lets it all run back in.
- Some tasks stay out after they run (next track, volume levels, output choice). Drag
  onto them as often as you like: move off and back onto one to do it again.
- Where a circle can be searched (Apps, a Wi-Fi password), just type. Enter takes the
  first circle on offer.
- Everything moves like liquid. Circles are drops that stretch as they fly, wobble when
  they land or are touched, and drift a little in place. A circle buds out of its parent
  on a neck that thins in the middle and pinches off, and a joined chain keeps a thread.
  The circle you hold reaches out to the circles it passes near.

## What's in it

- **Control center**
  - **Wi-Fi**: on/off and the networks around, connected one first. Each network can be
    connected, disconnected or forgotten (if saved). A secured network you haven't saved
    asks for its password: type it while that network is the last circle.
  - **Bluetooth**: on/off, scan, and your devices. A device can be connected, disconnected
    or unpaired; a new one found by the scan can be paired.
  - **Volume** (mute, levels), **Sound out** (pick the output), **Microphone** (mute, pick
    the input), **Brightness** (levels, via `brightnessctl` or `ddcutil`).
- **Apps**: the first nine of your own order (the dial shell's launcher keeps it), then
  All apps in alphabet groups. Type to find one by name, description or keyword.
- **Media**: a bigger circle wearing the album art and showing what's playing. Inside:
  back/forward 10 s, previous, play/pause, next, shuffle, repeat, and bringing the player
  to the front.
- **Windows**: every open window, to go to, make full screen or close.
- **Workspaces** 1–8.
- **Tools**: screenshot, wallpapers, notifications, do not disturb and settings, through
  the dial shell (when it is running).
- **Power**: lock, suspend, log out, restart, shut down. Each asks once more.

Circles show a dot on their rim when they're on (connected, playing, in use), and a
second line under their name (the network, the level, the artist).

## Run it

    qs -p ~/Dotfiles/circle-shell                          # for real
    CIRCLES_DEMO=1 qs -p ~/Dotfiles/circle-shell           # tasks only say what they'd do
    qs -p ~/Dotfiles/circle-shell ipc call circles toggle  # open / close from a keybind

It runs next to the dial shell (it sits on the overlay layer).

## Files

- `shell.qml`: the window, the pull from the edge, holding and dragging, typing (settings
  at the top: sizes, how far to pull, how circles fan out, the staggers).
- `Tree.qml`: what the circles are and what each task does. Add a circle there; the
  comment at its top lists everything a circle can have.
- `Bubble.qml`: a circle (a drop: its springs, wobble, drift, cover, dot, label, and the
  liquid to its parent).
- `Goo.qml`: the liquid between two circles (a neck that thins and pinches off, or a thread).
- `Colors.qml` is a link to the desktop's current colour scheme, so it follows the theme.
