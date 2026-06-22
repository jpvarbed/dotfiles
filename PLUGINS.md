# Installed Tools & Plugins

## Linear CLI

Issue tracking via Linear. Installed as a skill (`schpet/linear-cli`) by setup.sh;
the `linear` binary also runs via `npx @schpet/linear-cli`. Personal todos → team `JAS`.

## Claude Code Plugins

### Add marketplace first

```bash
/plugin marketplace add anthropics/claude-code
```

### Install plugins

```bash
/plugin install ralph-wiggum@claude-code-plugins
/plugin install feature-dev@claude-code-plugins
/plugin install commit-commands@claude-code-plugins
/plugin install agent-sdk-dev@claude-code-plugins
```

## What they do

- **ralph-wiggum**: Runs Claude in loop until task completes
- **feature-dev**: 7-phase feature development workflow with specialized agents
- **commit-commands**: Git workflow commands for committing, pushing, creating PRs
- **agent-sdk-dev**: Development toolkit for Claude Agent SDK

## Artifact Studio — share-artifact

Agent-native app host (repo `~/dev/artifact-share`, github `jpvarbed/artifact-share`). Any agent in
any project can publish an app → public URL `https://artifacts.jasonv.dev/<slug>/`.

- **Skill:** `skills/engineering/share-artifact/` (auto-linked into `~/.claude/skills` by setup.sh).
  Fetches `ARTIFACT_API_KEY` + `ARTIFACT_API_BASE` from bws on demand; drives the CLI at
  `~/dev/artifact-share/apps/cli/src/index.ts` (`share` | `deploy` | `backend` | `list/get/delete`).
- **MCP server:** `~/dev/artifact-share/apps/mcp` (tools `publish_artifact`, `deploy_app`,
  `provision_backend`, `list/get/delete_artifact`); env `ARTIFACT_API_BASE` + `ARTIFACT_API_KEY`.
- **Key:** durable agent key in bws as `ARTIFACT_API_KEY` (owner `jpvarbed`); base in `ARTIFACT_API_BASE`.
  All agent-published apps are owned by `jpvarbed` — manage via `artifact list` or studio.artifacts.jasonv.dev.

## Focus — timer + attention orchestrator

Server-owned Pomodoro **and** a cross-project agent fleet at `https://focus.jasonv.dev`. App repo
`~/dev/focus-timer` (private; Convex backend + Vite SPA). Tools repo `~/dev/focus-timer-tools`
(public, github `jpvarbed/focus-timer-tools`). The fleet lets any agent report its status, ask Jason
a question, and log decisions; Jason sees who's working / who needs him / what was decided on the board.

- **Skill:** `focus-timer` (in `focus-timer-tools/skills/focus-timer/`; install with
  `npx skills add jpvarbed/focus-timer-tools`). Covers the timer + fleet.
- **CLI:** `focus` (`focus-timer-tools/cli`) — timer (`status`/`start`/`pause`/`resume`/`skip`/`reset`/
  `stats`/`watch`) + fleet (`fleet`, `report agent= project= [state=] [task=]`, `ask agent= [severity=] "q"`).
  Env: `FOCUS_USER_ID` (your account id) + optional `CONVEX_URL` (defaults to prod).
- **MCP:** hosted `https://mcp.jasonv.dev/api/mcp` (pass your id in the `x-focus-user` header), or local
  stdio (`mcp/src/stdio.ts`). 11 tools: timer (`focus_status/start/pause/resume/skip/reset/stats`) +
  **fleet** (`focus_report`, `focus_ask`, `focus_event`, `focus_fleet`). Registered with ARD at
  `focus.jasonv.dev/.well-known/ai-catalog.json`.
- **Identity:** `FOCUS_USER_ID` = the web app's `focus_user_id` cookie (the access capability — no bws
  key). Use the same id to drive the same fleet/timer the web shows. Convex prod
  `perceptive-butterfly-406`, dev `vivid-ant-124`.
