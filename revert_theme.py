import re

def to_snake(match):
    name = match.group(1)
    # Convert camelCase to snake_case
    s1 = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    return 'Theme.' + re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1).lower()

with open('/home/boing/Dotfiles/quickshell/components/ControlCenter/ModuleGrid.qml', 'r') as f:
    content = f.read()

content = re.sub(r'Theme\.([A-Za-z]+)', to_snake, content)

with open('/home/boing/Dotfiles/quickshell/components/ControlCenter/ModuleGrid.qml', 'w') as f:
    f.write(content)
