"""Child processes the daemon runs (grim, piper, swaymsg…): STOP can kill every one of them."""
import asyncio
import subprocess

CHILDREN = set()


def _kill(p):
    if p.returncode is None:
        try:
            p.kill()
        except ProcessLookupError:
            pass


def kill_all():
    for p in list(CHILDREN):
        _kill(p)


async def run(args, *, env=None, input=None, timeout=None, check=True) -> bytes:
    """Runs a command (never through a shell) and returns its stdout. A cancelled or timed-out
    call kills the child."""
    p = await asyncio.create_subprocess_exec(
        *map(str, args), env=env,
        stdin=subprocess.PIPE if input is not None else subprocess.DEVNULL,
        stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    CHILDREN.add(p)
    try:
        out, err = await asyncio.wait_for(p.communicate(input), timeout)
    except BaseException:
        _kill(p)
        raise
    finally:
        CHILDREN.discard(p)
    if check and p.returncode != 0:
        raise RuntimeError(f"{args[0]}: {err.decode(errors='replace').strip() or 'failed (' + str(p.returncode) + ')'}")
    return out
