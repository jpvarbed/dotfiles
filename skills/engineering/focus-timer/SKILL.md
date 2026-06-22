---
name: focus-timer
description: Report into Jason's cross-project agent fleet and/or drive the server-owned Pomodoro timer (focus.jasonv.dev). Use when you (an agent) should tell Jason what you're working on, flag that you need him, or log a decision — and when the user wants to start/check/pace a focus session. Works from ANY project; the CLI/MCP and identity are global.
---

# Focus — timer + attention orchestrator

Jason runs many agents across projects. The **fleet** is how he sees who's working, who needs him,
and what each agent decided — on `focus.jasonv.dev`. This skill lets any agent report in, ask him a
question, or log provenance, and lets the user control the shared Pomodoro timer.

**Announce at start:** "Using focus-timer to report to the fleet." (or "to control the timer.")

## 1. Identity (no key, just an id)

Data is scoped by `FOCUS_USER_ID` — Jason's account id (the web app's `focus_user_id` cookie). Use
**his** id so you report into the fleet he's watching:

```bash
export FOCUS_USER_ID="<jason's focus_user_id>"   # or fetch from bws if stored there:
# set -a; source ~/dev/.env.local; set +a
# export FOCUS_USER_ID=$(bws secret list -o json | python3 -c "import sys,json;print(next(s['value'] for s in json.load(sys.stdin) if s['key']=='FOCUS_USER_ID'))")
```

Endpoint defaults to prod (`perceptive-butterfly-406`); override with `CONVEX_URL`. No password —
the id is the capability.

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

## 3. Auto-report (no manual calls) — CC hook, FOC-12

To make local Claude Code sessions report presence automatically, install the hook:
`~/dev/focus-timer-tools/scripts/cc-fleet-hook.py` into `~/.claude/settings.json`
(SessionStart/UserPromptSubmit→working, Notification→needs_you, Stop/SubagentStop→done). See
`focus-timer-tools/scripts/README.md`. Semantic asks/decisions still use the MCP/CLI explicitly.

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
