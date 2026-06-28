---
name: focus-timer
description: Report into Jason's cross-project agent fleet and/or drive the server-owned Pomodoro timer (focus.jasonv.dev). Use when you (an agent) should tell Jason what you're working on, flag that you need him, or log a decision — and when the user wants to start/check/pace a focus session. Works from ANY project; the CLI/MCP and identity are global.
---

# Focus — timer + attention orchestrator

Jason runs many agents across projects. The **fleet** is how he sees who's working, who needs him,
and what each agent decided — on `focus.jasonv.dev`. This skill lets any agent report in, ask him a
question, or log provenance, and lets the user control the shared Pomodoro timer.

**Announce at start:** "Using focus-timer to report to the fleet." (or "to control the timer.")

## 1. Auth — a minted key (FOC-23/24/25)

Agent writes (report/ask/event/recall/learn) authenticate with **`FOCUS_API_KEY`** — a minted
`ak_…` key (focus web → Settings → Mint key). The owner is derived from the key server-side; no
cleartext account id is carried, and the key is write-only to Jason's fleet + one-click revocable.
On Jason's machine it's loaded from bws two ways so the CLI/hook just work everywhere:
- **Terminal-launched** (`~/.zshrc`): exported into every interactive shell.
- **GUI-launched** (Claude desktop, IDEs — don't source `.zshrc`): a LaunchAgent
  (`macos/LaunchAgents/dev.jasonv.focus-key.plist` → `scripts/focus-key-load.sh`) runs at login
  and `launchctl setenv`s it into the GUI session, so apps started afterward inherit it. Both read
  the bws token transiently from `~/dev/.env.local`; only `FOCUS_API_KEY` ever enters the env.

```bash
export FOCUS_API_KEY=$(bws secret list -o json | jq -r '.[]|select(.key=="FOCUS_API_KEY")|.value' | head -1)
# Agent writes POST to FOCUS_CONVEX_SITE/agent/* (defaults to the auth deployment's .convex.site).
```

Timer **control/read** commands (status/start/stats/fleet) still use `FOCUS_USER_ID` against the
no-auth prod deployment until that surface goes key-native (next slice). The remote MCP takes the
key via `Authorization: Bearer ak_…` (and `x-focus-user` for control/reads).

## 2. Report into the fleet (the main agent use)

CLI (from `~/dev/focus-timer-tools`) or the hosted MCP at `https://mcp.jasonv.dev/api/mcp`
(pass the id in the `x-focus-user` header). Tools: `focus_report`, `focus_ask`, `focus_event`, `focus_fleet`.

```bash
FOC=~/dev/focus-timer-tools/cli/src/index.ts
bun "$FOC" report agent=<id> project=<name> [state=working|needs_you|done] [task=<title>]
bun "$FOC" ask    agent=<id> [severity=soft|hard] "your question for Jason"
bun "$FOC" recall "how do we anchor P4"               # find prior knowledge to cite
bun "$FOC" learn  "Title" body="…" [tags=a,b]         # capture a concept → knowledge:<slug>
bun "$FOC" decide "what you decided" cites=knowledge:<slug>[,knowledge:<slug>]   # the lineage
bun "$FOC" fleet                       # show the board: agents by project/task + open asks
```

Guidance for agents:
- `report ... state=working` when you pick up a task; `state=done` when you finish. `task` groups
  2+ agents on one workstream.
- `ask` for anything needing Jason: **soft** = can wait (held during his focus block, surfaces at his
  break); **hard** = you're blocked, pierces now. Don't mark everything hard.
- **At a real fork, `decide`.** Before deciding, `recall` to find prior knowledge; if it's new, `learn`
  it; then `decide "…" cites=knowledge:<slug>`. The cite becomes the graph's `decision —INFORMS→ knowledge`
  lineage — the whole point of the provenance graph. A decision with no cite is logged as a knowledge-gap
  (not rejected), so cite when you can. (MCP equivalent: `focus_event type:"decision"` with `refs`.)
- **Commits auto-capture** — the CC hook records commits you make during a session as `output` events
  (agent→produces→commit), so you don't log routine output by hand; reserve `decide` for the reasoning.

## 3. Auto-report (no manual calls) — CC hook, FOC-12/25

Already wired on Jason's machine: `~/dev/focus-timer-tools/scripts/cc-fleet-hook.py` runs from
`~/.claude/settings.json` on SessionStart/UserPromptSubmit→working, Notification→needs_you,
Stop/SubagentStop→done. It POSTs to `FOCUS_CONVEX_SITE/agent/report` with the `FOCUS_API_KEY`
exported by `~/.zshrc` — so every CC session in every project auto-reports under his account, with
no cleartext id. It never blocks CC (no key → no-op, errors swallowed, 3s timeout). Semantic
asks/decisions still use the MCP/CLI explicitly.

## 4. Drive the timer (human-facing)

```bash
bun "$FOC" status | start [label] | pause | resume | skip | reset | stats | watch
bun "$FOC" config focus=25 short=5 long=15 interval=4 autostart=true
```

The timer is server-owned and shared with the web app (realtime). To pace your own work: `start` a
block, watch for the phase to flip to a break, checkpoint, then continue.

## Errors

| Issue | Fix |
| --- | --- |
| Agent writes (`report`/`ask`/`event`/`recall`/`learn`) rejected (401) or silently no-op — `FOCUS_API_KEY` unset | Mint a key at focus web → Settings → Mint key, then export it: `export FOCUS_API_KEY=$(bws secret list -o json \| jq -r '.[]\|select(.key=="FOCUS_API_KEY")\|.value' \| head -1)`. GUI-launched apps that miss it need the `dev.jasonv.focus-key.plist` LaunchAgent loaded (or relaunch from a terminal that sourced `~/.zshrc`). |
| `bws` token missing so the key can't load (`bws` errors / empty value) | The bws access token is read transiently from `~/dev/.env.local` — confirm that file exists and holds the token; without it the LaunchAgent and `.zshrc` export both yield nothing, so the key never enters the env. |
| Timer control/read (`status`/`start`/`stats`/`fleet`) fails or returns nothing | These use `FOCUS_USER_ID` (not the key) against the no-auth prod deployment — set `FOCUS_USER_ID`. Via the remote MCP, also pass the `x-focus-user` header with the id. |
| `bun "$FOC" …` fails: command not found / cannot find module | Clone the public tooling repo `~/dev/focus-timer-tools` (`github jpvarbed/focus-timer-tools`) and run `bun install` once; `FOC=~/dev/focus-timer-tools/cli/src/index.ts`. |
| Hosted MCP at `https://mcp.jasonv.dev/api/mcp` not connected | Fall back to the CLI in `~/dev/focus-timer-tools` (same `focus_report`/`focus_ask`/`focus_event`/`focus_fleet` as `report`/`ask`/`event`/`fleet`); pass auth via `Authorization: Bearer ak_…` when the MCP is reachable again. |
| `decide` logged as a knowledge-gap instead of forming lineage | Provide a real cite: `recall` to find prior knowledge, `learn "Title" body="…"` if it's new, then `decide "…" cites=knowledge:<slug>`. A decision with no cite is recorded but never wired into the provenance graph. |

## Notes

- Tooling repo (clone if missing): `~/dev/focus-timer-tools` (github `jpvarbed/focus-timer-tools`,
  public) — `bun install` once. Skill also published to skills.sh. The app (web + Convex backend) is
  the separate **private** `jpvarbed/focus-timer` repo. Registered with ARD at
  `focus.jasonv.dev/.well-known/ai-catalog.json`.
- Convex prod `perceptive-butterfly-406`, dev `vivid-ant-124`. The board, asks (hard/soft shield),
  tasks (active→done graduation), and provenance events are all live.
