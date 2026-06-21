# dotfiles

Personal Claude Code setup: global preferences (`soul.md`), agent skills, plugin
config, and secrets bootstrap. Repo lives at `~/dev/dotfiles`.

## New machine

```bash
git clone https://github.com/jpvarbed/dotfiles.git ~/dev/dotfiles
printf 'BWS_ACCESS_TOKEN=%s\n' "<paste from your vault>" > ~/dev/.env.local   # the one root secret
~/dev/dotfiles/scripts/setup.sh
```

`setup.sh` is idempotent (safe to re-run) and **fully non-interactive** once
`~/dev/.env.local` exists:

1. Installs prerequisites (`age` via brew; `bws` via cargo; warns on missing `jq`).
2. Clones skill collections into `~/dev/*` (superpowers, mattpocock, convex,
   ponytail, cursor/plugins).
3. Links skills into `~/.claude/skills`: mattpocock, the curated cursor set
   (`skills/external-skills.list`), and my own dotfiles skills.
4. Installs the ponytail plugin via the `claude` CLI; flags superpowers if missing.
5. Sources `~/dev/.env.local` for `BWS_ACCESS_TOKEN`, makes `~/.zshrc` source it,
   verifies `bws`, and pulls the age key (`DOTFILES_AGE_KEY`) from bws.
6. Decrypts `soul.md.age` → symlinks `~/.claude/CLAUDE.md`; unseals
   `knowledge.tar.age` → `skills/knowledge/` (both with the age key).
7. Installs/configures the Gemini CLI for `adversarial-review` (api-key auth;
   pulls `GEMINI_API_KEY` from bws).

## Per-project Claude config

```bash
cd ~/dev/your-project
ln -sf ~/dev/dotfiles/.claude .claude
```

## Secrets — root of trust

One plaintext root, `~/dev/.env.local` (outside the repo, never committed), holds
`BWS_ACCESS_TOKEN` — your single master secret, kept in your Bitwarden vault.
Everything else flows from it:

- **bws** is the source of truth for all key/value secrets *and* the age key
  (`DOTFILES_AGE_KEY`). Fetch on demand: `bws secret list`, `bws run -- <cmd>`.
- **age** protects the doc files that don't fit bws. They're encrypted to a public
  recipient (`age-recipient.txt`, committed) and decrypted with the private age key
  (pulled from bws to `~/.config/age/key.txt`) — **non-interactive, no passphrase**.

| Committed (encrypted) | Decrypts to | What |
|---|---|---|
| `soul.md.age` | `soul.md` → `~/.claude/CLAUDE.md` | how I like to work |
| `knowledge.tar.age` | `skills/knowledge/` | personal reading-list KB (work email + notes) |
| `age-recipient.txt` | *(public key, committed as-is)* | recipient used to encrypt the above |

### Editing the secrets

```bash
scripts/age-init.sh            # one-time: create the age key, write age-recipient.txt, store key in bws
scripts/soul-edit.sh           # decrypt, edit in $EDITOR, re-encrypt soul.md.age
scripts/knowledge-edit.sh seal # tar skills/knowledge/ -> knowledge.tar.age (unseal to restore)
scripts/env-to-bws.sh --slim   # one-time: push .env.local secrets into bws, slim it to just the token
```

Commit the `.age` files and `age-recipient.txt`. Plaintext (`soul.md`,
`skills/knowledge/`) and `~/dev/.env.local` stay local.

## Skills

See [`skills/skill-reference.md`](./skills/skill-reference.md) for the external
collections I pull from and their sources. My own skills live in `skills/`.
