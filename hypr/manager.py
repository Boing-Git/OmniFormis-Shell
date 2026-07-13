#!/usr/bin/env python3
import argparse
import re
import os
import sys

# Resolve VARS_FILE relative to this script's location so it works whether
# called from ~/dotfiles or via a ~/.local/bin symlink.
SCRIPT_DIR = os.path.dirname(os.path.realpath(__file__))
VARS_FILE = os.path.join(SCRIPT_DIR, "modules", "variables.lua")

def read_file():
    if not os.path.exists(VARS_FILE):
        print(f"Error: {VARS_FILE} not found.")
        sys.exit(1)
    with open(VARS_FILE, "r") as f:
        return f.read()

def write_file(content):
    with open(VARS_FILE, "w") as f:
        f.write(content)

def parse_variables(content):
    """
    Parses the variables.lua file and returns a dictionary of variables
    with their type and comment (to be used as help text).
    """
    variables = {}
    lines = content.split('\n')
    current_comments = []
    
    current_category = "General"
    
    # Matches lines like:  Key = "Value", -- Comment
    pattern = re.compile(r'^[ \t]*([a-zA-Z0-9_]+)[ \t]*=[ \t]*(?:"([^"]*)"|(true|false)|(-?\d+(?:\.\d+)?))(?:,?[ \t]*(--.*)?)?$')
    
    for line in lines:
        stripped = line.strip()
        if stripped.startswith('--') and not stripped.startswith('---'):
            c = stripped.lstrip('-').strip()
            current_comments.append(c)
                
        elif stripped == '' or stripped.startswith('---'):
            current_comments = []
        else:
            match = pattern.match(line)
            if match:
                key = match.group(1)
                str_val = match.group(2)
                bool_val = match.group(3)
                num_val = match.group(4)
                comment = match.group(5)
                
                if len(current_comments) > 1:
                    current_category = current_comments[0]
                
                # Help text is the last comment or inline comment
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
                    # Check both inline comment and preceding comments for enums
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

def update_var(content, key, value, val_type):
    """
    Update a variable in the lua file.
    val_type can be 'string', 'bool', or 'number'
    Uses lambda replacement functions to avoid octal escape bugs with backreferences.
    """
    if val_type == "string":
        # Groups: (1:indent)(2:key)(3: = )"old_val"(4:trailing comma+comment)
        pattern = r'([ \t]*)(' + re.escape(key) + r')([ \t]*=[ \t]*)"[^"]*"(,?[ \t]*(?:--.*)?)$'
        repl_func = lambda m: f'{m.group(1)}{m.group(2)}{m.group(3)}"{value}"{m.group(4)}'
    elif val_type == "bool":
        val_str = "true" if str(value).lower() in ["true", "1", "yes", "y", "t"] else "false"
        # Groups: (1:indent)(2:key)(3: = )(4:old_bool)(5:trailing comma+comment)
        pattern = r'([ \t]*)(' + re.escape(key) + r')([ \t]*=[ \t]*)(true|false)(,?[ \t]*(?:--.*)?)$'
        repl_func = lambda m: f'{m.group(1)}{m.group(2)}{m.group(3)}{val_str}{m.group(5)}'
    elif val_type == "number":
        # Format number: write integers without .0, keep floats as-is
        try:
            num = float(value)
            if num == int(num) and '.' not in str(value):
                formatted = str(int(num))
            else:
                formatted = str(num)
        except ValueError:
            formatted = str(value)
        # Groups: (1:indent)(2:key)(3: = )(4:trailing comma+comment)
        pattern = r'([ \t]*)(' + re.escape(key) + r')([ \t]*=[ \t]*)-?\d+(?:\.\d+)?(,?[ \t]*(?:--.*)?)$'
        repl_func = lambda m: f'{m.group(1)}{m.group(2)}{m.group(3)}{formatted}{m.group(4)}'
    else:
        return content

    new_content, count = re.subn(pattern, repl_func, content, count=1, flags=re.MULTILINE)
    if count > 0:
        print(f"Successfully updated {key} to {value}")
    else:
        print(f"Warning: Could not find or update {key} in {VARS_FILE}")
    
    return new_content

def main():
    content = read_file()
    variables = parse_variables(content)
    
    parser = argparse.ArgumentParser(
        description="Hyprland Configuration Manager (Dynamically parses variables.lua)",
        epilog="Example: ./manager.py --AnimateStyle snappy --groupBar false"
    )
    
    parser.add_argument("-l", "--list", action="store_true", help="List all variables and their possible states")
    
    for key, info in variables.items():
        # Use str for all types to preserve exact user input format
        parser.add_argument(f"--{key}", type=str, help=info["help"])

    args, unknown = parser.parse_known_args()
    
    if args.list:
        for key, info in variables.items():
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
    
    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(1)
        
    if unknown:
        print(f"Warning: Unknown arguments provided: {unknown}")
        
    modified = False
    for key, info in variables.items():
        val = getattr(args, key, None)
        if val is not None:
            content = update_var(content, key, val, info["type"])
            modified = True
            
    if modified:
        write_file(content)
        import subprocess
            
        # Restart quickshell if GameMode was changed
        if getattr(args, "GameMode", None) is not None:
            subprocess.Popen("qs kill; sleep 0.1; qs -d", shell=True)

if __name__ == "__main__":
    main()
