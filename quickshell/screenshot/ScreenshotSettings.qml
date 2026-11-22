import QtQuick

// ─────────────────────────────────────────────────────────────────────────────
// SCREENSHOT SETTINGS: the screenshot tool (screenshot/ScreenshotTool.qml): where shots
// go, the rectangle and its handles, the size chip, the M3E floating toolbar and its
// buttons, and what happens after a shot.
//
// The look follows the Material 3 Expressive specs in "Design language/" (its tokens are
// in Design language/src/tokens/defaults/: floating-toolbar.ts, icon-button.ts,
// floating-action-button.ts, snackbar.ts, state.ts, shape.ts). The numbers below are
// those tokens; change them to taste. Sizes are px unless it says otherwise.
// ─────────────────────────────────────────────────────────────────────────────
QtObject {
    // ── where shots go ──
    // saved shots (Save and Annotate), named like GNOME's: "Screenshot From 2026-11-12 18-04-33.png"
    property string saveDir: "/home/boing/Pictures/Screenshots"
    property string namePrefix: "Screenshot From "
    property string dateFormat: "yyyy-MM-dd HH-mm-ss"

    // scratch space for the frozen screen and copied shots (cleared by the system)
    property string tempDir: "/tmp/dial-screenshot"

    // ms between the control center closing and the screen being frozen, so the dial
    // and the dragged icon are gone from the picture
    property int freezeDelay: 90

    // ── the rectangle ──
    // the size it starts at (from a drop or a click), and the smallest it can get
    property real startWidth: 480
    property real startHeight: 300
    property real minSize: 16

    // the line round it (M3 primary)
    property real borderWidth: 2

    // the darkening outside it: M3 scrim at this opacity
    property real scrimOpacity: 0.5

    // ── the handles ──
    // corners are L-shaped brackets: arm length and thickness
    property real cornerArm: 22
    property real cornerThickness: 5

    // edges are short capsules in the middle of each side
    property real edgeLength: 50
    property real edgeThickness: 5

    // how near (px) the mouse must be to grab one, and how much it grows under the mouse
    property real handleReach: 16
    property real handleHoverScale: 1.3

    // the M3 state layer (a soft circle) behind a handle under the mouse (state.ts: hover / pressed)
    property real handleHaloSize: 40
    property real hoverOpacity: 0.08
    property real pressedOpacity: 0.1

    // ── the size chip ("1280 × 720") on the rectangle's top edge (M3 plain tooltip colours) ──
    property real chipHeight: 28
    property real chipPadding: 12
    property real chipFontSize: 13       // M3 labelLarge-ish
    property real chipGap: 8

    // ── the floating toolbar (floating-toolbar.ts) ──
    property real toolbarHeight: 64
    property real toolbarPadding: 8
    property real toolbarGap: 4

    // space between the toolbar and the rectangle, and the least it keeps from the screen's edges
    property real toolbarOffset: 16

    // ── its icon buttons (icon-button.ts, between "small" 40 and "medium" 56) ──
    // round at rest, squarer while pressed (the M3E shape morph), and the icon size
    property real buttonSize: 48
    property real buttonPressedRadius: 12
    property real buttonIconSize: 24

    // ── the Copy button (floating-action-button.ts: a FAB beside the toolbar) ──
    property real fabSize: 64
    property real fabRadius: 16
    property real fabPressedRadius: 12
    property real fabIconSize: 28

    // ── the tooltip over a toolbar button (tooltip.ts: plain tooltip) ──
    property int tooltipDelay: 500
    property real tooltipHeight: 24
    property real tooltipFontSize: 12

    // ── after a shot ──
    // the camera flash over the shot: how bright it starts (0..1) and ms to fade
    property real flashOpacity: 0.55
    property int flashDuration: 380

    // the snackbar that says what happened (snackbar.ts): ms on screen, and its height
    property int snackbarTime: 2200
    property real snackbarHeight: 48
    property real snackbarFontSize: 14   // M3 bodyMedium

    // how far from the screen's bottom edge it sits
    property real snackbarOffset: 32
}
