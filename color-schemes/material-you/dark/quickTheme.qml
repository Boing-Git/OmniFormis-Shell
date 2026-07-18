pragma Singleton
import QtQuick
import "variables.js" as Vars

QtObject {
    function withAlpha(hexString, alpha) {
        let col = Qt.color(hexString);
        return Qt.rgba(col.r, col.g, col.b, alpha);
    }
	
		readonly property color background: "#1a1110"
	
		readonly property color error: "#ffb4ab"
	
		readonly property color error_container: "#93000a"
	
		readonly property color inverse_on_surface: "#392e2c"
	
		readonly property color inverse_primary: "#904b40"
	
		readonly property color inverse_surface: "#f1dfdb"
	
		readonly property color on_background: "#f1dfdb"
	
		readonly property color on_error: "#690005"
	
		readonly property color on_error_container: "#ffdad6"
	
		readonly property color on_primary: "#561e16"
	
		readonly property color on_primary_container: "#ffdad4"
	
		readonly property color on_primary_fixed: "#3a0905"
	
		readonly property color on_primary_fixed_variant: "#73342a"
	
		readonly property color on_secondary: "#442925"
	
		readonly property color on_secondary_container: "#ffdad4"
	
		readonly property color on_secondary_fixed: "#2c1511"
	
		readonly property color on_secondary_fixed_variant: "#5d3f3a"
	
		readonly property color on_surface: "#f1dfdb"
	
		readonly property color on_surface_variant: "#d8c2be"
	
		readonly property color on_tertiary: "#3e2e04"
	
		readonly property color on_tertiary_container: "#fbe0a6"
	
		readonly property color on_tertiary_fixed: "#251a00"
	
		readonly property color on_tertiary_fixed_variant: "#564419"
	
		readonly property color outline: "#a08c89"
	
		readonly property color outline_variant: "#534341"
	
		readonly property color primary: "#ffb4a7"
	
		readonly property color primary_container: "#73342a"
	
		readonly property color primary_fixed: "#ffdad4"
	
		readonly property color primary_fixed_dim: "#ffb4a7"
	
		readonly property color scrim: "#000000"
	
		readonly property color secondary: "#e7bdb6"
	
		readonly property color secondary_container: "#5d3f3a"
	
		readonly property color secondary_fixed: "#ffdad4"
	
		readonly property color secondary_fixed_dim: "#e7bdb6"
	
		readonly property color shadow: "#000000"
	
		readonly property color source_color: "#dd311f"
	
		readonly property color surface: "#1a1110"
	
		readonly property color surface_bright: "#423735"
	
		readonly property color surface_container: "#271d1c"
	
		readonly property color surface_container_high: "#322826"
	
		readonly property color surface_container_highest: "#3d3230"
	
		readonly property color surface_container_low: "#231918"
	
		readonly property color surface_container_lowest: "#140c0b"
	
		readonly property color surface_dim: "#1a1110"
	
		readonly property color surface_tint: "#ffb4a7"
	
		readonly property color surface_variant: "#534341"
	
		readonly property color tertiary: "#dec48c"
	
		readonly property color tertiary_container: "#564419"
	
		readonly property color tertiary_fixed: "#fbe0a6"
	
		readonly property color tertiary_fixed_dim: "#dec48c"
	
}