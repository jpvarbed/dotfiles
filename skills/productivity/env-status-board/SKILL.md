---
name: env-status-board
description: Use when the user asks "where are we", wants a status check / standup / snapshot of the dotfiles + skills + environment-setup work, or asks what shipped, what's open, or what's blocked. Gathers recent commits, open Linear JAS issues, and items blocked on the user, then renders a 3-column status board with the visualization tool.
---

# Env status board

A snapshot of the dotfiles / skills / env-setup work as a 3-column board:
**Shipped** (recent) · **Open — Linear JAS** · **Blocked on you** (manual / security).

## 1. Gather the three columns

**Shipped (recent).** Recent commits in dotfiles (and any other `~/dev` repo touched this session):
```bash
cd ~/dev/dotfiles && git log --oneline -12
```
Condense to ≤6 chips — present-tense outcomes, ≤8 words each (e.g. "Bake-off → kept avoid-ai-writing, culled unslop"). Fold related commits into one chip.

**Open — Linear JAS.** Fetch via the Linear API — reliable, unlike the `linear` CLI's `list` (which only shows *assigned-to-me* and errors without a sort):
```bash
eval "$(grep BWS_ACCESS_TOKEN ~/dev/.env.local)"; export BWS_ACCESS_TOKEN
KEY=$(bws secret list -o json | jq -r '.[]|select(.key=="LINEAR_API_KEY").value' | head -1)
curl -s https://api.linear.app/graphql -H "Authorization: $KEY" -H "Content-Type: application/json" \
  -d '{"query":"{ issues(filter:{team:{key:{eq:\"JAS\"}}, state:{type:{nin:[\"completed\",\"canceled\"]}}}, first:30){ nodes { identifier title priority state{name} } } }"}' \
  | jq -r '.data.issues.nodes[]? | "\(.identifier) [P\(.priority)] — \(.title)"'
```
Show the top 4–6 by priority. **Linear priority: 1=Urgent, 2=High, 3=Normal, 4=Low, 0=None** — so order `1→2→3→4` then `0` last (`0` is *unset*, NOT top priority; don't render it as urgent). Collapse a long tail into one muted "+ N more eval issues" chip.

**Blocked on you.** Items only the user can clear — scan for:
- leaked / rotated secrets (anything flagged compromised this session),
- `setup.sh` / `README.md` notes containing "manual", "sudo", "not in setup.sh", "run once", "pre-approve",
- unverified domains (e.g. Resend from-domain), pending external approvals.

1–4 chips. Red for security / exposure, amber for softer manual steps.

## 2. Render the board

Call the visualization `show_widget` tool using `templates/board.html` (this skill dir) as the structure — clone a chip `<div>` per item. Chip colors:

| Column | chip bg | chip text |
|---|---|---|
| Shipped | `#E1F5EE` | `#085041` |
| Open (JAS) | `#E6F1FB` | `#0C447C` |
| Blocked — security | `#FCEBEB` | `#791F1F` |
| Blocked — manual | `#FAEEDA` | `#633806` |
| Muted tail | `var(--color-background-secondary)` | `var(--color-text-secondary)` |

Keep chips terse, sentence case, no emoji. Title the widget `dotfiles_status_board`.

## 3. After the board

In response text (not inside the widget): a one-paragraph bottom line + the single highest-leverage next move. Don't restate the chips.

## Scope note

This is the **env / dotfiles** status board. For per-feature project status, pull from that
project's repo + its own JAS issues instead. Keep it cheap — it's a standup, not an audit.

## Errors

| Issue | Fix |
|---|---|
| `bws secret list` fails with a transient DNS / network error fetching the Linear key | Re-run the `bws secret list -o json \| jq ...` line once or twice; it's a flaky resolve, not a real auth failure. Confirm `BWS_ACCESS_TOKEN` was exported from `~/dev/.env.local` first. |
| `LINEAR_API_KEY` not found in bws (`KEY` comes back empty) | The Open — Linear JAS column can't load. Skip it and render the board with only Shipped + Blocked, noting the JAS fetch was unavailable — don't fabricate issues. Add the key to Bitwarden Secrets Manager to restore it. |
| Used `linear issue list --team JAS` and got nothing / an error | Expected — the CLI's `list` only returns *assigned-to-me* and errors without `--sort`. Use the GraphQL `curl` to `api.linear.app/graphql` in step 1 instead; it's the source of truth for the Open column. |
| `git log --oneline -12` is empty or errors with "not a git repository" | `~/dev/dotfiles` isn't a repo (or you're elsewhere). `cd ~/dev/dotfiles` first; if it's genuinely not initialized, render the Shipped column empty rather than inventing commits. |
| GraphQL returns `priority: 0` issues sorted to the top as if urgent | `0` = *None/unset*, not Urgent. Order `1→2→3→4` then `0` last, and never color a `0` chip red. |
