---
name: adversarial-review
description: Get a ruthless, INDEPENDENT second-model critique of a plan, spec, ADR, PRD, or diff via the Gemini CLI, then triage the findings (valid vs. re-litigation) and optionally fold them into the specs/issues. Use when the user wants to stress-test a plan with an outside model, "red-team" / "adversarial review" / "poke holes in" a design, or sanity-check before building.
---

# Adversarial Review

Use a *different* model (Gemini, via the `gemini` CLI) as an independent adversary
against your own plan. A second model with no stake in your reasoning catches
assumptions you've gone blind to. Then **triage** its output critically — the
reviewer is often confidently wrong, so every finding is a hypothesis to verify
against the actual artifact, not an instruction to obey.

**Announce at start:** "Using adversarial-review to get an independent critique of <X>."

## When to use

- Before committing to a plan/spec/ADR/PRD that's expensive to get wrong.
- After a `/grill-me` or brainstorming pass, as a final outside check.
- On a diff/PR, to surface bugs and bad assumptions a fresh model would see.

## Process

### 1. Pick the artifacts

Choose the smallest set of files that fully captures the *decisions* — the ADR /
spec / plan / diff, not the whole repo. The reviewer reasons only from what you
feed it, so include the rationale, not just the conclusions.

### 2. Run the review

```bash
skills/engineering/adversarial-review/gemini-review.sh \
  --focus "the specific bets you most want attacked" \
  path/to/ADR.md path/to/tasks.md
```

- `--focus` appends targeted attack instructions (the core bet, the riskiest
  slice, a specific invariant). Strongly recommended — a focused adversary is
  far sharper than a generic one.
- `--model` defaults to `gemini-2.5-pro`. Use `gemini-2.5-flash` for a quick,
  cheap pass.
- The script frames Gemini as a ruthless skeptic, ranks findings
  Critical/High/Medium, and ends with the single biggest risk.

For a noisy/important decision, run it **2–3 times** (or with both pro and flash)
and keep findings that recur — a single run's framing can be idiosyncratic.

### 3. Triage — do NOT trust the output verbatim

The external model has no access to your codebase and will invent gaps that don't
exist. For **each** finding:

- **Verify against the artifact.** Does the thing it claims is missing actually
  exist in a file/slice it wasn't shown? Quote the spec back to yourself.
- **Classify:** `VALID + actionable` / `valid but already covered` /
  `re-litigates a settled decision` / `wrong (reviewer lacked context)`.
- **Keep severity honest** — re-rank if the reviewer over/under-sold it.

Present the triage as a table: finding → verdict → proposed action. Be explicit
about which findings you're acting on vs. rejecting, and why.

### 4. Apply (optional)

For the `VALID + actionable` findings, fold them in: edit the spec/ADR, add or
amend issues on the tracker, or open follow-up tasks. Re-state the settled
decisions you're deliberately NOT reopening so they don't resurface next review.

## Notes

- This is an *independent* perspective, not an authority. Your job is judgment:
  the skill's value is the triage, not the raw critique.
- Keep the artifacts you send free of secrets — it's an external API call.

## Troubleshooting `gemini`

If `gemini` fails with `403 / SUBSCRIPTION_REQUIRED` ("no valid license"), the
CLI is using the OAuth (`oauth-personal`) path, which routes through Gemini Code
Assist and needs a licensed account. Switch it to API-key auth instead:

1. `~/.gemini/settings.json` → `{"security":{"auth":{"selectedType":"gemini-api-key"}}}`
2. `~/.gemini/.env` (chmod 600) → `GEMINI_API_KEY=<a Google AI Studio key>`
   (gemini auto-loads this file from any directory).

A `Token file corrupted` warning is just a bad `~/.gemini/mcp-oauth-tokens-v2.json`
(the MCP token cache) — reset it with `printf '{}' > ~/.gemini/mcp-oauth-tokens-v2.json`.
