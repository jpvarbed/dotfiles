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
On Jason's machine it's exported into every shell from bws (`~/.zshrc`), so the CLI/hook just work:

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
bun "$FOC" fleet                       # show the board: agents by project/task + open asks
```

Guidance for agents:
- `report ... state=working` when you pick up a task; `state=done` when you finish. `task` groups
  2+ agents on one workstream.
- `ask` for anything needing Jason: **soft** = can wait (held during his focus block, surfaces at his
  break); **hard** = you're blocked, pierces now. Don't mark everything hard.
- Record a provenance **decision** at real forks, citing the knowledge you used (so work is traceable):
  `focus_event` (MCP) with `type:"decision"`, a `summary`, and `refs:[{type:"informs",target:"knowledge:<id>"}]`.
  A decision with no `knowledge:` ref is logged as a knowledge-gap (not rejected).

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

## Notes

- Tooling repo (clone if missing): `~/dev/focus-timer-tools` (github `jpvarbed/focus-timer-tools`,
  public) — `bun install` once. Skill also published to skills.sh. The app (web + Convex backend) is
  the separate **private** `jpvarbed/focus-timer` repo. Registered with ARD at
  `focus.jasonv.dev/.well-known/ai-catalog.json`.
- Convex prod `perceptive-butterfly-406`, dev `vivid-ant-124`. The board, asks (hard/soft shield),
  tasks (active→done graduation), and provenance events are all live.
