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
	
		readonly property color inverse_on_surface: "#ffede7"
	
		readonly property color inverse_primary: "#ffb59b"
	
		readonly property color inverse_surface: "#392e2b"
	
		readonly property color on_background: "#231a16"
	
		readonly property color on_error: "#ffffff"
	
		readonly property color on_error_container: "#410002"
	
		readonly property color on_primary: "#ffffff"
	
		readonly property color on_primary_container: "#380d00"
	
		readonly property color on_primary_fixed: "#380d00"
	
		readonly property color on_primary_fixed_variant: "#72361e"
	
		readonly property color on_secondary: "#ffffff"
	
		readonly property color on_secondary_container: "#2c160d"
	
		readonly property color on_secondary_fixed: "#2c160d"
	
		readonly property color on_secondary_fixed_variant: "#5d4035"
	
		readonly property color on_surface: "#231a16"
	
		readonly property color on_surface_variant: "#53433e"
	
		readonly property color on_tertiary: "#ffffff"
	
		readonly property color on_tertiary_container: "#221b00"
	
		readonly property color on_tertiary_fixed: "#221b00"
	
		readonly property color on_tertiary_fixed_variant: "#50471a"
	
		readonly property color outline: "#85736d"
	
		readonly property color outline_variant: "#d8c2bb"
	
		readonly property color primary: "#8f4c33"
	
		readonly property color primary_container: "#ffdbcf"
	
		readonly property color primary_fixed: "#ffdbcf"
	
		readonly property color primary_fixed_dim: "#ffb59b"
	
		readonly property color scrim: "#000000"
	
		readonly property color secondary: "#77574c"
	
		readonly property color secondary_container: "#ffdbcf"
	
		readonly property color secondary_fixed: "#ffdbcf"
	
		readonly property color secondary_fixed_dim: "#e7bdaf"
	
		readonly property color shadow: "#000000"
	
		readonly property color source_color: "#a75434"
	
		readonly property color surface: "#fff8f6"
	
		readonly property color surface_bright: "#fff8f6"
	
		readonly property color surface_container: "#fceae4"
	
		readonly property color surface_container_high: "#f7e4df"
	
		readonly property color surface_container_highest: "#f1dfd9"
	
		readonly property color surface_container_low: "#fff1ec"
	
		readonly property color surface_container_lowest: "#ffffff"
	
		readonly property color surface_dim: "#e8d6d1"
	
		readonly property color surface_tint: "#8f4c33"
	
		readonly property color surface_variant: "#f5ded6"
	
		readonly property color tertiary: "#695e2f"
	
		readonly property color tertiary_container: "#f2e2a7"
	
		readonly property color tertiary_fixed: "#f2e2a7"
	
		readonly property color tertiary_fixed_dim: "#d5c68e"
	
}