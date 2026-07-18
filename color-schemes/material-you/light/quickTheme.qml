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
	
		readonly property color inverse_on_surface: "#ffede8"
	
		readonly property color inverse_primary: "#ffb59c"
	
		readonly property color inverse_surface: "#392e2b"
	
		readonly property color on_background: "#231a16"
	
		readonly property color on_error: "#ffffff"
	
		readonly property color on_error_container: "#410002"
	
		readonly property color on_primary: "#ffffff"
	
		readonly property color on_primary_container: "#380c00"
	
		readonly property color on_primary_fixed: "#380c00"
	
		readonly property color on_primary_fixed_variant: "#72351f"
	
		readonly property color on_secondary: "#ffffff"
	
		readonly property color on_secondary_container: "#2c160e"
	
		readonly property color on_secondary_fixed: "#2c160e"
	
		readonly property color on_secondary_fixed_variant: "#5d4036"
	
		readonly property color on_surface: "#231a16"
	
		readonly property color on_surface_variant: "#53433e"
	
		readonly property color on_tertiary: "#ffffff"
	
		readonly property color on_tertiary_container: "#221b00"
	
		readonly property color on_tertiary_fixed: "#221b00"
	
		readonly property color on_tertiary_fixed_variant: "#51461a"
	
		readonly property color outline: "#85736d"
	
		readonly property color outline_variant: "#d8c2bb"
	
		readonly property color primary: "#8f4c34"
	
		readonly property color primary_container: "#ffdbcf"
	
		readonly property color primary_fixed: "#ffdbcf"
	
		readonly property color primary_fixed_dim: "#ffb59c"
	
		readonly property color scrim: "#000000"
	
		readonly property color secondary: "#77574c"
	
		readonly property color secondary_container: "#ffdbcf"
	
		readonly property color secondary_fixed: "#ffdbcf"
	
		readonly property color secondary_fixed_dim: "#e7bdb0"
	
		readonly property color shadow: "#000000"
	
		readonly property color source_color: "#914a30"
	
		readonly property color surface: "#fff8f6"
	
		readonly property color surface_bright: "#fff8f6"
	
		readonly property color surface_container: "#fceae5"
	
		readonly property color surface_container_high: "#f7e4df"
	
		readonly property color surface_container_highest: "#f1dfd9"
	
		readonly property color surface_container_low: "#fff1ec"
	
		readonly property color surface_container_lowest: "#ffffff"
	
		readonly property color surface_dim: "#e8d6d1"
	
		readonly property color surface_tint: "#8f4c34"
	
		readonly property color surface_variant: "#f5ded7"
	
		readonly property color tertiary: "#695e2f"
	
		readonly property color tertiary_container: "#f3e2a7"
	
		readonly property color tertiary_fixed: "#f3e2a7"
	
		readonly property color tertiary_fixed_dim: "#d6c68e"
	
}