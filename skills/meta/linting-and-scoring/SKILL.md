---
name: linting-and-scoring
description: Lint and score a skill against a 40-check binary decomposed rubric across 11 categories (description, steps, code, error handling, env detection, tests, verification, docs, scope, interaction, cross-harness), then a pass-rate → tier verdict. Use when the user says "lint this skill", "score this skill", "review this skill", "lint and score", or "audit the skill library". NOT for live end-to-end behavior testing (use a runtime eval harness) or for general code review (use "review"). Pairs with determinize-refactor and writing-great-skills.
---

# Linting & scoring a skill (binary decomposed rubric)

Score a skill against **40 binary pass/fail checks across 11 categories**. Each check is
phrased so two reviewers reach the same verdict — no vibes. Mark a check (or a whole
category) **N/A** only when the rule genuinely doesn't apply, and exclude N/A from the
denominator.

## Input
`Path:` $ARGUMENTS — a SKILL.md, a skill dir, or a plugin dir. If none provided, ask for the
skill directory path.

## Step 1 — Read the skill
1. Read `SKILL.md` in the target directory.
2. Read all files in `references/` if present.
3. List all files in `scripts/` if present.
4. Read `test*.py` files to assess test quality.

Cite the specific text from `SKILL.md` as evidence for each check.

## Step 2 — Evaluate (mark each PASS / FAIL / N/A with a one-line reason)

### Description & triggers (5)
1. Description contains ≥3 trigger phrases in quotes.
2. Description contains a negative ("Use when… NOT when…", or "For X use Y instead").
3. Description includes both purpose and triggers.
4. Description is < 1024 characters.
5. Description names sibling skills by name (not just "use another skill").

### Step structure (5)
1. Steps are numbered (`## Step N` or a numbered list), not bulleted.
2. Each step has a single clear objective (not multiple actions combined).
3. Steps include concrete commands (not vague descriptions like "process the data").
4. Steps include a verification/confirmation mechanism.
5. Steps follow a logical order (gather context before processing, validate before shipping).

### Code examples (3)
1. Contains ≥1 concrete, copy-pasteable code block (not pseudocode).
2. Code blocks show actual commands/calls, not templates (not "{placeholder}" only).
3. Examples match the skill's `allowed-tools` (no Bash command shown if Bash isn't allowed).

### Error handling (4) «CRITICAL»
1. An error-recovery table exists (markdown table with `| Issue/Error | Fix |` columns).
2. The table covers ≥3 distinct failure modes (not a generic "something went wrong").
3. Each failure mode has a concrete fix action (not "check the logs" or "try again").
4. ≥1 failure covers tool/MCP unavailability or auth issues.

### Environment detection (4)
1. If it references OS-specific deps (e.g. `brew`, `launchctl`, `screencapture`), it has a platform guard.
2. If it behaves differently per repo type, it has repo-detection logic.
3. If it uses external CLIs, detection is end-to-end (actually runs the tool and checks output, not just "command exists").
4. If it's cross-platform, repo-agnostic, and uses no external CLIs → mark all 4 PASS (N/A).

### Test coverage (3)
1. Every `.py` script in `scripts/` has a corresponding `test_*.py`.
2. ≥1 test confirms success (output check, file exists, assertion passes).
3. If there's no `scripts/` directory → mark all 3 PASS (N/A).

### Verification steps (3)
1. SKILL.md has a way to confirm success (output check, file exists, test passes).
2. Destructive/irreversible actions require a confirmation before execution.
3. The final output format is specified (table, markdown, file path, etc.).

### Documentation & references (3)
1. SKILL.md body is under 500 lines (detail lives in `references/`).
2. Referenced files (`references/*.md`) actually exist on disk.
3. Frontmatter uses only allowed fields (`name`, `description`, `allowed-tools`, `argument-hint`, `license`, `compatibility`, `metadata`).

### Scope & reusability (3)
1. Clear scope boundary — what it does AND what it explicitly does not do.
2. Not hardcoded to a single service/repo/team — parameterized or configurable.
3. MCP tool names are fully qualified (e.g. `mcp__server__tool`).

### User interaction (3)
1. Asks the user for input/confirmation at least once (not fully autonomous with no guardrails).
2. Presents options/findings before taking destructive actions.
3. Gives enough context for the user to decide (not just "Proceed? Y/N").

### Cross-harness compatibility (4)
1. MCP calls have a fallback for when the agent CLI isn't on PATH (web/cloud harnesses).
2. Polling/waiting uses bounded loops with an explicit max-attempts (no unbounded `while true`).
3. Noise from harness hooks (e.g. a nonzero exit code that some harnesses inject) is documented and handled.
4. If it uses scheduling/monitor tools, it has a fallback for harnesses where those are unavailable.

## Step 3 — Calculate score
```
pass_rate = checks_passed / total_applicable_checks   # exclude N/A from the denominator
```

| Pass rate | Tier | Action |
|---|---|---|
| ≥ 90% | Ship Ready | All critical checks pass — ready to ship |
| 70–89% | Polish Needed | Fix failing checks, re-eval |
| < 70% | Rethink | Structural issues — consider a redesign |

**Quality gate:** every Error-handling check is «CRITICAL» and must pass regardless of overall
score. If any fails, the skill **cannot** be "Ship Ready" even at ≥90%.

> This rubric is LLM-judged, not ground truth — a consistent quality signal, not a certificate.

## Step 4 — Present results

**Scorecard** (one row per category):

| Category | Checks | Passed | Failed | Failing checks |
|---|---|---|---|---|
| Description & triggers | 5 | … | … | … |
| … | … | … | … | … |
| **Total** | **40** | **X** | **Y** | **pass_rate% — Tier** |

**Failed checks** — for each FAIL: `| Category | Check | Evidence | Fix |`.

**Top 3 recommendations** — the most impactful fixes, specific and actionable.

## Step 5 — Model card (optional)
If `model-card.yaml` exists in the skill dir, append the result:
```yaml
evaluations:
  - eval_type: binary-decomposed
    date: <today>
    score: "X/Y (Z%)"
    tier: <Ship Ready|Polish Needed|Rethink>
```
Also append to `score_history`, and flag **REGRESSION** if the score dropped vs the previous entry.

## Errors

| Issue | Fix |
|---|---|
| No path given | Ask the user for the skill directory before scoring. |
| Target has no `scripts/` | Mark Test coverage (3) N/A — don't fail it. |
| Can't tell if a check passes | Default to FAIL and note the ambiguity; binary means no benefit of the doubt. |
| Skill targets one harness only | Score Cross-harness against that harness; note reduced portability in recommendations. |
