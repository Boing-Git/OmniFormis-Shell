.pragma library
var animationDuration = 240;
var translucent = false;

var overviewGridRows = 2;
var overviewGridColumns = 5;
var overviewScale = 1;

var radiusAmount = 0.5
var radiusSmall = 8
var radiusMedium = 18
var radiusLarge = 24
var radiusExtraLarge = 38

var spacingSmall = 8
var spacingMedium = 16
var spacingLarge = 24

var paddingSmall = 8
var paddingMedium = 16
var paddingLarge = 24

var wallpaperMaskEnabled = true;
var wallpaperMaskScale = 1.05;
var wallpaperMaskShape = "Clamshell";
var wallpaperMaskColor = "transparent";
var wallpaperMaskOffsetX = 199;
var wallpaperMaskOffsetY = 55;
var clockShape = "4SidedCookie";

var fontFamily = "Google Sans Flex"
var m3Standard = [0.2, 0.0, 0.0, 1.0];
var m3StandardDecelerate = [0.0, 0.0, 0.0, 1.0];
var m3StandardAccelerate = [0.3, 0.0, 1.0, 1.0];
var m3EmphasizedDecelerate = [0.05, 0.7, 0.1, 1.0];
var m3EmphasizedAccelerate = [0.3, 0.0, 0.8, 0.15];
var m3ExpressiveSpatialFast = [0.42, 1.67, 0.21, 0.9];
var m3ExpressiveSpatialSlow = [0.39, 1.29, 0.35, 0.98];

var customStandard = [0.20, 0.00, 0.00, 1.00];
var customStandardDecelerate = [0.0, 0.0, 0.0, 1.0];
var customStandardAccelerate = [0.3, 0.0, 1.0, 1.0];
var customEmphasizedDecelerate = [0.05, 0.7, 0.1, 1.0];
var customEmphasizedAccelerate = [0.3, 0.0, 0.8, 0.15];
var customExpressiveSpatialFast = [0.42, 1.67, 0.21, 0.9];
var customExpressiveSpatialSlow = [0.39, 1.29, 0.35, 0.98];

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
    console.log("pushNotification called! modelData:", modelData);
    if (!modelData) {
        console.log("ERROR: modelData is null or undefined");
        return;
    }

    // Fallback to id if seqId is undefined
    var uniqueId = modelData.seqId !== undefined ? modelData.seqId : (modelData.id !== undefined ? modelData.id : Math.random());
    console.log("Notification uniqueId:", uniqueId);

    for (var i = 0; i < notificationHistory.length; i++) {
        if (notificationHistory[i].seqId === uniqueId) {
            console.log("Duplicate notification prevented:", uniqueId);
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
        invokeAction: function (id) {
            try { modelData.invokeAction(id); } catch (e) { }
        },
        dismiss: function () {
            try { modelData.dismiss(); } catch (e) { }
            removeNotification(this.seqId);
        }
    };

    notificationHistory.unshift(n);
    historyUpdated++;
    console.log("Notification pushed successfully! History size:", notificationHistory.length);
}

function removeNotification(seqId) {
    var initialLen = notificationHistory.length;
    notificationHistory = notificationHistory.filter(function (n) { return n.seqId !== seqId; });
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
