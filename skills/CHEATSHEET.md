# Skills cheat sheet — when to use what

The curated set after the skill-audit (72 → ~48). Plugins (superpowers, ponytail)
add the always-on process skills on top; this lists the on-demand ones.

## Design & plan
- **grill-me** — stress-test a plan/design by relentless interview (decision tree).
- **grill-with-docs** — same, but challenged against the project's docs + glossary.
- **prototype** — throwaway prototype to flesh out a design before committing.
- **architect** — sketch types, signatures, module structure before writing code.
- **to-prd** — turn the current conversation into a PRD.
- **to-issues** — break a plan/PRD into independently-grabbable tracker issues.
- **jason-prototype-stack** — stand up a new `<thing>.jasonv.dev` app fast.

## Build & fix
- **tdd** — red-green-refactor for a feature or bugfix.
- **total-tdd** — whole-app audit → test → fix → re-test loop (one canonical CSV).
- **diagnose** — disciplined loop for a hard bug or perf regression.
- **deslop** — strip AI-generated code slop.
- **typescript-best-practices** — when reading/editing `.ts`/`.tsx`.
- **make-interfaces-feel-better** — UI polish, micro-interactions, visual detail.
- **r3f-best-practices** — React Three Fiber / Three.js work.

## Review & verify
- **adversarial-review** — outside model (Gemini) red-teams a plan/spec/diff. Default for anything that matters.
- **review** — review changes since a point (standards + correctness).
- **thermos** — run both thermo-nuclear reviews in parallel, then synthesize.
- **thermo-nuclear-code-quality-review** — extremely strict maintainability/abstraction review.
- **thermo-nuclear-review** — security + correctness audit of a branch.
- **verify-this** — verify a specific claim with fresh local evidence.
- **blast-radius** — find what a change could break beyond the diff.
- **review-and-ship** — review branch, run/write tests, commit, open/update PR.
- **improve-codebase-architecture** — find deepening / refactor opportunities.

## Understand a codebase
- **how** — how does X work / where should this live / which layer owns it.
- **why** — why is X this way / design rationale / regression history.
- **agentic-engineering** — KB on building agentic systems (loops, harnesses, evals).

## PR / CI (GitHub flow)
- **make-pr-easy-to-review** · **get-pr-comments** · **fix-ci** · **loop-on-ci**
- **weekly-review** · **what-did-i-get-done** — summarize authored commits.

## Track & hand off
- **linear-cli** — manage Linear issues (personal todos → team `JAS`).
- **triage** — triage incoming issues through a state machine.
- **handoff** — compact the conversation into a handoff doc for another agent.
- **share-artifact** — publish an app/artifact (SVG, HTML, Markdown, multi-file React) → public URL at `artifacts.jasonv.dev/<slug>/`. Drives the artifact-studio-tools CLI; key from bws.

## Writing
- **writing-fragments** — mine raw nuggets before imposing structure.
- **writing-shape** — shape a pile of notes into an article.
- **writing-beats** — assemble an article as a journey of beats.
- **edit-article** — revise/tighten an existing draft.
- **unslop** — cut AI tells from any writing.

## Meta & utility
- **write-a-skill** — author a new skill (proper structure + progressive disclosure).
- **cli-for-agents** — design CLIs that agents can drive reliably.
- **domain-name-brainstormer** — name ideas + TLD availability.
- **caveman** — ultra-terse output mode. **zoom-out** — step back for higher-level context.
- **obsidian-vault** — Obsidian notes. **git-guardrails-claude-code** / **setup-pre-commit** — repo setup.
