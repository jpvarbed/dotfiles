---
name: mcp-dev
description: Use when building or extending an agent-driven product where agents act/publish through a Claude skill + CLI + MCP over one backend API — deciding how to split the repos, or adding a backend capability that must reach the clients without drifting. Covers the private-service-repo + public-tooling-repo pattern (artifact-share/artifact-studio-tools, focus-timer). Use whenever you touch one surface (backend, OpenAPI, CLI, MCP, skill, docs) and the others must stay in sync.
---

# mcp-dev — private service + public agent-tooling pattern

## Overview

Several of Jason's products are **agent-driven**: a backend that agents drive through a **skill + CLI + MCP**. The proven shape is **two repos**, not one:

- **Private service repo** — the backend (Convex), the web app, the deploy proxy, specs/ADRs, and the **OpenAPI spec**. Holds secrets and infra; never public.
- **Public tooling repo** — the **skill + CLI + MCP**, as **thin clients over the backend's `/v1` HTTP API**. Safe to open-source; any project installs it.

**The contract between them is the HTTP `/v1` API + its OpenAPI doc** — *not* a shared TS package (the public repo can't import the private backend). The backend is the only source of truth; every client is a dumb wrapper.

## When to use

- Starting a product where agents publish/act from ANY project via skill/CLI/MCP.
- Deciding repo structure for such a product (the #1 mistake is a single monorepo).
- Adding or changing a backend capability — it must propagate to CLI, MCP, skill, OpenAPI, docs.
- Pairs with [[jason-prototype-stack]] (the stack) and the sync loop is part of [[total-tdd]].

## Two-repo layout

```
~/dev/<product>/                 PRIVATE  (github jpvarbed/<product>)
  packages/backend/convex/       schema, functions, http.ts (/v1 router + renderer), openapi.ts
  apps/web/                       Vite/React console (own origin, holds keys)
  apps/<proxy>/                   Vercel path-proxy <product>.jasonv.dev/<slug> → Convex
  SPEC.md  PLAN.md  docs/adr/

~/dev/<product>-tools/           PUBLIC   (github jpvarbed/<product>-tools)
  cli/        `<product>` CLI    — fetch() over /v1
  mcp/        MCP server         — same /v1 calls, tool-per-capability
  skills/<verb>-<product>/SKILL.md   — drives the CLI
  README.md
```

Both repos are bun. The public tooling is cloned by `dotfiles/setup.sh`; the global skill in `dotfiles/skills/engineering/` drives the CLI and is auto-linked into `~/.claude/skills`.

## Keys / identity

- Writes need an API key (`ak_…`, sha256-hashed server-side, owner = a `userId`). Mint it in the console; agents read it from **bws** (`<PRODUCT>_API_KEY` + `_API_BASE`), never hardcoded, never written to disk or shipped in an app bundle.
- Humans sign in (email magic-link) and mint keys; both humans and keys resolve to one owner so everything lands in one dashboard.

## The sync rule (the whole point)

A new/changed backend capability propagates **outward in this fixed order — update all of it in one change:**

1. **backend** function + `convex/http.ts` `/v1` route (+ tests)
2. **`openapi.ts`** — the cross-repo contract (+ its test)
3. **CLI** command + `--help`
4. **MCP** tool + its description (the description is a user-facing contract)
5. **skill** SKILL.md (public copy in `<product>-tools` AND the private `dotfiles` copy)
6. **READMEs** of both repos

Put this checklist at the top of the private repo's `PLAN.md`. "Updated the CLI but not the OpenAPI/MCP/skill" is the drift this pattern exists to prevent — treat the six surfaces as one unit, and verify them in [[total-tdd]] sweeps.

## Common mistakes

| Mistake | Fix |
| --- | --- |
| One monorepo with backend + tooling | Split: private service, public tooling. Public must be shareable without exposing infra/secrets. |
| Shared TS "SDK" package imported by both | Can't cross the public/private boundary. The seam is the HTTP `/v1` API + OpenAPI. |
| MCP shells out to the CLI | Both wrap `/v1` directly; the **skill** is the only thing that drives the CLI. |
| Update CLI, forget OpenAPI/MCP/skill | Propagate all six surfaces in one change (see sync rule). |
| Key hardcoded or in the app bundle | bws on demand; key owner = userId; reads are open per visibility, writes need the key. |
| New slug per redeploy | Make publish idempotent for the owner (update in place); keep slug+token stable. |

## Real examples

- **artifact-share** (private) + **artifact-studio-tools** (public) — apps at `artifacts.jasonv.dev/<slug>/`, console at `studio.artifacts.jasonv.dev`.
- **focus-timer** — same trio (CLI/MCP/skill) over one Convex backend, used from any project.

## Errors

| Issue | Fix |
| --- | --- |
| Added a backend function + `convex/http.ts` `/v1` route but the CLI/MCP/skill still 404 or miss the new capability | Surface drift — walk the sync rule's six surfaces in order: regenerate `openapi.ts` (+ its test), add the CLI command + `--help`, the MCP tool + description, update both SKILL.md copies and both READMEs in the SAME change. |
| `openapi.ts` updated but the public `<product>-tools` repo still ships the old CLI/MCP shape (cross-repo skew) | The two repos sync only through the HTTP `/v1` API + OpenAPI doc, not a shared package. Re-pull `<product>-tools`, regenerate clients from the current `openapi.ts`, and run `total-tdd` to confirm CLI/MCP/skill match the live `/v1`. |
| MCP server returns no tools / "server not connected" in the client | The MCP server in `<product>-tools/mcp/` isn't registered or running — register it in the client config and confirm `<PRODUCT>_API_BASE` points at the deployed Convex `/v1`; the MCP calls `/v1` directly (it does not shell out to the CLI). |
| Write/publish calls fail with 401/403 while reads succeed | Missing or wrong API key — reads are open per visibility, writes need `ak_…`. Mint a key in the console and load `<PRODUCT>_API_KEY` from bws on demand; never hardcode it or commit it to either repo. |
| `<product>` CLI not found after a fresh machine / `dotfiles/setup.sh` run | The public tooling clone or the `~/.claude/skills` symlink didn't land — re-run `dotfiles/setup.sh` to clone `<product>-tools` and re-link the global skill in `dotfiles/skills/engineering/`. |
| Each redeploy mints a new slug/token, breaking existing links | Make publish idempotent for the owner — update in place keyed on `userId`, keeping slug + token stable across redeploys. |
