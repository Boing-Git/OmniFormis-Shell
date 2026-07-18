pragma Singleton
import QtQuick
import "variables.js" as Vars

QtObject {
    function withAlpha(hexString, alpha) {
        let col = Qt.color(hexString);
        return Qt.rgba(col.r, col.g, col.b, alpha);
    }
	
		readonly property color background: "#fff8f6"
	
		readonly property color error: "#ba1a1a"
	
		readonly property color error_container: "#ffdad6"
	
		readonly property color inverse_on_surface: "#ffedea"
	
		readonly property color inverse_primary: "#ffb4a7"
	
		readonly property color inverse_surface: "#392e2c"
	
		readonly property color on_background: "#231918"
	
		readonly property color on_error: "#ffffff"
	
		readonly property color on_error_container: "#410002"
	
		readonly property color on_primary: "#ffffff"
	
		readonly property color on_primary_container: "#3a0905"
	
		readonly property color on_primary_fixed: "#3a0905"
	
		readonly property color on_primary_fixed_variant: "#73342a"
	
		readonly property color on_secondary: "#ffffff"
	
		readonly property color on_secondary_container: "#2c1511"
	
		readonly property color on_secondary_fixed: "#2c1511"
	
		readonly property color on_secondary_fixed_variant: "#5d3f3a"
	
		readonly property color on_surface: "#231918"
	
		readonly property color on_surface_variant: "#534341"
	
		readonly property color on_tertiary: "#ffffff"
	
		readonly property color on_tertiary_container: "#251a00"
	
		readonly property color on_tertiary_fixed: "#251a00"
	
		readonly property color on_tertiary_fixed_variant: "#564419"
	
		readonly property color outline: "#857370"
	
		readonly property color outline_variant: "#d8c2be"
	
		readonly property color primary: "#904b40"
	
		readonly property color primary_container: "#ffdad4"
	
		readonly property color primary_fixed: "#ffdad4"
	
		readonly property color primary_fixed_dim: "#ffb4a7"
	
		readonly property color scrim: "#000000"
	
		readonly property color secondary: "#775651"
	
		readonly property color secondary_container: "#ffdad4"
	
		readonly property color secondary_fixed: "#ffdad4"
	
		readonly property color secondary_fixed_dim: "#e7bdb6"
	
		readonly property color shadow: "#000000"
	
		readonly property color source_color: "#dd311f"
	
		readonly property color surface: "#fff8f6"
	
		readonly property color surface_bright: "#fff8f6"
	
		readonly property color surface_container: "#fceae7"
	
		readonly property color surface_container_high: "#f7e4e1"
	
		readonly property color surface_container_highest: "#f1dfdb"
	
		readonly property color surface_container_low: "#fff0ee"
	
		readonly property color surface_container_lowest: "#ffffff"
	
		readonly property color surface_dim: "#e8d6d3"
	
		readonly property color surface_tint: "#904b40"
	
		readonly property color surface_variant: "#f5ddd9"
	
		readonly property color tertiary: "#6f5c2e"
	
		readonly property color tertiary_container: "#fbe0a6"
	
		readonly property color tertiary_fixed: "#fbe0a6"
	
		readonly property color tertiary_fixed_dim: "#dec48c"
	
}