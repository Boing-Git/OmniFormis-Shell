"""The user's own keyboards, mice and touchpads, read from /dev/input (the input group).

The AI's events never show here: they go to the compositor over Wayland, not through a device.
So any event here is the user, and in shared mode the AI makes way (daemon.on_user_input).
"""
import asyncio


async def watch(on_input):
    import evdev
    from evdev import ecodes as e

    devices = []
    for path in evdev.list_devices():
        try:
            d = evdev.InputDevice(path)
        except OSError:
            continue
        caps = d.capabilities()
        keys = caps.get(e.EV_KEY, [])
        if e.EV_REL in caps or e.KEY_A in keys or e.BTN_LEFT in keys or e.BTN_TOUCH in keys:
            devices.append(d)
        else:
            d.close()
    if not devices:
        raise RuntimeError("can't read any keyboard or mouse in /dev/input: is the user in the input group?")

    async def pump(d):
        try:
            async for ev in d.async_read_loop():
                if ev.type in (e.EV_KEY, e.EV_REL, e.EV_ABS):
                    on_input()
        except OSError:  # unplugged
            pass
        finally:
            d.close()
    await asyncio.gather(*(pump(d) for d in devices))
