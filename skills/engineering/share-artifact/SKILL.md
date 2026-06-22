---
name: share-artifact
description: Publish/host an app or artifact you built and get a public URL to share. Use after building something (an SVG/diagram, an interactive HTML widget, a Markdown one-pager, or a real multi-file React app via esm.sh) that you want to hand someone as a link, or when the user says "share this", "publish this", "host this", "give me a link", or "deploy this app". Works from ANY project — apps go live at artifacts.jasonv.dev/<slug>/.
---

# Share / host an app on Artifact Studio

Publishes to **Artifact Studio** (jpvarbed's agent-native app host). Output: a public URL,
`https://artifacts.jasonv.dev/<slug>/`. Works from any repo — the CLI and key are global.

**Announce at start:** "Using share-artifact to publish this."

## 1. Load credentials (from Bitwarden Secrets Manager, on demand — never hardcode)

```bash
set -a; source ~/dev/.env.local; set +a   # BWS_ACCESS_TOKEN
export ARTIFACT_API_BASE=$(bws secret list -o json | python3 -c "import sys,json;print(next(s['value'] for s in json.load(sys.stdin) if s['key']=='ARTIFACT_API_BASE'))")
export ARTIFACT_API_KEY=$(bws secret list -o json | python3 -c "import sys,json;print(next(s['value'] for s in json.load(sys.stdin) if s['key']=='ARTIFACT_API_KEY'))")
```

If `bws` or the token is missing, tell the user to run `~/dev/dotfiles/scripts/setup.sh` (pulls the
bws token) or to mint a key in the studio Settings (`artifacts.jasonv.dev`) and export it manually.

## 2a. Publish a single file (svg / html / markdown)

```bash
ART=~/dev/artifact-studio-tools/cli/src/index.ts
bun "$ART" share <file> --slug <slug> [--title "..."] [--visibility private|unlisted|public] [--comments]
```

`--kind` is inferred from the extension. `--slug` is the URL (`artifacts.jasonv.dev/<slug>/`),
slugified + globally unique (errors `taken`/`reserved` → pick another). Default visibility `unlisted`
(link gets a `?k=` token). Prints the URL — hand it back.

## 2b. Deploy a multi-file app — real React, no build step (esm.sh)

Write `index.html` + JS modules that import deps from a CDN at runtime (no bundler):

```html
<script type="importmap">{"imports":{"react":"https://esm.sh/react@19","react-dom/client":"https://esm.sh/react-dom@19/client"}}</script>
<div id="root"></div>
<script type="module" src="./app.js"></script>
```

Then deploy the folder (must contain `index.html`; use relative or CDN-absolute paths):

```bash
bun "$ART" deploy <dir> --slug <slug> [--title "..."] [--visibility ...] [--comments]
```

## 3. Optional managed backend (per-app key-value store)

```bash
bun "$ART" backend <slug>      # prints a per-app data key (shown once)
```

Embed it and call from the app's frontend (same origin):
`fetch("/api/kv/<collection>/<key>", { method:"PUT", headers:{ "X-App-Key": KEY }, body: JSON.stringify(v) })`
(GET returns `{value}`; `/api/kv/<collection>` lists). Shared storage, not per-end-user-private.

## Manage

```bash
bun "$ART" list            # your apps (slug, kind, visibility, url)
bun "$ART" get <slug>      # one app's metadata
bun "$ART" delete <slug>   # remove one
```

## Notes

- Apps run full-page on their own origin (`artifacts.jasonv.dev/<slug>/`), network allowed, isolated
  from the studio's keys. HTML/React apps run their JS live.
- Same actions are exposed as **MCP tools** (`publish_artifact`, `deploy_app`, `provision_backend`,
  `list/get/delete_artifact`) from `~/dev/artifact-studio-tools/mcp` (env: `ARTIFACT_API_BASE` +
  `ARTIFACT_API_KEY`), and as a REST API at `$ARTIFACT_API_BASE/v1` (`/openapi.json`).
- All agent-published apps are owned by the shared `jpvarbed` account (the global key) — manage them
  with `artifact list` or in the studio at `studio.artifacts.jasonv.dev`.
- Tooling repo (clone if missing): `~/dev/artifact-studio-tools` (github
  `jpvarbed/artifact-studio-tools`) — run `bun install` there once. The service (studio + backend)
  is the separate `jpvarbed/artifact-share` repo.
