#!/usr/bin/env bash
# bws-token-set.sh — capture the BWS_ACCESS_TOKEN and age-encrypt it.
#
# Reads the token from a hidden prompt (never written to disk in plaintext),
# pipes it straight into age -p, and writes bws-token.age. Commit that file;
# setup.sh decrypts it into ~/.config/bws/access-token on each machine.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENC="$DOTFILES/bws-token.age"

command -v age >/dev/null || { echo "age not installed (brew install age)"; exit 1; }

printf 'Paste BWS_ACCESS_TOKEN (input hidden): '
read -rs TOKEN
echo
[ -n "$TOKEN" ] || { echo "Empty token — aborting."; exit 1; }

echo "Encrypting -> $ENC (set/enter passphrase)…"
printf '%s' "$TOKEN" | age -p -o "$ENC"
unset TOKEN
echo "Done. Commit $ENC; run scripts/setup.sh to install it on a machine."
