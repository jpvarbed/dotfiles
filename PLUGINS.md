# Installed Tools & Plugins

## Beads Issue Tracker

```bash
curl -fsSL https://raw.githubusercontent.com/steveyegge/beads/main/scripts/install.sh | bash
```

Installed to: `~/.local/bin/bd`

## Claude Code Plugins

### From claude-code-plugins marketplace

```bash
/plugin install ralph-wiggum@claude-code-plugins
/plugin install feature-dev@claude-code-plugins
/plugin install commit-commands@claude-code-plugins
```

## What they do

- **ralph-wiggum**: Runs Claude in loop until task completes (use with Beads)
- **feature-dev**: 7-phase feature development workflow with specialized agents
- **commit-commands**: Git workflow commands for committing, pushing, creating PRs
