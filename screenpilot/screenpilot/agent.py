"""ASK and ACT. Both are plain coroutines the daemon runs as one task, so STOP is a cancel."""
import asyncio


async def run_ask(d, question: str) -> str:
    d.set_state("thinking")
    shot = await d.capture()
    return await d.backend().ask(question, shot, await d.context())


async def run_act(d, goal: str) -> str:
    session = d.backend().session(goal)
    note = ""
    async with asyncio.timeout(d.cfg["timeoutS"]):
        for _ in range(d.cfg["maxSteps"]):
            d.set_state("thinking")
            shot = await d.capture()
            action = await session.step(shot, await d.context(), note)
            if action.kind == "done":
                return action.text or "Done."
            d.set_state("acting")
            note = await d.execute(action, shot)
    return f"Stopped after {d.cfg['maxSteps']} steps without finishing."
