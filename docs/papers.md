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
  https://arxiv.org/html/2512.10172v1
