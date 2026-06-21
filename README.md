# dotfiles

Personal Claude Code setup: global preferences (`soul.md`), agent skills, plugin
config, and secrets bootstrap. Repo lives at `~/dev/dotfiles`.

## New machine

```bash
git clone https://github.com/jpvarbed/dotfiles.git ~/dev/dotfiles
~/dev/dotfiles/scripts/setup.sh
```

`setup.sh` is idempotent (safe to re-run) and does a full bootstrap:

1. Installs prerequisites (`age` via brew; `bws` via cargo if missing).
2. Clones skill collections into `~/dev/*` (superpowers, mattpocock, convex,
   ponytail, cursor/plugins).
3. Links skills into `~/.claude/skills`: mattpocock, the curated cursor set
   (`skills/external-skills.list`), and my own dotfiles skills.
4. Flags the superpowers + ponytail plugin marketplaces to register if missing.
5. Decrypts `soul.md.age` → symlinks it to `~/.claude/CLAUDE.md` (global prefs).
   Unseals `knowledge.tar.age` → `skills/knowledge/`.
6. Decrypts `bws-token.age` → `~/.config/bws/access-token`, exports it in
   `~/.zshrc`, and verifies `bws` auth.
7. Installs/configures the Gemini CLI for `adversarial-review` (api-key auth;
   pulls `GEMINI_API_KEY` from bws).

The decrypt/unseal steps prompt for your age passphrase.

## Per-project Claude config

```bash
cd ~/dev/your-project
ln -sf ~/dev/dotfiles/.claude .claude
```

## Secrets (age + Bitwarden)

Two secrets are committed **only** in age-encrypted form, unlocked by one local
passphrase. The decrypted plaintext is gitignored and never committed.

| Committed (encrypted) | Decrypts to | What |
|---|---|---|
| `soul.md.age` | `soul.md` → `~/.claude/CLAUDE.md` | how I like to work |
| `bws-token.age` | `~/.config/bws/access-token` | Bitwarden SM root token |
| `knowledge.tar.age` | `skills/knowledge/` | personal reading-list KB (work email + notes) |

The `BWS_ACCESS_TOKEN` unlocks everything else in Bitwarden Secrets Manager;
fetch other secrets on demand (`bws secret list`, `bws run -- <cmd>`).

### Editing the secrets

```bash
scripts/soul-edit.sh           # decrypt, edit in $EDITOR, re-encrypt soul.md.age
scripts/bws-token-set.sh       # capture a new BWS token and encrypt it
scripts/knowledge-edit.sh seal # tar skills/knowledge/ -> knowledge.tar.age (unseal to restore)
```

Commit the resulting `.age` files. Plaintext (`soul.md`, `bws-token`,
`skills/knowledge/`) stays local and gitignored.

## Skills

See [`skills/skill-reference.md`](./skills/skill-reference.md) for the external
collections I pull from and their sources. My own skills live in `skills/`.
