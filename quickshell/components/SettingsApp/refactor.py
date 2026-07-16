import re

with open("UnifiedSettingsPage.qml", "r") as f:
    content = f.read()

# 1. Add activeCategory property
content = re.sub(r'property var allVars: \[\]', 'property var allVars: []\n    property string activeCategory: "General"\n    onActiveCategoryChanged: applyFilter()', content)

# 2. Update updateVariable function
new_update_func = """    function updateVariable(key, val, source) {
        var cmd = source === "quickshell" ? '["omniformis", "qs", "set", "' + key + '", "' + val + '"]' : '["omniformis", "hypr", "--' + key + '", "' + val + '"]';
        var proc = Qt.createQmlObject('import Quickshell.Io; Process { command: ' + cmd + '; onExited: destroy() }', rootPage);
        proc.running = true;
    }"""
content = re.sub(r'function updateVariable\(key, val\) \{.*?\n    \}', new_update_func, content, flags=re.DOTALL)

# 3. Update loadSettings
content = re.sub(r'function loadSettings\(\) \{.*?\n    \}', 'function loadSettings() {\n        rootPage.allVars = [];\n        hyprManagerProc.running = true;\n        qsManagerProc.running = true;\n    }', content, flags=re.DOTALL)

# 4. Update Header text
content = re.sub(r'text: "Hyprland Configuration"', 'text: activeCategory', content)
content = re.sub(r'text: "Configuration, appearance, and window behavior"', 'text: "Manage settings for " + activeCategory', content)

# 5. Add section.property: "source" to ListView
content = re.sub(r'section\.property: "category"', 'section.property: "source"', content)

# 6. Update delegate to use new signature and source
content = re.sub(r'property string itemVal: model\.val', 'property string itemVal: model.val\n            property string itemSource: model.source', content)
content = re.sub(r'updateVariable\(itemKey, newVal\);', 'updateVariable(itemKey, newVal, itemSource);', content)
content = re.sub(r'updateVariable\(delegateRoot\.itemKey, newVal\);', 'updateVariable(delegateRoot.itemKey, newVal, delegateRoot.itemSource);', content)
content = re.sub(r'updateVariable\(delegateRoot\.itemKey, text\);', 'updateVariable(delegateRoot.itemKey, text, delegateRoot.itemSource);', content)
content = re.sub(r'updateVariable\(delegateRoot\.itemKey, val\.toString\(\)\);', 'updateVariable(delegateRoot.itemKey, val.toString(), delegateRoot.itemSource);', content)

# 7. Modify hyprManagerProc to append to allVars and add source
hypr_push_old = 'newVars.push({ key: key, type: type, help: helpPart, enums: enums.join("|||"), val: valPart, category: category });'
hypr_push_new = 'newVars.push({ key: key, type: type, help: helpPart, enums: enums.join("|||"), val: valPart, category: category, source: "Hyprland" });'
content = content.replace(hypr_push_old, hypr_push_new)
content = content.replace('rootPage.allVars = newVars;\n                applyFilter();', 'rootPage.allVars = rootPage.allVars.concat(newVars);\n                applyFilter();')

# 8. Add qsManagerProc
qs_proc = """
    Process {
        id: qsManagerProc
        command: ["omniformis", "qs", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\\n");
                var newVars = [];
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i].trim();
                    if (line.length === 0) continue;
                    
                    var colonIdx = line.indexOf(":");
                    if (colonIdx === -1) continue;
                    
                    var key = line.substring(0, colonIdx).trim();
                    var valPart = line.substring(colonIdx + 1).trim();
                    
                    var type = "string";
                    if (valPart === "true" || valPart === "false") {
                        type = "bool";
                    } else if (!isNaN(Number(valPart)) && valPart !== "") {
                        type = "number";
                    }
                    
                    var category = "Appearance";
                    if (key.startsWith("spacing") || key.startsWith("padding") || key === "wallpaperMaskScale") {
                        category = "General";
                    } else if (key === "animationDuration") {
                        category = "Appearance";
                    } else if (key.startsWith("radius")) {
                        category = "Appearance";
                    } else if (key === "overviewGridRows" || key === "overviewGridColumns" || key === "overviewScale") {
                        category = "General";
                    }
                    
                    newVars.push({ key: key, type: type, help: "Quickshell variable", enums: "", val: valPart, category: category, source: "Quickshell" });
                }
                
                rootPage.allVars = rootPage.allVars.concat(newVars);
                applyFilter();
            }
        }
    }
"""
content = content.replace('    function applyFilter()', qs_proc + '\n    function applyFilter()')

# 9. Update applyFilter logic
new_filter = """    function applyFilter() {
        var term = searchInput.text.trim();
        settingsModel.clear();
        for (var k = 0; k < rootPage.allVars.length; k++) {
            var v = rootPage.allVars[k];
            if (v.category !== rootPage.activeCategory) continue;
            if (term === "" || Vars.fuzzyMatch(term, v.key) || Vars.fuzzyMatch(term, v.help)) {
                settingsModel.append(v);
            }
        }
    }"""
content = re.sub(r'    function applyFilter\(\) \{.*?\n    \}', new_filter, content, flags=re.DOTALL)

with open("UnifiedSettingsPage.qml", "w") as f:
    f.write(content)
