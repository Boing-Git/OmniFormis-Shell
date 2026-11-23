.pragma library

// Shell configuration, as a shared QML JavaScript library.
// Import it in QML with:   import "variables.js" as Vars
// and read values as Vars.wallpapersPath, Vars.SortBy.Name, ...
//
// `.pragma library` loads this file once and shares it between every importer.
// Every top-level const is readable from QML; no `export` needed (that's only
// for .mjs ES modules, which Quickshell's scanner can't resolve).
//
// These are constants: edit this file and Quickshell reloads the shell.
/** @param {number} v @param {number} lo @param {number} hi */
const clamp = (v, lo, hi) => Math.min(Math.max(v, lo), hi);

// ───────────────────────── enums ─────────────────────────
/** What the dial is ordered by. */
const SortBy = Object.freeze({
    Name: "name",   // file name                 (a.png, b.png, c.png ...)
    Time: "time",   // last modified             (oldest first)
    Size: "size",   // file size in bytes        (smallest first)
    Type: "type",   // extension                 (.gif, .jpg, .png grouped)
    None: "none",   // filesystem order, no sorting
});

// ───────────────────────── animation ─────────────────────────

// ───────────────────────── wallpapers ─────────────────────────

// folder scanned for wallpapers (not recursive: sub-folders are ignored)
const wallpapersPath = "/home/boing/Pictures/Wallpapers/Wallpapers-Bank";

// ── wallpaper categories ──
// Name categories: a wallpaper is in a category when its file name contains any
// of the words (upper/lower case ignored). Add your own categories or words.
// Colour categories (red, orange, yellow, green, cyan, blue, purple, pink,
// grey, dark, light) are found automatically from each picture's main colour.
const categoryKeywords = {
    anime:    ["anime", "girl", "manga", "waifu", "sidonia", "ghibli", "naruto", "kimi"],
    city:     ["city", "street", "town", "urban", "building", "tokyo", "neon", "skyline", "rooftop", "balcony"],
    nature:   ["nature", "forest", "forrest", "tree", "mountain", "garden", "flower", "lake", "river", "field", "leaf", "butterfl"],
    space:    ["space", "star", "planet", "galaxy", "comet", "moon", "nebula", "cosmos", "astronaut"],
    sky:      ["sky", "sunset", "sunrise", "cloud", "dawn", "dusk"],
    night:    ["night", "dark", "midnight"],
    game:     ["game", "arcade", "pixel", "retro", "minecraft", "zelda"],
    room:     ["room", "classroom", "lofi", "desk", "window", "cafe", "bedroom", "library"],
    ocean:    ["ocean", "sea", "beach", "wave", "water", "island"],
    abstract: ["abstract", "minimal", "geometric", "pattern", "gradient", "shape"],
    vehicle:  ["car", "train", "bike", "plane", "ship", "boat"],
};

// where the main colour of every wallpaper is remembered between runs
const colorCachePath = "/home/boing/.cache/dial-quickshell/colors.json";

// include dot-files such as ".hidden.png"
const showHidden = false;

// ── sorting ──
const sortBy = SortBy.Name;

// false = A→Z, oldest→newest, smallest→biggest
// true  = Z→A, newest→oldest, biggest→smallest
const sortDescending = false;

// Only for SortBy.Name. false: "Zebra.png" and "apple.png" sort as a, z.
// true: all upper-case names sort before lower-case ones.
// (Plain text sort: "img10.png" still comes before "img2.png".)
const sortCaseSensitive = false;

// ── scrolling ──

// Momentum of wheel scrolling, for EVERY dial, 0 to 0.995:
//   0     - none: each notch moves exactly one wallpaper
//   0.90  - short glide
//   0.95  - medium glide
//   0.98  - long glide, like a heavy disc
const scrollMomentum = clamp(0.98, 0, 0.995);

// Speed added per notch, for EVERY dial. Must stay above scrollMomentum (1 = one notch ≈ one item).
const energy = Math.max(1, scrollMomentum + 0.01);

// ── drag / flick (for EVERY dial): hold, drag round the corner, let go ──
// how hard a flick throws the dial (1 = as fast as the mouse moved; 0 = no throw, it just settles)
const flickStrength = clamp(10, 0, 2);

// how much the newest mouse movement counts toward the throw speed
// (1 = only the last movement, jumpy; 0.3 = smoother, slower to react)
const flickSmoothing = clamp(0.6, 0.05, 1);

// ms you can hold still before letting go and still throw (longer: holding still still flicks)
const flickHoldMs = 80;

// ── snapping onto an item (for EVERY dial) ──

// When the glide hands over to the snap, as a share of one notch's speed:
//   0.05 - glides longer, snaps late (very slow, almost stopped)
//   0.1  - default
//   0.3  - stops gliding early and snaps soon
//   1.0  - snaps almost immediately (barely any glide)
const snapThreshold = clamp(0.1, 0.01, 1);

// How long the final settle onto the item takes, in ms (smaller = snappier).
// It uses the M3E expressive fast spatial curve.
const snapDuration = 421;

// ── theming ──

// border around the dial, px (0 = none)
const dialBorderWidth = 3;

// how round each wallpaper's corners are, px (0 = square corners)
const wallpaperRadius = 10;

// Glass: how solid each kind of shell surface is, 0.3 (very clear) .. 1 (solid, not
// translucent at all). Below 1 it turns to frosted glass and the wallpaper shows through;
// only the containers do: tiles, pills, text and icons on them stay solid, so they stay
// readable over any wallpaper. Also in the Settings control (Look), live
//   dials   the discs of the dials with a corner (control center, apps, wallpaper, power)
//   rings   the bands and search bars on them (glass over glass, so they read a step up)
//   popups  the pop-up dials (volume, brightness, workspaces, an arriving notification)
//   lock    the lock screen's dial (over the lock's own blurred wallpaper)
// Good glass: dials 0.72, rings 0.8, popups 0.62, lock 0.6. With Hyprland's blur off (game
// mode, low spec) the dials and pop-ups never go below 0.9: clear glass with nothing
// frosting it would make them hard to read
const glass = { dials: 1, rings: 1, popups: 1, lock: 1 };

// Frost: Hyprland blurs what is behind the glass. One switch for the dials, one for the
// pop-ups (off: clear glass, the windows behind stay sharp). `frostOver`: "everything"
// blurs the windows and the wallpaper behind; "wallpaper" blurs only the wallpaper (the
// windows behind don't show through at all, calmer). How strong the blur is, is
// Hyprland's own blur setting (decoration:blur:size / passes), shared with the windows
const frostDials = true;
const frostPopups = true;
const frostOver = "everything";

// how blurred the wallpaper behind the lock screen is, 0 (sharp) .. 10. The lock draws
// this itself (made once per wallpaper and level), so it doesn't touch Hyprland's blur
const lockBlur = 6;

// what the lock's sheet is (Prefs.lockBackground): "blur" (the wallpaper behind it, softened
// by lockBlur) or "glass" (a pane of liquid glass over it, bending it at the rim as it sweeps
// out of the power dial's spot; lockBlur frosts it)
const lockBackground = "blur";

// Liquid glass: the liquid glass library (Dotfiles/liquidglass-main) on every glass
// container of the shell: the dials and pop-ups, the bands and search bars on them, the
// lock's dial. Each bends, fringes and frosts the wallpaper behind it (a layer window can't
// see the windows under it, so the wallpaper is what it sees; the lock's glass sees the
// lock's softened picture), with a bevelled rim, highlights and a drop shadow. A
// container's colour (and its kind's Glass solidity above) fills the glass's body and
// clears across the bevel, so even a solid dial gets a liquid rim. Also in the Settings
// control (Liquid glass), live. `mode`: "off", "on", or "button" (on, and a dial's glass
// brightens under the mouse and flattens while pressed, the library's button mode).
// The rest are the library's own settings, with its defaults:
//   blurAmount       0 (sharp) .. 3 (1: the library's strongest): how blurred the wallpaper seen through it is
//   refraction       0 .. 2: how much it bends the wallpaper behind it
//   chromAberration  0 .. 0.3: colour fringing at the rim
//   edgeHighlight    0 .. 1: rim lighting and the thin highlight just inside the edge
//   specular         0 .. 1: highlights from four lights (Blinn-Phong)
//   fresnel          0 .. 2: the rim whitening where the glass turns away
//   distortion       0 .. 1: fine grain in the glass
//   zRadius          1 .. 100 px: the bevel's depth (how far in the rim curves)
//   bevelMode        "pill" (bends at both faces) or "dome" (flat below: a magnifier)
//   bodyFill         0 .. 1: how much of the container's colour (its Glass solidity)
//                    fills the body; 0: clear
//   opacity          0 .. 1: how much it covers what's really behind (the windows, and
//                    Hyprland's frost, show through below 1)
//   saturation       -1 (grey) .. 1 (vivid)
//   tintStrength     0 .. 1: a cool blue cast
//   brightness       -0.5 .. 0.5
//   shadowOpacity    0 .. 1, shadowSpread 0 .. 40 px, shadowOffsetY -20 .. 20 px
//   sees             "wallpaper", or "windows": a grim snapshot of the screen, taken
//                    `windowsSettle` ms after the windows change and every `windowsRefresh`
//                    ms while no dial is open (0: only when they change); or "live": the
//                    windows under an open dial streamed, `liveFps` frames a second each
//                    (the screen's own rate would cost 4x on a 240 Hz screen for no visible
//                    gain under the bend and blur), counting windows up to `liveMargin` px
//                    past the dial's box (the bend and the shadow reach out of it)
const liquid = {
    mode: "off",
    sees: "wallpaper",
    windowsSettle: 300,
    windowsRefresh: 4000,
    liveFps: 60,
    liveMargin: 48,
    blurAmount: 0,
    refraction: 0.69,
    chromAberration: 0.05,
    edgeHighlight: 0.05,
    specular: 0,
    fresnel: 1,
    distortion: 0,
    zRadius: 40,
    bevelMode: "pill",
    opacity: 1,
    bodyFill: 1,
    rings: true,
    saturation: 0,
    tintStrength: 0,
    brightness: 0,
    shadowOpacity: 0.3,
    shadowSpread: 10,
    shadowOffsetY: 1
};

// The design language (Settings → Design; Prefs.shapeStyle / textFont):
//   shapes  "expressive" (M3E's shapes) or "round" (circles and capsules, as Apple draws
//           them)
//   font    "system" (the app font) or a font family, e.g. "Inter"
//   tiles   the colours (Roles.qml): "tonal" (the theme's M3 roles) or "glass" (white
//           glyphs, white washes, picked in white)
//   tracks  "wavy" (M3E's wavy timeline) or "straight"
const design = {
    shapes: "expressive",
    font: "system",
    tiles: "tonal",
    tracks: "wavy",

    // the control center's outer ring: "three" (the tiles take turns through primary /
    // secondary / tertiary containers) or all one: "primary", "secondary", "tertiary"
    ringColors: "three",

    // how big the items you haven't picked are on every ring, against the size they were
    // drawn at (the picked one keeps its size): 1 is the old look
    inactiveScale: 0.8,

    // a ring that isn't liquid glass while liquid glass is on: its white wash and the white
    // of its hairline edges (1 px)
    flatBandWash: 0.08,
    flatBandHairline: 0.22,

    // Glass tiles' palette (Roles.qml), white at these opacities: a container (an unpicked
    // pill, a badge), a quieter surface, secondary text, hairlines and empty ticks; and the
    // dark material under toasts
    glassPalette: { container: 0.2, surface: 0.12, secondaryText: 0.7, hairline: 0.28, darkMaterial: 0.82 },

    // what's on screen under the dials (Underneath.qml), measured at `scale` of the screen
    // in a square `radius` px round each spot; brighter than `lightAbove` (0..1) counts as
    // light, and the ink turns dark there
    underneath: { scale: 0.1, radius: 350, lightAbove: 0.6 }
};

// Apple's Liquid Glass, as the Liquid settings: an approximation of iOS 26's Control Center
// (a clear body showing what's behind lightly frosted and a little smoky, no colour boost;
// a lens in a thin band at the rim; a hairline rim light catching the light top-left and
// bottom-right; a faint shadow; reacts to the pointer)
const liquidApple = {
    liquidGlass: "button", liquidSees: "windows", liquidRings: false,
    liquidBlur: 0.6, liquidFill: 0, liquidRefraction: 1, liquidChroma: 0.01, liquidEdge: 0.5,
    liquidSpecular: 0.3, liquidFresnel: 0.4, liquidDistortion: 0, liquidDepth: 20,
    liquidBevel: "pill", liquidOpacity: 1, liquidSaturation: 0, liquidTint: 0,
    liquidBrightness: -0.06, liquidShadow: 0.1, liquidShadowSpread: 14, liquidShadowOffset: 2
};

// where liquid glass keeps the wallpaper blurred ahead of time (ImageMagick, once per
// wallpaper and Blur level)
const liquidCachePath = "/home/boing/.cache/dial-quickshell/liquid";

// ───────────────────────── lock screen ─────────────────────────
// (lock/: Super + L, the power dial's Lock, or `qs ipc call lock lock`; hypridle locks
// through the same call)

// the PAM service the lock checks your password with: /etc/pam.d/<this>
const lockPamConfig = "system-auth";

// where the lock notes that the session is locked, so a shell that crashed or restarted
// while locked locks again the moment it starts (only within the same Hyprland session)
const lockStatePath = "/home/boing/.local/state/dial-quickshell/locked";

// where the lock keeps the wallpaper blurred ahead of time (ImageMagick, once per wallpaper),
// so locking never waits for a blur
const lockCachePath = "/home/boing/.cache/dial-quickshell/lock";

// What a new wallpaper's colours become (Prefs.themeScheme / themeSource): matugen's scheme
// type, and which of the wallpaper's colours it starts from ("0".."3": the most common
// first; or "saturation", "less-saturation", "lightness", "darkness")
const themeScheme = "scheme-tonal-spot";
const themeSource = "0";

// the one script every shell themes through (matugen, never prompting, one run at a time)
const themeApplyScript = "/home/boing/Dotfiles/scripts/theme-apply.sh";

// ── shuffle ──

// Fixed scramble on top of sortBy. The same wallpaper keeps the same neighbours
// until you change shuffleSeed or the number of files changes.
const shuffle = false;

// different seed = different scramble; any whole number
const shuffleSeed = 1;

// ── Dials Settings ──
// Where each dial lives. Any of the 8 spots:
//   corners (a quarter circle):         "topLeft" "topRight" "bottomLeft" "bottomRight"
//   edge middles (a half circle):       "top" "bottom" "left" "right"
// These are the starting spots: Edit in the control center's Dials control moves the
// wallpaper, apps and power dials, and remembers where you put them (in
// dialPositionsPath; delete that file, or run `qs ipc call dials reset`, to come back here).
const dialPositionsPath = "/home/boing/.local/state/dial-quickshell/positions.json";

// ── hints ── the shell teaches its drags the first few times you meet them: a short
// line appears by the dial when Edit comes on, or when a pill is picked up (what you can
// drop it on, that a flick dismisses it). Each hint shows this many times, then never
// again (remembered in hintsPath; delete it, or run `qs ipc call hints reset`, to see
// them again). 0 turns the hints off
const hintTimes = 0;
const hintsPath = "/home/boing/.local/state/dial-quickshell/hints.json";

// how long a hint stays, ms (a drag's hint also goes when the drag ends)
const hintHold = 5000;

// A hint also comes back once when its gesture went unused this many days (so a rare
// gesture isn't forgotten by the time it's needed). 0: never. The Help pill in the control
// center's Dials control replays the tour and the hints whenever you ask
const hintRemindDays = 30;

// The order of the control center's outer-ring tiles (drag a tile along the ring while
// Edit is on to change it). Delete the file to come back to the built-in order.
const controlOrderPath = "/home/boing/.local/state/dial-quickshell/control-order.json";

// ── live settings ── the values below (and scrollMomentum, flickStrength, hintTimes,
// osdEnabled, the sorting and the tick sound further up and down this file) can also be
// changed from inside the shell: the control center's Settings control, or
// `qs ipc call prefs set <key> <value>` (`prefs list` shows them all). A change made there
// applies at once with no reload, is remembered in settingsPath and wins over this file;
// `qs ipc call prefs reset <key>` comes back to the value here. See primitive/Prefs.qml.
const settingsPath = "/home/boing/.local/state/dial-quickshell/settings.json";

// where Settings → Advanced keeps the values changed in the settings files (primitive/Advanced.qml)
const advancedPath = "/home/boing/.local/state/dial-quickshell/advanced.json";

// How far a dial overshoots as it opens, 0 (none) to 10, and how quickly it opens and
// closes, 1 to 10. Bounce 2 / speed 6 is M3E's standard default spring (0.9 / 700): opening
// is the most frequent thing a dial does, so it gets the quick, calm one. Bounce 6 / speed 3
// is close to the expressive spring it used before (0.7 / 380)
const openBounce = 2;
const openSpeed = 6;

// Presets per Settings group (Prefs.qml): each is a Preset chip in that group, and sets
// the settings in `values` (any of the group's keys, as `qs ipc call prefs list` names
// them). Default (variables.js) and Custom (your own last values) are always there; a
// group's own "default" entry stands in for the generated Default (its label and values).
//
// Design: the whole look at once. M3 Expressive is this file's design with no liquid
// glass; Apple Liquid: round shapes, Inter, nothing overshoots (Apple's motion settles
// without bouncing), and Apple's Liquid Glass
const presets = {
    Design: [
        { value: "default", label: "M3 Expressive", values: {
            shapeStyle: design.shapes, textFont: design.font, tileStyle: design.tiles, trackStyle: design.tracks,
            openBounce: openBounce, liquidGlass: liquid.mode
        } },
        { value: "apple", label: "Apple Liquid", values: Object.assign({
            shapeStyle: "round", textFont: "Inter", tileStyle: "glass", trackStyle: "straight", openBounce: 0
        }, liquidApple) }
    ],
    Liquid: [
        { value: "apple", label: "Apple", values: liquidApple }
    ]
};

// ms a dial waits for the mouse to come back before it closes, so a slip off its edge
// doesn't cost you the dial (0: closes the moment the mouse leaves)
const slipGrace = 300;

// What the closed corners say. The corner where the volume lives can show an arc:
//   "off"    nothing
//   "level"  the volume level, always
//   "music"  only while music plays: the level, as a wave
//   "both"   the level always, waving while music plays
// The control center's corner shows a bead per waiting notification (cornerUnread)
const cornerVolume = "both";
const cornerUnread = true;

// seconds an arriving notification stays out before it goes back into its corner
const notifyHold = 6;

// "24h": 13:05;  "12h": 1:05 (no AM / PM);  "12hAmPm": 1:05 with an AM / PM shape
const clockFormat = "12h";

// The script that switches the colour scheme (the Theme group of the Settings control
// runs it: `<script> <scheme> <dark | light>`). It is told not to kill and relaunch the
// shell (DIAL_SHELL_RELOADS=1): the shell reloads itself and comes back where you were
const themeScript = "/home/boing/.config/color-schemes/set-theme.sh";

// where the Settings control notes the pill it was on just before that reload, to come back to it
const settingsResumePath = "/home/boing/.local/state/dial-quickshell/resume.json";

// The order of the apps on the launcher's ring. New apps go to the end instead of in
// between, so installing one never moves the others (pull a tile off the ring and drop it
// on another to move it). Delete the file to come back to the alphabet.
const appOrderPath = "/home/boing/.local/state/dial-quickshell/app-order.json";

// The PowerMenu Dial
const powerMenuPosition = "topRight";

// The Wallpaper Dial
const wallpaperDialPosition = "bottomRight";

// The AppLauncher Dial
const appLauncherPosition ="bottomLeft";
const selectedAppShape ="12SidedCookie"

// The Control Center Dial
const controlCenterPosition ="topLeft";

// ── OSDs ── which pop-up dials the shell loads at all. false: that OSD doesn't exist
// (no window, no pill in the control center's Dials control, no spot icon in Edit)
const osdEnabled = {
    volume: true,        // pops up on volume changes (AudioOsd.qml)
    brightness: false,    // pops up on brightness changes (BrightnessOsd.qml)
    workspaces: true,    // pops up while you move between workspaces (WorkspaceOsd.qml)
};

// The Audio OSD Dial (pops up on volume changes; shares its corner with another dial,
// but only exists on screen while it's open)
const audioOsdPosition = "topRight";

// The Brightness OSD Dial (pops up on brightness changes:
// qs ipc call brightness up | down | set 40, or the backlight changing on a laptop)
const brightnessOsdPosition = "topRight";

// how much one `up` / `down` call (or one wheel notch on the OSD) changes the brightness, 0..1
const brightnessStep = 0.05;

// ── Workspace OSD (a corner dial that pops up while you move between workspaces) ──

// the M3 shape each workspace wears, 1st to last (repeats after the last one).
// Any name from primitive/M3Shapes.qml; soft, roundish ones read best this small
// (the spiky Boom / Burst ones turn into blurs)
const workspaceShapes = [
    "4SidedCookie", "Pentagon", "Gem", "Sunny", "6SidedCookie",
    "Clamshell", "Flower", "SoftBurst", "PuffyDiamond", "12SidedCookie",
];

// the corner it pops up in. It shares the corner with that corner's dial, but only
// exists on screen while it's showing
const workspaceOsdPosition = "topLeft";

// how big it opens, px. Everything on it (ring, tiles, centre) scales with this
const workspaceOsdSize = 240;

// how long it stays after the last workspace change, ms (the mouse on it keeps it open)
const workspaceOsdHoldTime = 1200;

// how many workspaces its ring goes up to (further if a workspace past it is open)
const workspaceOsdCount = 10;

// ── motion (M3E expressive) ──
// M3E defines motion as springs (below). Every animation in the shell follows them:
// SpringValue (primitive/) runs a spring directly, and everything else animates along
// a curve worked out from a spring (springCurve), so changing a spring here changes
// every animation that uses it.
//   use:  NumberAnimation { duration: Vars.expressiveFastSpatial.duration
//                           easing.type: Easing.BezierSpline
//                           easing.bezierCurve: Vars.expressiveFastSpatial.bezier }

// ── springs (M3E, copied from Design language/src/tokens/defaults/motion.ts) ──
// dampingRatio: 1 = no bounce, lower = more bounce. stiffness: higher = faster.
const springs = {
    standard: {
        fast:    { spatial: { dampingRatio: 0.9, stiffness: 1400 }, effects: { dampingRatio: 1, stiffness: 3800 } },
        default: { spatial: { dampingRatio: 0.9, stiffness: 700  }, effects: { dampingRatio: 1, stiffness: 1600 } },
        slow:    { spatial: { dampingRatio: 0.9, stiffness: 300  }, effects: { dampingRatio: 1, stiffness: 800  } },
    },
    expressive: {
        fast:    { spatial: { dampingRatio: 0.6, stiffness: 800 }, effects: { dampingRatio: 1, stiffness: 3800 } },
        default: { spatial: { dampingRatio: 0.7, stiffness: 380 }, effects: { dampingRatio: 1, stiffness: 1600 } },
        slow:    { spatial: { dampingRatio: 0.8, stiffness: 200 }, effects: { dampingRatio: 1, stiffness: 800  } },
    },
};

// a short, very bouncy spring for shakes (a search with no match, a knob pulled past its
// end): kicked sideways (kickFor) and left to ring out round 0
const shakeSpring = { dampingRatio: 0.12, stiffness: 2000 };

// true: every animation follows the springs. false: M3E's published cubic-bezier
// stand-ins for three of them (below), and the dials grow / snap along those curves.
// Each primitive can still override it with its own `useSpring`.
const useSprings = true;

// M3E's published bezier versions of three springs. `bezier` is [x1, y1, x2, y2, 1, 1]
const m3eCurves = {
    defaultSpatial: { bezier: [0.38, 1.21, 0.22, 1.00, 1, 1], duration: 476 },   // spring 0.8 / 380
    fastSpatial:    { bezier: [0.42, 1.67, 0.21, 0.90, 1, 1], duration: 421 },   // spring 0.6 / 800
    fastEffects:    { bezier: [0.31, 0.94, 0.34, 1.00, 1, 1], duration: 151 },   // spring 1.0 / 3800
};

// A spring's 0 → 1 move as a QML easing curve, { bezier, duration }. It runs the spring
// (the same maths as SpringValue), ends it once it stays within 0.1% of the target, and
// follows the motion with 8 cubic pieces, each matching the spring's position and speed
// at both ends, so the curve is the spring's own motion (overshoot included) to within
// about 0.5% of the move. Keep it at 10 pieces or fewer: Qt 6.12 crashes on longer
// easing curves (11 pieces = 66 numbers crashes the shell on start).
function springCurve(spring) {
    const k = spring.stiffness, c = 2 * spring.dampingRatio * Math.sqrt(k);
    const h = 0.0005, xs = [0], vs = [0];
    let x = 0, v = 0, settle = 0;
    for (let i = 1; i * h <= 3; i++) {
        v += (k * (1 - x) - c * v) * h;
        x += v * h;
        xs.push(x);
        vs.push(v);
        if (Math.abs(1 - x) >= 0.001) settle = i;
    }
    const n = settle + 1, T = n * h, pieces = 8, bezier = [];
    let u0 = 0, x0 = 0, d0 = 0;
    for (let p = 1; p <= pieces; p++) {
        const i = Math.round(n * p / pieces), u1 = p / pieces, du = u1 - u0;

        // position, and speed in curve units (progress per whole duration)
        const x1 = p === pieces ? 1 : xs[i], d1 = vs[i] * T;
        bezier.push(u0 + du / 3, x0 + d0 * du / 3, u1 - du / 3, x1 - d1 * du / 3, u1, x1);
        u0 = u1; x0 = x1; d0 = d1;
    }
    return { bezier: bezier, duration: Math.round(T * 1000) };
}

// bigger moves, like a dial opening: slower, gentler overshoot (expressive default spatial)
const expressiveDefaultSpatial = useSprings ? springCurve(springs.expressive.default.spatial) : m3eCurves.defaultSpatial;

// size and position changes: overshoots a little, then settles (expressive fast spatial)
const expressiveFastSpatial = useSprings ? springCurve(springs.expressive.fast.spatial) : m3eCurves.fastSpatial;

// colour and opacity changes: no overshoot (expressive fast effects)
const expressiveFastEffects = useSprings ? springCurve(springs.expressive.fast.effects) : m3eCurves.fastEffects;

// The same two moves with no overshoot at all, for Bounce 0 in the Settings control ("calm":
// nothing overshoots anywhere). Read them through Prefs.fastSpatial / Prefs.defaultSpatial,
// which pick the expressive or the calm one
const calmFastSpatial = springCurve({ dampingRatio: 1, stiffness: springs.expressive.fast.spatial.stiffness });
const calmDefaultSpatial = springCurve({ dampingRatio: 1, stiffness: springs.expressive.default.spatial.stiffness });

// slower fades (M3E publishes no curve for these, so they always follow the springs)
const expressiveDefaultEffects = springCurve(springs.expressive.default.effects);
const expressiveSlowEffects = springCurve(springs.expressive.slow.effects);

// the speed to kick a resting spring with (SpringValue.kick) so its first swing reaches
// `amplitude`, for a bouncy spring (dampingRatio below 1) like shakeSpring
function kickFor(amplitude, spring) {
    const z = Math.min(spring.dampingRatio, 0.999), w = Math.sqrt(spring.stiffness);
    return amplitude * w / Math.exp(-z * Math.acos(z) / Math.sqrt(1 - z * z));
}

// The size of the square box the M3Shapes paths are drawn in (0..box on both
// axes). Used to scale a path to whatever it's drawn into.
const m3ShapeBox = 100;

// ── sound ──

// A tick each time a dial passes an item (fast spins rattle), for EVERY dial:
//   "off"   no ticks
//   "even"  every tick at tickVolume
//   "soft"  quieter in a fast spin (down to about a third) and while music plays, so the
//           sound you hear most is the quietest
const ticks = "soft";

// tick loudness, 0.0 (silent) to 1.0 (full)
const tickVolume = 0.4;
