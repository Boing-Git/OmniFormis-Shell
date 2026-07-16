pragma Singleton
import QtQuick
import "variables.js" as Vars

QtObject {
    function withAlpha(hexString, alpha) {
        let col = Qt.color(hexString);
        return Qt.rgba(col.r, col.g, col.b, alpha);
    }
	
		readonly property color background: "#1a110e"
	
		readonly property color error: "#ffb4ab"
	
		readonly property color error_container: "#93000a"
	
		readonly property color inverse_on_surface: "#392e2b"
	
		readonly property color inverse_primary: "#8f4c33"
	
		readonly property color inverse_surface: "#f1dfd9"
	
		readonly property color on_background: "#f1dfd9"
	
		readonly property color on_error: "#690005"
	
		readonly property color on_error_container: "#ffdad6"
	
		readonly property color on_primary: "#55200a"
	
		readonly property color on_primary_container: "#ffdbcf"
	
		readonly property color on_primary_fixed: "#380d00"
	
		readonly property color on_primary_fixed_variant: "#72361e"
	
		readonly property color on_secondary: "#442a21"
	
		readonly property color on_secondary_container: "#ffdbcf"
	
		readonly property color on_secondary_fixed: "#2c160d"
	
		readonly property color on_secondary_fixed_variant: "#5d4035"
	
		readonly property color on_surface: "#f1dfd9"
	
		readonly property color on_surface_variant: "#d8c2bb"
	
		readonly property color on_tertiary: "#393005"
	
		readonly property color on_tertiary_container: "#f2e2a7"
	
		readonly property color on_tertiary_fixed: "#221b00"
	
		readonly property color on_tertiary_fixed_variant: "#50471a"
	
		readonly property color outline: "#a08d86"
	
		readonly property color outline_variant: "#53433e"
	
		readonly property color primary: "#ffb59b"
	
		readonly property color primary_container: "#72361e"
	
		readonly property color primary_fixed: "#ffdbcf"
	
		readonly property color primary_fixed_dim: "#ffb59b"
	
		readonly property color scrim: "#000000"
	
		readonly property color secondary: "#e7bdaf"
	
		readonly property color secondary_container: "#5d4035"
	
		readonly property color secondary_fixed: "#ffdbcf"
	
		readonly property color secondary_fixed_dim: "#e7bdaf"
	
		readonly property color shadow: "#000000"
	
		readonly property color source_color: "#a75434"
	
		readonly property color surface: "#1a110e"
	
		readonly property color surface_bright: "#423733"
	
		readonly property color surface_container: "#271d1a"
	
		readonly property color surface_container_high: "#322824"
	
		readonly property color surface_container_highest: "#3d322f"
	
		readonly property color surface_container_low: "#231a16"
	
		readonly property color surface_container_lowest: "#140c09"
	
		readonly property color surface_dim: "#1a110e"
	
		readonly property color surface_tint: "#ffb59b"
	
		readonly property color surface_variant: "#53433e"
	
		readonly property color tertiary: "#d5c68e"
	
		readonly property color tertiary_container: "#50471a"
	
		readonly property color tertiary_fixed: "#f2e2a7"
	
		readonly property color tertiary_fixed_dim: "#d5c68e"
	
}