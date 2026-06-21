#!/usr/bin/env bash
# rotate-age-key.sh — rotate the age key that protects the doc files.
#
# Old key decrypts the .age files, a new key re-encrypts them; updates
# age-recipient.txt and the DOTFILES_AGE_KEY secret in bws. Run when the age key
# may be compromised. Needs BWS_ACCESS_TOKEN exported (set BWS_PROJECT_ID if >1 project).
#
# CAVEAT: prior .age blobs stay in the PUBLIC git history and remain readable with
# the OLD key forever. Rotation protects future commits, not past ones — if the old
# key leaked, treat the historically-committed soul.md/knowledge contents as exposed.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEY="$HOME/.config/age/key.txt"; RECIP="$DOTFILES/age-recipient.txt"
say(){ printf '\033[1;34m==>\033[0m %s\n' "$*"; }

command -v age >/dev/null && command -v age-keygen >/dev/null || { echo "age not installed"; exit 1; }
[ -f "$KEY" ] || { echo "no current key at $KEY — nothing to rotate"; exit 1; }

tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT

say "Decrypting docs with the current key"
[ -f "$DOTFILES/soul.md.age" ]      && age -d -i "$KEY" "$DOTFILES/soul.md.age"      > "$tmp/soul.md"
[ -f "$DOTFILES/knowledge.tar.age" ] && age -d -i "$KEY" "$DOTFILES/knowledge.tar.age" > "$tmp/knowledge.tar"

say "Generating a new key"
mv "$KEY" "$KEY.old.$(date +%Y%m%d-%H%M%S)"
age-keygen -o "$KEY" 2>/dev/null; chmod 600 "$KEY"
age-keygen -y "$KEY" > "$RECIP"

say "Re-encrypting with the new key"
[ -f "$tmp/soul.md" ]      && age -R "$RECIP" -o "$DOTFILES/soul.md.age" "$tmp/soul.md"
[ -f "$tmp/knowledge.tar" ] && age -R "$RECIP" -o "$DOTFILES/knowledge.tar.age" "$tmp/knowledge.tar"

say "Updating DOTFILES_AGE_KEY in bws"
if [ -n "${BWS_ACCESS_TOKEN:-}" ] && command -v bws >/dev/null && command -v jq >/dev/null; then
  id="$(bws secret list -o json 2>/dev/null | jq -r '.[]|select(.key=="DOTFILES_AGE_KEY")|.id' | head -1)"
  if [ -n "$id" ] && [ "$id" != "null" ]; then
    bws secret edit "$id" --value "$(cat "$KEY")" >/dev/null && echo "   updated bws DOTFILES_AGE_KEY"
  else
    proj="${BWS_PROJECT_ID:-$(bws project list -o json 2>/dev/null | jq -r 'if length==1 then .[0].id else empty end')}"
    [ -n "$proj" ] && bws secret create DOTFILES_AGE_KEY "$(cat "$KEY")" "$proj" >/dev/null \
      && echo "   created bws DOTFILES_AGE_KEY" || echo "   set BWS_PROJECT_ID and store DOTFILES_AGE_KEY manually"
  fi
else echo "   export BWS_ACCESS_TOKEN, then update DOTFILES_AGE_KEY in bws manually"; fi

echo
echo "Done. Commit: soul.md.age, knowledge.tar.age, age-recipient.txt"
echo "Old key kept at $KEY.old.* — delete after you confirm the re-encrypted files work."