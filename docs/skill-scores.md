# Own-skill lint scores

Scored with `meta/linting-and-scoring` (40-check binary rubric, CRITICAL error-handling gate).
LLM-judged, not ground truth — expect ±a few points of judge variance. Snapshot: 2026-06-28.

## After the error-table sweep + total-tdd determinize

| skill | before | after | tier | gate |
|---|---|---|---|---|
| adversarial-review | 91% | **97%** | Ship Ready | ✓ |
| env-status-board | 72% | **91%** | Ship Ready | ✓ |
| visual-critique | 69% | 88% | Polish | ✓ |
| total-tdd | 68% | 83% | Polish | ✓ (+ tested scripts → Test coverage 3/3) |
| jason-prototype-stack | 59% | 82% | Polish | ✓ |
| share-artifact | 71% | 73% | Polish | ✓ (was gate-blocked) |
| focus-timer | 59% | 71% | Polish | ✓ |
| mcp-dev | 65% | 68% | Rethink | ✓ |

All 8 now pass the CRITICAL error-handling gate (was 0/8). `mcp-dev` stays sub-70 because it's a
conceptual pattern doc (no concrete command block / output artifact), not an error-handling gap.

## Common remaining gaps (the path to Ship Ready)
- Descriptions missing a **negative** ("NOT when…") and **sibling-skill names**.
- MCP tools not written in fully-qualified `mcp__server__tool` form.
- A few destructive actions (e.g. `delete <slug>`) lack a confirmation gate.

## Not separately scored
The other own skills — `goal-spec`, `linting-and-scoring`, `determinize-refactor` (meta),
`agentic-engineering` (KB), `caveman` (output mode), `writing-hooks` (voice) — are non-procedural;
the rubric fits them loosely, so their scores reflect category-mismatch more than real debt.
