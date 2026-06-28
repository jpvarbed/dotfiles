---
name: determinize-refactor
description: Analyze a prompt-heavy skill and produce a migration plan to move instructions out of the prompt into scripts and structured contracts — improving reliability and cutting token cost. "Script mode." Use when a skill is verbose/flaky, when you want deterministic behavior instead of model judgment, or to estimate token savings from refactoring a skill.
---

# determinize-refactor (script mode)

Take a prompt-heavy skill and produce a **prioritized migration plan** that moves
everything that *can* be deterministic out of the prose and into **scripts** or
**structured contracts** — leaving the prompt to carry only genuine human judgment.
Fewer tokens, less variance, more reliable runs.

> v1, reconstructed from reference screenshots (`~/Downloads/IMG_9545–9548`). Refine
> against the originals; the classification + plan structure are faithful.

## Input
A plugin path, a skill dir, or a single `SKILL.md`. **Ask for the target scope before
continuing** if ambiguous.

## Step 1 — Read the prompt corpus
Read the SKILL.md (and references). Inventory every instruction/step.

## Step 2 — Classify each instruction
- **→ Script** — deterministic operations: validation, formatting, file ops, parsing,
  calculations, fixed sequences. These are the biggest wins: move to a bundled script the
  skill *calls*, so the model runs a command instead of reasoning through steps.
- **→ Structured contract** — fixed mappings, formulas, output templates, API-call specs,
  enums, thresholds. Encode as data/schema/templates, not prose.
- **→ Keep as prose** — genuine judgment: interpretation, ambiguous decisions, context the
  model must weigh. Don't determinize what actually needs a brain.

## Step 3 — Migration plan
Produce a ranked plan (highest reliability/token win first). For each item: what moves,
to a script or a contract, and the rough token saving. Offer two levels:
- **Conservative** — move only clearly-deterministic ops; lowest risk.
- **Aggressive** — also structure the borderline cases; maximum savings, more upfront work.

End with an **estimated total token reduction** (conservative vs aggressive) and the first
3 refactors to do. Pairs with `linting-and-scoring` (score first, then determinize the
keepers) and `cli-for-agents` (design the scripts agent-friendly).
