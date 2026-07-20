pragma Singleton
import QtQuick
import "variables.js" as Vars

QtObject {
    function withAlpha(hexString, alpha) {
        let col = Qt.color(hexString);
        return Qt.rgba(col.r, col.g, col.b, alpha);
    }
	
		readonly property color background: "#faf9f8"
	
		readonly property color error: "#ba1a1a"
	
		readonly property color error_container: "#ffdad6"
	
		readonly property color inverse_on_surface: "#f1f1f0"
	
		readonly property color inverse_primary: "#a9cecc"
	
		readonly property color inverse_surface: "#2f3130"
	
		readonly property color on_background: "#1a1c1c"
	
		readonly property color on_error: "#ffffff"
	
		readonly property color on_error_container: "#410002"
	
		readonly property color on_primary: "#ffffff"
	
		readonly property color on_primary_container: "#9fc4c2"
	
		readonly property color on_primary_fixed: "#00201f"
	
		readonly property color on_primary_fixed_variant: "#2a4d4b"
	
		readonly property color on_secondary: "#ffffff"
	
		readonly property color on_secondary_container: "#3c4948"
	
		readonly property color on_secondary_fixed: "#111e1d"
	
		readonly property color on_secondary_fixed_variant: "#3c4948"
	
		readonly property color on_surface: "#1a1c1c"
	
		readonly property color on_surface_variant: "#414848"
	
		readonly property color on_tertiary: "#ffffff"
	
		readonly property color on_tertiary_container: "#c7b7d7"
	
		readonly property color on_tertiary_fixed: "#21172f"
	
		readonly property color on_tertiary_fixed_variant: "#4e425c"
	
		readonly property color outline: "#717978"
	
		readonly property color outline_variant: "#c1c8c7"
	
		readonly property color primary: "#001f1e"
	
		readonly property color primary_container: "#103534"
	
		readonly property color primary_fixed: "#c4eae8"
	
		readonly property color primary_fixed_dim: "#a9cecc"
	
		readonly property color scrim: "#000000"
	
		readonly property color secondary: "#536160"
	
		readonly property color secondary_container: "#d4e3e1"
	
		readonly property color secondary_fixed: "#d7e5e4"
	
		readonly property color secondary_fixed_dim: "#bbc9c8"
	
		readonly property color shadow: "#000000"
	
		readonly property color source_color: "#103534"
	
		readonly property color surface: "#faf9f8"
	
		readonly property color surface_bright: "#faf9f8"
	
		readonly property color surface_container: "#eeeeed"
	
		readonly property color surface_container_high: "#e8e8e7"
	
		readonly property color surface_container_highest: "#e2e2e1"
	
		readonly property color surface_container_low: "#f4f3f3"
	
		readonly property color surface_container_lowest: "#ffffff"
	
		readonly property color surface_dim: "#dadad9"
	
		readonly property color surface_tint: "#426463"
	
		readonly property color surface_variant: "#dde4e3"
	
		readonly property color tertiary: "#21162e"
	
		readonly property color tertiary_container: "#362b44"
	
		readonly property color tertiary_fixed: "#eddcfd"
	
		readonly property color tertiary_fixed_dim: "#d0c0e0"
	
}