.pragma library

var radiusAmount = 0.5;
var radiusSmall = 8;
var radiusMedium = 16;
var radiusLarge = 24;
var radiusExtraLarge = 38;
var cornerPower = 2.0;

var spacingSmall = 11;
var spacingMedium = 16;
var spacingLarge = 24;

var paddingSmall = 8;
var paddingMedium = 16;
var paddingLarge = 24;

var fontFamily = "Rubik";
var animationDuration = 240;
var flickDeceleration = 1500;
var maximumFlickVelocity = 3000;
var translucent = true;
var blurAmount = 30;
var panelOpacity = 0.85;
var componentOpacity = 0.5;

var overviewGridRows = 2;
var overviewGridColumns = 5;
var overviewScale = 0.15;

var wallpaperMaskEnabled = true;
var wallpaperMaskScale = 0.7;
var wallpaperMaskShape = "6SidedCookie";
var wallpaperMaskColor = "transparent";
var wallpaperMaskOffsetX = 0;
var wallpaperMaskOffsetY = 0;

var clockShape = "Sunny";
var clockShowTicks = true;
var clockShowCenterDot = true;

var mediaPlayerShape = "12SidedCookie";
var mediaPlayerArtScale = 1.0;
var mediaPlayerArtOffsetX = 0;
var mediaPlayerArtOffsetY = 0;

var panelStyle = "Floating";
var pillPosition = "Top";
var gameMode = false;

var desktopClockEnabled = true;
var desktopCalenderEnabled = true;
var desktopMediaPlayerEnabled = true;

var m3Standard = [0.2, 0.0, 0.0, 1.0];
var m3StandardDecelerate = [0.0, 0.0, 0.0, 1.0];
var m3StandardAccelerate = [0.3, 0.0, 1.0, 1.0];
var m3EmphasizedDecelerate = [0.05, 0.7, 0.1, 1.0];
var m3EmphasizedAccelerate = [0.3, 0.0, 0.8, 0.15];
var m3ExpressiveSpatialFast = [0.42, 1.67, 0.21, 0.9];
var m3ExpressiveSpatialSlow = [0.39, 1.29, 0.35, 0.98];

var customStandard = [0.2, 0.0, 0.0, 1.0];
var customStandardDecelerate = [0.0, 0.0, 0.0, 1.0];
var customStandardAccelerate = [0.3, 0.0, 1.0, 1.0];
var customEmphasizedDecelerate = [0.05, 0.7, 0.1, 1.0];
var customEmphasizedAccelerate = [0.3, 0.0, 0.8, 0.15];
var customExpressiveSpatialFast = [0.42, 1.67, 0.21, 0.9];
var customExpressiveSpatialSlow = [0.39, 1.29, 0.35, 0.98];

function getTopLeftRadius(style, pos, isGame, defRad) {
    var rad = (defRad !== undefined && defRad !== null) ? defRad : 24;
    if (isGame || !style || !pos) return rad;
    if (style === "Attached" && (pos === "Top" || pos === "Left")) return 0;
    return rad;
}

function getTopRightRadius(style, pos, isGame, defRad) {
    var rad = (defRad !== undefined && defRad !== null) ? defRad : 24;
    if (isGame || !style || !pos) return rad;
    if (style === "Attached" && (pos === "Top" || pos === "Right")) return 0;
    return rad;
}

function getBottomLeftRadius(style, pos, isGame, defRad) {
    var rad = (defRad !== undefined && defRad !== null) ? defRad : 24;
    if (isGame || !style || !pos) return rad;
    if (style === "Attached" && (pos === "Bottom" || pos === "Left")) return 0;
    return rad;
}

function getBottomRightRadius(style, pos, isGame, defRad) {
    var rad = (defRad !== undefined && defRad !== null) ? defRad : 24;
    if (isGame || !style || !pos) return rad;
    if (style === "Attached" && (pos === "Bottom" || pos === "Right")) return 0;
    return rad;
}

function fuzzyMatch(pattern, str) {
    if (!pattern) return true;
    if (!str) return false;
    pattern = pattern.toLowerCase();
    str = str.toLowerCase();
    
    var patternIdx = 0;
    for (var i = 0; i < str.length; i++) {
        if (str[i] === pattern[patternIdx]) {
            patternIdx++;
            if (patternIdx === pattern.length) return true;
        }
    }
    return false;
}

var notificationHistory = [];
var historyUpdated = 0;

function pushNotification(modelData) {
    if (!modelData) return;
    
    var uniqueId = modelData.seqId !== undefined ? modelData.seqId : (modelData.id !== undefined ? modelData.id : Math.random());

    for (var i = 0; i < notificationHistory.length; i++) {
        if (notificationHistory[i].seqId === uniqueId) {
            return;
        }
    }
    
    var actionsArray = [];
    if (modelData.actions) {
        for (var j = 0; j < modelData.actions.length; j++) {
            actionsArray.push({
                identifier: modelData.actions[j].identifier,
                text: modelData.actions[j].text
            });
        }
    }
    
    var n = {
        seqId: uniqueId,
        appName: modelData.appName,
        appIcon: modelData.appIcon,
        summary: modelData.summary,
        body: modelData.body,
        image: modelData.image,
        urgency: modelData.urgency,
        actions: actionsArray,
        expireTimeout: modelData.expireTimeout,
        defaultTimeout: modelData.defaultTimeout,
        invokeAction: function(id) {
            try { modelData.invokeAction(id); } catch(e) {}
        },
        dismiss: function() {
            try { modelData.dismiss(); } catch(e) {}
            removeNotification(this.seqId);
        }
    };
    
    notificationHistory.unshift(n);
    historyUpdated++;
}

function removeNotification(seqId) {
    var initialLen = notificationHistory.length;
    notificationHistory = notificationHistory.filter(function(n) { return n.seqId !== seqId; });
    if (notificationHistory.length !== initialLen) {
        historyUpdated++;
    }
}

function clearNotifications() {
    for (var i = 0; i < notificationHistory.length; i++) {
        var n = notificationHistory[i];
        if (n && typeof n.dismiss === 'function' && !n.closed) {
            n.dismiss();
        }
    }
    notificationHistory = [];
    historyUpdated++;
}