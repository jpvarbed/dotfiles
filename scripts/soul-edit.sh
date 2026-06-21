#!/usr/bin/env bash
# soul-edit.sh — edit and (re)encrypt soul.md. Non-interactive (age key mode).
#
# Encrypts to the public recipient (age-recipient.txt); decrypts with the private
# identity (~/.config/age/key.txt, pulled from bws by setup.sh). Run age-init.sh
# first if there's no recipient yet. Use --no-edit to just (re)seal.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLAIN="$DOTFILES/soul.md"; ENC="$DOTFILES/soul.md.age"
RECIP="$DOTFILES/age-recipient.txt"; KEY="$HOME/.config/age/key.txt"

command -v age >/dev/null || { echo "age not installed (brew install age)"; exit 1; }
[ -f "$RECIP" ] || { echo "No $RECIP — run scripts/age-init.sh first."; exit 1; }

if [ -f "$ENC" ] && [ ! -f "$PLAIN" ]; then
  [ -f "$KEY" ] || { echo "Need $KEY to decrypt — run setup.sh (pulls it from bws)."; exit 1; }
  age -d -i "$KEY" "$ENC" > "$PLAIN"
fi
[ -f "$PLAIN" ] || { echo "No $PLAIN to edit. Create it first."; exit 1; }

[ "${1:-}" != "--no-edit" ] && "${EDITOR:-vi}" "$PLAIN"

age -R "$RECIP" -o "$ENC" "$PLAIN"
echo "Encrypted -> $ENC (commit it). $PLAIN stays local (gitignored)."
