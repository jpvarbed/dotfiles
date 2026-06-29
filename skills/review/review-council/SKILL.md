---
name: review-council
description: Convene a multi-model, multi-persona review council to grade a Claude-authored plan, spec, tasks list, design, PRD, or diff before it's acted on. Runs ≥3 distinct personas (Architect / Pragmatist / Verifier) across TWO independent outside engines — Codex (`codex exec`, yolo) and Gemini — then synthesizes a consensus PASS/CONCERNS/FAIL verdict + a deduped must-fix list. Use when the user says "review council", "have codex + gemini grade this", "council-review the plan", or before dispatching a plan to /goal or implementing a /spec. Heavier than adversarial-review (which is a single Gemini pass) — reach for the council when the work matters.
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
```
Run: `skills/review/review-council/council.sh [--focus "<area>"] <artifact-file>`

## The council (≥3 personas across 2 engines)
Both engines are used so a finding's strength reflects model diversity, not just one model's quirks.

| Persona | Engine | Lens |
|---|---|---|
| **Architect** | Codex | Soundness — will it actually work? hidden assumptions, missing cases, failure modes, wrong abstractions. |
| **Pragmatist** | Gemini | YAGNI & cost — over-engineered? simpler path? scope creep? effort justified by value? |
| **Verifier** | Codex | Verifiability & risk — is each step's done-condition checkable? irreversible/blast-radius risks? could success be reward-hacked? |

Edit the `PERSONAS` array in `council.sh` to rebalance or add a 4th (e.g. a **Risk/Security** persona on Gemini). Each persona returns the same fixed shape: `VERDICT` + ≤3 ranked findings (`[H|M|L] claim — why — fix`) + biggest risk.

## Step 1 — Run the council
Invoke `council.sh` on the artifact. It runs each persona on its engine (`codex exec --dangerously-bypass-approvals-and-sandbox` = yolo; Gemini via the sibling `gemini-review.sh`) and prints each persona's block. Engines run independently — if one fails (auth/CLI), the others still produce a partial council; note the gap, don't silently drop it.

## Step 2 — Synthesize (Claude) → the output contract
Read all persona blocks and produce ONE report:

```
COUNCIL VERDICT: PASS | CONCERNS | FAIL
GATE: proceed | revise-then-proceed | stop
MUST-FIX (deduped, ranked):
  - [H|M|L] <finding>  (raised by: Architect, Verifier)   ← agreement = higher confidence
PER-PERSONA: Architect <verdict> · Pragmatist <verdict> · Verifier <verdict>
```

**Verdict rule (deterministic):**
- **FAIL** if any persona returns FAIL on a High-severity issue → GATE: stop.
- **CONCERNS** if any High/Medium findings remain (no blocking FAIL) → GATE: revise-then-proceed.
- **PASS** if all personas PASS or only Low findings remain → GATE: proceed.

Dedupe findings across personas (the same issue from two personas is higher-confidence, list it first). Triage like `adversarial-review`: drop findings that re-litigate a settled decision or invent gaps not in the artifact — say why you dropped them. LLM-judged, so it's a strong signal, not a certificate.

## Use it with plans & other skills
- After `writing-plans` / `to-prd` / `to-issues` / a `goal-spec` brief / a `/spec` `tasks.md` — council it before acting.
- It IS the multi-model upgrade of `goal-spec`'s "adversarial pass" and `/spec gate`'s readiness check — call it there when the stakes warrant.
- `adversarial-review` = quick single-Gemini check; `review-council` = the full panel. Use the council when a wrong plan is expensive.

## Errors

| Issue | Fix |
|---|---|
| `codex` not on PATH | Install the Codex CLI (`codex --version` to confirm); without it the Codex personas are skipped — run gemini-only and note the reduced council. |
| Codex hangs or asks to act on the repo | The prompt says review-only; it runs with `--dangerously-bypass-approvals-and-sandbox` so there are no prompts. If it tries repo work, tighten the persona prompt or use `--sandbox read-only`. |
| Gemini persona errors (auth/trust/model 404) | See `adversarial-review`'s error table — `gemini-review.sh` carries the fixes (API-key auth in `~/.gemini/.env`, `--yolo --skip-trust`, a live `--model`). |
| Personas all agree too easily | They share an artifact; vary the engines/lenses (edit `PERSONAS`) or add `--focus` on the riskiest area. Agreement on a real flaw is fine; agreement on "looks good" deserves a skeptical re-read. |
| Reviewing a huge diff/spec | Council the highest-risk slice (name what you scoped out), or split — don't feed 10k lines and trust a one-shot verdict. |
