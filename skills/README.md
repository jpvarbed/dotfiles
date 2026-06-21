# Skills

Personal agent skills, organized by category (mirrors the layout of
`mattpocock/skills`). Each skill is a directory with a `SKILL.md` (YAML
frontmatter `name` + `description`, then the process) plus any helper scripts.

```
skills/
└── <category>/
    └── <skill-name>/
        ├── SKILL.md      # frontmatter + instructions
        └── *.sh          # optional helpers
```

## Skills

### engineering
- **adversarial-review** — ruthless independent second-model (Gemini CLI) critique
  of a plan/spec/ADR/diff, then triage + optionally fold findings into specs/issues.
