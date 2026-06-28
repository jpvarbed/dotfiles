---
name: jason-prototype-stack
description: Stand up a new <thing>.jasonv.dev web app fast, the way focus.jasonv.dev was built — bun monorepo + Vite/React SPA + Convex backend + Vercel static deploy + Squarespace DNS, with CLI and Claude-skill clients reusing the same backend. Use when "starting a new small web app", "prototype on jasonv.dev", or "scaffolding a Convex + Vite project". Not for publishing a one-off artifact you already built — use `share-artifact`; not for a build-step-free esm.sh React app — use `build-artifact-app`; not for the multi-client backend split itself — see `mcp-dev`.
---

# Jason Prototype Stack

Idea → live at `<thing>.jasonv.dev` in an afternoon. This is the recipe
`focus.jasonv.dev` was built on (repo `~/dev/focus-timer`, github `jpvarbed/focus-timer`).
Copy the defaults; deviate only with a reason worth writing in an ADR.

**Announce at start:** "Using jason-prototype-stack to scaffold this."

## The stack (defaults)

- **Monorepo:** bun workspaces — `apps/web`, `apps/cli`, `packages/backend`, `skills/<name>`.
- **Frontend:** Vite + React 19 + Tailwind v4, a plain SPA (not Next.js — no SSR needed). Do
  one real design pass with the `frontend-design` skill; don't ship the default look.
- **Backend:** Convex — document DB + queries/mutations + scheduler + realtime + a generated
  typed client, in one system. No separate API server, no polling layer, no hand-written DB
  client. A scheduled function can advance state server-side with no client open.
- **Identity:** anonymous per-user id. Client generates `crypto.randomUUID()`, stores it
  locally, and passes it as a `userId` arg; data is scoped by `userId` via a `by_user` index.
  The UUID is unguessable so it doubles as the access capability — no password, no login prompt.
  Real login (Convex Auth) is an opt-in upgrade later that maps an identity → the same `userId`.
- **Clients reuse the backend:** web first; a `focus`-style CLI (`ConvexHttpClient` +
  `makeFunctionReference("file:export")` so it builds before codegen, id from an env var) and a
  Claude skill that wraps the CLI both drop in for near-free.
- **Hosting:** web = Vercel static (prebuilt `dist`); backend = Convex cloud; domain
  `<sub>.jasonv.dev`.
- **Docs in-repo:** `PLAN.md` (decision log/status), `SPEC.md` (glossary + invariants, OKF
  style), `docs/adr/` (hard-to-reverse decisions), `docs/*.svg` (diagrams).
- **Tickets:** Linear. focus-timer uses team **FOC**; a new product gets its own team. No Linear
  MCP — GraphQL API with `LINEAR_API_KEY` (header `Authorization: <key>`, no `Bearer`). Labels
  are team-scoped (moving an issue between teams drops custom labels).

## Build order (clients-first; it proves the design before any UI)

0. Brainstorm/`grill-me` the design. Write `PLAN.md` + `SPEC.md` + ADRs as decisions land.
1. **Backend:** Convex schema + pure helpers (unit-test these) + functions + any scheduled work.
   `cd packages/backend && npx convex dev --once` creates the deployment, generates the typed
   client, and typechecks — one shot.
2. **CLI:** thin `ConvexHttpClient` wrapper.
3. **Skill:** a `SKILL.md` that drives the CLI.
4. **Web:** Vite SPA; design pass; verify with the Claude Preview tools
   (`mcp__Claude_Preview__preview_start` → `mcp__Claude_Preview__preview_screenshot`), iterate on real screenshots.
5. **Deploy** (below).

## Provisioning — the commands that actually worked

```bash
# Convex (auth: ~/.convex/config.json = {"accessToken": "<CONVEX_PAT>"})
cd packages/backend
npx convex dev --once --configure new --project <name> --dev-deployment cloud   # creates cloud dev deployment
npx convex env set FOCUS_SECRET "$(openssl rand -hex 32)"                        # set server-side secrets here
# writes CONVEX_URL/CONVEX_DEPLOYMENT to packages/backend/.env.local

# GitHub (fine-grained PATs CANNOT create repos — use the gh keyring login)
env -u GH_TOKEN -u GITHUB_TOKEN gh repo create jpvarbed/<repo> --private --source=. --remote=origin --push

# Vercel (use VERCEL_FULL_TOKEN; needs --scope; deploy the prebuilt static dist)
bun --filter @<app>/web build
cp -R apps/web/dist /tmp/<name> && cd /tmp/<name>
vercel deploy --prod --yes --scope jpvarbeds-projects --token="$VERCEL_FULL_TOKEN"

# Custom domain on external DNS (the CLI `vercel domains add` 403s — use the project API)
curl -s -X POST "https://api.vercel.com/v10/projects/<project>/domains?teamId=<team>" \
  -H "Authorization: Bearer $VERCEL_FULL_TOKEN" -H "Content-Type: application/json" \
  -d '{"name":"<sub>.jasonv.dev"}'        # returns the TXT verify record
# then add DNS in Squarespace, then:
curl -s -X POST "https://api.vercel.com/v9/projects/<project>/domains/<sub>.jasonv.dev/verify?teamId=<team>" \
  -H "Authorization: Bearer $VERCEL_FULL_TOKEN"
```

DNS records for `<sub>.jasonv.dev`: **CNAME `<sub>` → `cname.vercel-dns.com`** + the **TXT
`_vercel`** verify value. Add them in **Squarespace** (`account.squarespace.com/domains/managed/
jasonv.dev/dns/dns-settings`) via the Claude-in-Chrome tools. Editing DNS triggers a Google
re-verify — the human completes that sign-in; don't drive logins.

## Secrets

`~/dev/.env.local` (plaintext, gitignored) + Bitwarden Secrets Manager (`bws`). Keys you'll
need: `CONVEX_PAT`, `VERCEL_FULL_TOKEN`, `LINEAR_API_KEY`, `BITWARDEN_ACCESS_TOKEN`, `gh` keyring
login. The GitHub fine-grained `GITHUB_PAT_LLC_TOKEN` exists but can't create repos.

## Errors

| Issue | Fix |
| --- | --- |
| `npx convex dev --once` fails to auth / no access token | Write `~/.convex/config.json` = `{"accessToken": "<CONVEX_PAT>"}`; fetch `CONVEX_PAT` from `~/dev/.env.local` or `bws`, never hardcode it. |
| Vercel deploy errors "project not found" / scope-related 403 | Pass `--scope jpvarbeds-projects` and `--token="$VERCEL_FULL_TOKEN"`; deploy the prebuilt `dist` (`cp -R apps/web/dist /tmp/<name>`), not the source. |
| `vercel domains add` returns 403 when attaching `<sub>.jasonv.dev` | Skip the CLI — `POST https://api.vercel.com/v10/projects/<project>/domains?teamId=<team>` with `Authorization: Bearer $VERCEL_FULL_TOKEN`, then hit the `/verify` endpoint. |
| `gh repo create` fails / can't create repo with a token | Fine-grained PATs (`GITHUB_PAT_LLC_TOKEN`) can't create repos — use the keyring login: `env -u GH_TOKEN -u GITHUB_TOKEN gh repo create ...`. |
| Domain stuck "pending verification" after adding it | DNS not propagated — add **CNAME `<sub>` → `cname.vercel-dns.com`** + **TXT `_vercel`** in Squarespace, wait, then re-run the Vercel `/verify` POST. |
| Convex `api` import is `undefined` / typed client missing | Codegen hasn't run — `cd packages/backend && npx convex dev --once` first; in the CLI use `makeFunctionReference("file:export")` so it builds pre-codegen. |
| Convex deploy rejects a schema change with validation error | Adding a required field to a table with rows fails — make it `v.optional(...)` or clear the test rows before deploying. |
| `noUncheckedIndexedAccess` makes Convex `anyApi` proxy `| undefined` | Don't use the `anyApi` proxy — call via `makeFunctionReference("file:export")` instead. |
| Diagram render hangs (Excalidraw CDN / `mermaid-cli` Puppeteer time out in sandbox) | Don't run headless-browser renderers — use the `show_widget` visualize tool and save a self-contained `.svg` to `docs/`. |
| Out of project slots provisioning secrets backend | Bitwarden SM free = 3 projects, Supabase free = 2 — that cap is why this stack uses Convex; reuse an existing project or go Convex. |

## Planned additions

- **Artifact sharing (next):** publish the nice artifacts built with Claude (SVGs, HTML
  widgets, markdown one-pagers) to a shareable link, `art.jasonv.dev/<id>`. First app to build
  on this stack. Spec: `~/dev/artifact-share/BRIEF.md` + Linear FOC-2.
