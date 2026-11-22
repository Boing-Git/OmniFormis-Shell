import QtQuick

// Text that stays smooth turned, scaled or curved: drawn from distance fields (Qt's own
// scalable text), with the font's hinting off so the letters keep their true shapes at
// any angle and size. The text partner of SymbolIcon; use it for every label.
//
// Tested against the other ways at 11-18 px: native text gets jagged, colour-fringed edges
// once turned; curve / outline (SymbolIcon's way) are smooth but come out thinner and
// lighter at small sizes. Still a plain Text, so elide, wrap and alignment all work.
Text {
    // primitives never pick a colour: always pass one in
    required color

    renderType: Text.QtRendering
    font.hintingPreference: Font.PreferNoHinting
    font.family: Prefs.fontFamily
}
