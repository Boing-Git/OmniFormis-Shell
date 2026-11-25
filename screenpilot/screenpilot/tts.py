"""Speech: piper (a local voice model) played through PipeWire. One sentence queue; STOP empties it
and cuts what is playing. Another engine only needs say() and stop()."""
import asyncio
import json
import os
import re
import subprocess

_LINE_START = re.compile(r"^\s{0,3}(#{1,6}|>|[-*+]|\d+[.)])\s+", re.M)


def speakable(text: str) -> str:
    """What to read out: no code, no markdown marks, no URLs; lines become sentences."""
    text = re.sub(r"```.*?(```|$)", "\n", text, flags=re.S)
    text = re.sub(r"`[^`\n]*`", "", text)
    text = re.sub(r"!\[[^\]]*\]\([^)]*\)", "", text)
    text = re.sub(r"\[([^\]]*)\]\([^)]*\)", r"\1", text)
    text = re.sub(r"https?://\S+", "", text)
    text = _LINE_START.sub("", text)
    text = re.sub(r"[*_~]{1,3}([^*_~\n]+)[*_~]{1,3}", r"\1", text)
    lines = [re.sub(r"\s+", " ", line).strip() for line in text.splitlines()]
    lines = [line for line in lines if line]
    # every line but the last ends as a sentence, so piper pauses between them
    return " ".join([line if line[-1] in ".!?:;," else line + "." for line in lines[:-1]] + lines[-1:])


class Piper:
    def __init__(self, model, rate=None):
        self.model = model
        self.rate = rate or json.load(open(model + ".json"))["audio"]["sample_rate"]
        self.queue = asyncio.Queue()
        self.procs = []
        self.worker = None

    def piper_cmd(self):
        return ["piper", "-m", self.model, "--output-raw"]

    def player_cmd(self):
        return ["pw-play", "--raw", "--rate", str(self.rate), "--format", "s16", "--channels", "1", "-"]

    def say(self, text):
        text = speakable(text)
        if not text:
            return
        self.queue.put_nowait(text)
        if self.worker is None or self.worker.done():
            self.worker = asyncio.ensure_future(self._work())

    async def _work(self):
        while not self.queue.empty():
            text = self.queue.get_nowait()
            r, w = os.pipe()
            try:
                piper = await asyncio.create_subprocess_exec(*self.piper_cmd(), stdin=subprocess.PIPE, stdout=w,
                                                             stderr=subprocess.DEVNULL)
                player = await asyncio.create_subprocess_exec(*self.player_cmd(), stdin=r, stdout=subprocess.DEVNULL,
                                                              stderr=subprocess.DEVNULL)
            finally:
                os.close(r)
                os.close(w)
            self.procs = [piper, player]
            try:
                piper.stdin.write(text.encode())
                await piper.stdin.drain()
                piper.stdin.close()
            except (BrokenPipeError, ConnectionResetError):
                pass
            await player.wait()
            if piper.returncode is None:
                piper.kill()
            await piper.wait()
            self.procs = []

    def stop(self):
        """Empties the queue and cuts the sentence playing now. Needs no event loop (STOP's
        signal handler calls it)."""
        while not self.queue.empty():
            self.queue.get_nowait()
        for p in self.procs:
            if p.returncode is None:
                try:
                    p.kill()
                except ProcessLookupError:
                    pass
