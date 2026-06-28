#!/usr/bin/env bash
# setup.sh — bootstrap this machine from dotfiles. Idempotent (safe to re-run).
#
# Root of trust (model B): ~/dev/.env.local holds BWS_ACCESS_TOKEN (your one
# master secret, kept in your password vault). bws is the source of truth for the
# age key and all other secrets. setup is fully non-interactive once .env.local
# exists:  .env.local -> bws -> age key -> decrypt soul.md / knowledge -> pull keys.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEV="$HOME/dev"
CLAUDE_DIR="$HOME/.claude"
AGE_KEY="$HOME/.config/age/key.txt"

say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '   \033[1;32m✓\033[0m %s\n' "$*"; }
warn() { printf '   \033[1;33m!\033[0m %s\n' "$*"; }
skip() { printf '   \033[2m· %s (skip)\033[0m\n' "$*"; }

# 1. Prerequisites -----------------------------------------------------------
say "Checking prerequisites"
command -v git  >/dev/null || warn "git not found — install Xcode CLT (xcode-select --install)"
command -v node >/dev/null || warn "node not found — some skills need it (brew install node)"
command -v jq   >/dev/null || warn "jq not found — needed to pull secrets from bws (brew install jq)"
if command -v brew >/dev/null; then
  command -v age >/dev/null && skip "age present" || { say "Installing age"; brew install age && ok "age installed"; }
else
  warn "Homebrew not found — install age manually (https://github.com/FiloSottile/age)"
fi
if command -v bws >/dev/null; then skip "bws present ($(bws --version 2>/dev/null))"
elif command -v cargo >/dev/null; then say "Installing bws via cargo"; cargo install bws && ok "bws installed"
else warn "bws missing and no cargo — release: https://github.com/bitwarden/sdk-sm/releases"; fi
if command -v skills >/dev/null; then skip "skills CLI present ($(skills --version 2>/dev/null))"
elif command -v npm >/dev/null; then say "Installing skills CLI"; npm i -g skills >/dev/null && ok "skills installed" || warn "skills CLI install failed (see npm error above)"
else warn "npm not found — skills.sh installs will fall back to npx"; fi

# 2. Skill collections -------------------------------------------------------
say "Cloning skill collections (if missing)"
clone() { if [ -e "$2" ]; then skip "$(basename "$2") exists"; elif git clone --depth 1 "$1" "$2" 2>/dev/null; then ok "cloned $(basename "$2")"; else warn "clone failed: $(basename "$2")"; fi; }
mkdir -p "$DEV"
clone https://github.com/obra/superpowers              "$DEV/superpowers"
clone https://github.com/mattpocock/skills             "$DEV/mattpocockskills"
clone https://github.com/get-convex/agent-skills       "$DEV/agent-skills"
clone https://github.com/get-convex/convex-backend-skill "$DEV/convex-backend-skill"
clone https://github.com/DietrichGebert/ponytail       "$DEV/ponytail"
clone https://github.com/cursor/plugins                "$DEV/plugins"
clone https://github.com/anthropics/knowledge-work-plugins "$DEV/knowledge-work-plugins"  # curated data+design skills
clone https://github.com/jpvarbed/artifact-studio-tools "$DEV/artifact-studio-tools"  # share-artifact CLI/MCP
# the share-artifact skill drives this CLI — install its deps
if [ -d "$DEV/artifact-studio-tools" ] && command -v bun >/dev/null; then
  (cd "$DEV/artifact-studio-tools" && bun install >/dev/null 2>&1) && ok "artifact-studio-tools deps" || warn "bun install failed in artifact-studio-tools"
fi

# 3. Link skills -> ~/.claude/skills -----------------------------------------
SKILLS_DIR="$CLAUDE_DIR/skills"; mkdir -p "$SKILLS_DIR"
link_skill() { ln -sfn "$1" "$SKILLS_DIR/$(basename "$1")"; }
if [ -f "$DEV/mattpocockskills/scripts/link-skills.sh" ]; then
  say "Linking mattpocock skills"; bash "$DEV/mattpocockskills/scripts/link-skills.sh" >/dev/null && ok "mattpocock linked"
  # culled in the skill-audit — link-skills re-adds everything, so drop these
  for x in teach scaffold-exercises setup-matt-pocock-skills migrate-to-shoehorn; do rm -f "$SKILLS_DIR/$x"; done
else warn "mattpocockskills/scripts/link-skills.sh missing"; fi
LIST="$DOTFILES/skills/external-skills.list"
if [ -f "$LIST" ]; then
  say "Linking curated cursor skills"; n=0
  while IFS= read -r p; do case "$p" in ''|\#*) continue;; esac
    if [ -f "$DEV/plugins/$p/SKILL.md" ]; then link_skill "$DEV/plugins/$p"; n=$((n+1)); else warn "missing: $p"; fi
  done < "$LIST"; ok "$n cursor skills linked"
else warn "skills/external-skills.list missing"; fi
# 3a. Link agents -> ~/.claude/agents (some plugins ship subagents their skills dispatch) ----
# A skill that calls `subagent_type: "x"` needs the agent def in ~/.claude/agents; link_skill alone
# (above) only installs the orchestrator skill, not the workers it fans out to.
AGENTS_DIR="$CLAUDE_DIR/agents"; mkdir -p "$AGENTS_DIR"
link_agent() { ln -sfn "$1" "$AGENTS_DIR/$(basename "$1")"; }
if [ -d "$DEV/plugins/thermos/agents" ]; then
  say "Linking thermos review subagents"; na=0
  for a in "$DEV/plugins/thermos/agents"/*.md; do [ -f "$a" ] && link_agent "$a" && na=$((na+1)); done
  ok "$na thermos agents linked"
fi

KWLIST="$DOTFILES/skills/knowledge-work-skills.list"
if [ -f "$KWLIST" ]; then
  say "Linking curated knowledge-work skills"; n=0
  while IFS= read -r p; do case "$p" in ''|\#*) continue;; esac
    if [ -f "$DEV/knowledge-work-plugins/$p/SKILL.md" ]; then link_skill "$DEV/knowledge-work-plugins/$p"; n=$((n+1)); else warn "missing: $p"; fi
  done < "$KWLIST"; ok "$n knowledge-work skills linked"
fi
say "Linking dotfiles' own skills"; m=0
while IFS= read -r -d '' s; do link_skill "$(dirname "$s")"; m=$((m+1)); done \
  < <(find "$DOTFILES/skills" -name SKILL.md -not -path '*/deprecated/*' -print0)
ok "$m own skills linked"

# build-artifact-app lives in the public tools repo (single source); link it too.
# share-artifact is NOT linked from there — dotfiles owns the bws-keyed variant above.
[ -d "$DEV/artifact-studio-tools/skills/build-artifact-app" ] \
  && link_skill "$DEV/artifact-studio-tools/skills/build-artifact-app" && ok "build-artifact-app linked"

# Convex skills (get-convex/agent-skills) — well-named, link the convex-* ones.
for s in convex convex-create-component convex-migration-helper convex-performance-audit convex-quickstart convex-setup-auth; do
  [ -d "$DEV/agent-skills/skills/$s" ] && link_skill "$DEV/agent-skills/skills/$s"
done

# 3b. skills.sh — individual third-party skills (symlinked, registry-managed) --
if command -v skills >/dev/null || command -v npx >/dev/null; then
  # entries: "<repo-url>|<skill-name>"  (add more as you adopt them)
  SKILLS_SH=(
    "https://github.com/jakubkrehel/make-interfaces-feel-better|make-interfaces-feel-better"
    "https://github.com/composiohq/awesome-claude-skills|domain-name-brainstormer"
    "https://github.com/schpet/linear-cli|linear-cli"
    "https://github.com/vercel-labs/agent-browser|agent-browser"   # verify UI in a real browser
    "https://github.com/vercel-labs/portless|portless"             # stable .localhost dev URLs
    "https://github.com/vercel-labs/emulate|emulate"               # offline fakes of Stripe/GitHub/AWS…
    "https://github.com/conorbronsdon/avoid-ai-writing|avoid-ai-writing"  # de-AI-ify writing (detector + score)
    "https://github.com/motion-creative/skills|hook-writing"              # marketing copy: hooks/ads/UGC
    "https://github.com/motion-creative/skills|hook-voice-patterns"
    "https://github.com/motion-creative/skills|hook-tactics"
    "https://github.com/motion-creative/skills|ad-concept-generator"
    "https://github.com/motion-creative/skills|ugc-scriptwriter"
  )
  # NOTE: only Claude Code natively consumes these global skills. skills.sh reports
  # broad multi-agent support, but Cursor/Gemini/OpenCode have no global-skills dir
  # it writes to — they only get the CLIs (e.g. `linear`) usable from any terminal.
  say "Installing skills.sh skills"
  for entry in "${SKILLS_SH[@]}"; do
    url="${entry%%|*}"; name="${entry##*|}"
    if [ -e "$SKILLS_DIR/$name" ]; then skip "$name"; continue; fi
    if command -v skills >/dev/null; then skills add "$url" --skill "$name" -g -y >/dev/null 2>&1 || true
    else npx --yes skills@latest add "$url" --skill "$name" -g -y >/dev/null 2>&1 || true; fi
    [ -e "$SKILLS_DIR/$name" ] && ok "$name" || warn "skills.sh failed: $name"
  done
else warn "no skills CLI or npx — skip skills.sh skills"; fi

# verification CLIs the skills above drive (emulate runs via npx, no global needed)
if command -v npm >/dev/null; then
  for c in agent-browser portless; do
    command -v "$c" >/dev/null && skip "$c present" || { npm i -g "$c" >/dev/null 2>&1 && ok "$c installed" || warn "$c install failed"; }
  done
fi
# pixelshot (PixelRAG) — the pixelbrowse skill drives it; CLI via pipx (PEP 668 safe)
if command -v pixelshot >/dev/null; then skip "pixelshot present"
else command -v pipx >/dev/null || { command -v brew >/dev/null && brew install pipx >/dev/null 2>&1; }
  command -v pipx >/dev/null && { pipx install pixelrag >/dev/null 2>&1 && ok "pixelshot installed" || warn "pixelshot: pipx install pixelrag"; } || warn "no pipx — pipx install pixelrag"
fi

# 4. Plugins (via the claude CLI) --------------------------------------------
if command -v claude >/dev/null; then
  if claude plugin list 2>/dev/null | grep -q "ponytail@ponytail"; then skip "ponytail installed"
  else say "Installing ponytail plugin"
    claude plugin marketplace add DietrichGebert/ponytail >/dev/null 2>&1 || true
    claude plugin install ponytail@ponytail >/dev/null 2>&1 && ok "ponytail installed" \
      || warn "ponytail install failed — /plugin install ponytail@ponytail"
  fi
  [ -d "$CLAUDE_DIR/plugins/marketplaces/superpowers-dev" ] && skip "superpowers registered" \
    || warn "superpowers: /plugin marketplace add obra/superpowers"
  if claude plugin list 2>/dev/null | grep -q "pixelbrowse@pixelrag-plugins"; then skip "pixelbrowse installed"
  else claude plugin marketplace add StarTrail-org/PixelRAG >/dev/null 2>&1 || true
    claude plugin install pixelbrowse@pixelrag-plugins >/dev/null 2>&1 && ok "pixelbrowse installed" \
      || warn "pixelbrowse: /plugin install pixelbrowse@pixelrag-plugins"; fi
else warn "claude CLI not found — install plugins via /plugin in-app"; fi

# 5. Secrets root: .env.local -> bws -> age key ------------------------------
say "Loading secrets root (~/dev/.env.local)"
ENVLOCAL="$DEV/.env.local"
if [ -f "$ENVLOCAL" ]; then
  # parse without sourcing (keys may contain dots); only need the access token
  while IFS= read -r line || [ -n "$line" ]; do
    line="${line#export }"
    case "$line" in BWS_ACCESS_TOKEN=*|BITWARDEN_ACCESS_TOKEN=*)
      v="${line#*=}"; v="${v%\"}"; v="${v#\"}"; export BWS_ACCESS_TOKEN="$v";; esac
  done < "$ENVLOCAL"
  [ -n "${BWS_ACCESS_TOKEN:-}" ] && ok "loaded BWS token from .env.local" || warn "no BWS/BITWARDEN token in .env.local"
else warn "no $ENVLOCAL — create it with BWS_ACCESS_TOKEN=… (paste from your vault)"; fi

if [ -n "${BWS_ACCESS_TOKEN:-}" ]; then
  ZRC="$HOME/.zshrc"
  if [ -f "$ZRC" ] && grep -qF 'dotfiles: load BWS token' "$ZRC"; then skip "zshrc has bws-load"
  else
    cat >> "$ZRC" <<'ZRCBLOCK'

# dotfiles: load BWS token on demand — run `bws-load` when you need bws
bws-load() { export BWS_ACCESS_TOKEN="$(sed -nE 's/^(export )?(BWS_ACCESS_TOKEN|BITWARDEN_ACCESS_TOKEN)="?([^"]*)"?$/\3/p' "$HOME/dev/.env.local" 2>/dev/null | head -1)"; echo "BWS token loaded into this shell."; }
ZRCBLOCK
    ok "zshrc now defines bws-load (on-demand, not auto-exported)"
  fi
  if bws secret list >/dev/null 2>&1; then ok "bws auth verified"; else warn "bws auth failed — token invalid/expired"; fi
  # pull the age identity key from bws (decrypts the doc files)
  if [ -f "$AGE_KEY" ]; then skip "age key present"
  elif command -v jq >/dev/null; then
    mkdir -p "$(dirname "$AGE_KEY")"
    k="$(bws secret list -o json 2>/dev/null | jq -r '.[]|select(.key=="DOTFILES_AGE_KEY")|.value' | head -1)"
    if [ -n "$k" ] && [ "$k" != "null" ]; then printf '%s\n' "$k" > "$AGE_KEY"; chmod 600 "$AGE_KEY"; ok "age key pulled from bws"
    else warn "DOTFILES_AGE_KEY not in bws — run scripts/age-init.sh and store it"; fi
  fi
else
  warn "no BWS_ACCESS_TOKEN — skipping bws/age/secret steps"
fi

# 6. soul.md -> every agent's global guidance file ---------------------------
say "Setting up soul.md (global prefs for all agents)"
if [ -f "$DOTFILES/soul.md.age" ]; then
  if [ ! -f "$DOTFILES/soul.md" ]; then
    [ -f "$AGE_KEY" ] && { age -d -i "$AGE_KEY" "$DOTFILES/soul.md.age" > "$DOTFILES/soul.md" && ok "decrypted soul.md"; } \
      || warn "no age key — can't decrypt soul.md.age"
  else skip "soul.md present"; fi
  if [ -f "$DOTFILES/soul.md" ]; then
    # Claude + Gemini auto-write memories to their global file, so give them an
    # @import of soul.md (a real file) — those writes stay local instead of
    # polluting/clobbering soul.md. Codex has no @import and doesn't auto-write → symlink.
    for tgt in "$CLAUDE_DIR/CLAUDE.md" "$HOME/.gemini/GEMINI.md"; do
      mkdir -p "$(dirname "$tgt")"
      if [ -f "$tgt" ] && [ ! -L "$tgt" ] && grep -qxF "@$DOTFILES/soul.md" "$tgt"; then skip "${tgt/#$HOME/~} imports soul.md"
      else
        if [ -e "$tgt" ] || [ -L "$tgt" ]; then mv "$tgt" "$tgt.bak.$(date +%s)" 2>/dev/null || rm -f "$tgt"; fi
        printf '@%s\n' "$DOTFILES/soul.md" > "$tgt"; ok "${tgt/#$HOME/~} imports soul.md"
      fi
    done
    ctgt="$HOME/.codex/AGENTS.md"; mkdir -p "$(dirname "$ctgt")"
    if [ -L "$ctgt" ]; then skip "${ctgt/#$HOME/~} linked"
    else [ -e "$ctgt" ] && mv "$ctgt" "$ctgt.bak.$(date +%s)"; ln -sfn "$DOTFILES/soul.md" "$ctgt"; ok "linked ${ctgt/#$HOME/~} -> soul.md"; fi
  fi
else warn "soul.md.age not found — create it with scripts/soul-edit.sh"; fi

# 6b. Knowledge base ---------------------------------------------------------
say "Setting up knowledge base"
if [ -f "$DOTFILES/knowledge.tar.age" ]; then
  if [ -d "$DOTFILES/skills/knowledge" ]; then skip "skills/knowledge present"
  elif [ -f "$AGE_KEY" ]; then bash "$DOTFILES/scripts/knowledge-edit.sh" unseal && ok "knowledge unsealed"
    [ -d "$DOTFILES/skills/knowledge/agentic-engineering" ] && link_skill "$DOTFILES/skills/knowledge/agentic-engineering"
  else warn "no age key — can't unseal knowledge.tar.age"; fi
else warn "knowledge.tar.age not found — create it with scripts/knowledge-edit.sh seal"; fi

# 7. Gemini CLI (adversarial-review) -----------------------------------------
say "Setting up Gemini CLI"
command -v gemini >/dev/null && skip "gemini present ($(gemini --version 2>/dev/null))" \
  || { command -v brew >/dev/null && { say "Installing gemini-cli"; brew install gemini-cli && ok "installed"; } || warn "install gemini-cli manually"; }
GSETTINGS="$HOME/.gemini/settings.json"
if [ -f "$GSETTINGS" ]; then skip "~/.gemini/settings.json exists"
else mkdir -p "$HOME/.gemini"; printf '{\n  "security": {\n    "auth": {\n      "selectedType": "gemini-api-key"\n    }\n  }\n}\n' > "$GSETTINGS"; ok "wrote ~/.gemini/settings.json"; fi
GENV="$HOME/.gemini/.env"
if [ -f "$GENV" ] && grep -q 'GEMINI_API_KEY' "$GENV"; then skip "~/.gemini/.env has key"
elif [ -n "${BWS_ACCESS_TOKEN:-}" ] && command -v jq >/dev/null; then
  # the gemini key is stored as GOOGLE_API_KEY; accept either name
  key="$(bws secret list -o json 2>/dev/null | jq -r '.[]|select(.key=="GEMINI_API_KEY" or .key=="GOOGLE_API_KEY")|.value' | head -1)"
  if [ -n "$key" ] && [ "$key" != "null" ]; then printf 'GEMINI_API_KEY=%s\n' "$key" > "$GENV"; chmod 600 "$GENV"; ok "wrote ~/.gemini/.env from bws"
  else warn "no GEMINI_API_KEY/GOOGLE_API_KEY in bws — set ~/.gemini/.env manually"; fi
else warn "can't fetch GEMINI_API_KEY (need bws token + jq)"; fi

# gy alias: gemini YOLO (auto-approve + skip trust) for adversarial-review etc
if [ -f "$HOME/.zshrc" ] && grep -qF 'alias gy=' "$HOME/.zshrc"; then skip "gy alias present"
else printf "\n# gemini YOLO (auto-approve + skip trust) — adversarial-review etc\nalias gy='gemini --yolo --skip-trust'\n" >> "$HOME/.zshrc"; ok "added gy alias"; fi

# 8. Scheduled-task bodies ---------------------------------------------------
# Track task SKILL.md bodies in the repo; symlink them into ~/.claude. NOTE: this
# restores the *body* only — the cron registration is separate (re-create via the
# scheduled-tasks tool in Claude Code on a new machine).
if [ -d "$DOTFILES/scheduled-tasks" ]; then
  for d in "$DOTFILES/scheduled-tasks"/*/; do
    [ -f "${d}SKILL.md" ] || continue
    name=$(basename "$d"); live="$CLAUDE_DIR/scheduled-tasks/$name"
    mkdir -p "$live"
    ln -sfn "${d}SKILL.md" "$live/SKILL.md"; ok "linked scheduled-task $name"
  done
fi

say "Done. Open a new shell to pick up env changes."
