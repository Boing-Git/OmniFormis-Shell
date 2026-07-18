#!/usr/bin/env python3
import argparse
import os
import re
import sys
import subprocess

SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))

# ==========================================
# THEME GENERATION
# ==========================================
def parse_qml_theme(filepath):
    c = {}
    name = None
    found_from_comment = False
    try:
        with open(filepath, 'r') as f:
            for line in f:
                line = line.strip()
                if line.startswith('//') and not found_from_comment:
                    comment_name = line.lstrip('/').strip()
                    if comment_name:
                        name = comment_name
                        found_from_comment = True
                if not line or line.startswith('//'): continue
                match = re.search(r'readonly property color (\w+):\s*"([^"]+)"', line)
                if match:
                    key = match.group(1)
                    val = match.group(2)
                    c[key] = val
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        sys.exit(1)
        
    if not found_from_comment or not name:
        base_name = os.path.basename(filepath)
        name = base_name.replace('.qml', '')
        
    name = re.sub(r'(?i)[-\s]*(light|dark)[-\s]*', ' ', name)
    name = name.replace('-', ' ').replace('_', ' ')
    name = ' '.join(name.split()).title()
    
    if not name:
        name = "AutoTheme"
        
    return c, name, found_from_comment

def process_template(template_content, light_map, dark_map, is_dark_mode=True):
    pattern = r'\{\{\s*colors\.([a-zA-Z0-9_]+)\.(light|dark)\.hex[^\}]*\}\}'
    def replacer(match):
        color_name = match.group(1)
        mode = match.group(2)
        mapping = light_map if mode == 'light' else dark_map
        return mapping.get(color_name, '#000000')
        
    template_content = re.sub(pattern, replacer, template_content)
    template_content = re.sub(r'\{\{\s*image\s*\}\}', '/tmp/wallpaper.png', template_content)

    loop_pattern = r'<\*\s*for\s+name\s*,\s*value\s+in\s+colors\s*\*>(.*?)<\*\s*endfor\s*\*>'
    def loop_replacer(match):
        inner_template = match.group(1)
        result = []
        if 'value.dark' in inner_template:
            map_to_use = dark_map
        elif 'value.light' in inner_template:
            map_to_use = light_map
        else:
            map_to_use = dark_map if is_dark_mode else light_map
            
        for color_name, hex_val in map_to_use.items():
            hex_stripped = hex_val.lstrip('#')
            s = inner_template.replace('{{name}}', color_name)
            s = re.sub(r'\{\{\s*value\.(light|dark)\.hex_stripped[^\}]*\}\}', hex_stripped, s)
            s = re.sub(r'\{\{\s*value\.(light|dark)\.hex[^\}]*\}\}', hex_val, s)
            result.append(s)
        return "".join(result)
        
    template_content = re.sub(loop_pattern, loop_replacer, template_content, flags=re.DOTALL)
    return template_content

def cmd_theme_generate(light_file, dark_file):
    light_map, light_name, light_has_comment = parse_qml_theme(light_file)
    dark_map, dark_name, dark_has_comment = parse_qml_theme(dark_file)
    
    if light_has_comment:
        theme_name = light_name
    elif dark_has_comment:
        theme_name = dark_name
    else:
        theme_name = light_name if len(light_name) >= len(dark_name) else dark_name
        
    dir_name = theme_name.lower().replace(' ', '-')

    config_path = os.path.expanduser('~/.config/matugen/config.toml')
    if not os.path.exists(config_path):
        print(f"Error: {config_path} not found.")
        sys.exit(1)

    with open(config_path, 'r') as f:
        config_content = f.read()

    templates = []
    current_template = None
    for line in config_content.splitlines():
        line = line.strip()
        if not line or line.startswith('#'): continue
        if line.startswith('[templates.'):
            if current_template is not None:
                templates.append(current_template)
            current_template = {}
            continue
        if '=' in line and current_template is not None:
            k, v = line.split('=', 1)
            k = k.strip()
            v = v.strip().strip("'").strip('"')
            current_template[k] = v
            
    if current_template is not None:
        templates.append(current_template)

    matugen_dir = os.path.expanduser('~/.config/matugen/')
    for tmpl in templates:
        input_p = tmpl.get('input_path')
        output_p = tmpl.get('output_path')
        if not input_p or not output_p:
            continue

        in_path = os.path.normpath(os.path.join(matugen_dir, input_p.replace('./', '')))
        out_path = os.path.expanduser(output_p)
        out_path = out_path.replace('material-you', dir_name)

        if not os.path.exists(in_path):
            print(f"Warning: template not found {in_path}")
            continue

        with open(in_path, 'r') as f:
            content = f.read()

        is_dark = 'dark' in in_path
        new_content = process_template(content, light_map, dark_map, is_dark_mode=is_dark)

        os.makedirs(os.path.dirname(out_path), exist_ok=True)
        with open(out_path, 'w') as f:
            f.write(new_content)

        print(f"Generated {out_path}")

    print(f"Theme '{theme_name}' generated successfully!")

def cmd_theme_list():
    theme_dir = os.path.expanduser('~/.config/color-schemes/')
    if not os.path.exists(theme_dir):
        print(f"Error: {theme_dir} not found.")
        sys.exit(1)
    
    themes = [d for d in os.listdir(theme_dir) 
              if os.path.isdir(os.path.join(theme_dir, d)) and d not in ('current', 'currect')]
              
    if not themes:
        print("No themes found.")
        return
        
    print("Available Themes:")
    for t in sorted(themes):
        print(f"  - {t}")

def cmd_theme_toggle():
    current_link = os.path.expanduser('~/.config/color-schemes/current/quickTheme.qml')
    if not os.path.exists(current_link):
        print("No current theme linked.")
        sys.exit(1)
        
    real_path = os.path.realpath(current_link)
    parts = real_path.split('/')
    if len(parts) < 3:
        print("Invalid theme path structure.")
        sys.exit(1)
        
    current_mode = parts[-2]
    current_theme = parts[-3]
    
    new_mode = "light" if current_mode == "dark" else "dark"
    set_script = os.path.expanduser('~/.config/color-schemes/set-theme.sh')
    
    print(f"Toggling to {current_theme} ({new_mode})")
    subprocess.Popen([set_script, current_theme, new_mode])

# ==========================================
# QUICKSHELL VARIABLES & MANAGEMENT (QS)
# ==========================================
VARIABLES_PATH = os.path.normpath(os.path.join(SCRIPT_DIR, '..', 'quickshell', 'Variables', 'variables.js'))

def qs_load_variables():
    try:
        with open(VARIABLES_PATH, 'r') as f:
            return f.read()
    except FileNotFoundError:
        print(f"Error: Could not find variables.js at {VARIABLES_PATH}")
        sys.exit(1)

def qs_save_variables(content):
    with open(VARIABLES_PATH, 'w') as f:
        f.write(content)

def qs_parse_all(content):
    matches = re.finditer(r'^var\s+([a-zA-Z0-9_]+)\s*=\s*(.*?);?$', content, re.MULTILINE)
    variables = {}
    for match in matches:
        variables[match.group(1)] = match.group(2).strip()
    return variables

def qs_cmd_list():
    content = qs_load_variables()
    variables = qs_parse_all(content)
    
    # Filter out raw bezier variables, keep the semantic ones
    exclude = ["m3Standard", "m3StandardDecelerate", "m3StandardAccelerate", 
               "m3EmphasizedDecelerate", "m3EmphasizedAccelerate", 
               "m3ExpressiveSpatialFast", "m3ExpressiveSpatialSlow",
               "customStandard", "customStandardDecelerate", "customStandardAccelerate", 
               "customEmphasizedDecelerate", "customEmphasizedAccelerate", 
               "customExpressiveSpatialFast", "customExpressiveSpatialSlow"]
               
    for k, v in variables.items():
        if k not in exclude:
            print(f"{k}: {v}")

def qs_cmd_get(key):
    content = qs_load_variables()
    variables = qs_parse_all(content)
    if key in variables:
        print(variables[key])
    else:
        print(f"Error: Variable '{key}' not found.")
        sys.exit(1)

def qs_update_var(content, key, value):
    new_value_str = value
    
    # Check if we need to wrap in quotes based on the old value
    pattern_get = rf'^(var\s+{key}\s*=\s*)(.*?)(;?)$'
    match = re.search(pattern_get, content, re.MULTILINE)
    if match:
        old_value = match.group(2)
        if old_value.startswith('"') and old_value.endswith('"'):
            if not (new_value_str.startswith('"') and new_value_str.endswith('"')):
                new_value_str = f'"{new_value_str}"'
        elif old_value.startswith("'") and old_value.endswith("'"):
            if not (new_value_str.startswith("'") and new_value_str.endswith("'")):
                new_value_str = f"'{new_value_str}'"
                
    pattern = rf'^(var\s+{key}\s*=\s*)(.*?)(;?)$'
    def repl(m):
        return f"{m.group(1)}{new_value_str}{m.group(3)}"
        
    new_content, _ = re.subn(pattern, repl, content, count=1, flags=re.MULTILINE)
    return new_content

def qs_cmd_set(key, value):
    content = qs_load_variables()
    variables = qs_parse_all(content)
    
    if key not in variables:
        print(f"Error: Variable '{key}' not found.")
        sys.exit(1)
        
    new_content = qs_update_var(content, key, value)
    qs_save_variables(new_content)
    print(f"Set '{key}' to {value}")

def qs_cmd_kill():
    print("Killing Quickshell...")
    subprocess.run("pkill -9 quickshell; pkill -9 .quickshell-wra", shell=True)

def qs_cmd_start(detached=False):
    print("Starting Quickshell...")
    if detached:
        subprocess.Popen("quickshell > /dev/null 2>&1 &", shell=True)
    else:
        subprocess.run("quickshell", shell=True)

# ==========================================
# BEZIER PRESETS
# ==========================================
import json

PRESETS_FILE = os.path.expanduser("~/.config/quickshell/bezier_presets.json")

def bezier_save(name, payload=None):
    if payload:
        variables = json.loads(payload)
    else:
        content = qs_load_variables()
        variables = qs_parse_all(content)
    
    # 1. Save to JSON preset file
    preset = {}
    for k in ["customStandard", "customStandardDecelerate", "customStandardAccelerate", 
              "customEmphasizedDecelerate", "customEmphasizedAccelerate", 
              "customExpressiveSpatialFast", "customExpressiveSpatialSlow"]:
        if k in variables:
            preset[k] = variables[k]
            
    presets = {}
    if os.path.exists(PRESETS_FILE):
        try:
            with open(PRESETS_FILE, 'r') as f:
                presets = json.load(f)
        except:
            pass
            
    presets[name] = preset
    
    os.makedirs(os.path.dirname(PRESETS_FILE), exist_ok=True)
    with open(PRESETS_FILE, 'w') as f:
        json.dump(presets, f, indent=4)
        
    # 2. Generate Hyprland Lua Animation Style
    lua_file = os.path.expanduser(f"~/.config/hypr/modules/animations/{name}.lua")
    lua_content = f"""local vars = require("modules.variables")

hl.config({{
    bezier = {{
        "customStandard, {preset.get('customStandard', '0.2, 0.0, 0.0, 1.0').strip('[]')}",
        "customStandardDecelerate, {preset.get('customStandardDecelerate', '0.0, 0.0, 0.0, 1.0').strip('[]')}",
        "customStandardAccelerate, {preset.get('customStandardAccelerate', '0.3, 0.0, 1.0, 1.0').strip('[]')}",
        "customEmphasizedDecelerate, {preset.get('customEmphasizedDecelerate', '0.05, 0.7, 0.1, 1.0').strip('[]')}",
        "customEmphasizedAccelerate, {preset.get('customEmphasizedAccelerate', '0.3, 0.0, 0.8, 0.15').strip('[]')}",
        "customExpressiveSpatialFast, {preset.get('customExpressiveSpatialFast', '0.42, 1.67, 0.21, 0.9').strip('[]')}",
        "customExpressiveSpatialSlow, {preset.get('customExpressiveSpatialSlow', '0.39, 1.29, 0.35, 0.98').strip('[]')}"
    }},
    animation = {{
        "windows, 1, 4, customStandard",
        "windowsIn, 1, 4, customEmphasizedDecelerate, popin 80%",
        "windowsOut, 1, 3, customEmphasizedAccelerate, popin 80%",
        "border, 1, 5, customExpressiveSpatialSlow",
        "borderangle, 1, 8, customExpressiveSpatialSlow",
        "fade, 1, 3, customStandard",
        "workspaces, 1, 4, customExpressiveSpatialSlow, fade"
    }}
}})
"""
    with open(lua_file, 'w') as f:
        f.write(lua_content)
        
    # 3. Add to AnimateStyle enum in variables.lua
    var_content = hypr_read_file()
    
    # Find the AnimateStyle definition
    pattern = r'(--.*AnimateStyle.*\n\s*AnimateStyle\s*=\s*".*?"\s*,\s*--\s*)(.*?)\n'
    match = re.search(pattern, var_content)
    if match:
        enums = match.group(2).split(',')
        enums = [e.strip() for e in enums]
        if f'"{name}"' not in enums:
            enums.append(f'"{name}"')
            new_comment = "-- " + ", ".join(enums)
            var_content = var_content[:match.end(1)] + ", ".join(enums) + "\n" + var_content[match.end():]
            hypr_write_file(var_content)
            
    # 4. Save directly to variables.js (without applying)
    qs_content = qs_load_variables()
    for k, v in preset.items():
        qs_content = qs_update_var(qs_content, k, v)
    qs_save_variables(qs_content)
    
    print(f"Saved bezier preset and generated Animation Style '{name}'")

def bezier_load(name):
    if not os.path.exists(PRESETS_FILE):
        print("No presets found.")
        sys.exit(1)
        
    try:
        with open(PRESETS_FILE, 'r') as f:
            presets = json.load(f)
    except:
        print("Error reading presets file.")
        sys.exit(1)
        
    if name not in presets:
        print(f"Preset '{name}' not found.")
        sys.exit(1)
        
    preset = presets[name]
    content = qs_load_variables()
    
    for k, v in preset.items():
        pattern = rf'^(var\s+{k}\s*=\s*)(.*?)(;?)$'
        def repl(m):
            return f"{m.group(1)}{v}{m.group(3)}"
        content, count = re.subn(pattern, repl, content, count=1, flags=re.MULTILINE)
        
    qs_save_variables(content)
    print(f"Loaded bezier preset '{name}'. (You may need to reload Quickshell)")

def bezier_list():
    if not os.path.exists(PRESETS_FILE):
        print("No presets found.")
        return
    try:
        with open(PRESETS_FILE, 'r') as f:
            presets = json.load(f)
            print("Available Bezier Presets:")
            for k in presets.keys():
                print(f"  - {k}")
    except:
        print("Error reading presets file.")

# ==========================================
# HYPRLAND MANAGER
# ==========================================
HYPR_VARS_FILE = os.path.normpath(os.path.join(SCRIPT_DIR, '..', 'hypr', 'modules', 'variables.lua'))

def hypr_read_file():
    if not os.path.exists(HYPR_VARS_FILE):
        print(f"Error: {HYPR_VARS_FILE} not found.")
        sys.exit(1)
    with open(HYPR_VARS_FILE, "r") as f:
        return f.read()

def hypr_write_file(content):
    with open(HYPR_VARS_FILE, "w") as f:
        f.write(content)

def hypr_parse_variables(content):
    variables = {}
    lines = content.split('\n')
    current_comments = []
    current_category = "General"
    pattern = re.compile(r'^([a-zA-Z0-9_]+)[ \t]*=[ \t]*(?:"([^"]*)"|(true|false)|(-?\d+(?:\.\d+)?))(?:,?[ \t]*(--.*)?)?$')
    
    for line in lines:
        stripped = line.strip()
        if stripped.startswith('--') and not stripped.startswith('---'):
            c = stripped.lstrip('-').strip()
            current_comments.append(c)
        elif stripped == '' or stripped.startswith('---'):
            current_comments = []
        else:
            match = pattern.match(stripped)
            if match:
                key = match.group(1)
                str_val = match.group(2)
                bool_val = match.group(3)
                num_val = match.group(4)
                comment = match.group(5)
                
                if len(current_comments) > 1:
                    current_category = current_comments[0]
                
                help_text = comment.strip("- ") if comment else (current_comments[-1] if current_comments else f"Set {key}")
                
                if str_val is not None:
                    val_type = "string"
                    current_val = str_val
                elif bool_val is not None:
                    val_type = "bool"
                    current_val = bool_val
                elif num_val is not None:
                    val_type = "number"
                    current_val = num_val
                else:
                    current_comments = []
                    continue
                    
                if key == "ColorScheme":
                    current_comments = []
                    continue
                    
                enums = []
                if val_type == "string":
                    comments_to_check = []
                    if comment:
                        comments_to_check.append(comment)
                    comments_to_check.extend(current_comments)
                    
                    for c in comments_to_check:
                        m = re.search(r'\((.*)\)', c)
                        if m:
                            quotes = re.findall(r'"([^"]+)"', m.group(1))
                            if quotes:
                                enums.extend(quotes)
                            
                variables[key] = {
                    "type": val_type,
                    "help": help_text,
                    "enums": enums,
                    "val": current_val,
                    "category": current_category
                }
            current_comments = []
            
    return variables

def hypr_update_var(content, key, value, val_type):
    if val_type == "string":
        pattern = r'([ \t]*)(' + re.escape(key) + r')([ \t]*=[ \t]*)"[^"]*"(,?[ \t]*(?:--.*)?)$'
        repl_func = lambda m: f'{m.group(1)}{m.group(2)}{m.group(3)}"{value}"{m.group(4)}'
    elif val_type == "bool":
        val_str = "true" if str(value).lower() in ["true", "1", "yes", "y", "t"] else "false"
        pattern = r'([ \t]*)(' + re.escape(key) + r')([ \t]*=[ \t]*)(true|false)(,?[ \t]*(?:--.*)?)$'
        repl_func = lambda m: f'{m.group(1)}{m.group(2)}{m.group(3)}{val_str}{m.group(5)}'
    elif val_type == "number":
        try:
            num = float(value)
            if num == int(num) and '.' not in str(value):
                formatted = str(int(num))
            else:
                formatted = str(num)
        except ValueError:
            formatted = str(value)
        pattern = r'([ \t]*)(' + re.escape(key) + r')([ \t]*=[ \t]*)-?\d+(?:\.\d+)?(,?[ \t]*(?:--.*)?)$'
        repl_func = lambda m: f'{m.group(1)}{m.group(2)}{m.group(3)}{formatted}{m.group(4)}'
    else:
        return content

    new_content, count = re.subn(pattern, repl_func, content, count=1, flags=re.MULTILINE)
    if count > 0:
        print(f"Successfully updated {key} to {value}")
    else:
        print(f"Warning: Could not find or update {key} in {HYPR_VARS_FILE}")
    
    return new_content

def handle_hypr_manager(args, unknown_args):
    content = hypr_read_file()
    variables = hypr_parse_variables(content)

    exclude = ["CustomStandard", "CustomStandardDecelerate", "CustomStandardAccelerate", 
               "CustomEmphasizedDecelerate", "CustomEmphasizedAccelerate", 
               "CustomExpressiveSpatialFast", "CustomExpressiveSpatialSlow"]

    is_list = args.list or (unknown_args and "list" in unknown_args)
    if is_list:
        for key, info in variables.items():
            if key in exclude:
                continue
            if info["type"] == "bool":
                type_str = "togglable bool"
            elif info.get("enums"):
                type_str = f"enum ({', '.join(info['enums'])})"
            else:
                type_str = info["type"]
                
            left_part = f"{key}: {type_str}"
            val_part = f"[{info['val']}]"
            print(f"{left_part:<50} {val_part:<15} - {info['category']} | {info['help']}")
        sys.exit(0)
    
    if unknown_args and "list" in unknown_args:
        unknown_args.remove("list")
        
    if unknown_args and not any([getattr(args, k, None) for k in variables.keys()]):
        # No known arguments matched
        print(f"Warning: Unknown arguments provided: {unknown_args}")
        sys.exit(1)
        
    modified = False
    for key, info in variables.items():
        val = getattr(args, key, None)
        if val is not None:
            content = hypr_update_var(content, key, val, info["type"])
            modified = True
            
    if modified:
        hypr_write_file(content)
        if getattr(args, "GameMode", None) is not None:
            # GameMode changed, restart shell
            subprocess.Popen("omniformis qs kill; sleep 0.1; omniformis qs start -d", shell=True)

# ==========================================
# MAIN PARSER
# ==========================================
def main():
    parser = argparse.ArgumentParser(description="Omniformis: Unified configuration CLI")
    subparsers = parser.add_subparsers(dest="command")

    # 1. theme
    parser_theme = subparsers.add_parser("theme", help="Manage themes")
    theme_subparsers = parser_theme.add_subparsers(dest="theme_command")
    
    theme_gen = theme_subparsers.add_parser("generate", help="Generate theme from QML files")
    theme_gen.add_argument("light_file", help="Path to light theme QML")
    theme_gen.add_argument("dark_file", help="Path to dark theme QML")
    
    theme_subparsers.add_parser("list", help="List available themes")
    theme_subparsers.add_parser("toggle", help="Toggle between light and dark mode")

    # 2. qs
    parser_qs = subparsers.add_parser("qs", help="Quickshell management")
    qs_subparsers = parser_qs.add_subparsers(dest="qs_command")
    
    qs_get = qs_subparsers.add_parser("get", help="Get a QS variable")
    qs_get.add_argument("key", help="The variable name")
    
    qs_set = qs_subparsers.add_parser("set", help="Set a QS variable")
    qs_set.add_argument("key", help="The variable name")
    qs_set.add_argument("value", help="The new value")
    
    qs_subparsers.add_parser("list", help="List QS variables")
    qs_subparsers.add_parser("kill", help="Kill Quickshell processes")
    
    qs_start = qs_subparsers.add_parser("start", help="Start Quickshell")
    qs_start.add_argument("-d", "--detached", action="store_true", help="Run in background")

    # 3. bezier
    parser_bezier = subparsers.add_parser("bezier", help="Bezier preset management")
    bezier_subparsers = parser_bezier.add_subparsers(dest="bezier_command")
    
    b_save = bezier_subparsers.add_parser("save", help="Save current custom curves as a preset")
    b_save.add_argument("name", help="Name of the preset")
    b_save.add_argument("--payload", help="JSON string representing the temporary memory of 7 curves")
    
    b_load = bezier_subparsers.add_parser("load", help="Load a bezier preset")
    b_load.add_argument("name", help="Name of the preset")
    
    bezier_subparsers.add_parser("list", help="List available bezier presets")

    # 4. hypr (we add arguments dynamically like the old manager.py)
    parser_hypr = subparsers.add_parser("hypr", help="Hyprland variables management")
    parser_hypr.add_argument("-l", "--list", action="store_true", help="List all variables and their possible states")
    
    # Pre-parse just to get variables for the help text, but only if they are asking for hypr
    content = hypr_read_file()
    variables = hypr_parse_variables(content)
    for key, info in variables.items():
        parser_hypr.add_argument(f"--{key}", type=str, help=info["help"])

    args, unknown = parser.parse_known_args()

    if args.command == "theme":
        if args.theme_command == "generate":
            cmd_theme_generate(args.light_file, args.dark_file)
        elif args.theme_command == "list":
            cmd_theme_list()
        elif args.theme_command == "toggle":
            cmd_theme_toggle()
        else:
            parser_theme.print_help()
            sys.exit(1)
            
    elif args.command == "qs":
        if args.qs_command == "get":
            qs_cmd_get(args.key)
        elif args.qs_command == "set":
            qs_cmd_set(args.key, args.value)
        elif args.qs_command == "list":
            qs_cmd_list()
        elif args.qs_command == "kill":
            qs_cmd_kill()
        elif args.qs_command == "start":
            qs_cmd_start(args.detached)
        else:
            parser_qs.print_help()
            sys.exit(1)
            
    elif args.command == "bezier":
        if args.bezier_command == "save":
            bezier_save(args.name, getattr(args, "payload", None))
        elif args.bezier_command == "load":
            bezier_load(args.name)
        elif args.bezier_command == "list":
            bezier_list()
        else:
            parser_bezier.print_help()
            sys.exit(1)
            
    elif args.command == "hypr":
        handle_hypr_manager(args, unknown)
        
    else:
        parser.print_help()
        sys.exit(1)

if __name__ == "__main__":
    main()
