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
