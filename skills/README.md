# Skills

Personal agent skills, organized by category (mirrors the layout of
`mattpocock/skills`). Each skill is a directory with a `SKILL.md` (YAML
frontmatter `name` + `description`, then the process) plus any helper scripts.

See [`skill-reference.md`](./skill-reference.md) for the external skill
collections I pull from (Superpowers, mattpocock, Convex) and their git sources.

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
