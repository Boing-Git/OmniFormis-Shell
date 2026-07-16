pragma Singleton
import QtQuick
import "variables.js" as Vars

QtObject {
    function withAlpha(hexString, alpha) {
        let col = Qt.color(hexString);
        return Qt.rgba(col.r, col.g, col.b, alpha);
    }
	
		readonly property color background: "#fbf1c7"
	
		readonly property color error: "#9d0006"
	
		readonly property color error_container: "#fb4934"
	
		readonly property color inverse_on_surface: "#ebdbb2"
	
		readonly property color inverse_primary: "#fabd2f"
	
		readonly property color inverse_surface: "#282828"
	
		readonly property color on_background: "#3c3836"
	
		readonly property color on_error: "#fbf1c7"
	
		readonly property color on_error_container: "#9d0006"
	
		readonly property color on_primary: "#fbf1c7"
	
		readonly property color on_primary_container: "#3c3836"
	
		readonly property color on_primary_fixed: "#3c3836"
	
		readonly property color on_primary_fixed_variant: "#79740e"
	
		readonly property color on_secondary: "#fbf1c7"
	
		readonly property color on_secondary_container: "#076678"
	
		readonly property color on_secondary_fixed: "#3c3836"
	
		readonly property color on_secondary_fixed_variant: "#076678"
	
		readonly property color on_surface: "#3c3836"
	
		readonly property color on_surface_variant: "#504945"
	
		readonly property color on_tertiary: "#fbf1c7"
	
		readonly property color on_tertiary_container: "#8f3f71"
	
		readonly property color on_tertiary_fixed: "#3c3836"
	
		readonly property color on_tertiary_fixed_variant: "#8f3f71"
	
		readonly property color outline: "#7c6f64"
	
		readonly property color outline_variant: "#bdae93"
	
		readonly property color primary: "#b57614"
	
		readonly property color primary_container: "#fabd2f"
	
		readonly property color primary_fixed: "#fabd2f"
	
		readonly property color primary_fixed_dim: "#d79921"
	
		readonly property color scrim: "#282828"
	
		readonly property color secondary: "#076678"
	
		readonly property color secondary_container: "#83a598"
	
		readonly property color secondary_fixed: "#83a598"
	
		readonly property color secondary_fixed_dim: "#458588"
	
		readonly property color shadow: "#282828"
	
		readonly property color source_color: "#b57614"
	
		readonly property color surface: "#fbf1c7"
	
		readonly property color surface_bright: "#fbf1c7"
	
		readonly property color surface_container: "#ebdbb2"
	
		readonly property color surface_container_high: "#d5c4a1"
	
		readonly property color surface_container_highest: "#bdae93"
	
		readonly property color surface_container_low: "#fbf1c7"
	
		readonly property color surface_container_lowest: "#ffffff"
	
		readonly property color surface_dim: "#d5c4a1"
	
		readonly property color surface_tint: "#b57614"
	
		readonly property color surface_variant: "#ebdbb2"
	
		readonly property color tertiary: "#8f3f71"
	
		readonly property color tertiary_container: "#d3869b"
	
		readonly property color tertiary_fixed: "#d3869b"
	
		readonly property color tertiary_fixed_dim: "#b16286"
	
}