# Skill reference

Skill collections I pull from, with their git sources and local clones. Add a row
when I start using a new one. (My own skills live alongside this in `skills/`.)

| Collection | Git | Local clone | What / why |
|---|---|---|---|
| **Superpowers** | https://github.com/obra/superpowers | `~/dev/superpowers` + installed as a Claude Code plugin at `~/.claude/plugins/marketplaces/superpowers-dev` | TDD / debugging / brainstorming / writing-plans / subagent-driven-dev + hooks. The process backbone. |
| **mattpocock/skills** | https://github.com/mattpocock/skills | `~/dev/mattpocockskills` | Engineering workflow: `grill-me`, `to-issues`, `to-prd`, `triage`, `handoff`, `prototype`, `diagnose`, `zoom-out`. Small, composable. |
| **Convex agent-skills** | https://github.com/get-convex/agent-skills | `~/dev/agent-skills` | Building on Convex: `convex`, `convex-quickstart`, `convex-create-component`, `convex-setup-auth`, `convex-migration-helper`, `convex-performance-audit`. |
| **Convex backend-skill** | https://github.com/get-convex/convex-backend-skill | `~/dev/convex-backend-skill` | Convex backend `design` + `quickstart`. Pair with agent-skills when evaluating/using Convex (e.g. the prompt-lab storage spike, ADR-002). |

## Install / update

- **Superpowers + mattpocock** are installed into projects via
  `pnw-golf-ai/scripts/setup-skills.sh` (clones + registers the plugin). Re-run to
  update. mattpocock can also be installed with `npx skills@latest add mattpocock/skills`.
- **Convex** skills: clone the repo, then point your agent's skills dir at its
  `skills/` (or copy the ones you want). Auth needs `CONVEX_PAT` (in Bitwarden SM
  project `pnw-golf-ai`; backup in `~/dev/.env.local`).
- **My own skills** (this folder): each is `skills/<category>/<name>/SKILL.md`.
  - `engineering/adversarial-review` — Gemini-CLI red-team of a plan/spec/diff.

## Convention

Each skill = a dir with `SKILL.md` (YAML frontmatter `name` + `description`, then
the process) plus optional helper scripts. Categories mirror mattpocock's layout
(`engineering`, `productivity`, …).
