#!/bin/sh
# GUI session keys -> launchd env (FOC-25 + Arize cc-tracing). GUI apps (Claude desktop, IDEs) don't
# source ~/.zshrc, so they can't see shell-exported keys. This puts the keys in the user's launchd
# session via `launchctl setenv`, so every GUI-launched app started afterward inherits them:
#   FOCUS_API_KEY  — the CC fleet hook reports presence/commits (write-only, revocable)
#   ARIZE_API_KEY  — the claude-code-tracing plugin ships OpenInference spans to Arize
#
# Run at login by ~/Library/LaunchAgents/dev.jasonv.focus-key.plist. The root bws token is read
# transiently from ~/dev/.env.local and never persisted; only the named keys enter the session env.
# No-op on any failure.
TOKEN="$(sed -nE 's/^(export )?(BWS_ACCESS_TOKEN|BITWARDEN_ACCESS_TOKEN)="?([^"]*)"?$/\3/p' "$HOME/dev/.env.local" 2>/dev/null | head -1)"
[ -n "$TOKEN" ] || exit 0
JSON="$(BWS_ACCESS_TOKEN="$TOKEN" "$HOME/.local/bin/bws" secret list -o json 2>/dev/null)"
[ -n "$JSON" ] || exit 0

set_key() {  # $1 = secret name → launchctl setenv if present
  v="$(printf '%s' "$JSON" | /usr/bin/jq -r --arg k "$1" '.[]|select(.key==$k)|.value' | head -1)"
  [ -n "$v" ] && [ "$v" != "null" ] && /bin/launchctl setenv "$1" "$v"
}
set_key FOCUS_API_KEY
set_key ARIZE_API_KEY
exit 0
