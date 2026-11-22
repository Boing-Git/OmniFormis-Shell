#!/usr/bin/env python3
# Puts comments on the project's comment standard (CLAUDE.md), in every .qml / .js / .py /
# .sh file of this project except the "Design language" folder:
#   - a comment sits directly above the thing it explains: no blank line below it
#   - one blank line above it, between it and code it doesn't explain (none right after
#     an opening `{` `[` `(` or a Python `:`, and none at the very top of a file)
# End-of-line comments explain their own line and are left alone.
#
#   scripts/comment-spacing.py           fix the files
#   scripts/comment-spacing.py --check   only list what would change (exits 1 if anything would)
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKIP_DIRS = {"Design language", ".git", "node_modules"}
EXTENSIONS = {".qml": "//", ".js": "//", ".py": "#", ".sh": "#"}


def is_comment(line, mark):
    s = line.strip()
    if mark == "#":
        # a shebang / encoding line isn't a comment about the code below
        return s.startswith("#") and not s.startswith("#!") and "coding" not in s[:20]

    # `//` lines, and one-line `/* … */` / `/** … */` doc comments
    return s.startswith("//") or (s.startswith("/*") and s.endswith("*/"))


def opens_block(line, mark):
    # also a shebang line: it counts as the top of the file
    s = line.rstrip()
    return s.endswith(("{", "[", "(")) or (mark == "#" and (s.endswith(":") or s.startswith("#!")))


def closes_block(line):
    return line.strip().startswith(("}", "]", ")"))


def string_lines(lines, mark):
    """Indexes of lines inside a multi-line string (JS template literal, Python triple quotes),
    which must never be touched."""
    inside, out = None, set()
    for i, line in enumerate(lines):
        if inside is not None:
            out.add(i)
        tokens = ['"""', "'''"] if mark == "#" else ["`"]
        for t in tokens:
            if line.count(t) % 2 == 1:
                if inside is None:
                    inside = t
                elif inside == t:
                    inside = None
    return out


def fix(text, mark):
    lines = text.split("\n")
    frozen = string_lines(lines, mark)
    comment = [i not in frozen and is_comment(l, mark) for i, l in enumerate(lines)]
    blank = [l.strip() == "" and i not in frozen for i, l in enumerate(lines)]
    # how many blank lines to keep before each line (None: leave as it is)
    want = [None] * len(lines)

    i = 0
    while i < len(lines):
        if not comment[i]:
            i += 1
            continue
        start = i
        while i < len(lines) and comment[i]:
            i += 1
        end = i - 1

        # above: one blank line, none after an opener or at the top of the file
        p = start - 1
        while p >= 0 and blank[p]:
            p -= 1
        if p < 0 or opens_block(lines[p], mark):
            want[start] = 0
        else:
            want[start] = 1

        # below: no blank line before the code it explains (not before another comment
        # block, which is its own thing, nor before a closing bracket: nothing to explain)
        n = end + 1
        while n < len(lines) and blank[n]:
            n += 1
        if n < len(lines) and n > end + 1 and not comment[n] and not closes_block(lines[n]) and n not in frozen:
            want[n] = 0

    out, out_frozen = [], []
    for idx, line in enumerate(lines):
        if want[idx] is not None:
            while out and out[-1].strip() == "" and not out_frozen[-1]:
                out.pop()
                out_frozen.pop()
            out.extend([""] * want[idx])
            out_frozen.extend([False] * want[idx])
        out.append(line)
        out_frozen.append(idx in frozen)
    return "\n".join(out)


def files():
    for path in sorted(ROOT.rglob("*")):
        rel = path.relative_to(ROOT)
        if any(part in SKIP_DIRS for part in rel.parts):
            continue
        if path.is_file() and not path.is_symlink() and path.suffix in EXTENSIONS:
            yield path


def main():
    check = "--check" in sys.argv[1:]
    changed = []
    for path in files():
        old = path.read_text()
        new = fix(old, EXTENSIONS[path.suffix])
        if new != old:
            changed.append(path.relative_to(ROOT))
            if not check:
                path.write_text(new)
    verb = "would change" if check else "changed"
    for p in changed:
        print(f"{verb}: {p}")
    print(f"{len(changed)} file(s) {verb}")
    return 1 if check and changed else 0


if __name__ == "__main__":
    sys.exit(main())
