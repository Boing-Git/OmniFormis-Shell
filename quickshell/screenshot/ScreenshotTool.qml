import Quickshell
import QtQuick
import Quickshell.Io
import Quickshell.Wayland
import ".."
import "../primitive"
import "../variables.js" as Vars

// The screenshot tool. It freezes the screen, then puts a rectangle on it (springing out
// of where you dropped the Screenshot pill) with M3 handles to move and resize it, and an
// M3 Expressive floating toolbar beside it: Close, Whole screen, Annotate (Satty), Save,
// and Copy as the toolbar's FAB.
//
// Start it from the control center's Dials control (click Screenshot, or drag the pill
// off the ring and drop it where you want the rectangle), or from a keybind:
//   qs -p <this folder> ipc call screenshot open   (round the mouse; `middle`: the screen's middle)
//
// keys: Enter / Ctrl+C copy · Ctrl+S save · E annotate · F whole screen · arrows move it
// (Shift: 10 px) · Esc closes
//
// ★ settings: screenshot/ScreenshotSettings.qml ★
PanelWindow {
    id: tool
    // the screen the shell lives on (Dials.screen): when the monitor goes away and comes
    // back (a DisplayPort monitor does as it sleeps) the window follows it back
    screen: Dials.screen


    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay

    // its own name, so window rules meant for the dials (e.g. blur) leave it alone
    WlrLayershell.namespace: "dial-screenshot"

    // the keyboard only while the rectangle is up
    WlrLayershell.keyboardFocus: phase === "select" ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    readonly property var cfg: ScreenshotSettings {}

    // the screen's size (the window's own width / height are only its requested size, and
    // its content has no size yet while it's hidden, when the rectangle is laid out)
    readonly property real screenW: screen ? screen.width : contentItem.width
    readonly property real screenH: screen ? screen.height : contentItem.height

    // "idle": nothing on screen;  "freezing": taking the picture of the screen;
    // "select": the rectangle is up;  "done": only the snackbar is left
    property string phase: "idle"
    visible: phase === "select" || phase === "done"

    // the whole screen takes the mouse while selecting; after a shot nothing does (the
    // snackbar is only a message)
    mask: Region {
        width: tool.phase === "select" ? tool.screenW : 0
        height: tool.phase === "select" ? tool.screenH : 0
    }

    Component.onCompleted: Dials.screenshot = tool

    IpcHandler {
        target: "screenshot"

        // the rectangle on the window under the mouse, or round the mouse if there's none
        // (the keybind: you aim with the mouse, then press it)
        function open(): void { cursorPos.running = true }

        // the rectangle in the middle of the screen
        function middle(): void { tool.start(NaN, NaN) }

        // the rectangle round (x, y), in screen px
        function at(x: int, y: int): void { tool.start(x, y) }

        // the rectangle on the focused window (the whole screen if there's none)
        function window(): void {
            const name = tool.screen && tool.screen.name ? tool.screen.name : ""
            Windows.refresh(name, () => tool.start(NaN, NaN, Windows.focusedRect()))
        }
        function close(): void { tool.close() }
    }

    // asks Hyprland where the mouse is (in this screen's px), then starts on the window
    // under it, or round it if there's no window. The middle of the screen if that fails
    // or the mouse is on another screen.
    Process {
        id: cursorPos
        command: ["hyprctl", "cursorpos", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let x = NaN, y = NaN
                try {
                    const p = JSON.parse(text)
                    x = p.x - (tool.screen ? tool.screen.x : 0)
                    y = p.y - (tool.screen ? tool.screen.y : 0)
                    if (x < 0 || y < 0 || x > tool.screenW || y > tool.screenH) x = y = NaN
                } catch (e) {}
                if (isNaN(x)) { tool.start(NaN, NaN); return }
                const name = tool.screen && tool.screen.name ? tool.screen.name : ""
                Windows.refresh(name, () => tool.start(x, y, Windows.rectAt(x, y)))
            }
        }
        onExited: code => { if (code !== 0) tool.start(NaN, NaN) }
    }

    // ── files ──
    readonly property string frozenPath: cfg.tempDir + "/frozen.png"
    readonly property string copyPath: cfg.tempDir + "/shot.png"
    function savePath() {
        return cfg.saveDir + "/" + cfg.namePrefix + Qt.formatDateTime(new Date(), cfg.dateFormat) + ".png"
    }

    // the frozen picture's pixels per screen px (1, or e.g. 1.5 on a scaled monitor)
    readonly property real pixelRatio: frozen.implicitWidth > 0 && screenW > 0 ? frozen.implicitWidth / screenW : 1

    // ── starting ──
    // where the rectangle grows out of (this window's px; NaN: the middle of the screen)
    property real fromX: NaN
    property real fromY: NaN

    // the rectangle to start with instead (e.g. the window the Screenshot pill was dropped
    // on); empty: the usual size round (fromX, fromY)
    property rect fromRect: Qt.rect(0, 0, 0, 0)

    function start(x, y, r) {
        if (phase === "freezing" || phase === "select") return
        endTimer.stop()
        snackTimer.stop()
        fromX = x
        fromY = y
        fromRect = r && r.width > 0 && r.height > 0 ? r : Qt.rect(0, 0, 0, 0)
        phase = "freezing"

        // give whatever started it (the control center, the dragged icon) a moment to
        // leave the screen, so it isn't in the picture
        freezeTimer.restart()
    }

    Timer {
        id: freezeTimer
        interval: tool.cfg.freezeDelay
        onTriggered: {
            const name = tool.screen && tool.screen.name ? tool.screen.name : ""
            freezer.exec(["sh", "-c", 'mkdir -p "$1" && shift && exec grim "$@"', "sh", tool.cfg.tempDir]
                .concat(name !== "" ? ["-o", name] : [])
                .concat([tool.frozenPath]))
        }
    }

    // grim takes the frozen picture (without the cursor)
    Process {
        id: freezer
        onExited: code => {
            if (code !== 0) { tool.fail(); return }

            // a new name each time, so the picture is never an old cached one
            frozen.source = ""
            frozen.source = "file://" + tool.frozenPath + "?" + Date.now()
        }
    }

    // the picture is ready: show it under the rectangle
    function enter() {
        const w = Math.min(cfg.startWidth, screenW), h = Math.min(cfg.startHeight, screenH)
        const cx = isNaN(fromX) ? screenW / 2 : fromX
        const cy = isNaN(fromY) ? screenH / 2 : fromY
        const x = Math.max(0, Math.min(screenW - w, cx - w / 2))
        const y = Math.max(0, Math.min(screenH - h, cy - h / 2))

        // a window's rect, cut to the screen
        const f = fromRect
        const l = Math.max(0, f.x), t = Math.max(0, f.y)
        const r = Math.min(screenW, f.x + f.width), b = Math.min(screenH, f.y + f.height)
        const onWindow = f.width > 0 && r > l && b > t
        beforeWhole = Qt.rect(0, 0, 0, 0)
        phase = "select"
        shown = 1
        box.growFrom(cx, cy, onWindow ? Qt.rect(l, t, r - l, b - t) : Qt.rect(x, y, w, h))
        keys.forceActiveFocus()
    }

    // ── leaving ──
    // 1 while the rectangle, the darkening and the toolbar are up; faded to 0 on the way out
    property real shown: 0
    Behavior on shown { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

    // closes without a shot
    function close() {
        if (phase !== "select") return
        shown = 0
        snackText = ""
        phase = "done"
        endTimer.interval = Vars.expressiveFastEffects.duration + 20
        endTimer.restart()
    }

    // something went wrong (no picture, or the shot couldn't be made)
    function fail() {
        shown = 0
        snackText = "Couldn't take the screenshot"
        phase = "done"
        snackTimer.restart()
    }

    // after a shot, or a close: the window goes away
    Timer {
        id: endTimer
        onTriggered: {
            tool.phase = "idle"
            frozen.source = ""
        }
    }

    // ── taking the shot ── "copy": to the clipboard;  "save": to saveDir, and copied;
    // "edit": opened in Satty (it saves to saveDir and copies when you're done)
    function shoot(action) {
        if (phase !== "select" || box.sel.width < 1 || box.sel.height < 1) return
        const r = box.sel, f = pixelRatio
        const crop = Math.max(1, Math.round(r.width * f)) + "x" + Math.max(1, Math.round(r.height * f))
            + "+" + Math.round(r.x * f) + "+" + Math.round(r.y * f)
        const out = savePath()
        if (action === "edit") {
            Quickshell.execDetached(["sh", "-c",
                'mkdir -p "$(dirname "$4")" && magick "$1" -crop "$2" +repage "$3" && exec satty --filename "$3" --output-filename "$4" --copy-command wl-copy --early-exit',
                "sh", frozenPath, crop, copyPath, out])
            snackText = "Opening in Satty"
        } else if (action === "save") {
            worker.exec(["sh", "-c",
                'mkdir -p "$(dirname "$3")" && magick "$1" -crop "$2" +repage "$3" && wl-copy --type image/png < "$3" >/dev/null 2>&1',
                "sh", frozenPath, crop, out])
            snackText = "Saved to " + cfg.saveDir.replace(/^.*\//, "") + " and copied"
        } else {
            worker.exec(["sh", "-c",
                'magick "$1" -crop "$2" +repage "$3" && wl-copy --type image/png < "$3" >/dev/null 2>&1',
                "sh", frozenPath, crop, copyPath])
            snackText = "Copied to clipboard"
        }

        // the camera flash over the shot, then everything fades away but the snackbar
        flash.restart()
        shown = 0
        phase = "done"
        snackTimer.restart()
    }

    // crops the frozen picture (and copies / saves it); a failure changes the snackbar
    Process {
        id: worker
        onExited: code => { if (code !== 0) tool.snackText = "Couldn't save the screenshot" }
    }

    // ── whole screen ── and back to the rectangle you had
    property rect beforeWhole: Qt.rect(0, 0, 0, 0)
    readonly property bool whole: box.sel.x <= 0 && box.sel.y <= 0 && box.sel.width >= screenW && box.sel.height >= screenH
    function toggleWhole() {
        if (whole) {
            if (beforeWhole.width > 0) box.sel = beforeWhole
        } else {
            beforeWhole = box.sel
            box.sel = Qt.rect(0, 0, screenW, screenH)
        }
    }

    // ── the frozen screen ──
    Image {
        id: frozen
        anchors.fill: parent
        cache: false
        asynchronous: false
        smooth: true
        fillMode: Image.Stretch
        onStatusChanged: {
            if (tool.phase !== "freezing") return
            if (status === Image.Ready) tool.enter()
            else if (status === Image.Error) tool.fail()
        }

        // stays while the flash plays, then fades into the live screen under it
        opacity: tool.phase === "select" || flash.running ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
    }

    // ── keys ──
    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: e => {
            if (tool.phase !== "select") return
            const ctrl = e.modifiers & Qt.ControlModifier
            const step = e.modifiers & Qt.ShiftModifier ? 10 : 1
            const r = box.sel
            const nudge = (dx, dy) => {
                box.sel = Qt.rect(Math.max(0, Math.min(tool.screenW - r.width, r.x + dx)),
                                  Math.max(0, Math.min(tool.screenH - r.height, r.y + dy)), r.width, r.height)
            }
            switch (e.key) {
            case Qt.Key_Escape: tool.close(); break
            case Qt.Key_Return: case Qt.Key_Enter: tool.shoot("copy"); break
            case Qt.Key_C: if (ctrl) tool.shoot("copy"); else return; break
            case Qt.Key_S: if (ctrl) tool.shoot("save"); else return; break
            case Qt.Key_E: tool.shoot("edit"); break
            case Qt.Key_F: tool.toggleWhole(); break
            case Qt.Key_Left: nudge(-step, 0); break
            case Qt.Key_Right: nudge(step, 0); break
            case Qt.Key_Up: nudge(0, -step); break
            case Qt.Key_Down: nudge(0, step); break
            default: return
            }
            e.accepted = true
        }
    }

    // ── the rectangle, its handles and the darkening round it ──
    SelectionBox {
        id: box
        anchors.fill: parent
        cfg: tool.cfg
        shown: tool.shown
        enabled: tool.phase === "select"
        onAccepted: tool.shoot("copy")
    }

    // ── the camera flash ── over the shot, right after it's taken
    Rectangle {
        id: flashRect
        x: box.dx
        y: box.dy
        width: box.dw
        height: box.dh
        color: "white"
        opacity: 0
        NumberAnimation on opacity {
            id: flash
            running: false
            from: tool.cfg.flashOpacity
            to: 0
            duration: tool.cfg.flashDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Vars.expressiveFastEffects.bezier
        }
    }

    // ── the size chip: "1280 × 720" (the shot's real pixels) on the rectangle's top edge,
    // inside it when there's no room above (M3 plain tooltip colours) ──
    Rectangle {
        id: chip
        readonly property bool above: box.dy >= tool.cfg.chipHeight + tool.cfg.chipGap
        x: Math.max(0, Math.min(tool.screenW - width, box.dx))
        y: above ? box.dy - tool.cfg.chipGap - height : box.dy + tool.cfg.chipGap
        height: tool.cfg.chipHeight
        width: chipText.implicitWidth + tool.cfg.chipPadding * 2
        radius: height / 2
        color: Roles.inverse_surface
        opacity: tool.shown
        visible: box.dw > 0 && box.dh > 0

        SmoothText {
            id: chipText
            anchors.centerIn: parent
            text: Math.round(box.sel.width * tool.pixelRatio) + " × " + Math.round(box.sel.height * tool.pixelRatio)
            font.pixelSize: tool.cfg.chipFontSize
            font.weight: 600
            color: Roles.inverse_on_surface
        }
    }

    // ── the floating toolbar and its FAB ── under the rectangle, over it when there's no
    // room below, or inside its bottom edge when it fills the screen. It glides after the
    // rectangle on an M3E spring, and steps back while you drag
    Item {
        id: bar
        width: toolbar.width + tool.cfg.toolbarOffset / 2 + fab.width
        height: tool.cfg.toolbarHeight

        readonly property real off: tool.cfg.toolbarOffset
        readonly property rect r: box.sel
        readonly property real belowY: r.y + r.height + off
        readonly property real aboveY: r.y - off - height
        readonly property real wantY: belowY + height <= tool.screenH - off ? belowY
            : aboveY >= off ? aboveY
            : r.y + r.height - off - height
        readonly property real wantX: Math.max(off, Math.min(tool.screenW - off - width, r.x + r.width / 2 - width / 2))

        SpringValue {
            id: barX
            to: bar.wantX
            stiffness: Vars.springs.expressive.fast.spatial.stiffness
            dampingRatio: Vars.springs.expressive.default.spatial.dampingRatio
            epsilon: 0.1
        }
        SpringValue {
            id: barY
            to: bar.wantY
            stiffness: Vars.springs.expressive.fast.spatial.stiffness
            dampingRatio: Vars.springs.expressive.default.spatial.dampingRatio
            epsilon: 0.1
        }
        x: barX.value
        y: barY.value

        // pops up from a little smaller as the rectangle opens
        scale: tool.phase === "select" ? 1 : 0.85
        Behavior on scale { NumberAnimation { duration: Prefs.fastSpatial.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.fastSpatial.bezier } }
        opacity: tool.shown * (box.busy ? 0.4 : 1)
        Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }
        visible: opacity > 0.01

        // the toolbar starts where the rectangle is, so its first glide is short
        Connections {
            target: tool
            function onPhaseChanged() { if (tool.phase === "select") { barX.snap(bar.wantX); barY.snap(bar.wantY) } }
        }

        // M3E floating toolbar, standard colours: surface-container, on-surface
        Rectangle {
            id: toolbar
            height: tool.cfg.toolbarHeight
            width: buttons.width + tool.cfg.toolbarPadding * 2
            radius: height / 2
            color: Roles.surface_container
            antialiasing: true

            Row {
                id: buttons
                anchors.centerIn: parent
                spacing: tool.cfg.toolbarGap

                IconButton {
                    icon: "close"
                    label: "Close  ·  Esc"
                    size: tool.cfg.buttonSize
                    iconSize: tool.cfg.buttonIconSize
                    pressedRadius: tool.cfg.buttonPressedRadius
                    containerColor: "transparent"
                    contentColor: Roles.on_surface
                    onClicked: tool.close()
                }
                IconButton {
                    icon: tool.whole ? "fullscreen_exit" : "fullscreen"
                    label: (tool.whole ? "Back to the selection" : "Whole screen") + "  ·  F"

                    // M3E toggle: tonal while it's on
                    size: tool.cfg.buttonSize
                    iconSize: tool.cfg.buttonIconSize
                    pressedRadius: tool.cfg.buttonPressedRadius
                    radius: tool.whole ? tool.cfg.buttonPressedRadius : size / 2
                    containerColor: tool.whole ? Roles.secondary_container : "transparent"
                    contentColor: tool.whole ? Roles.on_secondary_container : Roles.on_surface
                    onClicked: tool.toggleWhole()
                }
                IconButton {
                    icon: "draw"
                    label: "Annotate  ·  E"
                    size: tool.cfg.buttonSize
                    iconSize: tool.cfg.buttonIconSize
                    pressedRadius: tool.cfg.buttonPressedRadius
                    containerColor: "transparent"
                    contentColor: Roles.on_surface
                    onClicked: tool.shoot("edit")
                }
                IconButton {
                    icon: "download"
                    label: "Save  ·  Ctrl+S"
                    size: tool.cfg.buttonSize
                    iconSize: tool.cfg.buttonIconSize
                    pressedRadius: tool.cfg.buttonPressedRadius
                    containerColor: "transparent"
                    contentColor: Roles.on_surface
                    onClicked: tool.shoot("save")
                }
            }
        }

        // the main action, M3E FAB beside the toolbar: primary-container, large corner
        IconButton {
            id: fab
            x: toolbar.width + tool.cfg.toolbarOffset / 2
            anchors.verticalCenter: toolbar.verticalCenter
            icon: "content_copy"
            filled: true
            label: "Copy  ·  Enter"
            size: tool.cfg.fabSize
            iconSize: tool.cfg.fabIconSize
            radius: tool.cfg.fabRadius
            pressedRadius: tool.cfg.fabPressedRadius
            containerColor: Roles.primary_container
            contentColor: Roles.on_primary_container
            onClicked: tool.shoot("copy")
        }
    }

    // ── the tooltip over the toolbar button under the mouse (M3 plain tooltip) ──
    // the button under the mouse, found from the toolbar's children
    readonly property var hoveredButton: {
        for (let i = 0; i < buttons.children.length; i++)
            if (buttons.children[i].hovered) return buttons.children[i]
        return fab.hovered ? fab : null
    }
    onHoveredButtonChanged: {
        tipShown = false
        if (hoveredButton) tipTimer.restart()
    }
    property bool tipShown: false
    Timer {
        id: tipTimer
        interval: tool.cfg.tooltipDelay
        onTriggered: tool.tipShown = !!tool.hoveredButton
    }

    Rectangle {
        id: tip
        readonly property var b: tool.hoveredButton

        // (reads the toolbar's position, so it moves along when the toolbar glides)
        readonly property point at: {
            bar.x; bar.y
            return b ? b.mapToItem(tool.contentItem, b.width / 2, 0) : Qt.point(0, 0)
        }
        x: Math.max(4, Math.min(tool.screenW - width - 4, at.x - width / 2))
        y: at.y - height - 8
        height: tool.cfg.tooltipHeight
        width: tipText.implicitWidth + 16
        radius: 4
        color: Roles.inverse_surface
        opacity: tool.tipShown && !!b && tool.phase === "select" ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

        SmoothText {
            id: tipText
            anchors.centerIn: parent
            text: tip.b ? tip.b.label : ""
            font.pixelSize: tool.cfg.tooltipFontSize
            color: Roles.inverse_on_surface
        }
    }

    // ── the snackbar ── says what happened, then the window goes away (M3: inverse
    // surface, extra-small corners)
    property string snackText: ""
    Timer {
        id: snackTimer
        interval: tool.cfg.snackbarTime
        onTriggered: {
            endTimer.interval = Prefs.defaultSpatial.duration
            endTimer.restart()
        }
    }
    Rectangle {
        id: snackbar
        readonly property bool up: tool.phase === "done" && tool.snackText !== "" && snackTimer.running
        height: tool.cfg.snackbarHeight
        width: Math.min(tool.screenW - 32, snackRow.implicitWidth + 32)
        x: (tool.screenW - width) / 2
        y: up ? tool.screenH - tool.cfg.snackbarOffset - height : tool.screenH + 8
        Behavior on y { NumberAnimation { duration: Prefs.defaultSpatial.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Prefs.defaultSpatial.bezier } }
        radius: 4
        color: Roles.inverse_surface
        opacity: up ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Vars.expressiveFastEffects.duration; easing.type: Easing.BezierSpline; easing.bezierCurve: Vars.expressiveFastEffects.bezier } }

        Row {
            id: snackRow
            anchors.centerIn: parent
            spacing: 10

            SymbolIcon {
                anchors.verticalCenter: parent.verticalCenter
                text: tool.snackText.startsWith("Couldn't") ? "error" : "check_circle"
                size: 20
                filled: true
                color: Roles.inverse_primary
            }
            SmoothText {
                id: snackLabel
                anchors.verticalCenter: parent.verticalCenter
                text: tool.snackText
                font.pixelSize: tool.cfg.snackbarFontSize
                color: Roles.inverse_on_surface
            }
        }
    }
}
