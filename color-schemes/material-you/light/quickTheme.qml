pragma Singleton
import QtQuick
import "variables.js" as Vars

QtObject {
    function withAlpha(hexString, alpha) {
        let col = Qt.color(hexString);
        return Qt.rgba(col.r, col.g, col.b, alpha);
    }
	
		readonly property color background: "#f7f9ff"
	
		readonly property color error: "#ba1a1a"
	
		readonly property color error_container: "#ffdad6"
	
		readonly property color inverse_on_surface: "#eff1f6"
	
		readonly property color inverse_primary: "#96ccff"
	
		readonly property color inverse_surface: "#2d3135"
	
		readonly property color on_background: "#181c20"
	
		readonly property color on_error: "#ffffff"
	
		readonly property color on_error_container: "#410002"
	
		readonly property color on_primary: "#ffffff"
	
		readonly property color on_primary_container: "#ffffff"
	
		readonly property color on_primary_fixed: "#001d33"
	
		readonly property color on_primary_fixed_variant: "#004a76"
	
		readonly property color on_secondary: "#ffffff"
	
		readonly property color on_secondary_container: "#2f4860"
	
		readonly property color on_secondary_fixed: "#001d33"
	
		readonly property color on_secondary_fixed_variant: "#304960"
	
		readonly property color on_surface: "#181c20"
	
		readonly property color on_surface_variant: "#404750"
	
		readonly property color on_tertiary: "#ffffff"
	
		readonly property color on_tertiary_container: "#ffffff"
	
		readonly property color on_tertiary_fixed: "#320046"
	
		readonly property color on_tertiary_fixed_variant: "#643178"
	
		readonly property color outline: "#707881"
	
		readonly property color outline_variant: "#c0c7d1"
	
		readonly property color primary: "#00588a"
	
		readonly property color primary_container: "#1471ad"
	
		readonly property color primary_fixed: "#cee5ff"
	
		readonly property color primary_fixed_dim: "#96ccff"
	
		readonly property color scrim: "#000000"
	
		readonly property color secondary: "#486179"
	
		readonly property color secondary_container: "#c9e2ff"
	
		readonly property color secondary_fixed: "#cee5ff"
	
		readonly property color secondary_fixed_dim: "#afc9e5"
	
		readonly property color shadow: "#000000"
	
		readonly property color source_color: "#1471ad"
	
		readonly property color surface: "#f7f9ff"
	
		readonly property color surface_bright: "#f7f9ff"
	
		readonly property color surface_container: "#eceef3"
	
		readonly property color surface_container_high: "#e6e8ee"
	
		readonly property color surface_container_highest: "#e0e2e8"
	
		readonly property color surface_container_low: "#f2f3f9"
	
		readonly property color surface_container_lowest: "#ffffff"
	
		readonly property color surface_dim: "#d8dadf"
	
		readonly property color surface_tint: "#00639b"
	
		readonly property color surface_variant: "#dce3ed"
	
		readonly property color tertiary: "#733f87"
	
		readonly property color tertiary_container: "#8d57a1"
	
		readonly property color tertiary_fixed: "#f9d8ff"
	
		readonly property color tertiary_fixed_dim: "#ecb1ff"
	
}