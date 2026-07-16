pragma Singleton
import QtQuick
import "variables.js" as Vars

QtObject {
    function withAlpha(hexString, alpha) {
        let col = Qt.color(hexString);
        return Qt.rgba(col.r, col.g, col.b, alpha);
    }
	
		readonly property color background: "#282828"
	
		readonly property color error: "#fb4934"
	
		readonly property color error_container: "#cc241d"
	
		readonly property color inverse_on_surface: "#282828"
	
		readonly property color inverse_primary: "#d79921"
	
		readonly property color inverse_surface: "#ebdbb2"
	
		readonly property color on_background: "#ebdbb2"
	
		readonly property color on_error: "#282828"
	
		readonly property color on_error_container: "#fbf1c7"
	
		readonly property color on_primary: "#282828"
	
		readonly property color on_primary_container: "#fbf1c7"
	
		readonly property color on_primary_fixed: "#fabd2f"
	
		readonly property color on_primary_fixed_variant: "#504945"
	
		readonly property color on_secondary: "#282828"
	
		readonly property color on_secondary_container: "#fbf1c7"
	
		readonly property color on_secondary_fixed: "#83a598"
	
		readonly property color on_secondary_fixed_variant: "#504945"
	
		readonly property color on_surface: "#ebdbb2"
	
		readonly property color on_surface_variant: "#bdae93"
	
		readonly property color on_tertiary: "#282828"
	
		readonly property color on_tertiary_container: "#fbf1c7"
	
		readonly property color on_tertiary_fixed: "#b8bb26"
	
		readonly property color on_tertiary_fixed_variant: "#504945"
	
		readonly property color outline: "#a89984"
	
		readonly property color outline_variant: "#665c54"
	
		readonly property color primary: "#fabd2f"
	
		readonly property color primary_container: "#d79921"
	
		readonly property color primary_fixed: "#fabd2f"
	
		readonly property color primary_fixed_dim: "#d79921"
	
		readonly property color scrim: "#1d2021"
	
		readonly property color secondary: "#83a598"
	
		readonly property color secondary_container: "#458588"
	
		readonly property color secondary_fixed: "#83a598"
	
		readonly property color secondary_fixed_dim: "#458588"
	
		readonly property color shadow: "#1d2021"
	
		readonly property color source_color: "#fabd2f"
	
		readonly property color surface: "#282828"
	
		readonly property color surface_bright: "#3c3836"
	
		readonly property color surface_container: "#3c3836"
	
		readonly property color surface_container_high: "#504945"
	
		readonly property color surface_container_highest: "#665c54"
	
		readonly property color surface_container_low: "#282828"
	
		readonly property color surface_container_lowest: "#1d2021"
	
		readonly property color surface_dim: "#1d2021"
	
		readonly property color surface_tint: "#fabd2f"
	
		readonly property color surface_variant: "#3c3836"
	
		readonly property color tertiary: "#b8bb26"
	
		readonly property color tertiary_container: "#98971a"
	
		readonly property color tertiary_fixed: "#b8bb26"
	
		readonly property color tertiary_fixed_dim: "#98971a"
	
}