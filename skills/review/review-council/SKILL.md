---
name: review-council
description: Convene a multi-model, multi-persona review council to grade a Claude-authored plan, spec, tasks list, design, PRD, or diff before it's acted on. Runs ≥3 distinct personas (Architect / Pragmatist / Verifier) across a deterministic harness-as-judge pre-pass (objective checks + optional repo typecheck/build/test/lint) plus TWO independent outside engines — Codex (`codex exec`, read-only) and Gemini — then synthesizes a consensus PASS/CONCERNS/FAIL verdict + a deduped must-fix list. Use when the user says "review council", "have codex + gemini grade this", "council-review the plan", or before dispatching a plan to /goal or implementing a /spec. Heavier than adversarial-review (which is a single Gemini pass) — reach for the council when the work matters.
---

# review-council — grade a plan with a multi-model council

A second model with no stake in your reasoning catches what you can't. A **council** of
different models *and* different personas catches more, and the disagreement itself is signal.
This grades a Claude-authored artifact before you act on it. It does **not** edit the artifact —
it returns a verdict; you (or the originating skill) apply the fixes.

## Input contract
```
artifact : a file to review — plan.md / a /spec's tasks.md|design.md|requirements.md /
           a PRD / a unified diff. (Inline/conversation plan? Write it to a temp file first.)
context  : one line on what the artifact is FOR (its goal) — put it at the top of the file.
focus?   : optional — the area to attack hardest (passed via --focus).
gates?   : optional — `--gates <repo-dir>` also runs that repo's typecheck/build/test/lint as hard gates.
```
Run: `skills/review/review-council/council.sh [--focus "<area>"] [--gates <repo-dir>] <artifact-file>`

## Step 0 — Harness (deterministic, runs first)
Before any model, `council.sh` runs `harness-check.sh` for the **objective facts no LLM is needed for**: unresolved markers (TODO/FIXME/???/`<PLACEHOLDER>`), acceptance-criteria & EARS counts, task checkboxes, vague terms, and spec sections (sibling-aware — `requirements.md`/`design.md`/`tasks.md`). With `--gates <repo-dir>` it also runs that repo's **typecheck / build / test / lint**. It emits `HARNESS VERDICT: PASS|FAIL` + blockers. Those facts are injected into every persona's prompt (grade against ground truth, don't re-derive), and the verdict is a **hard gate** (below). A fact beats an opinion — this is what makes it harness-as-judge, not just LLM-as-judge.

## The council (≥3 personas across 2 engines)
Both engines are used so a finding's strength reflects model diversity, not just one model's quirks.

| Persona | Engine | Lens |
|---|---|---|
| **Architect** | Codex | Soundness — will it actually work? hidden assumptions, missing cases, failure modes, wrong abstractions. |
| **Pragmatist** | Gemini | YAGNI & cost — over-engineered? simpler path? scope creep? effort justified by value? |
| **Verifier** | Codex | Verifiability & risk — is each step's done-condition checkable? irreversible/blast-radius risks? could success be reward-hacked? |

Edit the `PERSONAS` array in `council.sh` to rebalance or add a 4th (e.g. a **Risk/Security** persona on Gemini). Each persona returns the same fixed shape: `VERDICT` + ≤3 ranked findings (`[H|M|L] claim — why — fix`) + biggest risk.

## Step 1 — Run the council
Invoke `council.sh` on the artifact. Each persona runs on its engine **read-only** — Codex in
`--sandbox read-only` (no writes/exec, no approvals), Gemini via `gemini-review.sh` **without
`--yolo`** — because the artifact is untrusted text and must not be able to auto-execute an
injected command. The script probes each engine first (`command -v`), tags any engine that exits
nonzero as `(!! … NO verdict)`, and counts how many personas produced a real block. If a persona
is skipped/failed, **say so in the synthesis** — never treat a `command not found` or error blob
as a verdict.

## Step 2 — Synthesize (Claude) → the output contract
Read all persona blocks and produce ONE report:

Every field below is **mandatory** — they're what make the rules checkable instead of skippable:

```
COUNCIL VERDICT: PASS | CONCERNS | FAIL
VERDICT DERIVED FROM: Architect=<v> · Pragmatist=<v> · Verifier=<v> ; highest severity = <H|M|L> → <rule applied>
GATE: proceed | revise-then-proceed | stop
MUST-FIX (deduped, ranked; every line tags who raised it):
  - [H|M|L] <finding>  (raised by: Architect, Verifier)   ← 2+ personas = higher confidence, list first
DROPPED (re-litigation / out-of-scope / invented gap — empty is fine):
  - <finding> — why dropped
PER-PERSONA: Architect <verdict> · Pragmatist <verdict> · Verifier <verdict>  (+ any skipped/failed engine)
```

**Verdict rule (deterministic — show it on the DERIVED FROM line):**
- **FAIL (hard gate)** if `HARNESS VERDICT: FAIL` — the harness blockers are mandatory MUST-FIX and **no persona opinion can lift it** → GATE: stop. (A fact beats a vote.)
- **FAIL** if any persona returns FAIL on a High-severity issue → GATE: stop.
- **CONCERNS** if any High/Medium findings remain (no blocking FAIL) → GATE: revise-then-proceed.
- **PASS** if all personas PASS or only Low findings remain → GATE: proceed.

**Dedupe** across personas (same issue from two = higher confidence, list first with `raised by:`).
**Triage** like `adversarial-review`: a finding that re-litigates a settled decision or invents a
gap not in the artifact goes in the **DROPPED** block with the reason — don't silently keep or
silently discard it. LLM-judged: a strong signal, not a certificate.

## Use it with plans & other skills
- After `writing-plans` / `to-prd` / `to-issues` / a `goal-spec` brief / a `/spec` `tasks.md` — council it before acting.
- It IS the multi-model upgrade of `goal-spec`'s "adversarial pass" and `/spec gate`'s readiness check — call it there when the stakes warrant.
- `adversarial-review` = quick single-Gemini check; `review-council` = the full panel. Use the council when a wrong plan is expensive.

## Errors

| Issue | Fix |
|---|---|
| `codex` not on PATH | The script guards with `command -v codex` and skips those personas with a printed note — the council runs partial. Install the Codex CLI (`codex --version`) to restore them. |
| Codex hangs | Each engine call is wrapped in `timeout`/`gtimeout` (300s) when available — install coreutils (`brew install coreutils`) on macOS so the wrapper exists; otherwise a hung engine has no upper bound. |
| Why read-only / no `--yolo`? | **Security, not optional.** The artifact is untrusted; Codex runs `--sandbox read-only -c approval_policy=never` and Gemini drops `--yolo`, so an injected "run this" can't auto-execute. Do not "fix" a stuck run by re-adding full bypass. |
| Gemini persona errors (auth/trust/model 404) | See `adversarial-review`'s error table — `gemini-review.sh` carries the fixes (API-key auth in `~/.gemini/.env`, `--skip-trust`, a live `--model`). |
| Personas all agree too easily | They share an artifact; vary the engines/lenses (edit `PERSONAS`) or add `--focus` on the riskiest area. Agreement on a real flaw is fine; agreement on "looks good" deserves a skeptical re-read. |
| Reviewing a huge diff/spec | Council the highest-risk slice (name what you scoped out), or split — don't feed 10k lines and trust a one-shot verdict. |
