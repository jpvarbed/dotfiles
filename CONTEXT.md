# Context — glossary

Canonical terms for this dotfiles setup. Definitions only; no implementation
details (those live in README.md / scripts).

- **soul.md** — the single canonical file of *global working preferences* ("how I
  like to work"): communication, verification, boundaries. Agent-agnostic. One
  source of truth, symlinked into every agent's global guidance file.

- **agent global file** — where a given agent reads global guidance:
  `~/.claude/CLAUDE.md` (Claude Code), `~/.codex/AGENTS.md` (Codex),
  `~/.gemini/GEMINI.md` (Gemini CLI). Each is a *symlink to soul.md*, not a copy.

- **project guide** — *per-repo* tooling/conventions for one project (e.g. Linear,
  dev-browser). Lives as `CLAUDE.md` (Claude) and/or `AGENTS.md` (other agents) at
  a repo root. Distinct from soul.md: project guides are repo-specific and vary;
  soul.md is global and constant. Do not conflate "AGENTS.md the project guide"
  with "the agent global file."

- **skill** — a `SKILL.md` capability consumed *natively only by Claude Code* (and
  a few compatible agents). Cursor/Gemini/OpenCode do **not** consume global skills.

- **CLI** — a terminal tool (e.g. `linear`, `bws`, `age`, `gemini`). Usable by
  *any* agent regardless of skill support — this is how non-Claude agents get
  capabilities. The skill is just Claude-flavored usage docs around the CLI.

- **tracker** — issue/todo tracking is **Linear** (CLI `linear`, skill
  `linear-cli`). Personal todos → team `JAS`. (Beads is no longer used.)

- **secrets root** — `~/dev/.env.local` holds only `BWS_ACCESS_TOKEN`; **bws** is
  the source of truth for all other secrets and the **age** key that decrypts the
  committed `*.age` docs. See README.md.
