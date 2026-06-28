# Determinize-refactor audit — `total-tdd`

Target: `/Users/jasonvarbedian/dev/dotfiles/skills/engineering/total-tdd/SKILL.md`
Method: `skills/meta/determinize-refactor/SKILL.md`
Tokenizer: **none run** — all counts are line-based estimates (`tokens ≈ non_empty_lines × 11`, range multipliers 9 / 13). Label every number an estimate.

---

## 1. Token summary (mandatory)

| Corpus file | Non-empty lines | Est. tokens (×11) | Low (×9) | High (×13) |
|---|---|---|---|---|
| `SKILL.md` | 77 | 847 | 693 | 1,001 |
| `reference-report.html` (loaded as the render contract) | 73 | 803 | 657 | 949 |
| **Total corpus** | **150** | **1,650** | **1,350** | **1,950** |

`reference-report.html` is counted because the skill instructs the agent to "Match the bundled `reference-report.html`" — the model must read it every run to reproduce the HTML shape, so it is live prompt cost, not an inert asset.

**Original tokens:** ~1,650 (range 1,350–1,950).

**Post-refactor (formulas explicit):**
- `post_refactor_tokens = original_tokens − reducible_tokens`
- `improvement_percent = (reducible_tokens / original_tokens) × 100`

| Scenario | Reducible tokens | Post-refactor tokens | % improvement |
|---|---|---|---|
| **Conservative** | ~715 | ~935 | **~43%** |
| **Aggressive** | ~1,030 | ~620 | **~62%** |

These assume the HTML render and the CSV state-machine logic move into `render.py` + `tracker.py`, leaving SKILL.md as the judgment-bearing prose plus a thin "run the script" contract.

---

## 2. Concrete savings breakdown

Reducibility applied per determinism class (from the method's table):

| Section (file:lines) | Class | Est. tokens | Reducible % | Cons. saved | Aggr. saved |
|---|---|---|---|---|---|
| `reference-report.html` (entire render template) (1–73) | Output template | 803 | 80–95% | 642 | 763 |
| Report/tally spec — "per-status tally", one-line tally format (SKILL.md 44–52, 83) | Output template + tally math | ~55 | 80–95% | 44 | 52 |
| Resuming phase-inference rules (SKILL.md 88–91) | Strict workflow (state machine) | ~44 | 80–95% | 35 | 42 |
| Phase-terminal / "advance only when every row is terminal" gates (SKILL.md 53–74) | Strict workflow + partial | ~242 | 30–60% | 73 | 145 |
| CSV schema + column contract (SKILL.md 30–42) | Fixed mapping / contract | ~143 | 30–60%* | 43 | 86 |
| Errors table — CSV repair/recreate row (SKILL.md 101) | Retry/error policy (partial) | ~22 | 30–60% | 7 | 13 |
| **Totals** | | | | **~844** | **~1,101** |

\* CSV schema is partially reducible: the *header/validation* is deterministic (owned by `tracker.py`), but the human guidance on what a good `user_story`/`expected_behavior` looks like stays prose.

Conservative total clipped to ~715 and aggressive to ~1,030 after holding back the judgment-laced halves of the phase-gate and CSV-schema sections that must remain readable in prose.

**Top 5 sections by absolute savings (aggressive):**
1. `reference-report.html` render template — **763**
2. Phase-terminal gate logic — 145
3. CSV schema/validation — 86
4. Report tally spec — 52
5. Resuming phase-inference — 42

---

## 3. Top deterministic sections to extract first

1. **The HTML render** (`reference-report.html` + SKILL.md §"Report"). Largest single chunk (~803 tokens) and 100% mechanical: CSV → HTML with fixed columns, status CSS classes, and a tally line. Pure function of the CSV. No judgment whatsoever.
2. **The phase state machine** (SKILL.md §Phases done-gates + §Resuming). "Any `spec` → phase 2; any `fail` → phase 3; any `verified≠yes` → phase 4" and "advance only when every row is terminal" are exact, testable transitions — today re-derived by the model every resume, which is exactly where it drifts.
3. **The per-status tally math** (SKILL.md 83 + HTML line 30). Counting rows by status is arithmetic; the model should never be tallying by hand.

---

## 4. Detailed file conversion plan

| file | what | why | how | script path | savings (cons/aggr) | priority | risk |
|---|---|---|---|---|---|---|---|
| `reference-report.html` | Entire render template | 100% deterministic, biggest chunk; model re-reads it every phase to copy its shape | `render.py` owns it as a string template; HTML becomes a code asset the model never reads. Keep `reference-report.html` only as a fixture for the script's golden test | `skills/engineering/total-tdd/render.py` | 642 / 763 | **P0** | low |
| `SKILL.md` §Report (44–52) + Rules tally (83) | "render the CSV to HTML", "per-status tally", "one-line tally" | Mechanical render + arithmetic; replace prose with a single command | Collapse to one line: "Run `render.py docs/feature-audit.csv` after each phase." Script writes `feature-audit.html` and prints the tally | (in `render.py`) | 44 / 52 | **P0** | low |
| `SKILL.md` §Resuming (88–91) | Phase-inference from status column | Exact transition table; model drift on resume is the failure mode | `tracker.py phase` reads CSV, prints current phase + reason | `skills/engineering/total-tdd/tracker.py` | 35 / 42 | **P0** | low |
| `SKILL.md` §Phases done-gates (58–74) | "Done when…" terminal conditions per phase | Deterministic gate; should be a checked assertion, not a remembered rule | `tracker.py gate --phase N` exits 0 when the phase's rows are all terminal, else lists the blocking rows. Prose keeps *what to do* in each phase (judgment); script owns *when it's done* | `tracker.py` | 30 / 60 | **P1** | med |
| `SKILL.md` §Canonical tracker (30–42) | 9-column header + status enum + validation | Schema/validation is deterministic; recreate/repair is scripted | `tracker.py init` writes the exact header; `tracker.py validate` enforces 9 cols + status enum (`spec/pass/fail/fixed/verified`) and repairs drift | `tracker.py` | 30 / 60 | **P1** | med |
| `SKILL.md` §Errors CSV row (101) | "recreate with exact header / repair drift" | Folds into `tracker.py validate`; prose just points at it | Replace the long cell with "run `tracker.py validate` (recreates/repairs to schema)" | `tracker.py` | 7 / 13 | **P2** | low |

---

## 5. Suggested pipeline changes

Two scripts, both pure-CSV consumers, zero new deps (stdlib `csv`):

**`tracker.py`** — the CSV state machine.
- `tracker.py init` → write canonical 9-col header if absent.
- `tracker.py validate [--repair]` → assert/repair header + status enum; nonzero exit on drift.
- `tracker.py phase` → print current phase (1–4) + the reason (which status triggered it).
- `tracker.py gate --phase N` → exit 0 if all rows terminal for phase N, else list blockers.
- `tracker.py tally` → print `N total · spec/pass/fail/fixed/verified` one-liner.
- Input: `docs/feature-audit.csv`. Output: stdout + exit code. No mutation except `init`/`--repair`.

**`render.py`** — the view.
- `render.py docs/feature-audit.csv [-o docs/feature-audit.html]` → write self-contained HTML matching the template; print the tally.
- Owns the inlined HTML/CSS template (formerly `reference-report.html`).
- Golden test: render the sample CSV, diff against `reference-report.html` (kept as the fixture).

SKILL.md shrinks to: prerequisites, the four phase *intents* (prose), the evidence/judgment rules, and "run `tracker.py` / `render.py`" at the gates. The CSV stays canonical; the scripts are the only things that read/write its mechanics.

---

## 6. Residual prompt — what must stay model-driven

These are judgment, not rules — keep them as prose, do **not** script them:

- **What counts as a feature / how to slice user stories** (Phase 1 inventory). Walking routes/components/commands and deciding the granularity of a story is interpretation.
- **Deriving `expected_behavior` from the code** with a real `source` file:line — reading intent out of code is the core model task.
- **How to test UX / exercise a story in the running app** (Phase 2): which flows, what "looks broken," what console/network evidence matters. The *fact* of needing a browser+URL+stub per role is a deterministic prerequisite check (could be a preflight script), but *what to click and what's wrong* is judgment.
- **Whether a fix is in-scope** ("keep each fix diff tight; scope creep fine for finding, not for fixing") — a tradeoff call.
- **Evidence-before-status discipline** — the cultural rule that anchors the skill; state machine can enforce *that a status is set*, but only the model judges whether the observed behavior justifies `pass`.

**Honesty note:** this skill is genuinely ~half judgment. The ~43–62% reduction is real but concentrated almost entirely in the HTML render + the small state-machine/tally core. Don't over-promise: after extraction the remaining prose is mostly irreducible and should stay prose.
