#!/usr/bin/env bash
# knowledge-edit.sh — seal / unseal the personal knowledge base.
#
# skills/knowledge/ holds personal content (reading-list KB, work email in
# CURATOR.md, private notes). The dotfiles repo is PUBLIC, so the plaintext tree
# is gitignored and only the encrypted archive (knowledge.tar.age) is committed.
#
#   knowledge-edit.sh seal     tar skills/knowledge/ -> knowledge.tar.age (commit this)
#   knowledge-edit.sh unseal   knowledge.tar.age -> skills/knowledge/ (local, gitignored)
#
# The curator agent works on the plaintext tree; run `seal` after it updates the KB.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIR="$DOTFILES/skills/knowledge"
ENC="$DOTFILES/knowledge.tar.age"

command -v age >/dev/null || { echo "age not installed (brew install age)"; exit 1; }

case "${1:-}" in
  seal)
    [ -d "$DIR" ] || { echo "No $DIR to seal."; exit 1; }
    echo "Sealing $DIR -> $ENC (set/enter passphrase)…"
    tar -C "$DOTFILES/skills" -cf - knowledge | age -p -o "$ENC"
    echo "Done. Commit $ENC; skills/knowledge/ stays local (gitignored)."
    ;;
  unseal)
    [ -f "$ENC" ] || { echo "No $ENC to unseal."; exit 1; }
    echo "Unsealing $ENC -> $DIR (enter passphrase)…"
    age -d "$ENC" | tar -C "$DOTFILES/skills" -xf -
    echo "Done. Plaintext restored to $DIR."
    ;;
  *)
    echo "usage: knowledge-edit.sh {seal|unseal}"; exit 2 ;;
esac
