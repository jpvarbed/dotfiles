# Papers — skill & agent construction

Curated research for building skills/agents: harnesses, reliability, evaluation,
context/token engineering, instruction-following, tool use. Add a paper when it's
worth remembering; one line on *why it matters to us*.

(The broader personal reading list lives in the encrypted `agentic-engineering` KB;
this is the public, skill/agent-construction subset.)

## Instruction following & hierarchy
- **Many-Tier Instruction Hierarchy in LLM Agents (ManyIH)** — Zhang et al., JHU, Apr 2026.
  Agents must resolve conflicting instructions from many sources; with predefined fixed
  hierarchies frontier models hit only **~40% accuracy at 12 tiers** (vs >99% at 2).
  Proposes dynamically-instantiated privilege levels. → Directly maps to our layered
  instructions (soul.md global → project guide → skill → user → tool); conflict
  resolution across layers is an unsolved, real failure mode.
  https://arxiv.org/html/2604.09443v3
- **Offscript: Automated Auditing of Instruction Adherence in LLMs** — Clark et al., UW, Dec 2025.
  An **agentic auditor** LLM generates test queries to detect instruction-following
  violations (flagged 84.6%, 22.2% material on 65 custom instructions). → Pairs with
  `linting-and-scoring` + the verification ethos: auto-audit whether a skill/agent
  actually obeys its own instructions.
  → **applied:** Adherence-audit pass added to `meta/linting-and-scoring` (behavioral, generates
  adversarial test queries per instruction) via `meta/apply-paper`; JAS-22.
  https://arxiv.org/html/2512.10172v1

## Harnesses, reliability & evaluation
- **From Failed Trajectories to Reliable LLM Agents: Diagnosing and Repairing Harness Flaws (HarnessFix)** — Chen et al., Jun 2026.
  Drives harness repair from trace-grounded failure diagnoses: normalizes execution traces, attributes
  failures to a **7-layer harness taxonomy (ETCLOVG** — Execution, Tooling, Context, Lifecycle,
  Observability, Verification, Governance**)**, then applies scoped, regression-validated repairs;
  **+15–50%** held-out across four benchmarks, beating prompt-only evolution and human-designed harnesses.
  → A concrete framework for debugging *our* skills/harnesses: classify a failure by layer before
  patching, and prefer scoped edits over broad prompt rewrites. Pairs with `linting-and-scoring`.
  https://arxiv.org/html/2606.06324v1
- **Beyond pass@1: A Reliability Science Framework for Long-Horizon LLM Agents** — Khanal, Tao, Zhou, Mar 2026.
  pass@1 on short tasks is "structurally blind" to long-horizon reliability; capability and reliability
  rankings diverge at length, with frontier models showing **meltdown rates up to 19%**. Argues for
  reliability-specific metrics over single-shot capability scores. → Reinforces our verifiability-first
  ethos: a skill passing once ≠ reliable; measure consistency across long runs, not one green checkmark.
  https://arxiv.org/pdf/2603.29231
