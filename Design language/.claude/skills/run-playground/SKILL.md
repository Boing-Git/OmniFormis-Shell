---
name: run-playground
description: Build, run, and drive the Material 3 Expressive component playground at playground/. Use when asked to run the playground, screenshot a component, verify a new component visually, check hover/focus/state-layer/motion behavior, or interact with the running app.
---

`playground` is not a runnable dev app by itself — it imports
`@language-lit/material3-expressive` by package name, which only resolves
once the package is built and actually present in a `node_modules` next to
it. Drive it via
`.claude/skills/run-playground/driver.mjs`, a Node REPL (Playwright +
headless Chromium) that builds the package, packs it, installs it into an
isolated scratch fixture the same way `scripts/verify-consumer-fixtures.mjs`
does for its production-build CI gate, launches `vite` dev mode against that
fixture, and drives a real browser page against it.

All paths below are relative to the repo root.

## Prerequisites

None beyond the repo's own `npm install`. `playwright-core` is a devDependency
(added for this driver) and Playwright's Chromium was already cached on this
machine at `~/Library/Caches/ms-playwright/chromium-1228` — the driver never
re-downloads a browser when that cache is present. If a fresh machine has no
cache, `npx playwright install chromium` fetches one (~150MB, one-time).

## Setup

```bash
npm install
```

## Run (agent path)

Pipe commands to the driver on stdin, one per line:

```bash
node .claude/skills/run-playground/driver.mjs <<'EOF'
setup
serve
launch
section checkbox
console
quit
EOF
```

`setup` rebuilds the package and preps a fresh scratch fixture — run it once
per session, or again any time `src` changes. `serve` and `launch` can be
skipped on subsequent invocations only if you keep the same driver process
alive (state — `fixtureDir`, `browser`, the vite child process — lives in
that one process; a new `node driver.mjs` invocation starts over from
nothing, so `setup` is required again).

Screenshots land in `/tmp/m3e-playground-shots/` (override:
`SCREENSHOT_DIR`).

| command | what it does |
|---|---|
| `setup` | `npm run build`, pack, copy `playground` into a scratch dir, link `node_modules` + `.bin`, extract the tarball into it |
| `serve` | launch `vite` dev mode inside the fixture on a free port, poll until it responds |
| `launch` | open a headless Chromium page at the dev server |
| `section <name>` | screenshot just `.<name>-example` (the convention every `playground/examples/<Name>.example.tsx` follows — `checkbox`, `card`, `button`, `icon-button`, `fab`, `icon`, `surface`, `text`) |
| `ss [name]` | full-page screenshot |
| `click <css-sel>` / `hover <css-sel>` / `focus <css-sel>` | real Playwright interaction, not a DOM `.click()` — proves event handlers, not just markup |
| `wait <css-sel-or-text=...>` | wait up to 10s for a selector (Playwright text= locators work) |
| `eval <js>` | evaluate in the page, print JSON |
| `console` | print collected `console.error`/`pageerror` output — check this before declaring success |
| `quit` | close the browser, kill the vite process, delete the scratch fixture |

New component task (T12+): add its `.claude/skills`-external example first —
`playground/examples/<Name>.example.tsx` with a `.<name>-example` root
class, wired into `playground/src/main.tsx` — then `section <name>` works
with no driver changes.

## Run (human path)

```bash
npm run build
# then manually reproduce the fixture steps in `setup`, or just trust the
# driver — there is no simpler manual dev-server path for playground.
```

## Test

```bash
npm run verify
```

12 gates: typecheck, unit/interaction tests, package build, production
playground build, architecture/documentation/browser-support/CSS/token/release
checks, bundle-size budgets, and packed Vite/Next consumer fixture builds. This
is the automated, non-visual counterpart to what this skill drives by eye —
run both; this skill doesn't replace it.

## Gotchas

- **Never symlink the repo into its own `node_modules/@language-lit/...`.**
  It resolves and Vite will start, but Vite's dependency watcher walking a
  self-referential symlink risks an infinite loop. `setup` builds+packs+
  extracts into an *isolated* scratch directory instead — always do the same
  if you touch this by hand.
- **`.bin` must be included when linking dev dependencies.** It's dot-prefixed,
  so a naive "skip dotfiles" filter (which is otherwise correct — you do want
  to skip `.package-lock.json`, `.cache`, etc.) silently drops it too, and
  then `vite` isn't resolvable as an executable in the fixture. `setup`
  explicitly special-cases `.bin`.
- **`vite` must be launched with `cwd` set to the fixture directory**, not
  just pointed at it with `--config`. `playground/vite.config.ts` sets no
  explicit `root`, so it defaults to `process.cwd()` at launch time — spawn it
  from the wrong directory and every route 404s with no error, it just serves
  the wrong tree. The driver's `serve` command sets `cwd` on the `spawn()`
  call for exactly this reason.
- **A screenshot taken immediately after a state change can catch motion
  mid-flight**, not the settled end state — e.g. `click`ing a checkbox that
  drives three others via a parent/child relationship shows two of them
  mid-checkmark-reveal if you `section` right away. This is usually a feature
  (it proves the animation is real, not a static swap) but if you want a
  settled shot, add a short wait after `click`/`wait` before `section`/`ss`.
- **Ambiguous Playwright selectors fail loudly and safely.** `.checkbox-example
  input[type="checkbox"]` matches all 7 checkboxes in that example and throws
  a strict-mode violation rather than clicking the wrong one — that's caught
  by the driver's per-command try/catch and printed as `ERROR: ...`; the
  session continues and cleanup still runs. Scope selectors narrowly (e.g.
  `:has-text(...)`) instead of relying on this to save you.
- **`for await (const line of readlineInterface)` silently drops lines on
  piped/heredoc stdin.** This isn't a project-specific bug — it's a genuine Node.js
  readline quirk: on non-TTY stdin, `'line'` events for a whole heredoc fire
  synchronously as soon as the data arrives, but the async-iterator protocol
  only listens for one line at a time; any line that arrives while the
  consumer is mid-`await` on a previous command has no listener and is lost,
  and the interface then closes having delivered only the first command. The
  driver instead buffers `'line'` events into its own queue and drains that
  queue with a single async worker — safe for both a piped heredoc and real
  interactive typing. If you ever rewrite the driver's main loop, keep this
  pattern; the more "obvious" `for await` version silently breaks
  multi-command scripts, which is the primary way this driver gets used.

## Troubleshooting

- **`ERR_USE_AFTER_CLOSE: readline was closed`**: `rl.prompt()` was called
  after stdin already hit EOF (which, on a piped heredoc, happens almost
  immediately — well before queued commands finish processing). Route prompt
  calls through the driver's `safePrompt()` guard, not `rl.prompt()` directly.
- **`section <name>` reports `NOT_FOUND`**: either the component's example
  isn't wired into `playground/src/main.tsx` yet, or its root class
  doesn't follow the `.<name>-example` convention every existing example
  uses (`grep -oE '\.[a-z-]+-example\b' playground/src/playground.css` to
  check what's currently registered).
- **Everything 404s after `serve`**: `vite` was launched without `cwd` set to
  the fixture directory — see the Gotcha above.
- **`vite` fails to find its own binary**: the `.bin` symlink was skipped when
  linking dev dependencies — see the Gotcha above.
- **A stale fixture or vite process lingers after a crash**: the scratch
  directories live under `os.tmpdir()` as `m3e-playground-*` — safe to
  `rm -rf` any of them. `serve` picks a free port dynamically each run, so
  a leaked previous process won't block a new one; find and kill it with
  `lsof -i -P | grep LISTEN | grep node` if needed.
