pragma Singleton
import QtQuick
import "variables.js" as Vars

QtObject {
    function withAlpha(hexString, alpha) {
        let col = Qt.color(hexString);
        return Qt.rgba(col.r, col.g, col.b, alpha);
    }
	
		readonly property color background: "#1a110f"
	
		readonly property color error: "#ffb4ab"
	
		readonly property color error_container: "#93000a"
	
		readonly property color inverse_on_surface: "#392e2b"
	
		readonly property color inverse_primary: "#8f4c34"
	
		readonly property color inverse_surface: "#f1dfd9"
	
		readonly property color on_background: "#f1dfd9"
	
		readonly property color on_error: "#690005"
	
		readonly property color on_error_container: "#ffdad6"
	
		readonly property color on_primary: "#55200b"
	
		readonly property color on_primary_container: "#ffdbcf"
	
		readonly property color on_primary_fixed: "#380c00"
	
		readonly property color on_primary_fixed_variant: "#72351f"
	
		readonly property color on_secondary: "#442a21"
	
		readonly property color on_secondary_container: "#ffdbcf"
	
		readonly property color on_secondary_fixed: "#2c160e"
	
		readonly property color on_secondary_fixed_variant: "#5d4036"
	
		readonly property color on_surface: "#f1dfd9"
	
		readonly property color on_surface_variant: "#d8c2bb"
	
		readonly property color on_tertiary: "#393005"
	
		readonly property color on_tertiary_container: "#f3e2a7"
	
		readonly property color on_tertiary_fixed: "#221b00"
	
		readonly property color on_tertiary_fixed_variant: "#51461a"
	
		readonly property color outline: "#a08d86"
	
		readonly property color outline_variant: "#53433e"
	
		readonly property color primary: "#ffb59c"
	
		readonly property color primary_container: "#72351f"
	
		readonly property color primary_fixed: "#ffdbcf"
	
		readonly property color primary_fixed_dim: "#ffb59c"
	
		readonly property color scrim: "#000000"
	
		readonly property color secondary: "#e7bdb0"
	
		readonly property color secondary_container: "#5d4036"
	
		readonly property color secondary_fixed: "#ffdbcf"
	
		readonly property color secondary_fixed_dim: "#e7bdb0"
	
		readonly property color shadow: "#000000"
	
		readonly property color source_color: "#914a30"
	
		readonly property color surface: "#1a110f"
	
		readonly property color surface_bright: "#423733"
	
		readonly property color surface_container: "#271d1a"
	
		readonly property color surface_container_high: "#322824"
	
		readonly property color surface_container_highest: "#3d322f"
	
		readonly property color surface_container_low: "#231a16"
	
		readonly property color surface_container_lowest: "#140c0a"
	
		readonly property color surface_dim: "#1a110f"
	
		readonly property color surface_tint: "#ffb59c"
	
		readonly property color surface_variant: "#53433e"
	
		readonly property color tertiary: "#d6c68e"
	
		readonly property color tertiary_container: "#51461a"
	
		readonly property color tertiary_fixed: "#f3e2a7"
	
		readonly property color tertiary_fixed_dim: "#d6c68e"
	
}