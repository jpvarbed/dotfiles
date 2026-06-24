#!/bin/sh
# focus fleet key -> launchd session env (FOC-25). GUI apps (Claude desktop, IDEs) don't source
# ~/.zshrc, so the CC fleet hook can't see FOCUS_API_KEY from the shell. This puts it in the user's
# launchd session via `launchctl setenv`, so every GUI-launched app started afterward inherits it.
#
# Run at login by ~/Library/LaunchAgents/dev.jasonv.focus-key.plist. The root bws token is read
# transiently from ~/dev/.env.local and never persisted; only FOCUS_API_KEY enters the session env.
# The key is write-only to Jason's fleet + one-click revocable. No-op on any failure.
TOKEN="$(sed -nE 's/^(export )?(BWS_ACCESS_TOKEN|BITWARDEN_ACCESS_TOKEN)="?([^"]*)"?$/\3/p' "$HOME/dev/.env.local" 2>/dev/null | head -1)"
[ -n "$TOKEN" ] || exit 0
KEY="$(BWS_ACCESS_TOKEN="$TOKEN" "$HOME/.local/bin/bws" secret list -o json 2>/dev/null \
  | /usr/bin/jq -r '.[]|select(.key=="FOCUS_API_KEY")|.value' | head -1)"
[ -n "$KEY" ] && [ "$KEY" != "null" ] && /bin/launchctl setenv FOCUS_API_KEY "$KEY"
exit 0
