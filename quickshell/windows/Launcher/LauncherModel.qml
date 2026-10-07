import QtQuick
import Quickshell
import Quickshell.Io
import "../.."
import "../../theme"
import "../.."
import "../../theme"

Item {
    id: rootModel

    property string filterText: ""
    property var emojiModel: []
    property var fileModel: []
    property var clipboardModel: []

    property alias cliphistProcRunning: cliphistProc.running

    function refreshClipboard() {
        cliphistProc.running = true;
    }

    Process {
        id: emojiLoader
        command: ["cat", Quickshell.env("HOME") + "/.config/quickshell/scripts/emojis.txt"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.length > 0) {
                    var lines = this.text.split("\n");
                    var arr = [];
                    for (var i = 0; i < lines.length; i++) {
                        var line = lines[i].trim();
                        if (line.length > 0) {
                            var firstSpace = line.indexOf(" ");
                            var glyph = line;
                            if (firstSpace !== -1) {
                                glyph = line.substring(0, firstSpace);
                            } else {
                                glyph = line;
                            }

                            arr.push({
                                name: line,
                                command: ["wl-copy", glyph],
                                commandStr: JSON.stringify(["wl-copy", glyph]),
                                workingDirectory: Quickshell.env("HOME"),
                                icon: "",
                                isFile: false,
                                isSetting: true,
                                iconName: "emoji_emotions"
                            });
                        }
                    }
                    rootModel.emojiModel = arr;
                }
            }
        }
    }

    Process {
        id: fileFinderProc
        command: ["bash", "-c", "find ~/ -maxdepth 3 -type f -o -type d | grep -v '/\\.'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n");
                var arr = [];
                for (var i = 0; i < lines.length; i++) {
                    var path = lines[i].trim();
                    if (path.length > 0 && path !== Quickshell.env("HOME") && path !== Quickshell.env("HOME") + "/") {
                        var name = path.substring(path.lastIndexOf('/') + 1);
                        var isDir = (path.indexOf('.') === -1 || path.lastIndexOf('.') < path.lastIndexOf('/'));
                        arr.push({
                            name: name,
                            command: ["xdg-open", path],
                            commandStr: JSON.stringify(["xdg-open", path]),
                            workingDirectory: Quickshell.env("HOME"),
                            icon: "",
                            isFile: true,
                            isDir: isDir
                        });
                    }
                }
                rootModel.fileModel = arr;
            }
        }
    }

    Process {
        id: cliphistProc
        command: ["bash", "-c", "mkdir -p /tmp/qs_clip && cliphist list | head -n 100 | while IFS=$'\t' read -r id snippet; do if [[ \"$snippet\" == *\"[[ binary data\"* ]]; then if [ ! -f \"/tmp/qs_clip/clip_$id.img\" ]; then cliphist decode \"$id\" > \"/tmp/qs_clip/clip_$id.img\"; fi; fi; echo -e \"$id\\t$snippet\"; done"]
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n");
                var arr = [];
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i];
                    if (line.trim().length > 0) {
                        var tabIndex = line.indexOf("\t");
                        if (tabIndex !== -1) {
                            var id = line.substring(0, tabIndex);
                            var snippet = line.substring(tabIndex + 1);

                            var isImage = snippet.startsWith("[[ binary data") && (snippet.indexOf("png") !== -1 || snippet.indexOf("jpeg") !== -1 || snippet.indexOf("jpg") !== -1 || snippet.indexOf("webp") !== -1 || snippet.indexOf("bmp") !== -1);

                            var isFileUri = snippet.startsWith("file://");
                            var isUriImage = false;
                            var cleanPath = "";
                            if (isFileUri) {
                                cleanPath = snippet.replace("file://", "").split(" ")[0].split("\n")[0].trim();
                                try {
                                    cleanPath = decodeURIComponent(cleanPath);
                                } catch (e) {}
                                var ext = cleanPath.substring(cleanPath.lastIndexOf('.')).toLowerCase();
                                if (ext === ".png" || ext === ".jpg" || ext === ".jpeg" || ext === ".webp" || ext === ".gif") {
                                    isUriImage = true;
                                }
                            }

                            var clipImgPath = "";
                            if (isImage)
                                clipImgPath = "/tmp/qs_clip/clip_" + id + ".img";
                            else if (isUriImage)
                                clipImgPath = cleanPath;

                            var dispName = snippet;
                            if (isImage)
                                dispName = "Copied Image (" + id + ")";
                            else if (isFileUri)
                                dispName = "File: " + cleanPath.substring(cleanPath.lastIndexOf('/') + 1);

                            arr.push({
                                name: dispName,
                                clipId: id,
                                fullLine: line,
                                command: ["bash", "-c", "cliphist decode " + id + " | wl-copy"],
                                commandStr: JSON.stringify(["bash", "-c", "cliphist decode " + id + " | wl-copy"]),
                                workingDirectory: Quickshell.env("HOME"),
                                icon: "",
                                isFile: false,
                                isDir: false,
                                isMath: false,
                                isClipboard: true,
                                clipImagePath: clipImgPath
                            });
                        }
                    }
                }
                rootModel.clipboardModel = arr;
            }
        }
    }

    function clearClipboard() {
        cliphistWipeProc.running = true;
    }

    function deleteClipboardItem(id, fullLine) {
        cliphistDeleteProc.command = ["bash", "-c", "cliphist delete <<< " + JSON.stringify(fullLine)];
        cliphistDeleteProc.running = true;
    }

    Process {
        id: cliphistWipeProc
        command: ["cliphist", "wipe"]
        running: false
        onRunningChanged: {
            if (!running) {
                // Refresh clipboard
                cliphistProc.running = true;
            }
        }
    }

    Process {
        id: cliphistDeleteProc
        command: []
        running: false
        onRunningChanged: {
            if (!running) {
                // Refresh clipboard
                cliphistProc.running = true;
            }
        }
    }

    // The DesktopEntries -> plain-object conversion (icon string building, command fallback,
    // JSON.stringify) was previously redone from scratch on every keystroke, which is the app
    // list's only genuinely expensive step. It now only reruns when the installed apps actually
    // change, so a keystroke only has to fuzzy-match against an already-built array.
    property var baseApps: []

    function rebuildBaseApps() {
        var out = [];
        if (typeof DesktopEntries !== "undefined" && DesktopEntries.applications) {
            var appsSource = DesktopEntries.applications.values;
            if (appsSource) {
                for (var k = 0; k < appsSource.length; k++) {
                    var rApp = appsSource[k];
                    if (!rApp)
                        continue;

                    var execCmd = rApp.command || [];
                    var iconStr = rApp.icon || "";

                    if (iconStr !== "" && iconStr.indexOf("/") !== 0) {
                        iconStr = "?fallback=" + iconStr;
                    }

                    var finalCommand = Array.isArray(execCmd) && execCmd.length > 0 ? execCmd : ["bash", "-c", "gtk-launch " + (rApp.id || "")];
                    out.push({
                        name: rApp.name || "Unknown",
                        icon: iconStr,
                        command: finalCommand,
                        commandStr: JSON.stringify(finalCommand),
                        workingDirectory: rApp.workingDirectory || Quickshell.env("HOME"),
                        isFile: false,
                        isDir: false,
                        isSetting: false,
                        isClearAll: false,
                        isClipboard: false,
                        isMath: false
                    });
                }
            }
        }
        rootModel.baseApps = out;
    }

    Connections {
        target: (typeof DesktopEntries !== "undefined" && DesktopEntries.applications) ? DesktopEntries.applications : null
        function onValuesChanged() { rootModel.rebuildBaseApps(); }
    }

    property alias filteredModel: dynamicModel

    ListModel {
        id: dynamicModel
    }

    // Runs the diff as soon as the UI thread is next idle instead of after a fixed delay, so
    // results keep up even while typing continuously, and Qt.callLater coalesces a burst of
    // keystrokes into a single update instead of running once per key.
    function scheduleSync() {
        Qt.callLater(rootModel.runSync);
    }

    function runSync() {
        var targetArray = computeTargetArray();
        var keyProp = "name";

        // Build a set of target keys for O(1) lookups
        var targetKeys = {};
        for (var j = 0; j < targetArray.length; j++) {
            var key = targetArray[j][keyProp];
            if (key !== undefined) {
                targetKeys[key] = true;
            }
        }

        // 1. Remove items not in targetArray
        for (var i = dynamicModel.count - 1; i >= 0; i--) {
            var item = dynamicModel.get(i);
            if (item) {
                var key = item[keyProp];
                if (!targetKeys[key]) {
                    dynamicModel.remove(i, 1);
                }
            }
        }

        // Build a set of existing keys for O(1) lookups
        var existingKeys = {};
        for (var j = 0; j < dynamicModel.count; j++) {
            var item = dynamicModel.get(j);
            if (item) {
                var key = item[keyProp];
                if (key !== undefined) {
                    existingKeys[key] = true;
                }
            }
        }

        // 2. Add items
        var itemsToAdd = [];
        for (var i = 0; i < targetArray.length; i++) {
            var targetItem = targetArray[i];
            var key = targetItem[keyProp];
            if (key !== undefined && !existingKeys[key]) {
                var toAdd = {
                    name: targetItem.name || "",
                    command: targetItem.command || [],
                    commandStr: targetItem.commandStr || "",
                    workingDirectory: targetItem.workingDirectory || "",
                    icon: targetItem.icon || "",
                    isFile: targetItem.isFile || false,
                    isDir: targetItem.isDir || false,
                    isSetting: targetItem.isSetting || false,
                    isClearAll: targetItem.isClearAll || false,
                    isClipboard: targetItem.isClipboard || false,
                    isMath: targetItem.isMath || false,
                    iconName: targetItem.iconName || "",
                    clipId: targetItem.clipId || "",
                    fullLine: targetItem.fullLine || "",
                    clipImagePath: targetItem.clipImagePath || ""
                };
                itemsToAdd.push(toAdd);
                existingKeys[key] = true;
            }
        }

        for (var k = 0; k < itemsToAdd.length; k++) {
            dynamicModel.append(itemsToAdd[k]);
        }

        // 3. Move items using a shadow array to avoid O(N^2) dynamicModel.get() calls
        var currentKeys = [];
        for (var m = 0; m < dynamicModel.count; m++) {
            var mItem = dynamicModel.get(m);
            currentKeys.push(mItem ? mItem[keyProp] : null);
        }

        var maxItemsToMove = Math.min(targetArray.length, 50);
        for (var i = 0; i < maxItemsToMove; i++) {
            var targetItem = targetArray[i];
            var key = targetItem[keyProp];

            if (currentKeys[i] === key) {
                continue;
            }

            var currentIndex = currentKeys.indexOf(key, i + 1);

            if (currentIndex !== -1) {
                dynamicModel.move(currentIndex, i, 1);
                var movedKey = currentKeys.splice(currentIndex, 1)[0];
                currentKeys.splice(i, 0, movedKey);
            }
        }
    }

    onFilterTextChanged: scheduleSync()
    onEmojiModelChanged: scheduleSync()
    onFileModelChanged: scheduleSync()
    onClipboardModelChanged: scheduleSync()
    Component.onCompleted: {
        rebuildBaseApps();
        scheduleSync();
    }

    function computeTargetArray() {
        var text = rootModel.filterText.toLowerCase();

        if (text.startsWith("=")) {
            var expr = text.substring(1).trim();
            if (expr.length > 0) {
                try {
                    var safeExpr = expr.replace(/[^0-9+\-*/().%\s]/g, "");
                    if (safeExpr.length > 0) {
                        var result = eval(safeExpr);
                        if (result !== undefined && !isNaN(result)) {
                            return [
                                {
                                    name: result.toString(),
                                    command: ["wl-copy", result.toString()],
                                    commandStr: JSON.stringify(["wl-copy", result.toString()]),
                                    workingDirectory: Quickshell.env("HOME"),
                                    icon: "",
                                    isFile: false,
                                    isDir: false,
                                    isMath: true
                                }
                            ];
                        }
                    }
                } catch (e) {}
            }
            return [];
        }

        var settingsOptions = [
            {
                name: "Settings",
                command: ["INTERNAL:SETTINGS"],
                commandStr: JSON.stringify(["INTERNAL:SETTINGS"]),
                workingDirectory: Quickshell.env("HOME"),
                icon: "",
                isFile: false,
                isSetting: true,
                iconName: "settings"
            },
            {
                name: "Clipboard Manager",
                command: ["INTERNAL:CLIPBOARD"],
                commandStr: JSON.stringify(["INTERNAL:CLIPBOARD"]),
                workingDirectory: Quickshell.env("HOME"),
                icon: "",
                isFile: false,
                isSetting: true,
                iconName: "content_paste"
            },
            {
                name: "Emoji Picker",
                command: ["INTERNAL:EMOJI"],
                commandStr: JSON.stringify(["INTERNAL:EMOJI"]),
                workingDirectory: Quickshell.env("HOME"),
                icon: "",
                isFile: false,
                isSetting: true,
                iconName: "emoji_emotions"
            },
            {
                name: "Calculator",
                command: ["INTERNAL:CALCULATOR"],
                commandStr: JSON.stringify(["INTERNAL:CALCULATOR"]),
                workingDirectory: Quickshell.env("HOME"),
                icon: "",
                isFile: false,
                isSetting: true,
                iconName: "calculate"
            },
            {
                name: "Search the Web",
                command: ["INTERNAL:WEB_SEARCH"],
                commandStr: JSON.stringify(["INTERNAL:WEB_SEARCH"]),
                workingDirectory: Quickshell.env("HOME"),
                icon: "",
                isFile: false,
                isSetting: true,
                iconName: "travel_explore"
            }
        ];

        if (text.startsWith("/")) {
            var query = text.substring(1).trim();
            if (query === "") {
                return settingsOptions;
            }
            if (query.startsWith("web")) {
                var webQuery = query.substring(3).trim();
                return [
                    {
                        name: "Search Google for: " + (webQuery === "" ? "..." : webQuery),
                        command: webQuery === "" ? [] : ["xdg-open", "https://www.google.com/search?q=" + encodeURIComponent(webQuery)],
                        workingDirectory: Quickshell.env("HOME"),
                        icon: "",
                        isFile: false,
                        isSetting: true,
                        iconName: "travel_explore"
                    }
                ];
            }
            if (query.startsWith("emoji")) {
                if (query === "emoji")
                    return emojiModel;
                var emojiQuery = query.substring(5).trim();
                return emojiModel.filter(item => Vars.fuzzyMatch(emojiQuery, item.name));
            }
            if (query.startsWith("clipboard")) {
                var clipQuery = query.substring(9).trim();
                var results = [];
                if (clipQuery === "") {
                    results = clipboardModel;
                } else {
                    results = clipboardModel.filter(item => Vars.fuzzyMatch(clipQuery, item.name));
                }

                var finalResults = results.slice();
                finalResults.unshift({
                    name: "Clear Clipboard History",
                    command: ["INTERNAL:CLEAR_CLIPBOARD"],
                    commandStr: JSON.stringify(["INTERNAL:CLEAR_CLIPBOARD"]),
                    workingDirectory: Quickshell.env("HOME"),
                    icon: "",
                    isFile: false,
                    isSetting: false,
                    isMath: false,
                    isClipboard: false,
                    isClearAll: true
                });
                return finalResults;
            }
            if (query.startsWith("tools")) {
                var toolsQuery = query.substring(5).trim();
                if (toolsQuery === "")
                    return settingsOptions;
                return settingsOptions.filter(item => Vars.fuzzyMatch(toolsQuery, item.name));
            }
        }

        // Built once in rebuildBaseApps() and kept up to date via the DesktopEntries connection,
        // instead of being rebuilt (with JSON.stringify per app) on every keystroke.
        var allApps = rootModel.baseApps;

        if (text === "") {
            return allApps;
        }

        var matchedApps = [];
        for (var l = 0; l < allApps.length; l++) {
            var score = Vars.fuzzyMatchScore(text, allApps[l].name);
            if (score > 0) {
                var appWithScore = Object.assign({}, allApps[l]);
                appWithScore.score = score;
                matchedApps.push(appWithScore);
            }
        }

        matchedApps.sort(function (a, b) {
            return b.score - a.score;
        });
        if (text.indexOf("./") !== -1) {
            var fileQuery = text.replace(/\.\//g, "").trim();
            var matchedFiles = fileQuery === "" ? rootModel.fileModel.slice(0, 50) : rootModel.fileModel.filter(file => Vars.fuzzyMatch(fileQuery, file.name));
            return matchedApps.concat(matchedFiles);
        }

        return matchedApps;
    }
}
