"""The AI's own pointer and keyboard: one Wayland client speaking zwlr_virtual_pointer_v1 and
zwp_virtual_keyboard_v1 to whichever compositor it is pointed at (the sandbox's sway, or
Hyprland). No libraries: the wire protocol is a few structs.

The keyboard carries its own keymap, grown like wtype's: every keysym it needs sits on a spare
keycode, so any text types the same whatever the user's layout (Colemak here). It remembers what
it holds, so STOP can let go of everything; after release_all() it refuses every event until
unblock() (resume), so a run that is still unwinding can't slip one out.
"""
import asyncio
import os
import socket
import struct
import time

BUTTONS = {"left": 0x110, "right": 0x111, "middle": 0x112}
MODS = {"shift": 1, "ctrl": 4, "control": 4, "alt": 8, "option": 8, "mod1": 8,
        "super": 64, "cmd": 64, "meta": 64, "win": 64, "logo": 64, "mod4": 64}
NAMED = {"return": 0xff0d, "enter": 0xff0d, "kp_enter": 0xff8d, "tab": 0xff09, "escape": 0xff1b,
         "esc": 0xff1b, "backspace": 0xff08, "delete": 0xffff, "del": 0xffff, "home": 0xff50,
         "left": 0xff51, "up": 0xff52, "right": 0xff53, "down": 0xff54, "page_up": 0xff55,
         "pageup": 0xff55, "prior": 0xff55, "page_down": 0xff56, "pagedown": 0xff56, "next": 0xff56,
         "end": 0xff57, "insert": 0xff63, "menu": 0xff67, "print": 0xff61, "space": 0x20,
         "minus": 0x2d, "equal": 0x3d, "plus": 0x2b, "comma": 0x2c, "period": 0x2e, "slash": 0x2f,
         "backslash": 0x5c, "semicolon": 0x3b, "apostrophe": 0x27, "grave": 0x60,
         "bracketleft": 0x5b, "bracketright": 0x5d}
NAMED.update({f"f{n}": 0xffbe + n - 1 for n in range(1, 25)})
MAX_KEYS = 240  # keycodes 9..248 (xkb's keycodes stop at 255)


class Halted(Exception):
    """STOP happened: input is refused until resume."""


def keysym_for_char(ch: str) -> int:
    cp = ord(ch)
    if ch == "\n":
        return 0xff0d
    if ch == "\t":
        return 0xff09
    if 0x20 <= cp <= 0x7e or 0xa0 <= cp <= 0xff:  # Latin-1 keysyms are the code points
        return cp
    return 0x01000000 + cp


def parse_mods(mods: str) -> int:
    """"ctrl+shift" -> its modifier mask ("" -> 0)."""
    mask = 0
    for m in filter(None, (p.strip().lower() for p in mods.split("+"))):
        if m not in MODS:
            raise ValueError(f"unknown modifier {m!r}")
        mask |= MODS[m]
    return mask


def parse_combo(combo: str) -> tuple:
    """"ctrl+shift+t" -> (modifier mask, keysym). Shift is only what is said: "ctrl+T" is ctrl+t."""
    parts = combo.strip().split("+")
    if combo.strip().endswith("++"):
        parts = parts[:-2] + ["+"]
    *mods, key = parts
    mask = 0
    for m in mods:
        if m.strip().lower() not in MODS:
            raise ValueError(f"unknown modifier {m!r} in {combo!r}")
        mask |= MODS[m.strip().lower()]
    key = key.strip()
    if key.lower() in NAMED:
        return mask, NAMED[key.lower()]
    if len(key) == 1 and key.isprintable():
        return mask, keysym_for_char(key.lower() if key.isascii() else key)
    raise ValueError(f"unknown key {key!r} in {combo!r}")


def keymap_text(keysyms) -> str:
    """An xkb keymap with keysym i on keycode i + 9 (the evdev code i + 1), as wtype builds it."""
    codes = "".join(f"<K{i + 1}> = {i + 9};\n" for i in range(len(keysyms)))
    syms = "".join(f"key <K{i + 1}> {{[ {k:#x} ]}};\n" for i, k in enumerate(keysyms))
    return ("xkb_keymap {\n"
            f'xkb_keycodes "(unnamed)" {{\nminimum = 8;\nmaximum = {len(keysyms) + 9};\n{codes}}};\n'
            'xkb_types "(unnamed)" { include "complete" };\n'
            'xkb_compatibility "(unnamed)" { include "complete" };\n'
            f'xkb_symbols "(unnamed)" {{\n{syms}}};\n'
            "};\n")


class Input:
    """Everything but the wire: what is held, blocking after STOP, the keymap, timing. Subclasses
    send six primitives."""

    def __init__(self, delay=0.06):
        self.delay = delay
        self.held = set()        # ("button", code) / ("key", code)
        self.blocked = False     # STOP: refused until unblock()
        self.paused = False      # shared mode, the user is using the controls: wait
        self.keysyms = []        # keysym at keycode index + 1
        self.box = (0, 0, 1, 1)  # the layout rectangle absolute motion spans (x, y, w, h)

    # the wire
    def _motion(self, x, y): raise NotImplementedError
    def _button(self, code, state): raise NotImplementedError
    def _axis(self, axis, notches): raise NotImplementedError
    def _key(self, code, state): raise NotImplementedError
    def _mods(self, mask): raise NotImplementedError
    def _keymap(self, keysyms): raise NotImplementedError

    def _check(self):
        if self.blocked:
            raise Halted("stopped: input is off until resume")

    async def _gate(self):
        """Before every event: refused after STOP, held back while paused."""
        self._check()
        while self.paused:
            await asyncio.sleep(0.05)
            self._check()

    async def _pause(self, s=None):
        await asyncio.sleep(self.delay if s is None else s)

    async def move_to(self, x, y):
        await self._gate()
        self._motion(x, y)

    async def press(self, button="left"):
        await self._gate()
        code = BUTTONS[button]
        self.held.add(("button", code))
        self._button(code, 1)

    async def release(self, button="left"):
        code = BUTTONS[button]
        self._button(code, 0)
        self.held.discard(("button", code))

    async def click(self, button="left", mods=0):
        """mods: held for this click only (ctrl+click)."""
        await self._gate()
        if mods:
            self._mods(mods)
        try:
            await self.press(button)
            await self._pause(0.04)
            await self.release(button)
        finally:
            if mods:
                self._mods(0)

    async def double_click(self, button="left", mods=0):
        await self.click(button, mods)
        await self._pause(0.08)
        await self.click(button, mods)

    async def drag(self, x1, y1, x2, y2, steps=12):
        await self.move_to(x1, y1)
        await self.press()
        try:
            for i in range(1, steps + 1):
                await self._pause(0.025)
                await self.move_to(x1 + (x2 - x1) * i / steps, y1 + (y2 - y1) * i / steps)
        finally:
            await self.release()

    async def scroll(self, dx=0, dy=0):
        for axis, n in ((0, dy), (1, dx)):
            for _ in range(abs(n)):
                await self._gate()
                self._axis(axis, 1 if n > 0 else -1)
                await self._pause()

    def _codes(self, keysyms):
        """Keycodes for these keysyms, uploading one keymap first if any is new."""
        new = [k for k in dict.fromkeys(keysyms) if k not in self.keysyms]
        if new:
            if len(self.keysyms) + len(new) > MAX_KEYS:
                self.keysyms = []
            self.keysyms += new
            self._keymap(self.keysyms)
        return [self.keysyms.index(k) + 1 for k in keysyms]

    async def _tap(self, code):
        await self._gate()
        self.held.add(("key", code))
        self._key(code, 1)
        await self._pause(0.01)
        self._key(code, 0)
        self.held.discard(("key", code))
        await self._pause()

    async def type_text(self, text):
        await self._gate()
        syms = [keysym_for_char(c) for c in text if c in "\n\t" or c.isprintable()]
        # shortcut: more than MAX_KEYS different characters go in chunks, a keymap each
        for i in range(0, len(syms), 200):
            for code in self._codes(syms[i:i + 200]):
                await self._tap(code)

    async def key(self, combo):
        mask, keysym = parse_combo(combo)
        await self._gate()
        (code,) = self._codes([keysym])
        self._mods(mask)
        try:
            await self._tap(code)
        finally:
            self._mods(0)

    def release_all(self):
        """STOP: let go of everything, then refuse events until unblock(). Never raises."""
        self.blocked = True
        self.let_go()

    def let_go(self):
        """Releases every held button and key (the user takes over: nothing stays pressed)."""
        for kind, code in list(self.held):
            try:
                (self._button if kind == "button" else self._key)(code, 0)
            except Exception:
                pass
        self.held.clear()
        try:
            self._mods(0)
        except Exception:
            pass

    def unblock(self):
        self.blocked = False


def _now():
    return int(time.monotonic() * 1000) & 0xFFFFFFFF


def _string(text):
    b = text.encode() + b"\0"
    return struct.pack("<I", len(b)) + b + b"\0" * ((4 - len(b) % 4) % 4)


class WaylandInput(Input):
    """Input on the wire to the compositor at `display` (a WAYLAND_DISPLAY name or path)."""

    def __init__(self, display, delay=0.06):
        super().__init__(delay)
        path = display if display.startswith("/") else os.path.join(os.environ["XDG_RUNTIME_DIR"], display)
        self.s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
        self.s.settimeout(1)   # a compositor that stops answering can't hang the daemon
        self.s.connect(path)
        self.next_id, self.buf, self.globals = 2, b"", {}
        registry = self._new()
        self._send(1, 1, struct.pack("<I", registry))                  # wl_display.get_registry
        self._roundtrip(registry)
        for iface in ("wl_seat", "zwlr_virtual_pointer_manager_v1", "zwp_virtual_keyboard_manager_v1"):
            if iface not in self.globals:
                raise RuntimeError(f"the compositor at {display} has no {iface}")
        seat = self._bind(registry, "wl_seat", 1)
        pointers = self._bind(registry, "zwlr_virtual_pointer_manager_v1", 1)
        keyboards = self._bind(registry, "zwp_virtual_keyboard_manager_v1", 1)
        self.ptr, self.kbd = self._new(), self._new()
        self._send(pointers, 0, struct.pack("<II", seat, self.ptr))    # create_virtual_pointer
        self._send(keyboards, 0, struct.pack("<II", seat, self.kbd))   # create_virtual_keyboard
        self._roundtrip()

    def _new(self):
        self.next_id += 1
        return self.next_id - 1

    def _send(self, obj, opcode, payload=b"", fds=()):
        msg = struct.pack("<IHH", obj, opcode, 8 + len(payload)) + payload
        if fds:
            socket.send_fds(self.s, [msg], list(fds))
        else:
            self.s.sendall(msg)

    def _bind(self, registry, iface, version):
        oid = self._new()
        self._send(registry, 0, struct.pack("<I", self.globals[iface]) + _string(iface) + struct.pack("<II", version, oid))
        return oid

    def _read(self):
        while len(self.buf) < 8 or len(self.buf) < struct.unpack("<IHH", self.buf[:8])[2]:
            chunk = self.s.recv(65536)
            if not chunk:
                raise ConnectionError("the compositor closed the connection")
            self.buf += chunk
        obj, opcode, size = struct.unpack("<IHH", self.buf[:8])
        body, self.buf = self.buf[8:size], self.buf[size:]
        return obj, opcode, body

    def _roundtrip(self, registry=None):
        cb = self._new()
        self._send(1, 0, struct.pack("<I", cb))                        # wl_display.sync
        while True:
            obj, opcode, body = self._read()
            if obj == 1 and opcode == 0:                               # wl_display.error
                n = struct.unpack("<I", body[8:12])[0]
                raise RuntimeError("wayland error: " + body[12:12 + n - 1].decode())
            if obj == registry and opcode == 0:                        # wl_registry.global
                n = struct.unpack("<I", body[4:8])[0]
                self.globals[body[8:8 + n - 1].decode()] = struct.unpack("<I", body[:4])[0]
            if obj == cb and opcode == 0:                              # wl_callback.done
                return

    def _motion(self, x, y):
        bx, by, bw, bh = self.box
        px = min(max(round(x - bx), 0), int(bw))
        py = min(max(round(y - by), 0), int(bh))
        self._send(self.ptr, 1, struct.pack("<IIIII", _now(), px, py, int(bw), int(bh)))
        self._send(self.ptr, 4)                                        # frame

    def _button(self, code, state):
        self._send(self.ptr, 2, struct.pack("<III", _now(), code, state))
        self._send(self.ptr, 4)

    def _axis(self, axis, notches):
        self._send(self.ptr, 5, struct.pack("<I", 0))                  # axis_source: wheel
        self._send(self.ptr, 7, struct.pack("<IIii", _now(), axis, notches * 15 * 256, notches))
        self._send(self.ptr, 4)

    def _key(self, code, state):
        self._send(self.kbd, 1, struct.pack("<III", _now(), code, state))

    def _mods(self, mask):
        self._send(self.kbd, 2, struct.pack("<IIII", mask, 0, 0, 0))

    def _keymap(self, keysyms):
        data = keymap_text(keysyms).encode() + b"\0"
        fd = os.memfd_create("screenpilot-keymap")
        try:
            os.write(fd, data)
            self._send(self.kbd, 0, struct.pack("<II", 1, len(data)), fds=[fd])  # format xkb_v1
        finally:
            os.close(fd)
        self._roundtrip()  # the compositor has the keymap before the first key

    def close(self):
        try:
            self._send(self.ptr, 8)                                    # destroy
            self._send(self.kbd, 3)
            self._roundtrip()
        except (OSError, RuntimeError):
            pass
        self.s.close()
