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
- Scope creep is fine for *finding* issues across features; keep each *fix* diff tight.

## Resuming

Read `docs/feature-audit.csv`, infer the current phase from the column of statuses
(any `spec` → phase 2; any `fail` → phase 3; any `verified≠yes` → phase 4), and
continue from there.
