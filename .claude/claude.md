# Claude Configuration

## Tools Available

### Linear (issue tracking)

Track work in Linear via the `linear` CLI (or the `linear-cli` skill). Personal todos go in team `JAS`.

```bash
linear issue list --team JAS --sort priority   # ready work
linear issue create --team JAS --title "..." --description-file FILE
linear issue view <id>
```

Use Linear to track discovered work and maintain context between sessions.
