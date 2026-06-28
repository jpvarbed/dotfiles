---
name: total-tdd
description: 'Systematic whole-app quality loop. Inventory every feature into user stories with code-derived expected behavior, track them in one canonical CSV, then loop: test every story, document errors, fix logic/UX bugs, re-test. Use for "/total-tdd", auditing an entire app, building a feature/user-story spec from the code, or a full test-and-fix sweep across all features.'
---

# total-tdd — whole-app feature audit → test → fix loop

A resumable, four-phase loop over an entire app. The **canonical CSV is the single
source of truth and the state machine** — every run reads it, updates it, and stops
when the current phase's rows are all terminal. Resume any time by re-reading it.

## Prerequisites

Phase 2 drives the running app through three roles. Before starting it, confirm one
tool exists for each — if any is missing, say which and stop, rather than silently
downgrading to reading code (that defeats the skill):

- **Browser driver** (exercise the UI): `agent-browser` preferred, or any
  browser-automation tool/MCP that can navigate, fill, click, screenshot, and read
  console + network.
- **Stable local URL** (serve the app): `portless` preferred, or any fixed
  host:port / tunnel.
- **API stub** (offline integration paths): `emulate` preferred, or any local mock
  for Stripe/GitHub/AWS and similar.

These are this stack's defaults; substitute equivalents when absent. Never mark a row
tested without actually running the behavior through one tool per role.

## Canonical tracker

`docs/feature-audit.csv` in the target repo (create `docs/` if missing). One row per
feature. Columns:

```
id,area,user_story,expected_behavior,source,status,issues,fix,verified
```

- `user_story`: "As a <role>, I want <action>, so that <outcome>."
- `expected_behavior`: what the code actually does (cite `source` as file:line).
- `status`: `spec` → `pass` / `fail` → `fixed` → `verified`.
- Keep ONE canonical file. Never fork copies. Append/update rows in place.

## Report — `docs/feature-audit.html`

Each phase, render the CSV to a single self-contained HTML report and keep it in sync.
Match the bundled `reference-report.html` (same columns, a per-status tally, status
colors). The CSV stays canonical; the HTML is its rendered view.

The report is also the forcing function: having to fill one row per feature with a real
status and observed evidence is what stops the agent from skipping verification — an
empty cell is a visible gap, so every story gets exercised.

## Phases (advance only when every row is terminal for the phase)

1. **Inventory + spec.** Walk the whole app (routes, components, commands, APIs,
   jobs, settings). For each feature, add a row with a user story and expected
   behavior derived from the code, with `source` refs. Status `spec`.
   *Done when every feature has a `spec` row.*

2. **Test.** Exercise each story in the **real running app**, not by reading code.
   First get it running: find the start/serve command (package scripts, README, or
   ask) and expose it at a stable URL via portless (or equivalent). Then drive the UI
   with the browser driver (navigate, fill, click, screenshot, check console/network)
   and stub external APIs (Stripe/GitHub/AWS…) with emulate so integration paths run
   offline. Set `status` `pass` or `fail`; put concrete repro/error in `issues`.
   *Done when no row is still `spec`.*

3. **Fix.** Fix every `fail` — logic bugs and UX errors both count. Record what
   changed in `fix`, set `status` `fixed`. Stay focused; don't refactor unrelated code.
   *Done when no row is `fail`.*

4. **Re-test.** Re-run every story (all of them, not just fixed ones) in the real
   app. Set `verified` `yes` on confirmed rows; any new break goes back to `fail`.
   *Done when every row is `verified=yes`. If any flipped to `fail`, loop to phase 3.*

## Rules

- Evidence before status. A row is `pass`/`verified` only after the behavior was
  observed running — never from reading code (see `verify-this`,
  `verification-before-completion`).
- The CSV is canonical and append-only-in-place: update the existing row, don't
  duplicate. It survives across sessions — that's how the loop resumes.
- Report each phase as a one-line tally: `N total · spec/pass/fail/fixed/verified counts`.
- Re-render `docs/feature-audit.html` from the CSV at the end of each phase; never let it drift.
- Scope creep is fine for *finding* issues across features; keep each *fix* diff tight.

## Resuming

Read `docs/feature-audit.csv`, infer the current phase from the column of statuses
(any `spec` → phase 2; any `fail` → phase 3; any `verified≠yes` → phase 4), and
continue from there.

## Errors

| Issue | Fix |
| --- | --- |
| `agent-browser` (or substitute browser driver) not installed or its MCP/daemon isn't running, so Phase 2 can't navigate/click/screenshot | Don't downgrade to reading code — that voids the skill. Start the driver (or pick an equivalent that can navigate, fill, click, screenshot, and read console+network); if none exists, name the missing role per the Prerequisites and stop, leaving the rows at `spec`. |
| App won't start, or `portless` can't bind because the dev port is already taken by another process | Find the real start/serve command (package scripts, README, or ask) and run it; map it through `portless` to a fixed `.localhost` URL so the browser driver hits a stable address — fix the port conflict (kill the stale server or change the port) rather than testing against a moving `localhost:PORT`. |
| `emulate` not installed, so external integrations (Stripe/GitHub/AWS) can't be stubbed and those stories hit the network or fail | Install/run `emulate` (or another local mock for that provider) and point the app's API base/keys at it so integration paths run offline; if it can't be stood up, mark only the affected rows `fail` with the missing-stub reason in `issues` — never silently skip them. |
| Missing/required API key or credential for an integration the emulator can't fully fake, blocking a real path | Fetch the key from Bitwarden (`bws`) at run time and inject via env — never hardcode it; if it's unavailable, record the blocked story as `fail` with the missing-credential note in `issues` so it's a visible gap, not a fake `pass`. |
| `docs/feature-audit.csv` missing, corrupt, or its columns drifted from `id,area,user_story,expected_behavior,source,status,issues,fix,verified` mid-loop | Treat the CSV as the canonical state machine: recreate it with the exact 9-column header if absent, and repair drift to that schema before continuing — never fork a second copy. If status values are inconsistent, re-derive the phase from the Resuming rules and re-render `docs/feature-audit.html` from the repaired CSV so the report stops drifting. |
