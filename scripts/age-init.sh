#!/usr/bin/env bash
# age-init.sh — one-time: create the age key that protects the doc files.
#
# Encryption uses a PUBLIC recipient (age-recipient.txt, committed to the repo).
# Decryption uses the PRIVATE identity (~/.config/age/key.txt), which you store in
# bws as DOTFILES_AGE_KEY so other machines pull it via the BWS token. Run once.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEY="$HOME/.config/age/key.txt"
RECIP="$DOTFILES/age-recipient.txt"

command -v age-keygen >/dev/null || { echo "age not installed (brew install age)"; exit 1; }

# Lockout guard: a committed recipient + no local key means this is a NEW machine
# that should PULL the existing key, not mint a fresh one (which couldn't decrypt
# the already-committed *.age files).
if [ ! -f "$KEY" ] && [ -f "$RECIP" ]; then
  echo "Refusing: $RECIP exists but there's no local key at $KEY." >&2
  echo "Generating a new key here would orphan the committed *.age files." >&2
  echo "Run scripts/setup.sh (pulls DOTFILES_AGE_KEY from bws), or copy key.txt from another machine." >&2
  exit 1
fi

if [ -f "$KEY" ]; then
  echo "age identity already exists at $KEY"
else
  mkdir -p "$(dirname "$KEY")"
  age-keygen -o "$KEY" 2>/dev/null
  chmod 600 "$KEY"
  echo "Generated age identity at $KEY"
fi

age-keygen -y "$KEY" > "$RECIP"
echo
echo "Public recipient (commit $RECIP):"
cat "$RECIP"
echo

# Store the PRIVATE identity in bws (best effort) so new machines can decrypt.
stored=""
if [ -n "${BWS_ACCESS_TOKEN:-}" ] && command -v bws >/dev/null && command -v jq >/dev/null; then
  proj="${BWS_PROJECT_ID:-$(bws project list -o json 2>/dev/null | jq -r 'if length==1 then .[0].id else empty end')}"
  if [ -n "$proj" ]; then
    if bws secret list "$proj" -o json 2>/dev/null | jq -e '.[]|select(.key=="DOTFILES_AGE_KEY")' >/dev/null; then
      echo "DOTFILES_AGE_KEY already in bws (left as-is)."; stored=1
    elif bws secret create DOTFILES_AGE_KEY "$(cat "$KEY")" "$proj" >/dev/null 2>&1; then
      echo "Stored DOTFILES_AGE_KEY in bws (project $proj)."; stored=1
    fi
  fi
fi
if [ -z "$stored" ]; then
  echo "Store the PRIVATE identity in bws manually (need BWS_ACCESS_TOKEN exported):"
  echo "  bws secret create DOTFILES_AGE_KEY \"\$(cat $KEY)\" <PROJECT_ID>"
fi
echo
echo "Then seal your files:  scripts/soul-edit.sh --no-edit  &&  scripts/knowledge-edit.sh seal"
