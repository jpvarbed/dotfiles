# Skill reference

Skill collections I pull from, with their git sources and local clones. Add a row
when I start using a new one. (My own skills live alongside this in `skills/`.)

| Collection | Git | Local clone | What / why |
|---|---|---|---|
| **Superpowers** | https://github.com/obra/superpowers | `~/dev/superpowers` + installed as a Claude Code plugin at `~/.claude/plugins/marketplaces/superpowers-dev` | TDD / debugging / brainstorming / writing-plans / subagent-driven-dev + hooks. The process backbone. |
| **mattpocock/skills** | https://github.com/mattpocock/skills | `~/dev/mattpocockskills` | Engineering workflow: `grill-me`, `to-issues`, `to-prd`, `triage`, `handoff`, `prototype`, `diagnose`, `zoom-out`. Small, composable. |
| **Convex agent-skills** | https://github.com/get-convex/agent-skills | `~/dev/agent-skills` | Building on Convex: `convex`, `convex-quickstart`, `convex-create-component`, `convex-setup-auth`, `convex-migration-helper`, `convex-performance-audit`. |
| **Convex backend-skill** | https://github.com/get-convex/convex-backend-skill | `~/dev/convex-backend-skill` | Convex backend `design` + `quickstart`. Pair with agent-skills when evaluating/using Convex (e.g. the prompt-lab storage spike, ADR-002). |
| **ponytail** | https://github.com/DietrichGebert/ponytail | `~/dev/ponytail` + Claude Code plugin (`ponytail@ponytail`) | "Lazy senior dev" — forces the minimal solution that works (YAGNI, stdlib-first). Skills: `ponytail`, `-review`, `-audit`, `-debt`. Needs `node` on PATH. |
| **cursor/plugins** | https://github.com/cursor/plugins | `~/dev/plugins` | Cursor's marketplace (`.cursor-plugin`, *not* a CC marketplace), so I cherry-pick individual skills. Curated set in [`external-skills.list`](./external-skills.list): thermos quality-review, pstack principles, cursor-team-kit PR/CI flow, orchestrate/continual-learning. |

## Install / update

The canonical bootstrap is **`~/dev/dotfiles/scripts/setup.sh`** (idempotent):
it clones the collections below into `~/dev/*` if missing, links mattpocock skills
into `~/.claude/skills` via `link-skills.sh`, and registers the superpowers plugin
marketplace. Re-run it to pull a new machine into sync.

- **mattpocock** — `~/dev/mattpocockskills/scripts/link-skills.sh` symlinks each
  skill into `~/.claude/skills/<name>` (flattening the category folders, skipping
  `deprecated/`). Re-run after `git pull`. (`npx skills@latest add mattpocock/skills`
  also works for per-project installs.)
- **Superpowers** — installed as a Claude Code plugin (marketplace
  `~/.claude/plugins/marketplaces/superpowers-dev`). Add with
  `/plugin marketplace add obra/superpowers` in Claude Code.
- **ponytail** — installed as a Claude Code plugin. In Claude Code:
  `/plugin marketplace add DietrichGebert/ponytail && /plugin install ponytail@ponytail`
  (enabled in `.claude/settings.json`). Needs `node` on PATH for its hooks.
- **cursor/plugins** — curated symlinks. setup.sh reads
  [`external-skills.list`](./external-skills.list) and links each listed
  `SKILL.md` dir into `~/.claude/skills`. Edit that file to add/remove skills,
  then re-run setup.sh (or `link-skills.sh`-style: `ln -sfn`).
- **Convex** skills: clone the repo, then point your agent's skills dir at its
  `skills/` (or copy the ones you want). Auth needs `CONVEX_PAT` (in Bitwarden SM
  project `pnw-golf-ai`; backup in `~/dev/.env.local`).
- **My own skills** (this folder): each is `skills/<category>/<name>/SKILL.md`,
  symlinked into `~/.claude/skills` by setup.sh.
  - `engineering/adversarial-review` — Gemini-CLI red-team of a plan/spec/diff.
  - `engineering/goal` — whole-app audit→test→fix loop; one canonical feature-audit CSV.
  - `engineering/jason-prototype-stack` — recipe to ship a new `<thing>.jasonv.dev` app fast
    (bun + Vite/React SPA + Convex + Vercel + Squarespace DNS); built from focus-timer.
  - `knowledge/agentic-engineering` — reading-list KB curator (encrypted; see README).

Secrets (`~/dev/.env.local` → bws → age key → `soul.md.age` / `knowledge.tar.age`)
are handled by `setup.sh`; see the top-level [`README.md`](../README.md).

## Convention

Each skill = a dir with `SKILL.md` (YAML frontmatter `name` + `description`, then
the process) plus optional helper scripts. Categories mirror mattpocock's layout
(`engineering`, `productivity`, …).
