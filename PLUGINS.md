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
