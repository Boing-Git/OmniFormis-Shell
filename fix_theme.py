import re

def to_camel(match):
    words = match.group(1).split('_')
    return 'Theme.' + words[0] + ''.join(w.title() for w in words[1:])

with open('/home/boing/Dotfiles/quickshell/components/ControlCenter/ModuleGrid.qml', 'r') as f:
    content = f.read()

content = re.sub(r'Theme\.([a-z_]+)', to_camel, content)

with open('/home/boing/Dotfiles/quickshell/components/ControlCenter/ModuleGrid.qml', 'w') as f:
    f.write(content)
