.pragma library

// Turns Qt key events into the names Hyprland expects, and back into combinations that use the
// modifier variables ($MM, $SM, ...). Kept free of any UI so it can be reasoned about on its own.

var CANONICAL_MODIFIERS = {
    SUPER: "SUPER", WIN: "SUPER", LOGO: "SUPER", META: "SUPER", MOD4: "SUPER",
    CTRL: "CTRL", CONTROL: "CTRL",
    ALT: "ALT", MOD1: "ALT",
    SHIFT: "SHIFT", CAPS: "CAPS", MOD2: "MOD2", MOD3: "MOD3", MOD5: "MOD5"
};

// Display order of modifiers in a recorded combination
var MODIFIER_ORDER = ["SUPER", "CTRL", "ALT", "SHIFT"];

// What the modifier keys themselves are called, so a single modifier can be recorded
var MODIFIER_KEYS = {};
MODIFIER_KEYS[Qt.Key_Meta] = "SUPER";
MODIFIER_KEYS[Qt.Key_Super_L] = "SUPER";
MODIFIER_KEYS[Qt.Key_Super_R] = "SUPER";
MODIFIER_KEYS[Qt.Key_Control] = "CTRL";
MODIFIER_KEYS[Qt.Key_Alt] = "ALT";
MODIFIER_KEYS[Qt.Key_AltGr] = "ALT";
MODIFIER_KEYS[Qt.Key_Shift] = "SHIFT";

var NAMED_KEYS = {};
NAMED_KEYS[Qt.Key_Space] = "Space";
NAMED_KEYS[Qt.Key_Return] = "Return";
NAMED_KEYS[Qt.Key_Enter] = "Return";
NAMED_KEYS[Qt.Key_Escape] = "Escape";
NAMED_KEYS[Qt.Key_Tab] = "Tab";
NAMED_KEYS[Qt.Key_Backtab] = "Tab";
NAMED_KEYS[Qt.Key_Backspace] = "BackSpace";
NAMED_KEYS[Qt.Key_Delete] = "Delete";
NAMED_KEYS[Qt.Key_Insert] = "Insert";
NAMED_KEYS[Qt.Key_Home] = "Home";
NAMED_KEYS[Qt.Key_End] = "End";
NAMED_KEYS[Qt.Key_PageUp] = "Page_Up";
NAMED_KEYS[Qt.Key_PageDown] = "Page_Down";
NAMED_KEYS[Qt.Key_Left] = "Left";
NAMED_KEYS[Qt.Key_Right] = "Right";
NAMED_KEYS[Qt.Key_Up] = "Up";
NAMED_KEYS[Qt.Key_Down] = "Down";
NAMED_KEYS[Qt.Key_Print] = "Print";
NAMED_KEYS[Qt.Key_Pause] = "Pause";
NAMED_KEYS[Qt.Key_Menu] = "Menu";
NAMED_KEYS[Qt.Key_ScrollLock] = "Scroll_Lock";
NAMED_KEYS[Qt.Key_Comma] = "comma";
NAMED_KEYS[Qt.Key_Period] = "period";
NAMED_KEYS[Qt.Key_Slash] = "slash";
NAMED_KEYS[Qt.Key_Backslash] = "Backslash";
NAMED_KEYS[Qt.Key_Semicolon] = "semicolon";
NAMED_KEYS[Qt.Key_Apostrophe] = "apostrophe";
NAMED_KEYS[Qt.Key_BracketLeft] = "BracketLeft";
NAMED_KEYS[Qt.Key_BracketRight] = "BracketRight";
NAMED_KEYS[Qt.Key_Minus] = "Minus";
NAMED_KEYS[Qt.Key_Equal] = "Equal";
NAMED_KEYS[Qt.Key_QuoteLeft] = "grave";
// Media and hardware keys
NAMED_KEYS[Qt.Key_VolumeUp] = "XF86AudioRaiseVolume";
NAMED_KEYS[Qt.Key_VolumeDown] = "XF86AudioLowerVolume";
NAMED_KEYS[Qt.Key_VolumeMute] = "XF86AudioMute";
NAMED_KEYS[Qt.Key_MicMute] = "XF86AudioMicMute";
NAMED_KEYS[Qt.Key_MediaPlay] = "XF86AudioPlay";
NAMED_KEYS[Qt.Key_MediaTogglePlayPause] = "XF86AudioPlay";
NAMED_KEYS[Qt.Key_MediaPause] = "XF86AudioPause";
NAMED_KEYS[Qt.Key_MediaStop] = "XF86AudioStop";
NAMED_KEYS[Qt.Key_MediaNext] = "XF86AudioNext";
NAMED_KEYS[Qt.Key_MediaPrevious] = "XF86AudioPrev";
NAMED_KEYS[Qt.Key_MonBrightnessUp] = "XF86MonBrightnessUp";
NAMED_KEYS[Qt.Key_MonBrightnessDown] = "XF86MonBrightnessDown";
NAMED_KEYS[Qt.Key_Calculator] = "XF86Calculator";

// A shifted symbol reports as the symbol, but Hyprland binds the key underneath it (US layout)
var UNSHIFTED = {
    "!": "1", "@": "2", "#": "3", "$": "4", "%": "5", "^": "6", "&": "7", "*": "8", "(": "9", ")": "0",
    "_": "Minus", "+": "Equal", "{": "BracketLeft", "}": "BracketRight", "|": "Backslash",
    ":": "semicolon", "\"": "apostrophe", "<": "comma", ">": "period", "?": "slash", "~": "grave"
};

function canonicalModifier(word) {
    return CANONICAL_MODIFIERS[String(word).toUpperCase()] || "";
}

// The modifier a pressed key stands for, or "" when it is not a modifier key
function modifierOfKey(key) {
    return MODIFIER_KEYS[key] || "";
}

// Modifiers held in a Qt modifier mask, in display order
function modifiersFrom(mask) {
    var held = [];
    if (mask & Qt.MetaModifier) held.push("SUPER");
    if (mask & Qt.ControlModifier) held.push("CTRL");
    if (mask & Qt.AltModifier) held.push("ALT");
    if (mask & Qt.ShiftModifier) held.push("SHIFT");
    return held;
}

// The Hyprland name for the key in a key event. Unknown keys fall back to their hardware code,
// which Hyprland also accepts, so any key can be recorded. Returns "" for modifier-only presses.
function keyName(event) {
    var key = event.key;
    if (MODIFIER_KEYS[key] !== undefined || key === Qt.Key_CapsLock || key === Qt.Key_NumLock || key === Qt.Key_Hyper_L || key === Qt.Key_Hyper_R)
        return "";
    if (key >= Qt.Key_A && key <= Qt.Key_Z)
        return String.fromCharCode(key);
    if (key >= Qt.Key_0 && key <= Qt.Key_9)
        return String.fromCharCode(key);
    if (key >= Qt.Key_F1 && key <= Qt.Key_F35)
        return "F" + (key - Qt.Key_F1 + 1);
    if (NAMED_KEYS[key] !== undefined)
        return NAMED_KEYS[key];
    if (event.text && UNSHIFTED[event.text] !== undefined)
        return UNSHIFTED[event.text];
    return event.nativeScanCode > 0 ? "code:" + event.nativeScanCode : "";
}

// The combination as it is stored. With useVariables on, a modifier that one of the modifier
// variables holds is written as that variable, so "SUPER + T" becomes "$MM + T".
// `variables` is the name -> value map of the config.
function buildCombo(modifiers, key, useVariables, variables) {
    var byValue = {};
    if (useVariables && variables) {
        // The first variable holding a modifier wins, so the four main ones are preferred in order
        var names = ["MM", "SM", "TM", "QM"];
        var others = Object.keys(variables).filter(function (n) { return names.indexOf(n) === -1; });
        names.concat(others).forEach(function (name) {
            var canonical = canonicalModifier(variables[name] || "");
            if (canonical && byValue[canonical] === undefined)
                byValue[canonical] = name;
        });
    }
    var parts = [];
    modifiers.forEach(function (m) {
        parts.push(byValue[m] !== undefined ? "$" + byValue[m] : m);
    });
    parts.push(key);
    return parts.join(" + ");
}

// The pieces of a stored combination, for drawing one chip per key
function tokens(combo) {
    if (!combo)
        return [];
    return String(combo).split("+").map(function (t) { return t.trim(); }).filter(function (t) { return t !== ""; });
}

function isVariable(token) {
    return token.charAt(0) === "$";
}

function isPlaceholder(token) {
    return /\{[A-Za-z0-9]+\}/.test(token);
}

// A short label for a key chip
function label(token) {
    if (isVariable(token))
        return token;
    var pretty = { Page_Up: "PgUp", Page_Down: "PgDn", BackSpace: "Backspace", Return: "Enter", comma: ",", period: ".",
        slash: "/", Backslash: "\\", semicolon: ";", apostrophe: "'", grave: "`", Minus: "-", Equal: "=",
        BracketLeft: "[", BracketRight: "]", mouse_up: "Scroll up", mouse_down: "Scroll down" };
    if (pretty[token] !== undefined)
        return pretty[token];
    if (token.indexOf("mouse:") === 0) {
        var buttons = { "272": "Left click", "273": "Right click", "274": "Middle click", "275": "Back click", "276": "Forward click" };
        return buttons[token.substring(6)] || token;
    }
    if (token.indexOf("XF86Audio") === 0)
        return token.substring(9);
    return token.length === 1 ? token.toUpperCase() : token;
}

// Checks a typed combination the same way the engine resolves it. Returns "" when it is fine,
// otherwise a short reason. An empty combination is valid: it disables the shortcut.
function validate(combo, variables) {
    var text = String(combo).trim();
    if (text === "")
        return "";
    var vars = variables || {};
    var keys = 0;

    function walk(spec, depth) {
        if (depth > 8)
            return "Variables nest too deeply";
        var parts = spec.split("+");
        for (var i = 0; i < parts.length; i++) {
            var token = parts[i].trim();
            if (token === "")
                continue;
            var m = token.match(/^\$\{?([A-Za-z0-9_]+)\}?$/);
            var name = m ? m[1] : null;
            // A bare word is only a variable when it holds a modifier (MM -> SUPER)
            if (!name && vars[token] !== undefined && canonicalModifier(vars[token]))
                name = token;
            if (name) {
                if (vars[name] === undefined)
                    return "Unknown variable $" + name;
                var inner = walk(String(vars[name]), depth + 1);
                if (inner)
                    return inner;
            } else if (!canonicalModifier(token)) {
                keys++;
            }
        }
        return "";
    }

    var err = walk(text, 0);
    if (err)
        return err;
    if (keys === 0)
        return "Add a key";
    if (keys > 1)
        return "Only one key is allowed";
    return "";
}
