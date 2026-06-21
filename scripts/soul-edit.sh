#!/usr/bin/env bash
# soul-edit.sh — edit and (re)encrypt soul.md.
#
# - If only soul.md.age exists, decrypts it first (prompts passphrase).
# - Opens soul.md in $EDITOR (skip with --no-edit, e.g. for first-time sealing).
# - Re-encrypts to soul.md.age with a passphrase (age -p).
#
# soul.md (plaintext) stays local and gitignored; commit only soul.md.age.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLAIN="$DOTFILES/soul.md"
ENC="$DOTFILES/soul.md.age"

command -v age >/dev/null || { echo "age not installed (brew install age)"; exit 1; }

if [ -f "$ENC" ] && [ ! -f "$PLAIN" ]; then
  echo "Decrypting $ENC (enter passphrase)…"
  age -d "$ENC" > "$PLAIN"
fi

[ -f "$PLAIN" ] || { echo "No $PLAIN to edit. Create it first, then re-run."; exit 1; }

if [ "${1:-}" != "--no-edit" ]; then
  "${EDITOR:-vi}" "$PLAIN"
fi

echo "Encrypting -> $ENC (set/enter passphrase)…"
age -p -o "$ENC" "$PLAIN"
echo "Done. Commit $ENC; $PLAIN stays local (gitignored)."
