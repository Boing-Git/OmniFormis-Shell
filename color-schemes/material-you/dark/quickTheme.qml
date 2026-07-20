pragma Singleton
import QtQuick
import "variables.js" as Vars

QtObject {
    function withAlpha(hexString, alpha) {
        let col = Qt.color(hexString);
        return Qt.rgba(col.r, col.g, col.b, alpha);
    }
	
		readonly property color background: "#121414"
	
		readonly property color error: "#ffb4ab"
	
		readonly property color error_container: "#93000a"
	
		readonly property color inverse_on_surface: "#2f3130"
	
		readonly property color inverse_primary: "#426463"
	
		readonly property color inverse_surface: "#e2e2e1"
	
		readonly property color on_background: "#e2e2e1"
	
		readonly property color on_error: "#690005"
	
		readonly property color on_error_container: "#ffdad6"
	
		readonly property color on_primary: "#113635"
	
		readonly property color on_primary_container: "#9fc4c2"
	
		readonly property color on_primary_fixed: "#00201f"
	
		readonly property color on_primary_fixed_variant: "#2a4d4b"
	
		readonly property color on_secondary: "#263332"
	
		readonly property color on_secondary_container: "#dcebe9"
	
		readonly property color on_secondary_fixed: "#111e1d"
	
		readonly property color on_secondary_fixed_variant: "#3c4948"
	
		readonly property color on_surface: "#e2e2e1"
	
		readonly property color on_surface_variant: "#c1c8c7"
	
		readonly property color on_tertiary: "#372c45"
	
		readonly property color on_tertiary_container: "#c7b7d7"
	
		readonly property color on_tertiary_fixed: "#21172f"
	
		readonly property color on_tertiary_fixed_variant: "#4e425c"
	
		readonly property color outline: "#8b9291"
	
		readonly property color outline_variant: "#414848"
	
		readonly property color primary: "#a9cecc"
	
		readonly property color primary_container: "#103534"
	
		readonly property color primary_fixed: "#c4eae8"
	
		readonly property color primary_fixed_dim: "#a9cecc"
	
		readonly property color scrim: "#000000"
	
		readonly property color secondary: "#bbc9c8"
	
		readonly property color secondary_container: "#414e4d"
	
		readonly property color secondary_fixed: "#d7e5e4"
	
		readonly property color secondary_fixed_dim: "#bbc9c8"
	
		readonly property color shadow: "#000000"
	
		readonly property color source_color: "#103534"
	
		readonly property color surface: "#121414"
	
		readonly property color surface_bright: "#383939"
	
		readonly property color surface_container: "#1e2020"
	
		readonly property color surface_container_high: "#282a2a"
	
		readonly property color surface_container_highest: "#333535"
	
		readonly property color surface_container_low: "#1a1c1c"
	
		readonly property color surface_container_lowest: "#0d0f0e"
	
		readonly property color surface_dim: "#121414"
	
		readonly property color surface_tint: "#a9cecc"
	
		readonly property color surface_variant: "#414848"
	
		readonly property color tertiary: "#d0c0e0"
	
		readonly property color tertiary_container: "#362b44"
	
		readonly property color tertiary_fixed: "#eddcfd"
	
		readonly property color tertiary_fixed_dim: "#d0c0e0"
	
}