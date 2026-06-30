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

**One-time per machine (needs sudo, so not in setup.sh):**
```bash
portless service install   # auto-start the portless proxy at boot → https://<name>.localhost dev URLs
```

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
scripts/rotate-age-key.sh      # rotate the age key: re-encrypt docs, update age-recipient.txt + bws
```

**On compromise / rotation:** `rotate-age-key.sh` re-keys going forward, but prior
`*.age` blobs stay in the public git history and remain readable with the *old*
key. So rotation protects future commits, not past ones — if the age key leaked,
treat the historically-committed `soul.md`/`knowledge` contents as exposed. To
rotate the `BWS_ACCESS_TOKEN`, revoke the machine account in Bitwarden, issue a new
token, and update `~/dev/.env.local`.

Commit the `.age` files and `age-recipient.txt`. Plaintext (`soul.md`,
`skills/knowledge/`) and `~/dev/.env.local` stay local.

## Skills

See [`skills/skill-reference.md`](./skills/skill-reference.md) for the external
collections I pull from and their sources. My own skills live in `skills/`.

## Dev tools

[`docs/tools.md`](./docs/tools.md) — running log of interesting dev tools (using /
evaluating / watching), cross-referenced to Linear JAS issues.

## Gotchas — desktop app env, hooks, tracing

Hard-won, cross-cutting. Most of these trace back to **one root cause: GUI-launched apps
(Claude desktop, IDEs) do NOT source `~/.zshrc`**, so anything a shell export provides is invisible
to them.

- **Keys for the desktop app come from launchd, not the shell.** Terminal `claude` gets keys via the
  `claude() { ARIZE_API_KEY=… }` wrapper in `~/.zshrc`; the desktop app gets nothing from that. Fix:
  `scripts/focus-key-load.sh` (run by the `dev.jasonv.focus-key` LaunchAgent at login) fetches keys
  from bws and `launchctl setenv`s them into the GUI session — currently `FOCUS_API_KEY` (fleet hook)
  and `ARIZE_API_KEY` (cc-tracing). The bws token is read transiently; only the named keys enter the
  session env. **Any new key the desktop app needs → add it there.** After changing the launchd env,
  **fully quit + reopen the app** (it inherits env only at launch).
- **`~/.claude/settings.json` (env block + hooks) is read at session START.** Editing it — or the
  launchd env, or a hook script's effect on env — only applies to **new** sessions. Restart to test.
- **Arize tracing of Claude Code:** the `claude-code-tracing` plugin streams OpenInference spans
  (full prompts + tool details + content, since `ARIZE_LOG_*=true`) to the Arize **`claude-code`**
  project — but only where `ARIZE_API_KEY` is present (so: terminal always, desktop only after the
  launchd fix above). Query traces with `ax traces list <project-id> --start-time <ISO>` (the Arize
  **ingest** key 401s on the GraphQL API — use the `ax` CLI). Get project ids via `ax projects list`.
- **Fleet hooks:** presence/activity = `cc-fleet-hook.py` (SessionStart/UserPromptSubmit/Stop);
  **commits = `cc-commit-hook.py` (PostToolUse on Bash)**, which is cwd-independent. The earlier
  Stop-based capture only scanned the session's *own cwd* repo, so it silently missed commits when
  the session was rooted outside a repo (`~/dev`) or committed to a *different* repo — the common
  orchestration case. Decisions/knowledge are never auto-captured (reasoning can't be inferred); they
  need explicit `focus decide` / `focus learn`.
- **Hosting a key-gated artifact → use `public`, not `unlisted`.** Unlisted apps token-gate *every*
  request, but a browser fetches relative sub-resources (`./app.js`, `./styles.css`) without the
  token → 404 → blank page. Privacy comes from the in-app key gate, not the URL.

## Papers

[`docs/papers.md`](./docs/papers.md) — research for skill / agent construction
(harnesses, reliability, eval, instruction-following).

[`docs/harnesses.md`](./docs/harnesses.md) — survey of coding-agent harnesses
(superpowers, Taskmaster, spec-kit, BMAD, …) focused on state machines + gates.
