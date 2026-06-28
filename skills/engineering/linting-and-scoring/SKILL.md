---
name: linting-and-scoring
description: Lint and score a skill against a binary decomposed rubric — unambiguous pass/fail checks across ~11 categories, then a pass-rate → tier → action verdict. Use when reviewing a skill's quality, deciding whether a new/edited skill is good enough, or auditing the skill library. Two reviewers should reach the same verdict.
---

# Linting & scoring a skill (binary decomposed rubric)

Score a skill with **binary pass/fail checks** across the categories below. Each
check is phrased so two reviewers reach the same verdict — no vibes. Skip a whole
category as **N/A** when it genuinely doesn't apply.

> v1, reconstructed from reference screenshots (`~/Downloads/IMG_9541–9544`). Refine
> the exact checks against the originals; the structure + scoring are faithful.

## Input
`Path:` $ARGUMENTS — a SKILL.md, a skill dir, or a plugin dir.

## Step 1 — Read the skill
Read `SKILL.md`, any reference files, and any scripts in the target. Cite the specific
text for each check as evidence.

## Step 2 — Evaluate (binary checks; mark PASS / FAIL / N/A with a one-line reason)

**Description & triggers** — does the `description` say what it does AND when to use it
(concrete trigger phrases/keywords)? Third person? ≤1024 chars? Distinct from sibling skills?

**Structure** — `SKILL.md` present + valid frontmatter (`name`, `description`)? Under ~100
lines (else split via progressive disclosure)? Consistent terminology? Concrete examples?

**Environment detection** — does it detect/declare its prerequisites (tools, runtime, auth)
rather than assume them? Fails loudly if a dependency is missing?

**Test coverage** — non-trivial logic leaves a runnable check (demo/self-test)? Claims are
verifiable, not asserted?

**Verification steps** — does it require evidence before "done" (run it, show output) rather
than claim success?

**Documentation & references** — bundled content correct + one-level-deep? Links resolve?
No stale/time-sensitive facts?

**Reusability** — works from any project / not hardcoded to one repo? Parameters over magic
values?

**User interaction** — clear inputs, sensible defaults, doesn't block on the human for
reversible work?

**Cross-harness compatibility** — avoids tool names/assumptions specific to one agent where
it doesn't need them? Degrades gracefully?

(Add categories the source rubric lists; keep every check binary.)

## Step 3 — Score
```
pass_rate = checks_passed / total_applicable_checks   # skip N/A categories
```
Map to a tier + action:

| Pass rate | Tier | Action |
|---|---|---|
| ≥ 0.9 | Ship | use as-is |
| 0.75–0.9 | Polish | fix the failed checks, then ship |
| 0.5–0.75 | Rework | structural gaps — revise before relying on it |
| < 0.5 | Reject | rebuild or cull |

Output: the per-category checklist (PASS/FAIL/N/A + reason), the pass rate, the tier, and
the top 3 fixes. Pairs with `determinize-refactor` (make a passing skill cheaper/more
deterministic) and `writing-great-skills`.
