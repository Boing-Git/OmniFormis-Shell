pragma Singleton
import QtQuick
import "variables.js" as Vars

QtObject {
    function withAlpha(hexString, alpha) {
        let col = Qt.color(hexString);
        return Qt.rgba(col.r, col.g, col.b, alpha);
    }
	
		readonly property color background: "#101418"
	
		readonly property color error: "#ffb4ab"
	
		readonly property color error_container: "#93000a"
	
		readonly property color inverse_on_surface: "#2d3135"
	
		readonly property color inverse_primary: "#00639b"
	
		readonly property color inverse_surface: "#e0e2e8"
	
		readonly property color on_background: "#e0e2e8"
	
		readonly property color on_error: "#690005"
	
		readonly property color on_error_container: "#ffdad6"
	
		readonly property color on_primary: "#003353"
	
		readonly property color on_primary_container: "#ffffff"
	
		readonly property color on_primary_fixed: "#001d33"
	
		readonly property color on_primary_fixed_variant: "#004a76"
	
		readonly property color on_secondary: "#183249"
	
		readonly property color on_secondary_container: "#d1e6ff"
	
		readonly property color on_secondary_fixed: "#001d33"
	
		readonly property color on_secondary_fixed_variant: "#304960"
	
		readonly property color on_surface: "#e0e2e8"
	
		readonly property color on_surface_variant: "#c0c7d1"
	
		readonly property color on_tertiary: "#4b1860"
	
		readonly property color on_tertiary_container: "#ffffff"
	
		readonly property color on_tertiary_fixed: "#320046"
	
		readonly property color on_tertiary_fixed_variant: "#643178"
	
		readonly property color outline: "#8a919b"
	
		readonly property color outline_variant: "#404750"
	
		readonly property color primary: "#96ccff"
	
		readonly property color primary_container: "#1471ad"
	
		readonly property color primary_fixed: "#cee5ff"
	
		readonly property color primary_fixed_dim: "#96ccff"
	
		readonly property color scrim: "#000000"
	
		readonly property color secondary: "#afc9e5"
	
		readonly property color secondary_container: "#324b63"
	
		readonly property color secondary_fixed: "#cee5ff"
	
		readonly property color secondary_fixed_dim: "#afc9e5"
	
		readonly property color shadow: "#000000"
	
		readonly property color source_color: "#1471ad"
	
		readonly property color surface: "#101418"
	
		readonly property color surface_bright: "#36393e"
	
		readonly property color surface_container: Vars.translucent ? withAlpha("#1d2024", 0.5) : "#1d2024"
	
		readonly property color surface_container_high: Vars.translucent ? withAlpha("#272a2e", 0.5) : "#272a2e"
	
		readonly property color surface_container_highest: Vars.translucent ? withAlpha("#323539", 0.5) : "#323539"
	
		readonly property color surface_container_low: "#181c20"
	
		readonly property color surface_container_lowest: "#0b0f12"
	
		readonly property color surface_dim: "#101418"
	
		readonly property color surface_tint: "#96ccff"
	
		readonly property color surface_variant: "#404750"
	
		readonly property color tertiary: "#ecb1ff"
	
		readonly property color tertiary_container: "#8d57a1"
	
		readonly property color tertiary_fixed: "#f9d8ff"
	
		readonly property color tertiary_fixed_dim: "#ecb1ff"
	
}