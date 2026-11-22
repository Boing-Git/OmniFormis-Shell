import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import "primitive"
import "variables.js" as Vars

// Compact "today at a glance" badge that replaces the clock pill's plain date text: a volume
// ring wraps around a centered Wi-Fi icon, open at the bottom, with the day-of-month at its
// left foot, the month number at its right foot, and the day-of-week sitting under the icon
// in the gap.
Item {
    id: root

    implicitWidth: 86

    // Tight to the actual content span (ring top ~1px to badge-row bottom ~42px) instead of
    // leaving extra room — padding here doesn't center the content, it just adds dead space
    // below it, since everything is laid out from the top down.
    implicitHeight: 44

    // ---- Date ----
    property string dayNumber: "1"
    property string monthNumber: "1"
    property string dayAbbrev: ""
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.updateDate()
        Component.onCompleted: root.updateDate()
    }
    function updateDate() {
        var d = new Date();
        var days = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];
        root.dayNumber = String(d.getDate());
        root.monthNumber = String(d.getMonth() + 1);
        root.dayAbbrev = days[d.getDay()];
    }

    // ---- Volume, or battery on a laptop (drives how much of the ring is "filled") ----
    property var audioNode: Pipewire.defaultAudioSink
    PwObjectTracker { objects: [root.audioNode] }
    property real volumeLevel: audioNode && audioNode.audio && !audioNode.audio.muted ? audioNode.audio.volume : 0.0

    // UPower.displayDevice is UPower's own pick of "the one battery that matters" (laptop
    // battery over a mouse/keyboard battery, etc.); isLaptopBattery is what actually tells a
    // laptop apart from a desktop with no battery at all.
    readonly property var batteryDevice: UPower.displayDevice
    readonly property bool hasBattery: batteryDevice && batteryDevice.isPresent && batteryDevice.isLaptopBattery

    // UPowerDevice.percentage is 0-100, unlike Pipewire's 0-1 volume, so it's normalized to
    // match before driving the ring's fill fraction.
    property real ringLevel: hasBattery ? (batteryDevice.percentage / 100) : volumeLevel
    Behavior on ringLevel { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

    // ---- Wi-Fi ----
    property var wifiDevice: Networking.devices.values.find(d => d.type === DeviceType.Wifi)
    property var activeNet: wifiDevice ? wifiDevice.networks.values.find(n => n.connected) : null
    readonly property string wifiIcon: {
        if (!Networking.wifiEnabled) return "";
        if (!root.activeNet) return "";

        // 1, 2 or 3 bars, or the full fan from 70% up (the same as the Wi-Fi tile:
        // controlcenter/WifiControl.qml)
        const pct = (root.activeNet.signalStrength || 0) * 100;
        return pct >= 70 ? "\ue1d8" : pct >= 50 ? "\uebe1" : pct >= 30 ? "\uebd6" : "\uebe4";
    }

    // filled while connected, outlined otherwise (the variable font's FILL axis)
    readonly property bool wifiFilled: !!root.activeNet
    readonly property color wifiIconColor: root.activeNet ? Roles.secondary : Roles.on_surface

    M3Shapes { id: m3 }
    property int badgeSize: 22

    // the date/month badges: shape, fill and text colours
    property string badgeShape: "6SidedCookie"
    readonly property color badgeFillColor: Roles.tertiary_container
    readonly property color badgeTextColor: Roles.on_tertiary_container

    // ================= The ring =================
    QtObject {
        id: ring
        property real cx: 43
        property real cy: 18
        property real r: 17

        // Feet sit at exactly 9 and 3 o'clock (a flat 180deg upper semicircle) instead of
        // dipping down toward 8 and 4 o'clock: the feet land level with the ring's own center
        // instead of below it, which both spreads them to their widest and means nothing needs
        // headroom below the ring anymore, so the whole icon can be shorter.
        property real startAngle: 180
        property real sweepAngle: 180
        property real minVisibleSweep: 10

        function ptX(deg) { return cx + r * Math.cos(deg * Math.PI / 180); }
        function ptY(deg) { return cy + r * Math.sin(deg * Math.PI / 180); }

        // Same technique as the Design language repo's linear wavy-progress indicator
        // (components/WavyProgress/wavePaths.ts createLinearWavePath): anchors sit back on the
        // true line/radius at a fixed wavelength, with a quadratic control point at each
        // midpoint pushed out by the amplitude, alternating direction each half-wave. Adapted
        // here from a straight baseline to a circular one, offsetting radially instead of
        // vertically.
        property real waveAmplitude: 1.8
        property real halfWaveDeg: 20
        function wavyArcPath(startDeg, sweepDeg) {
            if (sweepDeg <= 0) return "";
            function pt(deg, radialOffset) {
                var rr = r + radialOffset;
                var a = deg * Math.PI / 180;
                return (cx + rr * Math.cos(a)) + " " + (cy + rr * Math.sin(a));
            }
            var steps = Math.max(1, Math.round(sweepDeg / halfWaveDeg));
            var stepDeg = sweepDeg / steps;
            var d = "M " + pt(startDeg, 0);
            var dir = 1;
            for (var i = 1; i <= steps; i++) {
                var controlDeg = startDeg + stepDeg * (i - 0.5);
                var anchorDeg = startDeg + stepDeg * i;
                d += " Q " + pt(controlDeg, dir * waveAmplitude) + " " + pt(anchorDeg, 0);
                dir *= -1;
            }
            return d;
        }
    }

    // Equal gap used both above and below the Wi-Fi icon, so "ring to icon" and "icon to day
    // text" read as the same spacing instead of two independently-tuned offsets that happen
    // to look similar.
    property real iconGap: 2
    property real ringPeakY: ring.cy - ring.r
    property real activeSweepAngle: Math.max(ring.minVisibleSweep, ring.sweepAngle * root.ringLevel)
    Behavior on activeSweepAngle { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

    // Badges sit a fixed gap below the ring's feet instead of riding them exactly, so the ring
    // reads as clearly above the date/month row rather than running right into it.
    property real badgeRowCenterY: 31

    Shape {
        id: arcShape
        anchors.fill: parent
        antialiasing: true

        // The analytic curve renderer avoids the jagged/tessellated look the default
        // renderer gives small arcs like this ring.
        preferredRendererType: Shape.CurveRenderer

        // Dim background ring (full sweep)
        ShapePath {
            strokeColor: Roles.surface_variant
            strokeWidth: 3
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            startX: ring.ptX(ring.startAngle)
            startY: ring.ptY(ring.startAngle)
            PathAngleArc {
                centerX: ring.cx
                centerY: ring.cy
                radiusX: ring.r
                radiusY: ring.r
                startAngle: ring.startAngle
                sweepAngle: ring.sweepAngle
            }
        }

        // Bright volume-fill ring (partial sweep): the Design language repo's wavy-progress
        // technique, wrapped around our circular track instead of a straight one.
        ShapePath {
            strokeColor: Roles.secondary
            strokeWidth: 3
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: ring.wavyArcPath(ring.startAngle, root.activeSweepAngle) }
        }
    }

    // ---- Wi-Fi icon: top edge sits `iconGap` below the ring's peak. Given an explicit fixed
    // width and center-aligned instead of relying on the glyph's own (not always centered)
    // advance width, so it sits exactly on ring.cx regardless of the font's own bearing. ----
    SymbolIcon {
        id: wifiText
        x: ring.cx - width / 2
        y: root.ringPeakY + root.iconGap
        text: root.wifiIcon
        filled: root.wifiFilled
        size: 23
        color: root.wifiIconColor
        Behavior on color { ColorAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
    }

    // ---- Day-of-week: below the badge row now that the badges moved down off the ring ----
    SmoothText {
        x: ring.cx - width / 2 
        y: root.badgeRowCenterY - 5 
        text: root.dayAbbrev
        font.weight: 700
        font.pixelSize: 11                 // M3 labelSmall (the smallest M3 size)
        color: Roles.secondary
    }

    // ---- Date: badge centered exactly on the ring's starting foot ----
    Item {
        width: root.badgeSize
        height: root.badgeSize
        x: ring.ptX(ring.startAngle) - width / 2 - 5
        y: root.badgeRowCenterY - height / 2

        Image {
            anchors.fill: parent
            source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='" + m3.getPath(root.badgeShape) + "' fill='" + String(root.badgeFillColor).replace("#", "%23") + "'/></svg>"
            sourceSize: Qt.size(root.badgeSize * 4, root.badgeSize * 4)
            smooth: true
            antialiasing: true
            mipmap: true
        }
        SmoothText {
            anchors.centerIn: parent
            text: root.dayNumber
                font.weight: 800
            font.pixelSize: 11
            color: root.badgeTextColor
        }
    }

    // ---- Month: badge centered exactly on the ring's ending foot ----
    Item {
        width: root.badgeSize
        height: root.badgeSize
        x: ring.ptX(ring.startAngle + ring.sweepAngle) - width / 2 + 5
        y: root.badgeRowCenterY - height / 2

        Image {
            anchors.fill: parent
            source: "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 100'><path d='" + m3.getPath(root.badgeShape) + "' fill='" + String(root.badgeFillColor).replace("#", "%23") + "'/></svg>"
            sourceSize: Qt.size(root.badgeSize * 4, root.badgeSize * 4)
            smooth: true
            antialiasing: true
            mipmap: true
        }
        SmoothText {
            anchors.centerIn: parent
            text: root.monthNumber
                font.weight: 800
            font.pixelSize: 11
            color: root.badgeTextColor
        }
    }
}
