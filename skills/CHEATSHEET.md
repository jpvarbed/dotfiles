# Skills cheat sheet — when to use what

The on-demand skills: 19 of my own (full inventory + sources in [`skill-reference.md`](./skill-reference.md))
plus the curated external sets. Plugins (superpowers, ponytail) add the always-on process skills on
top; this is the *when-to-use-what* index.

## Design & plan
- **grill-me** — stress-test a plan/design by relentless interview (decision tree).
- **grill-with-docs** — same, but challenged against the project's docs + glossary.
- **prototype** — throwaway prototype to flesh out a design before committing.
- **architect** — sketch types, signatures, module structure before writing code.
- **domain-modeling** — pin down domain terminology / ubiquitous language + record ADRs.
- **codebase-design** — deep-module design vocabulary; where seams go, testability.
- **to-prd** — turn the current conversation into a PRD.
- **to-issues** — break a plan/PRD into independently-grabbable tracker issues.
- **jason-prototype-stack** — stand up a new `<thing>.jasonv.dev` app fast.

## Build & fix
- **tdd** — red-green-refactor for a feature or bugfix.
- **total-tdd** — whole-app audit → test → fix → re-test loop (one canonical CSV).
- **diagnosing-bugs** — disciplined loop for a hard bug or perf regression.
- **implement** — implement a piece of work from a PRD or set of issues.
- **deslop** — strip AI-generated code slop.
- **typescript-best-practices** — when reading/editing `.ts`/`.tsx`.
- **make-interfaces-feel-better** — UI polish, micro-interactions, visual detail.
- **r3f-best-practices** — React Three Fiber / Three.js work.
- **openrouter** — call any LLM (gpt/gemini/llama/deepseek…) via OpenRouter's one-key OpenAI-compatible gateway; cheap/free model routing + non-Claude second opinions. Key from bws. (gemini-CLI *critiques* → `adversarial-review` instead.)
- **mcp-dev** — build/extend an agent product across one backend → CLI + MCP + skill (the private-service + public-tooling split); keep the surfaces in sync.

## Review & verify
- **adversarial-review** — outside model (Gemini) red-teams a plan/spec/diff. Quick single-model check.
- **review-council** — harness-as-judge (deterministic checks + repo gates) + multi-model (Codex `exec` + Gemini) × ≥3 personas grade a plan/spec/tasks → consensus PASS/CONCERNS/FAIL + deduped must-fix. The heavy upgrade of adversarial-review; use before `/goal` dispatch or implementing a `/spec`.
- **visual-critique** — 3-run majority-vote Gemini critique of a rendered image / 3D pose / UI (kills single-run hallucination). Use to verify a render/figure/screenshot looks right.
- **review** — review changes since a point (standards + correctness).
- **thermos** — run both thermo-nuclear reviews in parallel, then synthesize.
- **thermo-nuclear-code-quality-review** — extremely strict maintainability/abstraction review.
- **thermo-nuclear-review** — security + correctness audit of a branch.
- **verify-this** — verify a specific claim with fresh local evidence.
- **blast-radius** — find what a change could break beyond the diff.
- **review-and-ship** — review branch, run/write tests, commit, open/update PR.
- **improve-codebase-architecture** — find deepening / refactor opportunities.

## Verify in the real app
- **agent-browser** — drive a real browser (navigate, fill, click, screenshot, console/network). Cross-agent UI verifier; powers `/total-tdd`'s test phases.
- **portless** — stable `https://<name>.localhost` dev URLs. One-time per machine: `portless service install` (auto-starts the proxy at boot; sudo). Then just run `portless` instead of `npm run dev`. Worktrees: `portless run` auto-prefixes the branch as a subdomain (`feat-x.golf.localhost`) so main + feature worktrees run side-by-side; explicit `portless <name> …` skips the prefix.
- **emulate** — offline stateful fakes of Stripe/GitHub/Google/AWS… to verify API-integration code with no network or keys.

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
- **share-artifact** — publish an app/artifact (SVG, HTML, Markdown, multi-file React) → public URL at `<slug>.jasonv.app`. Drives the artifact-studio-tools CLI; key from bws.

## Writing
- **writing-fragments** — mine raw nuggets before imposing structure.
- **writing-shape** — shape a pile of notes into an article.
- **writing-beats** — assemble an article as a journey of beats.
- **edit-article** — revise/tighten an existing draft.
- **avoid-ai-writing** — the de-AI editor: deterministic detector (0–100 score + flags), rewrite/detect/edit modes, voice profiles. Won the bake-off vs `unslop` (culled).
- **writing-hooks** — Jason's voice for tweets/threads/hooks (plain, finding-first); catches the tells avoid-ai-writing + the motion hook skills miss. Pair when drafting/cleaning a tweet or hook.

## Marketing / copy  (motion-creative)
- **hook-writing** — high-converting hooks for ads / TikTok / Reels / organic.
- **hook-voice-patterns** — swipe file of native scroll-stopping hook templates.
- **hook-tactics** — 35+ hook/headline tactic types (which frame to use when).
- **ad-concept-generator** — turn a hook/idea into a full paid-social ad concept.
- **ugc-scriptwriter** — UGC / creator / testimonial scripts for paid social.

## Data & analysis  (knowledge-work)
- **analyze** — answer a data question, from a quick lookup to a full report (golf/finance data).
- **explore-data** — profile a new dataset: shape, nulls, distributions, quality issues.
- **statistical-analysis** — trends, outliers, correlations, significance tests.
- **build-dashboard** — interactive self-contained HTML dashboard (KPI cards, charts, filters).
- **data-visualization** — publication-quality charts in Python (matplotlib/seaborn/plotly).

## Design / UI  (knowledge-work)
- **design-critique** — structured feedback on usability, hierarchy, consistency (Figma/screenshot).
- **accessibility-review** — WCAG 2.1 AA audit (contrast, keyboard nav, target size, screen readers).
- **ux-copy** — microcopy: button labels, error messages, empty states, confirmations. (Pairs with `make-interfaces-feel-better` under Build & fix.)

## Meta & utility
- **writing-great-skills** — author/edit skills well (structure + progressive disclosure).
- **linting-and-scoring** — score a skill against a binary pass/fail rubric → tier + top fixes.
- **determinize-refactor** — plan to move a skill's prose into scripts/contracts (script-mode; cut tokens + variance).
- **goal-spec** — compile a rough task into a launch-ready `/goal` brief: verifiability gate → context-access + verification-plan + binary rubric → adversarial pass. Use before dispatching agents.
- **apply-paper** — turn a research finding (docs/papers.md) into a concrete skill/agent change: claim → where-it-applies → change → before/after proof. Closes capture→shipped.
- **instruction-conflicts** — audit the layered instruction stack (user → soul.md → project → skill → tool) for contradictions + make precedence explicit. Use when layers may clash or the agent ignores a rule.
- **cli-for-agents** — design CLIs that agents can drive reliably.
- **domain-name-brainstormer** — name ideas + TLD availability.
- **env-status-board** — "where are we": 3-column status board (shipped / open Linear JAS / blocked-on-you) of the dotfiles+skills+env work, rendered with the viz tool.
- **caveman** — ultra-terse output mode (own skill; upstream dropped it).
- **gap-briefing** — catch up on what changed since the model's cutoff, filtered through Jason's projects → ranked, sourced, visual intel briefing ("what did I miss").
- **focus-timer** — report into the cross-project agent fleet / drive the focus.jasonv.dev Pomodoro timer (works from any project; CLI + MCP).
- **resolving-merge-conflicts** — resolve an in-progress git merge/rebase conflict.
- **obsidian-vault** — Obsidian notes. **git-guardrails-claude-code** / **setup-pre-commit** — repo setup.
