#!/usr/bin/env bash
# knowledge-edit.sh — seal / unseal the personal knowledge base (age key mode).
#
# skills/knowledge/ is personal (reading-list KB, work email, notes) and the repo
# is PUBLIC, so the plaintext tree is gitignored and only knowledge.tar.age (the
# encrypted archive) is committed.
#   seal     tar skills/knowledge/ -> knowledge.tar.age   (commit this)
#   unseal   knowledge.tar.age -> skills/knowledge/        (local, gitignored)
# Encrypts to the public recipient; decrypts with the private identity from bws.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENC="$DOTFILES/knowledge.tar.age"
RECIP="$DOTFILES/age-recipient.txt"; KEY="$HOME/.config/age/key.txt"

command -v age >/dev/null || { echo "age not installed (brew install age)"; exit 1; }
[ -f "$RECIP" ] || { echo "No $RECIP — run scripts/age-init.sh first."; exit 1; }

case "${1:-}" in
  seal)
    [ -d "$DOTFILES/skills/knowledge" ] || { echo "No skills/knowledge to seal."; exit 1; }
    tar -C "$DOTFILES/skills" -cf - knowledge | age -R "$RECIP" -o "$ENC"
    echo "Sealed -> $ENC (commit it). skills/knowledge/ stays local (gitignored)." ;;
  unseal)
    [ -f "$ENC" ] || { echo "No $ENC to unseal."; exit 1; }
    [ -f "$KEY" ] || { echo "Need $KEY to decrypt — run setup.sh (pulls it from bws)."; exit 1; }
    age -d -i "$KEY" "$ENC" | tar -C "$DOTFILES/skills" -xf -
    echo "Unsealed -> $DOTFILES/skills/knowledge/." ;;
  *) echo "usage: knowledge-edit.sh {seal|unseal}"; exit 2 ;;
esac
