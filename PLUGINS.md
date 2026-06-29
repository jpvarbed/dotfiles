# Installed Tools & Plugins

## Arize — LLM/agent observability (tracing)

Trace everything we ship so we can SEE what agents do, then run the
**detect → investigate → fix** loop. Free year of Pro (code `ARIZEAIE2026`).

- **CLI:** `ax` (v0.25+), installed by setup.sh via `uv tool install arize-ax-cli`.
  Auth + profile live in `~/.arize/profiles/default.toml` (API key, NOT in this
  repo). Verify: `ax --version && ax profiles show && ax spaces list`.
- **Skills (12):** `arize-instrumentation` (add tracing from scratch),
  `arize-trace` (export/investigate spans+sessions), `arize-evaluator`,
  `arize-experiment`, `arize-dataset`, `arize-prompt-optimization`,
  `arize-prompts`, `arize-annotation`, `arize-ai-provider-integration`,
  `arize-link`, `arize-compliance-audit`, `arize-admin`. Installed globally by
  setup.sh (`skills add Arize-ai/arize-skills --skill "*" -g -y`) and symlinked
  into `~/.claude/skills`. The `-g` step logs "PromptScript does not support
  global skill installation" — **ignore it**, the universal symlinks still land.
- **Space:** `jpvarbed Space` = id `U3BhY2U6NDM1OTg6U3ZpOA==`. Projects already
  sending traces: `bible-chat`, `bible-chat-evals` (pnw-golf-ai coaching RAG).

### Tracing your own Claude Code sessions (the high-leverage one)

Official Arize plugin `claude-code-tracing@coding-harness-tracing` hooks every CC
session and emits **OpenInference spans** to Arize — turn traces, LLM spans (model +
tokens), per-tool spans (Bash/Edit/Read I/O), and subagent spans. Project `claude-code`.

- **Install:** `claude plugin marketplace add Arize-ai/coding-harness-tracing` then
  `claude plugin install claude-code-tracing@coding-harness-tracing`. Hooks auto-register
  via the plugin's `hooks.json`; `run-hook` self-bootstraps a venv on first session
  (pip-installs openinference/arize-otel). Wired into setup.sh §4.
- **Config (non-secret) → `~/.claude/settings.json` `env`:** `ARIZE_PROJECT_NAME`,
  `ARIZE_SPACE_ID`, `ARIZE_TRACE_ENABLED=true`, and `ARIZE_LOG_PROMPTS` /
  `ARIZE_LOG_TOOL_DETAILS` / `ARIZE_LOG_TOOL_CONTENT` (all `true` = full content).
  Set any `ARIZE_LOG_*` to `false` to redact that category.
- **API key — config.yaml fallback (the fix that makes it actually work).** Originally the key
  was injected ONLY by the `claude()` zsh wrapper (off-disk). That **silently dropped most
  sessions** — `resolve_backend` needs `api_key`+`space_id` together, and app-launched /
  cron / pre-existing-shell sessions have no key in env (81× "No backend configured" in
  `~/.arize/harness/logs/claude-code.log`). Fix: `harnesses.claude-code` in
  `~/.arize/harness/config.yaml` carries the `api_key` (600), like codex/cursor. Now EVERY
  session traces regardless of launch path. The `claude()` wrapper still works and **env
  beats config** when present, so wrapper-launched sessions stay "off-disk" — but the disk
  fallback is what guarantees coverage. (Off-disk purity was already moot: same key is in
  config.yaml for codex/cursor + the ax profile.)
- Tracing fails *silently* (session still runs) if creds/venv/network are missing — confirm with
  `ax projects list` (expect `claude-code`) + `ax spans export claude-code --space U3BhY2U6NDM1OTg6U3ZpOA== --days 1 --output-dir .`.
- **Verified 2026-06-29:** a synthetic session produced `Bash` (TOOL) + `Turn 1` (LLM)
  spans in-space. Uninstall: `claude plugin uninstall claude-code-tracing@coding-harness-tracing`.

### Tracing the rest of the fleet (codex, gemini, opencode, cursor)

Same repo, different harnesses via the **interactive** installer
`~/.claude/plugins/marketplaces/coding-harness-tracing/install.sh <harness>` (or the
curl one-liner). All land in the same space, one project per harness. `~/.arize/harness/config.yaml`
is pre-seeded (chmod 600) so the wizard runs prompt-light; the shared core resolves creds
**env-first, then config.yaml** (common.py `resolve_backend`).

**Credential split (deliberate):**
- **Terminal CLIs — `gemini`, `opencode`:** `api_key` OMITTED from config.yaml; injected
  from bws by `_arize_key`/wrapper functions in `.zshrc` (off-disk). The wrapper exports
  ONLY `ARIZE_API_KEY` (not space id) so config-mode supplies the right per-harness project.
- **App/GUI — `codex`, `cursor`:** hooks don't run in a wrapped shell, so `api_key` lives
  in config.yaml (600, in `~/.arize`, gitignored, alongside the ax profile copy).

**Run these once (interactive — needs your TTY):**
```bash
REPO=~/.claude/plugins/marketplaces/coding-harness-tracing
"$REPO"/install.sh gemini
"$REPO"/install.sh opencode
"$REPO"/install.sh codex     # then: start codex, run /hooks, approve arize-hook-codex-*
"$REPO"/install.sh cursor    # optional; GUI
```
Verify each: `ax projects list` shows the project, then `ax spans export <project> --space U3BhY2U6NDM1OTg6U3ZpOA== --limit 10 --output-dir .`.

**Caveats:**
- **codex** CLI is now installed via `brew install codex` (shares `~/.codex` with the app).
  Its tracing is **notify-only** (v2 design — NOT `[[hooks]]`/`/hooks`; that README is stale).
  Codex's `notify` is a single program-with-args, but the installer blindly *appended* its
  hook to the existing computer-use `notify` array → Codex ran the computer-use client with
  the Arize path as a mere argument, so the Arize hook **never executed** (no spans, no
  `codex.log`). Fix: a fan-out wrapper `~/.codex/arize/notify-fanout.sh` that runs BOTH the
  computer-use client (`SkyComputerUseClient turn-ended "$JSON"`) and `arize-hook-codex-notify
  "$JSON"`; `config.toml` `notify` points at the wrapper. Verified: `codex` project + spans
  flowing. Backup at `~/.codex/config.toml.arize-bak.*`. **Durability gap:** re-running
  `install.sh codex` would re-break the notify — re-apply the fan-out wrapper if so.
- **cursor** is a GUI IDE — key on disk (accepted).
- Pre-seeded config.yaml should skip cred prompts; if the wizard still asks, the seed
  didn't take (re-run `setup.sh` or re-seed) — don't type the key into a committed file.

### Gotchas (learned the hard way — save the next agent the round-trips)
- **`ax spans export` won't resolve a project by name** unless you pass `--space`.
  The `ARIZE_SPACE` env var did **not** resolve names for export. Simplest: pass
  the **project ID** + `--space <space-id>` explicitly. The profile TOML has no
  default-space field, so there's nothing to persist — use the IDs above.
- Detect query that works (errors in bible-chat, last 30d):
  ```bash
  ax spans export TW9kZWw6NzY4NjM3MzU0Nzp1aFhH \
    --space U3BhY2U6NDM1OTg6U3ZpOA== \
    --filter "status_code = 'ERROR'" --limit 50 --output-dir .
  ```
  `--filter` also takes `latency_ms > 1000` etc. Output is JSON (`--stdout` to pipe).

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
  `~/dev/artifact-studio-tools/cli/src/index.ts` (`share` | `deploy` | `backend` | `list/get/delete`).
- **MCP server:** `~/dev/artifact-studio-tools/mcp` (tools `publish_artifact`, `deploy_app`,
  `provision_backend`, `list/get/delete_artifact`); env `ARTIFACT_API_BASE` + `ARTIFACT_API_KEY`.
- **Key:** durable agent key in bws as `ARTIFACT_API_KEY` (owner `jpvarbed`); base in `ARTIFACT_API_BASE`.
  All agent-published apps are owned by `jpvarbed` — manage via `artifact list` or studio.artifacts.jasonv.dev.

## Focus — timer + attention orchestrator

Server-owned Pomodoro **and** a cross-project agent fleet at `https://focus.jasonv.dev`. App repo
`~/dev/focus-timer` (private; Convex backend + Vite SPA). Tools repo `~/dev/focus-timer-tools`
(public, github `jpvarbed/focus-timer-tools`). The fleet lets any agent report its status, ask Jason
a question, and log decisions; Jason sees who's working / who needs him / what was decided on the board.

- **Skill:** `focus-timer` — canonical driver at `skills/engineering/focus-timer/` (auto-linked into
  `~/.claude/skills` by setup.sh); a copy ships in `focus-timer-tools/skills/focus-timer/` for skills.sh
  (`npx skills add jpvarbed/focus-timer-tools`). Covers timer + fleet (report/ask/event/fleet).
- **Scripts:** `focus-timer-tools/scripts/cc-fleet-hook.py` (FOC-12) — `~/.claude/settings.json` hook
  so local Claude Code sessions auto-report presence (SessionStart→working, Notification→needs_you,
  Stop→done). See `scripts/README.md`.
- **CLI:** `focus` (`focus-timer-tools/cli`) — timer (`status`/`start`/`pause`/`resume`/`skip`/`reset`/
  `stats`/`watch`) + fleet (`fleet`, `report agent= project= [state=] [task=]`, `ask agent= [severity=] "q"`).
  Env: `FOCUS_API_KEY` (minted key, for fleet/report/ask/learn/recall) + `FOCUS_USER_ID` (for
  timer control/reads until that surface is keyed) + optional `CONVEX_URL`/`FOCUS_CONVEX_SITE`.
- **MCP:** hosted `https://mcp.jasonv.dev/api/mcp` (pass your id in the `x-focus-user` header), or local
  stdio (`mcp/src/stdio.ts`). 11 tools: timer (`focus_status/start/pause/resume/skip/reset/stats`) +
  **fleet** (`focus_report`, `focus_ask`, `focus_event`, `focus_fleet`). Registered with ARD at
  `focus.jasonv.dev/.well-known/ai-catalog.json`.
- **Identity:** `FOCUS_USER_ID` = the web app's `focus_user_id` cookie (the access capability — no bws
  key). Use the same id to drive the same fleet/timer the web shows. Convex prod
  `perceptive-butterfly-406`, dev `vivid-ant-124`.
