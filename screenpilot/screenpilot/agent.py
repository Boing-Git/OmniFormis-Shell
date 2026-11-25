"""ASK and ACT. Both are plain coroutines the daemon runs as one task, so STOP is a cancel."""
import asyncio

from . import config, safety


async def run_ask(d, question: str) -> str:
    d.set_state("thinking")
    shot = await d.capture(d.capture_mode)
    return await d.backend().ask(question, shot, await d.context())


async def run_act(d, goal: str) -> str:
    await d.prepare_act()
    session = d.backend().session(goal)
    log = safety.RunLog(config.state_dir() / "runs", goal, d.cfg["keepRuns"])
    note, first = "", True
    async with asyncio.timeout(d.cfg["timeoutS"]):
        for _ in range(d.cfg["maxSteps"]):
            problem = await d.guard_problem()
            if problem:
                d.stop(problem)
                await asyncio.sleep(0)  # the cancel lands here
            d.set_state("thinking")
            shot = await d.capture()
            context = await d.context()
            action = await session.step(shot, context, note)
            if action.kind == "done":
                return action.text or "Done."
            ask = safety.question(action, context, d.cfg["confirm"], first)
            if ask and not await d.confirm(ask):
                log.step(action, shot, "the user said no")
                return "You said no, so I stopped there."
            first = False
            d.set_state("acting")
            d.broadcast({"type": "step", "text": safety.describe(action)})
            note = await d.execute(action, shot)
            log.step(action, shot, note)
    return f"Stopped after {d.cfg['maxSteps']} steps without finishing."
