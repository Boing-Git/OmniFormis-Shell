pragma Singleton
import QtQuick
import "primitive"
import "variables.js" as Vars

// The colour roles as the design paints them (Settings → Design → Tiles). Tonal: the
// theme's own M3 roles (Colors), passed straight through. Glass: Apple's way, from what's on
// screen under the open dial (Underneath.qml): its colour behind everything, and glyphs,
// washes and picked things in white over a dark area or near-black over a light one; red
// kept for errors.
// Same names as Colors, so a part switches by reading Roles.x instead of Colors.x
QtObject {
    readonly property bool glass: Prefs.tileStyle === "glass"
    readonly property var g: Vars.design.glassPalette

    // ink: the colour of glyphs and text, from what's under the open dial (Underneath.qml):
    // near-black over a light area, white over a dark one; `back` is its opposite
    readonly property color ink: Underneath.light ? Qt.rgba(0.08, 0.08, 0.09, 1) : "white"
    readonly property color back: Underneath.light ? "white" : "black"
    function inked(a) { return Qt.rgba(ink.r, ink.g, ink.b, a) }

    // picked / lit: in ink, with the opposite on it
    readonly property color primary: glass ? ink : Colors.primary
    readonly property color on_primary: glass ? back : Colors.on_primary
    readonly property color secondary: glass ? ink : Colors.secondary
    readonly property color on_secondary: glass ? back : Colors.on_secondary
    readonly property color tertiary: glass ? ink : Colors.tertiary
    readonly property color on_tertiary: glass ? back : Colors.on_tertiary
    readonly property color inverse_primary: glass ? ink : Colors.inverse_primary
    readonly property color tertiary_fixed: glass ? ink : Colors.tertiary_fixed

    // the same light / dark tone in both modes (M3's fixed roles): what must stay light, like
    // the whites of the mascots' eyes
    readonly property color primary_fixed: glass ? "white" : Colors.primary_fixed
    readonly property color on_primary_fixed: glass ? "black" : Colors.on_primary_fixed
    readonly property color tertiary_fixed_dim: glass ? inked(g.secondaryText) : Colors.tertiary_fixed_dim

    // containers: washes of ink
    readonly property color primary_container: glass ? inked(g.container) : Colors.primary_container
    readonly property color secondary_container: glass ? inked(g.container) : Colors.secondary_container
    readonly property color tertiary_container: glass ? inked(g.container) : Colors.tertiary_container
    readonly property color surface_container: glass ? inked(g.surface) : Colors.surface_container
    readonly property color surface_container_high: glass ? inked(g.surface) : Colors.surface_container_high
    readonly property color surface_container_highest: glass ? inked(g.container) : Colors.surface_container_highest
    readonly property color surface_variant: glass ? inked(g.container) : Colors.surface_variant

    // the surfaces behind everything: the colour under the dial
    readonly property color surface: glass ? Underneath.color : Colors.surface
    readonly property color surface_container_lowest: glass ? Underneath.color : Colors.surface_container_lowest

    // what sits on them
    readonly property color on_primary_container: glass ? ink : Colors.on_primary_container
    readonly property color on_secondary_container: glass ? ink : Colors.on_secondary_container
    readonly property color on_tertiary_container: glass ? ink : Colors.on_tertiary_container
    readonly property color on_surface: glass ? ink : Colors.on_surface
    readonly property color on_surface_variant: glass ? inked(g.secondaryText) : Colors.on_surface_variant
    readonly property color outline_variant: glass ? inked(g.hairline) : Colors.outline_variant
    readonly property color outline: glass ? inked(g.hairline) : Colors.outline

    // toasts and chips over the screen (Apple's dark material)
    readonly property color inverse_surface: glass ? Qt.rgba(0.12, 0.12, 0.13, g.darkMaterial) : Colors.inverse_surface
    readonly property color inverse_on_surface: glass ? "white" : Colors.inverse_on_surface

    // the same in both
    readonly property color error: Colors.error
    readonly property color on_error: Colors.on_error
    readonly property color error_container: Colors.error_container
    readonly property color on_error_container: Colors.on_error_container
    readonly property color scrim: Colors.scrim
    readonly property color shadow: Colors.shadow
}
