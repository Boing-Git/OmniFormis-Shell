import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Wayland
import QtQuick.Shapes
import "primitive"

// The 30-second example from primitive/README.md, in a window so it shows.
PanelWindow {
    // the screen the shell lives on (Dials.screen): when the monitor goes away and comes
    // back (a DisplayPort monitor does as it sleeps) the window follows it back
    screen: Dials.screen

    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    mask: Region { item: dial }

    // take the keyboard while the dial is open, so it can be used with keys
    WlrLayershell.keyboardFocus: dial.open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    // open / close from a keybind:  qs -p <this folder> ipc call power toggle
    IpcHandler {
        target: "power"
        function toggle(): void { dial.open = !dial.open }
        function open(): void { dial.open = true }
        function close(): void { dial.open = false }
    }

    // so other dials can find it (Dials.qml)
    Component.onCompleted: Dials.register("power", dial)

    DialDelegate {
        id: dial
        corner: Dials.spotOf("power")
        expandedSize: 200

        // M3E roles: the dial is a surface container, edged with outline-variant
        color: Roles.surface_container
        borderColor: Roles.outline_variant

        onScrolled: dir => spin.scrollBy(dir)
        onDragged: deg => spin.dragBy(deg)
        onFlung: speed => spin.fling(speed)
        // Lock hands over to the lock screen (lock/): its sheet grows on from this dial's
        // size, out of this spot. The rest run their command
        onActivated: {
            // the item the ring is settling on, not one passing the mark mid-spin
            const e = powerItems[ring.wrap(spin.heading)]
            if (e.lock && Dials.lock) Dials.lock.lock(dial.currentSize)
            else runner.exec(e.command)
        }

        DialRotation {
            id: spin

            // spacing from the tile size, so tiles never touch at any dial size:
            // (tile 70 + gap 16) / (inner edge of the ring) → degrees
            stepDeg: (70 + 16) / (dial.expandedSize * 0.8 - 35) * 180 / Math.PI

            // scrolling feel is shared by every dial (variables.js)
            momentum: Prefs.scrollMomentum
            energy: Prefs.energy
            snapThreshold: 0.3      // this dial only: snaps sooner
            snapDuration: 300       // this dial only: quicker settle
        }

        // one shared shape library for every tile
        M3Shapes { id: shapes }

        // the 5 power-menu entries:
        //   label   - the name
        //   icon    - a Material Symbols icon name (type the name, the font draws the icon)
        //   shape   - the M3 shape behind it
        //   command - what runs when it's picked (argv list: program, then its arguments)
        //   lock    - true: picking it opens the lock screen from here (the command is only
        //             the fallback, if the lock screen isn't loaded)
        readonly property var powerItems: [
            { label: "Lock",     icon: "lock",               shape: "4SidedCookie", lock: true, command: ["loginctl", "lock-session"] },
            { label: "Logout",   icon: "logout",             shape: "12SidedCookie",    command: ["hyprctl", "dispatch", "hl.dsp.exit()"] },
            { label: "Suspend",  icon: "bedtime",            shape: "6SidedCookie",     command: ["systemctl", "suspend"] },
            { label: "Reboot",   icon: "restart_alt",        shape: "Sunny",   command: ["systemctl", "reboot"] },
            { label: "Shutdown", icon: "power_settings_new", shape: "Gem",      command: ["systemctl", "poweroff"] }
        ]

        // runs the picked entry's command
        Process { id: runner }


        DialBand {
            anchors.fill: parent
            cx: dial.centerX; cy: dial.centerY
            radius: dial.expandedSize * 0.7  // same as the ring; follows the dial size
            frameHeight: 80                 // same as the ring's itemHeight
            startDeg: dial.startDeg - 15    // a bit wider than the visible part
            sweepDeg: dial.sweepDeg + 30

            // the track: one surface step above the dial
            bandColor: Roles.surface_container_high
            holeColor: Roles.outline_variant
            DialRing {
                id: ring
                count: dial.powerItems.length          // 5 entries, looping
                pressed: dial.pressed                  // lets the selected tile know it's being clicked
                anchors.fill: parent
                cx: dial.centerX
                cy: dial.centerY
                startDeg: dial.startDeg
                sweepDeg: dial.sweepDeg
                radius: dial.expandedSize * 0.7   // 80% of the dial: always fits inside
                stepDeg: spin.stepDeg
                scroll: spin.scroll
                itemWidth: 70
                itemHeight: 70

                delegate: Item {
                    // which entry this tile shows, 0..4, filled in by DialRing (from `count`)
                    property int itemIndex
                    readonly property var entry: dial.powerItems[itemIndex]

                    // this tile's angle on the ring, filled in by DialRing every frame
                    property real ringDeg

                    // true while this tile is closest to the 45° mark, filled in by DialRing
                    property bool selected

                    // true while this tile is selected and the mouse button is held, filled in by DialRing
                    property bool clicked
                    rotation: -(ringDeg + 90)      // cancel the ring's tilt: the whole tile stays upright

                    Shape {
                        id: tileShape
                        anchors.fill: parent
                        preferredRendererType: Shape.CurveRenderer
                        // grows when selected, on a spring: it keeps its speed when the selection
                        // moves on mid-growth, where a fixed curve would start again from rest
                        scale: grow.value
                        SpringValue {
                            id: grow
                            to: selected ? 100 / 70 : 1
                            stiffness: Vars.springs.expressive.fast.spatial.stiffness
                            dampingRatio: Vars.springs.expressive.fast.spatial.dampingRatio
                            epsilon: 0.001
                            Component.onCompleted: snap(to)
                        }

                        // the icon, drawn as one vector shape: stays sharp as the tile grows, with
                        // no seams in the filled glyphs (see primitive/SymbolIcon.qml)
                        SymbolIcon {
                            anchors.centerIn: parent              // middle of the shape
                            z: 1                                  // on top of the shape
                            text: entry.icon
                            size: 32                              // icon size

                            // outlined, filling in while selected
                            filled: selected

                            // M3E FAB menu: on-primary-container, on-primary when selected
                            color: selected ? Roles.on_primary : Roles.on_primary_container
                            Behavior on color{
                                ColorAnimation{
                                    duration: Vars.expressiveFastEffects.duration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Vars.expressiveFastEffects.bezier
                                }
                            }
                        }

                        ShapePath{
                            // M3E FAB menu: items are primary-container, the selected one primary
                            fillColor: selected ? Roles.primary : Roles.primary_container
                            strokeColor: "transparent"
                            scale: ring.shapeScale
                            PathSvg {
                                path: shapes.getPath(entry.shape)

                             }
                            Behavior on fillColor{
                                ColorAnimation{
                                    duration: Vars.expressiveFastEffects.duration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Vars.expressiveFastEffects.bezier
                                }   
                            }
                        }
                    }
                }
            }
        }
    }
}
