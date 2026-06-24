#!/bin/sh
# Periodic Neo4j projection sync (FOC-30), run by launchd (dev.jasonv.focus-graph-sync.plist) on a
# StartInterval so Aura stays fresh without manual `graph.ts sync`. launchd has a bare PATH and no
# env, so set a PATH and pull NEO4J_* + FOCUS_API_KEY from bws (root token read transiently from
# ~/dev/.env.local; only the needed vars enter this process). No-op on any failure.
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$HOME/.bun/bin:$HOME/.local/bin"
TOKEN="$(sed -nE 's/^(export )?(BWS_ACCESS_TOKEN|BITWARDEN_ACCESS_TOKEN)="?([^"]*)"?$/\3/p' "$HOME/dev/.env.local" 2>/dev/null | head -1)"
[ -n "$TOKEN" ] || exit 0
eval "$(BWS_ACCESS_TOKEN="$TOKEN" bws secret list -o json 2>/dev/null \
  | jq -r '.[] | select(.key=="NEO4J_URI" or .key=="NEO4J_USERNAME" or .key=="NEO4J_PASSWORD" or .key=="FOCUS_API_KEY") | "export \(.key)=\(.value|@sh)"')"
[ -n "$FOCUS_API_KEY" ] && [ -n "$NEO4J_URI" ] || exit 0
export FOCUS_CONVEX_SITE="${FOCUS_CONVEX_SITE:-https://vivid-ant-124.convex.site}"
cd "$HOME/dev/focus-timer-tools" || exit 1
exec bun scripts/graph.ts sync
