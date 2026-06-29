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

### knowledge
- **agentic-engineering** — curated KB on building agentic systems (loop/harness
  design, context engineering, the agentic web).
- **gap-briefing** — close the cutoff→now delta filtered through your own projects:
  fan-out search, read primary sources, rank by impact, deliver a visual sourced
  briefing, persist roadmap-relevant findings. Output to `docs/digests/gap-briefings/`.
