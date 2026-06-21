#!/usr/bin/env bash
# setup.sh — bootstrap this machine from dotfiles.
#
# Idempotent: safe to re-run. Anything already in place is skipped.
# Full bootstrap: prerequisites, skill collections, skill linking,
# soul.md (-> ~/.claude/CLAUDE.md), and the Bitwarden Secrets Manager token.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEV="$HOME/dev"
CLAUDE_DIR="$HOME/.claude"

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '   \033[1;32m✓\033[0m %s\n' "$*"; }
warn() { printf '   \033[1;33m!\033[0m %s\n' "$*"; }
skip() { printf '   \033[2m· %s (skip)\033[0m\n' "$*"; }

# 1. Prerequisites -----------------------------------------------------------
say "Checking prerequisites"
command -v git  >/dev/null || warn "git not found — install Xcode CLT (xcode-select --install)"
command -v node >/dev/null || warn "node not found — some skills need it (brew install node)"

if command -v brew >/dev/null; then
  if command -v age >/dev/null; then skip "age present"
  else say "Installing age"; brew install age && ok "age installed"; fi
else
  warn "Homebrew not found — install age manually (https://github.com/FiloSottile/age)"
fi

if command -v bws >/dev/null; then
  skip "bws present ($(bws --version 2>/dev/null))"
elif command -v cargo >/dev/null; then
  say "Installing bws via cargo (compiles from source, slow)"
  cargo install bws && ok "bws installed"
else
  warn "bws missing and no cargo — download a release into ~/.local/bin:"
  warn "  https://github.com/bitwarden/sdk-sm/releases"
fi

# 2. Skill collections -------------------------------------------------------
say "Cloning skill collections (if missing)"
clone() { # $1 = git url, $2 = dest dir
  if [ -d "$2/.git" ]; then skip "$(basename "$2")"
  else git clone --depth 1 "$1" "$2" && ok "cloned $(basename "$2")"; fi
}
mkdir -p "$DEV"
clone https://github.com/obra/superpowers              "$DEV/superpowers"
clone https://github.com/mattpocock/skills             "$DEV/mattpocockskills"
clone https://github.com/get-convex/agent-skills       "$DEV/agent-skills"
clone https://github.com/get-convex/convex-backend-skill "$DEV/convex-backend-skill"
clone https://github.com/DietrichGebert/ponytail       "$DEV/ponytail"
clone https://github.com/cursor/plugins                "$DEV/plugins"

# 3. Link skills -> ~/.claude/skills -----------------------------------------
SKILLS_DIR="$CLAUDE_DIR/skills"
mkdir -p "$SKILLS_DIR"
link_skill() { ln -sfn "$1" "$SKILLS_DIR/$(basename "$1")"; }  # $1 = skill dir

if [ -f "$DEV/mattpocockskills/scripts/link-skills.sh" ]; then
  say "Linking mattpocock skills -> ~/.claude/skills"
  bash "$DEV/mattpocockskills/scripts/link-skills.sh" >/dev/null && ok "mattpocock skills linked"
else
  warn "mattpocockskills/scripts/link-skills.sh not found — clone step may have failed"
fi

# Curated cursor/plugins skills (cursor uses .cursor-plugin, not a CC marketplace)
LIST="$DOTFILES/skills/external-skills.list"
if [ -f "$LIST" ]; then
  say "Linking curated cursor skills -> ~/.claude/skills"
  n=0
  while IFS= read -r p; do
    case "$p" in ''|\#*) continue;; esac
    if [ -f "$DEV/plugins/$p/SKILL.md" ]; then link_skill "$DEV/plugins/$p"; n=$((n+1))
    else warn "missing cursor skill: $p"; fi
  done < "$LIST"
  ok "$n cursor skills linked"
else
  warn "skills/external-skills.list not found"
fi

# My own dotfiles skills (engineering/, knowledge/, … ; skip deprecated)
say "Linking dotfiles' own skills -> ~/.claude/skills"
m=0
while IFS= read -r -d '' s; do
  link_skill "$(dirname "$s")"; m=$((m+1))
done < <(find "$DOTFILES/skills" -name SKILL.md -not -path '*/deprecated/*' -print0)
ok "$m own skills linked"

# 4. Plugin marketplaces (registered in-app) ---------------------------------
if [ -d "$CLAUDE_DIR/plugins/marketplaces/superpowers-dev" ]; then
  skip "superpowers marketplace registered"
else
  warn "superpowers not registered — in Claude Code: /plugin marketplace add obra/superpowers"
fi
# ponytail is a real Claude Code plugin (node hooks; node is required)
if [ -d "$CLAUDE_DIR/plugins/marketplaces/ponytail" ]; then
  skip "ponytail marketplace registered"
else
  warn "ponytail not registered — in Claude Code:"
  warn "  /plugin marketplace add DietrichGebert/ponytail && /plugin install ponytail@ponytail"
fi

# 5. soul.md -> ~/.claude/CLAUDE.md ------------------------------------------
say "Setting up soul.md (global working preferences)"
if [ -f "$DOTFILES/soul.md.age" ]; then
  if [ ! -f "$DOTFILES/soul.md" ]; then
    say "Decrypting soul.md.age (enter your passphrase)"
    age -d "$DOTFILES/soul.md.age" > "$DOTFILES/soul.md" && ok "decrypted soul.md"
  else
    skip "soul.md already decrypted"
  fi
  mkdir -p "$CLAUDE_DIR"
  if [ -L "$CLAUDE_DIR/CLAUDE.md" ]; then
    skip "~/.claude/CLAUDE.md symlink exists"
  else
    if [ -e "$CLAUDE_DIR/CLAUDE.md" ]; then
      mv "$CLAUDE_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.bak.$(date +%s)"
      warn "backed up existing ~/.claude/CLAUDE.md"
    fi
    ln -sfn "$DOTFILES/soul.md" "$CLAUDE_DIR/CLAUDE.md"
    ok "linked ~/.claude/CLAUDE.md -> dotfiles/soul.md"
  fi
else
  warn "soul.md.age not found — create it with scripts/soul-edit.sh"
fi

# 5b. Personal knowledge base ------------------------------------------------
say "Setting up knowledge base"
if [ -f "$DOTFILES/knowledge.tar.age" ]; then
  if [ -d "$DOTFILES/skills/knowledge" ]; then
    skip "skills/knowledge already present"
  else
    say "Unsealing knowledge.tar.age (enter your passphrase)"
    bash "$DOTFILES/scripts/knowledge-edit.sh" unseal && ok "knowledge unsealed"
    [ -d "$DOTFILES/skills/knowledge/agentic-engineering" ] && \
      link_skill "$DOTFILES/skills/knowledge/agentic-engineering"
  fi
else
  warn "knowledge.tar.age not found — create it with scripts/knowledge-edit.sh seal"
fi

# 6. Bitwarden Secrets Manager token -----------------------------------------
say "Setting up Bitwarden Secrets Manager (bws) token"
TOKEN_FILE="$HOME/.config/bws/access-token"
if [ -f "$DOTFILES/bws-token.age" ]; then
  if [ ! -f "$TOKEN_FILE" ]; then
    mkdir -p "$(dirname "$TOKEN_FILE")"
    say "Decrypting bws-token.age (enter your passphrase)"
    age -d "$DOTFILES/bws-token.age" > "$TOKEN_FILE"
    chmod 600 "$TOKEN_FILE"
    ok "wrote $TOKEN_FILE (chmod 600)"
  else
    skip "bws token already present"
  fi
  ZRC="$HOME/.zshrc"
  if [ -f "$ZRC" ] && grep -qF 'BWS_ACCESS_TOKEN' "$ZRC"; then
    skip "~/.zshrc already exports BWS_ACCESS_TOKEN"
  else
    {
      printf '\n# Bitwarden Secrets Manager (added by dotfiles setup.sh)\n'
      printf 'export BWS_ACCESS_TOKEN="$(cat "$HOME/.config/bws/access-token" 2>/dev/null)"\n'
    } >> "$ZRC"
    ok "added BWS_ACCESS_TOKEN export to ~/.zshrc (restart shell to load)"
  fi
  if BWS_ACCESS_TOKEN="$(cat "$TOKEN_FILE")" bws secret list >/dev/null 2>&1; then
    ok "bws auth verified (secret list succeeded)"
  else
    warn "bws auth check failed — token may be invalid or expired"
  fi
else
  warn "bws-token.age not found — create it with scripts/bws-token-set.sh"
fi

# 7. Gemini CLI (for adversarial-review) -------------------------------------
say "Setting up Gemini CLI (adversarial-review)"
if command -v gemini >/dev/null; then
  skip "gemini present ($(gemini --version 2>/dev/null))"
elif command -v brew >/dev/null; then
  say "Installing gemini-cli"; brew install gemini-cli && ok "gemini-cli installed"
else
  warn "gemini missing and no brew — install gemini-cli manually"
fi
# Force API-key auth (avoids the OAuth/SUBSCRIPTION_REQUIRED path)
GSETTINGS="$HOME/.gemini/settings.json"
if [ -f "$GSETTINGS" ]; then
  skip "~/.gemini/settings.json exists"
else
  mkdir -p "$HOME/.gemini"
  printf '{\n  "security": {\n    "auth": {\n      "selectedType": "gemini-api-key"\n    }\n  }\n}\n' > "$GSETTINGS"
  ok "wrote ~/.gemini/settings.json (gemini-api-key auth)"
fi
# API key: pull GEMINI_API_KEY from bws if we don't already have it
GENV="$HOME/.gemini/.env"
if [ -f "$GENV" ] && grep -q 'GEMINI_API_KEY' "$GENV"; then
  skip "~/.gemini/.env already has GEMINI_API_KEY"
elif [ -f "$TOKEN_FILE" ] && command -v bws >/dev/null && command -v jq >/dev/null; then
  key="$(BWS_ACCESS_TOKEN="$(cat "$TOKEN_FILE")" bws secret list -o json 2>/dev/null \
        | jq -r '.[] | select(.key=="GEMINI_API_KEY") | .value' | head -1)"
  if [ -n "$key" ] && [ "$key" != "null" ]; then
    printf 'GEMINI_API_KEY=%s\n' "$key" > "$GENV"; chmod 600 "$GENV"
    ok "wrote ~/.gemini/.env from bws"
  else
    warn "GEMINI_API_KEY not found in bws — add it there, or set ~/.gemini/.env manually"
  fi
else
  warn "can't fetch GEMINI_API_KEY (need bws token + jq) — set ~/.gemini/.env manually"
fi

say "Done. Open a new shell (or 'source ~/.zshrc') to pick up env changes."
