import os
import re
import sys

def parse_kitty_theme(filepath):
    c = {}
    name = "AutoTheme"
    try:
        with open(filepath, 'r') as f:
            for line in f:
                line = line.strip()
                if not line: continue
                if line.startswith('## name:'):
                    name = line.split(':', 1)[1].strip()
                    continue
                if line.startswith('#'): continue
                parts = line.split()
                if len(parts) >= 2:
                    key = parts[0]
                    val = parts[1]
                    c[key] = val
    except Exception as e:
        print(f"Error reading {filepath}: {e}")
        sys.exit(1)
    return c, name

def map_colors_from_kitty(c_raw):
    bg = c_raw.get('background', '#000000')
    fg = c_raw.get('foreground', '#ffffff')
    
    bg_hex = bg.lstrip('#')
    if len(bg_hex) == 6:
        r, g, b = int(bg_hex[0:2], 16), int(bg_hex[2:4], 16), int(bg_hex[4:6], 16)
        is_dark = (r*0.299 + g*0.587 + b*0.114) < 128
    else:
        is_dark = True
        
    return c_raw, is_dark

def build_material_theme(c, is_dark):
    bg = c.get('background', '#000000')
    fg = c.get('foreground', '#ffffff')
    sel_bg = c.get('selection_background', c.get('color8', fg))
    
    # Quickshell uses 'primary' as the main background for the Control Center
    primary = bg
    on_primary = fg
    
    # Quickshell uses 'primary_container' for active toggles (Wi-Fi, Bluetooth)
    # Using foreground for the toggle and background for the text creates a perfect high-contrast look
    primary_container = fg
    on_primary_container = bg
    
    secondary = sel_bg
    on_secondary = fg
    secondary_container = sel_bg
    on_secondary_container = fg
    
    tertiary = c.get('color4', fg)
    on_tertiary = bg
    tertiary_container = c.get('color4', fg)
    on_tertiary_container = bg
    
    error = c.get('color1', '#ff0000')
    on_error = bg
    error_container = c.get('color1', '#ff0000')
    on_error_container = bg

    return {
        'background': bg,
        'surface': bg,
        'surface_dim': sel_bg,
        'surface_bright': sel_bg,
        'surface_variant': sel_bg,
        'on_surface': fg,
        'on_surface_variant': c.get('color8', fg),
        'on_background': fg,
        'outline': c.get('color8', sel_bg),
        'outline_variant': sel_bg,
        
        'primary': primary,
        'on_primary': on_primary,
        'primary_container': primary_container,
        'on_primary_container': on_primary_container,
        'primary_fixed': primary_container,
        'primary_fixed_dim': primary_container,
        'on_primary_fixed': on_primary_container,
        'on_primary_fixed_variant': on_primary_container,
        
        'secondary': secondary,
        'on_secondary': on_secondary,
        'secondary_container': secondary_container,
        'on_secondary_container': on_secondary_container,
        'secondary_fixed': secondary_container,
        'secondary_fixed_dim': secondary_container,
        'on_secondary_fixed': on_secondary_container,
        'on_secondary_fixed_variant': on_secondary_container,
        
        'tertiary': tertiary,
        'on_tertiary': on_tertiary,
        'tertiary_container': tertiary_container,
        'on_tertiary_container': on_tertiary_container,
        'tertiary_fixed': tertiary_container,
        'tertiary_fixed_dim': tertiary_container,
        'on_tertiary_fixed': on_tertiary_container,
        'on_tertiary_fixed_variant': on_tertiary_container,
        
        'error': error,
        'on_error': on_error,
        'error_container': error_container,
        'on_error_container': on_error_container,
        
        'shadow': '#000000' if is_dark else '#d0d0d0',
        'scrim': '#000000' if is_dark else '#d0d0d0',
        'inverse_surface': fg,
        'inverse_on_surface': bg,
        'inverse_primary': primary,
    }

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

def main():
    if len(sys.argv) < 3:
        print("Usage: python generate_theme.py <light_theme.conf> <dark_theme.conf>")
        sys.exit(1)

    light_file = sys.argv[1]
    dark_file = sys.argv[2]
    
    light_raw, light_name = parse_kitty_theme(light_file)
    dark_raw, dark_name = parse_kitty_theme(dark_file)
    
    c_light, _ = map_colors_from_kitty(light_raw)
    c_dark, _ = map_colors_from_kitty(dark_raw)
    
    light_map = build_material_theme(c_light, False)
    dark_map = build_material_theme(c_dark, True)
    
    theme_name = light_name.replace(' Light', '').replace(' Dark', '').replace(' Dawn', '')
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

if __name__ == '__main__':
    main()
