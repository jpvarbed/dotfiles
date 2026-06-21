#!/usr/bin/env bash
# env-to-bws.sh — migrate secrets from ~/dev/.env.local into Bitwarden Secrets
# Manager, leaving .env.local with only the BWS access token (model B).
#
# Run this in YOUR terminal. Values are never printed. Existing bws secrets are
# never overwritten (skipped). The BWS/BITWARDEN access token itself is not pushed.
#
#   env-to-bws.sh --dry-run   list what WOULD be pushed (no bws calls, names only)
#   env-to-bws.sh             push missing secrets to bws (does NOT touch .env.local)
#   env-to-bws.sh --slim      push, then rewrite .env.local to just BWS_ACCESS_TOKEN
#                             (original backed up to .env.local.bak.<timestamp>)
#
# Set BWS_PROJECT_ID to choose the target project if you have more than one.
set -euo pipefail

MODE="${1:-push}"
ENVLOCAL="$HOME/dev/.env.local"
[ -f "$ENVLOCAL" ] || { echo "no $ENVLOCAL"; exit 1; }

# Parse .env.local line-by-line (no sourcing — keys may contain dots, and we never
# want to execute the file). Capture the access token; collect the rest into two
# parallel indexed arrays (bash 3.2 has no associative arrays).
TOKEN=""; KEYS=(); VALS=()
while IFS= read -r line || [ -n "$line" ]; do
  case "$line" in ''|\#*) continue;; esac
  line="${line#export }"
  [ "$line" = "${line#*=}" ] && continue        # no '=' → skip
  key="${line%%=*}"; val="${line#*=}"
  key="${key#"${key%%[![:space:]]*}"}"; key="${key%"${key##*[![:space:]]}"}"  # trim
  # Single-line values only. An opening quote with no closing quote = multiline
  # (e.g. a PEM key) — skip rather than silently corrupt it; migrate those by hand.
  case "$val" in
    \"*\") val="${val#\"}"; val="${val%\"}";;
    \'*\') val="${val#\'}"; val="${val%\'}";;
    \"*|\'*) echo "  ! skipping $key — multiline/unterminated value, migrate manually"; continue;;
  esac
  case "$key" in
    BWS_ACCESS_TOKEN|BITWARDEN_ACCESS_TOKEN) TOKEN="$val";;
    *) KEYS+=("$key"); VALS+=("$val");;
  esac
done < "$ENVLOCAL"

if [ "$MODE" = "--dry-run" ]; then
  echo "DRY RUN — no bws calls. Would push these ${#KEYS[@]} keys (token excluded):"
  i=0; while [ "$i" -lt "${#KEYS[@]}" ]; do
    if [ -n "${VALS[$i]}" ]; then echo "  + ${KEYS[$i]}"; else echo "  · ${KEYS[$i]} (empty, skipped)"; fi
    i=$((i+1))
  done
  [ -n "$TOKEN" ] && echo "Access token found (kept in .env.local as BWS_ACCESS_TOKEN after --slim)." \
                  || echo "WARNING: no access token found in .env.local."
  exit 0
fi

command -v bws >/dev/null || { echo "bws not installed"; exit 1; }
command -v jq  >/dev/null || { echo "jq not installed (brew install jq)"; exit 1; }
[ -n "$TOKEN" ] || { echo "no BWS_ACCESS_TOKEN / BITWARDEN_ACCESS_TOKEN in .env.local"; exit 1; }
export BWS_ACCESS_TOKEN="$TOKEN"

# Resolve target project
PROJECT="${BWS_PROJECT_ID:-}"
if [ -z "$PROJECT" ]; then
  pcount="$(bws project list -o json | jq 'length')"
  if [ "$pcount" = "1" ]; then PROJECT="$(bws project list -o json | jq -r '.[0].id')"
  else echo "Found $pcount bws projects — set BWS_PROJECT_ID and re-run:"; bws project list -o json | jq -r '.[]|"  \(.id)  \(.name)"'; exit 1; fi
fi
echo "Target bws project: $PROJECT"

existing="$(bws secret list "$PROJECT" -o json | jq -r '.[].key')"
created=0; skipped=0; empty=0
i=0; while [ "$i" -lt "${#KEYS[@]}" ]; do
  k="${KEYS[$i]}"; v="${VALS[$i]}"; i=$((i+1))
  if printf '%s\n' "$existing" | grep -qxF "$k"; then skipped=$((skipped+1)); continue; fi
  [ -n "$v" ] || { empty=$((empty+1)); continue; }
  bws secret create "$k" "$v" "$PROJECT" >/dev/null && { echo "  + $k"; created=$((created+1)); }
done
echo "Done: $created created, $skipped already in bws, $empty empty/skipped."

if [ "$MODE" = "--slim" ]; then
  bak="$ENVLOCAL.bak.$(date +%Y%m%d-%H%M%S)"
  cp "$ENVLOCAL" "$bak"
  { echo "# Secrets root (model B): only the BWS token lives here. Everything else is in bws."
    echo "BWS_ACCESS_TOKEN=$TOKEN"; } > "$ENVLOCAL"
  chmod 600 "$ENVLOCAL"
  echo "Slimmed $ENVLOCAL → only BWS_ACCESS_TOKEN (backup: $bak)."
fi
