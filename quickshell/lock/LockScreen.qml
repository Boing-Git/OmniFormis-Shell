import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import ".."
import "../primitive"
import "../variables.js" as Vars

// The lock screen: locks the session, checks the password with PAM, and holds what every
// screen draws (LockSurface.qml, one per screen). Sizes and timings: LockSettings.qml.
//
//   Dials.lock.lock(size)       the power dial's Lock: the sheet grows on from the dial's size
//   qs ipc call lock lock       Super + L, hypridle (lock_cmd), anything else
//
// There is no unlock call: only the password unlocks. The locked state survives a shell
// reload (PersistentProperties) and a crash (Vars.lockStatePath: the next shell to start in
// the same Hyprland session locks again at once, and Hyprland's
// misc:allow_session_lock_restore lets it take the lock over).
Scope {
    id: root

    readonly property LockSettings cfg: LockSettings {}

    // ── the state every screen draws ──
    // true while the session is locked (kept through a reload)
    readonly property bool locked: keep.locked

    // the spot the sheet grows out of and goes back into: the power dial's (the lock lives
    // in the power dial; Super + L opens it from there too)
    readonly property string origin: keep.origin

    // "in": the sheet grows over the screen; "covered": locked and waiting for the
    // password; "out": the password was right, the sheet goes back into its spot; "": unlocked
    property string phase: ""
    readonly property bool covered: phase === "covered"

    // the sheet's growth, 0 (only its spot) .. 1 (the whole screen). `handover`: the px it
    // starts from (the power dial's size, so it carries on from the dial instead of
    // growing out of nothing); 0 once it covers the screen
    readonly property real cover: coverSpring.value
    property real handover: 0
    function sheetRadius(full) { return handover + (full - handover) * cover }

    // the ring is out round the clock (a key or a move wakes it; it folds away again after
    // cfg.restAfter with nothing typed)
    property bool awake: false

    // what has been typed (never stored anywhere), and how many beads that is
    property string password: ""
    readonly property int count: Array.from(password).length

    // how many bead slots the ring keeps: the most beads since it was last cleared, so a
    // deleted bead can play its way out
    property int peak: 0

    // the count just before the ring was cleared: beads leave newest first from there
    property int clearedFrom: 0

    // PAM is checking the password
    property bool checking: false

    // a wrong password: the ring rattles, the beads and the mark turn to the error colour
    property bool wrong: false

    // the password was right: the lock opens (the mark's lock opens, then the sheet goes)
    property bool unlocking: false

    // Caps Lock seems on (worked out from the letters typed: an upper-case letter without
    // Shift, or a lower-case one with it)
    property bool capsLock: false

    // what the lock has to say along the top of the ring, and in which tone
    property string note: ""
    readonly property string statusText: checking ? "Checking…"
        : note !== "" ? note
        : capsLock && count > 0 ? "Caps Lock is on"
        : awake && count === 0 ? "Type your password"
        : ""
    readonly property string statusTone: checking ? "quiet" : note !== "" ? "error" : capsLock && count > 0 ? "warn" : "quiet"

    // how far the ring has turned (degrees): one notch per bead, plus the rattle
    readonly property real turn: spin.scroll + rattle.value

    // the wallpaper on the sheet (the wallpaper dial knows which is on screen); "" before
    // it's known: the sheet is plain surface then
    readonly property string wallpaper: {
        Dials.revision
        const w = Dials.dials.wallpaper
        return w && w.currentPath ? w.currentPath : ""
    }

    // The same wallpaper blurred, made ahead of time with ImageMagick (one small file per
    // wallpaper in Vars.lockCachePath), so locking never waits for a blur and the lock draws
    // none of its own (Qt 6.12's effect masks crash: see WallpaperRing.qml). "" until it
    // exists: the sheet shows the wallpaper as it is meanwhile
    readonly property string blurTarget: wallpaper === "" ? "" : Vars.lockCachePath + "/" + Qt.md5(wallpaper) + "-" + Prefs.lockBlur + ".jpg"
    property string blurred: ""

    // what the sheet shows: the blurred wallpaper once it's made, the wallpaper itself until then
    readonly property bool pictureBlurred: blurred !== "" && blurred === blurTarget
    readonly property string picture: pictureBlurred ? blurred : wallpaper

    // the picture as a url (each part of the path escaped, so names with spaces or # load)
    readonly property string pictureUrl: picture === "" ? "" : "file://" + picture.split("/").map(encodeURIComponent).join("/")

    // kept loaded all the time, so the lock's sheet has it in its first frame (Qt shares
    // a picture loaded at the same url and size): the sheet never grows empty and then
    // fills in. Never drawn
    Image {
        source: root.pictureUrl
        sourceSize.width: 1280
        asynchronous: true
        visible: false
    }
    onBlurTargetChanged: _makeBlur()
    function _makeBlur() {
        if (blurTarget === "" || blurrer.running) return
        blurrer.target = blurTarget
        blurrer.exec(["sh", "-c",
            'test -s "$2" || { mkdir -p "$(dirname "$2")" && magick "$1" -resize "1280x720^" $3 -quality 92 "$2.part.jpg" && mv "$2.part.jpg" "$2"; }',
            "sh", wallpaper, blurTarget, Prefs.lockBlur > 0 ? "-blur 0x" + (Prefs.lockBlur * 2.4) : ""])
    }
    Process {
        id: blurrer
        property string target: ""
        onExited: code => {
            if (code === 0) root.blurred = target

            // the wallpaper changed again while this one was being made
            if (target !== root.blurTarget) root._makeBlur()
        }
    }

    // ── locking ──
    // `fromSize`: px the sheet starts from at the power dial's spot (0: from the corner)
    function lock(fromSize) {
        if (keep.locked) { poke(); return }
        keep.origin = Dials.spotOf("power")
        handover = Math.max(0, fromSize || 0)
        _clearState()
        coverSpring.snap(0)
        phase = "in"
        lockedAt = Date.now()
        keep.locked = true
        _remember(true)

        // the sheet grows at once (waiting for the compositor to confirm the lock left it
        // sitting at the dial's size for a few frames)
        _grow()
    }
    property real lockedAt: 0

    // straight to locked, no motion (a shell started after a crash while locked)
    function _lockAtOnce() {
        keep.origin = Dials.spotOf("power")
        handover = 0
        _clearState()
        coverSpring.to = 1
        coverSpring.snap(1)
        phase = "covered"
        lockedAt = Date.now()
        keep.locked = true
        _remember(true)
    }

    function _grow() {
        if (phase !== "in") return
        coverSpring.stiffness = Vars.springs.expressive.default.spatial.stiffness
        coverSpring.dampingRatio = Vars.springs.expressive.default.spatial.dampingRatio
        coverSpring.to = 1
        coverSpring.start()
    }
    // the sheet first reaches the far corner: it covers the screen. The rest of its
    // overshoot is past the screen's edge, so nothing more shows
    Connections {
        target: coverSpring
        function onValueChanged() {
            if (root.phase === "in" && coverSpring.value >= 1) {
                root.handover = 0
                root.phase = "covered"
            } else if (root.phase === "out" && coverSpring.value <= 0.003) {
                root._release()
            }
        }
        function onSettled() { if (root.phase === "out") root._release() }
    }

    // 0 .. 1 (the expressive default spring to lock, the standard fast one to unlock:
    // unlocking is the moment you want to get going, so it doesn't make you watch)
    SpringValue {
        id: coverSpring
        to: 0
        epsilon: 0.0005
    }

    // ── unlocking ──
    function _unlocked() {
        checking = false
        unlocking = true
        awake = true
        restTimer.stop()

        // the dial fades first (the lock opening as it goes), then the sheet goes back into
        // its spot, as a dial's content fades before it shrinks
        phase = "out"
        shrinkAfterFade.restart()

        // whatever happens to the motion, the session is handed back
        releaseFallback.restart()
    }
    Timer {
        id: shrinkAfterFade
        interval: Vars.expressiveFastEffects.duration
        onTriggered: {
            coverSpring.stiffness = Vars.springs.standard.fast.spatial.stiffness
            coverSpring.dampingRatio = Vars.springs.standard.fast.spatial.dampingRatio
            coverSpring.to = 0
            coverSpring.start()
        }
    }
    Timer {
        id: releaseFallback
        interval: 1500
        onTriggered: root._release()
    }

    // the sheet is back in its spot: give the session back
    function _release() {
        releaseFallback.stop()
        if (!keep.locked) return
        keep.locked = false
        phase = ""
        _clearState()
        _remember(false)
    }

    function _clearState() {
        password = ""
        peak = 0
        clearedFrom = 0
        checking = false
        wrong = false
        unlocking = false
        note = ""
        awake = false

        // straight back to the start, without a tick
        spin.silent = true
        spin.dragBy(-spin.scroll)
        spin.silent = false
        rattle.snap(0)
        restTimer.stop()
    }

    // ── typing ── (each screen sends its keys and mouse here)
    // a key press: returns true when the lock used it (every key is the lock's while locked)
    function key(event) {
        poke()
        if (!covered || checking || unlocking) return true
        const ctrl = (event.modifiers & Qt.ControlModifier) !== 0
        switch (event.key) {
        case Qt.Key_Return: case Qt.Key_Enter:
            submit(); return true
        case Qt.Key_Escape:
            if (count > 0) clear()
            else { note = ""; awake = false }
            return true
        case Qt.Key_Backspace:
            if (ctrl) clear()
            else backspace()
            return true
        }

        // ctrl+u clears, like a terminal
        if (ctrl && event.key === Qt.Key_U) { clear(); return true }
        if (event.text.length > 0 && event.text >= " " && !ctrl
            && !(event.modifiers & (Qt.AltModifier | Qt.MetaModifier)))
            type(event.text, (event.modifiers & Qt.ShiftModifier) !== 0)
        return true
    }

    function type(text, shift) {
        // a letter tells whether Caps Lock is on
        const up = text !== text.toLowerCase(), low = text !== text.toUpperCase()
        if (up || low) capsLock = up !== shift
        note = ""
        statusHold.stop()
        clearedFrom = 0
        password += text
        peak = Math.max(peak, count)
        spin.snapTo(count - 1)
    }

    function backspace() {
        if (count === 0) return
        const a = Array.from(password)
        a.pop()
        password = a.join("")
        spin.snapTo(Math.max(0, count - 1))
    }

    // every bead leaves, newest first, and the ring spins back to the start
    function clear() {
        if (count === 0) return
        clearedFrom = count
        password = ""
        spin.snapTo(0)
        peakReset.interval = clearedFrom * cfg.beadStagger + 500
        peakReset.restart()
    }
    Timer {
        id: peakReset
        onTriggered: if (root.count === 0) { root.peak = 0; root.clearedFrom = 0 }
    }

    // a key or a move: the ring comes out, and folds away again after a while untouched
    function poke() {
        if (!covered && phase !== "in") return
        if (phase === "covered") awake = true
        restTimer.restart()
    }

    // the pointer moved: the first move right after locking is only the pointer landing
    // on the new surface, not the hand
    function moved() {
        if (Date.now() - lockedAt < 700) return
        poke()
    }

    Timer {
        id: restTimer
        interval: root.cfg.restAfter
        onTriggered: {
            if (root.count > 0 || root.checking || root.unlocking) { restart(); return }
            root.awake = false
            root.note = ""
        }
    }

    // ── checking ──
    property string _answer: ""

    function submit() {
        if (count === 0 || checking || !covered) return
        _answer = password
        note = ""
        checking = true
        if (!pam.start()) _broken()
    }

    PamContext {
        id: pam
        config: Vars.lockPamConfig

        // the only question asked is the password
        onPamMessage: {
            if (pam.responseRequired) {
                pam.respond(root._answer)
                root._answer = ""
            }
        }
        onCompleted: result => {
            root._answer = ""
            if (result === PamResult.Success) root._unlocked()
            else if (result === PamResult.Failed) root._wrong("Wrong password")
            else if (result === PamResult.MaxTries) root._wrong("Too many tries, wait a moment")

            // PAM itself went wrong (not the password)
            else root._broken()
        }
        onError: error => {
            root._answer = ""
            root._broken()
        }
    }

    // the password was wrong: the ring rattles like a safe's dial that won't open, then
    // spins back to the start
    function _wrong(text) {
        checking = false
        wrong = true
        note = text
        rattle.kick(Vars.kickFor(cfg.stepDeg * 0.45, Vars.shakeSpring))
        wrongTimer.restart()
    }
    Timer {
        id: wrongTimer
        interval: root.cfg.wrongHold
        onTriggered: {
            root.wrong = false
            root.clear()
            statusHold.restart()
        }
    }

    // the note stays a while after the ring is clear
    Timer {
        id: statusHold
        interval: root.cfg.statusHold
        onTriggered: root.note = ""
    }

    // PAM itself failed (not a wrong password): say so, and keep what was typed to try again
    function _broken() {
        checking = false
        note = "Couldn't check the password"
        rattle.kick(Vars.kickFor(cfg.stepDeg * 0.3, Vars.shakeSpring))
    }

    // ── the ring's motion ── one notch per bead, on the expressive fast spring (a small
    // overshoot: the detent of a safe's dial), with the shell's tick on every notch
    DialRotation {
        id: spin
        stepDeg: root.cfg.stepDeg
        momentum: 0
        spring: Vars.springs.expressive.fast.spatial
    }

    // the rattle: kicked sideways and left to ring out round 0 (Vars.shakeSpring)
    SpringValue {
        id: rattle
        to: 0
        stiffness: Vars.shakeSpring.stiffness
        dampingRatio: Vars.shakeSpring.dampingRatio
        epsilon: 0.01
    }

    // ── the lock itself ── one LockSurface per screen
    WlSessionLock {
        id: session
        locked: keep.locked
        // the compositor ended the lock on its own (another locker took over, or it
        // refused): don't keep pretending
        onLockStateChanged: if (!locked && keep.locked) { keep.locked = false; root.phase = ""; root._clearState(); root._remember(false) }

        LockSurface { lock: root }
    }

    // ── surviving a reload, a crash ──
    // a reload keeps these (so a reload while locked stays locked)
    PersistentProperties {
        id: keep
        reloadableId: "dialLockState"
        property bool locked: false
        property string origin: "topRight"

        // after a reload: still locked means covered, at once
        onReloaded: if (locked) { root.handover = 0; coverSpring.to = 1; coverSpring.snap(1); root.phase = "covered"; root.lockedAt = Date.now() }
    }

    // no reloading while locked: a file saved meanwhile waits for the unlock
    Binding {
        target: Quickshell
        property: "watchFiles"
        value: false
        when: root.locked
    }

    // a note that the session is locked, for a shell started after a crash: it carries the
    // Hyprland session's signature, so a new login never starts locked
    readonly property string _session: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") || ""
    Process { id: noter }
    function _remember(on) {
        if (on && _session !== "")
            noter.exec(["sh", "-c", 'mkdir -p "$(dirname "$1")" && printf "%s" "$2" > "$1"', "sh", Vars.lockStatePath, _session])
        else
            noter.exec(["rm", "-f", Vars.lockStatePath])
    }
    FileView {
        path: Vars.lockStatePath
        printErrors: false
        onLoaded: {
            if (!keep.locked && root._session !== "" && text().trim() === root._session)
                root._lockAtOnce()
        }
    }

    Component.onCompleted: Dials.lock = root

    // from a keybind, hypridle, a script:  qs ipc call lock lock
    IpcHandler {
        target: "lock"
        function lock(): void { root.lock(0) }
        function isLocked(): bool { return root.locked }
    }
}
