#!/usr/bin/env python3
import os
import re

VARS_FILE = os.path.expanduser("~/.config/hypr/modules/variables.lua")
THEME_QML = os.path.expanduser("~/.config/color-schemes/currect/theme.qml")
COLORSCHEMES_DIR = os.path.expanduser("~/.config/hypr/scheme")

def main():
    # 1. Read variables.lua to find the active ColorScheme and GameMode
    color_scheme = "material-you" # Default fallback
    game_mode = False
    try:
        with open(VARS_FILE, "r") as f:
            content = f.read()
            # Match ColorScheme = "name"
            match = re.search(r'ColorScheme\s*=\s*["\']([^"\']+)["\']', content)
            if match:
                color_scheme = match.group(1)
            # Match GameMode = true/false
            match_gm = re.search(r'GameMode\s*=\s*(true|false)', content, re.IGNORECASE)
            if match_gm:
                game_mode = (match_gm.group(1).lower() == 'true')
    except Exception as e:
        print(f"Error reading {VARS_FILE}: {e}")

    # 2. Read the corresponding Lua file
    lua_file = os.path.join(COLORSCHEMES_DIR, f"{color_scheme}.lua")
    colors = {}
    try:
        with open(lua_file, "r") as f:
            content = f.read()
            # Parse Lua table structure
            # Matches key = "value"
            pattern = re.compile(r'([a-zA-Z0-9_]+)\s*=\s*["\']([^"\']+)["\']')
            for match in pattern.finditer(content):
                key = match.group(1)
                value = match.group(2)
                colors[key] = value
    except Exception as e:
        print(f"Error reading {lua_file}: {e}")
        return

    if not colors:
        print("No colors found in lua file.")
        return

    # 3. Generate Theme.qml
    qml_content = "pragma Singleton\nimport QtQuick\n\nQtObject {\n"
    
    for key, value in colors.items():
        if key == "image":
            continue
        if isinstance(value, str) and value.startswith("0x"):
            value = "#" + value[2:]
        # Ensure the key is valid (some json files might have metadata like 'source_color' that we can just include)
        qml_content += f'    property color {key}: "{value}"\n'
        
    qml_content += f'    property bool gameMode: {"true" if game_mode else "false"}\n'
    qml_content += "}\n"

    try:
        with open(THEME_QML, "w") as f:
            f.write(qml_content)
        print(f"Successfully generated {THEME_QML} using '{color_scheme}' scheme")
    except Exception as e:
        print(f"Error writing to {THEME_QML}: {e}")

if __name__ == "__main__":
    main()
