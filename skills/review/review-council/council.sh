#!/usr/bin/env bash
# council.sh — multi-model, multi-persona review council for a Claude-authored
# artifact (plan / spec / tasks / design / PRD / diff). Runs >=3 distinct personas
# across two independent outside engines — Codex (`codex exec`, yolo) and Gemini
# (via the sibling adversarial-review/gemini-review.sh) — and prints each persona's
# verdict + findings. Claude then SYNTHESIZES them into the council report (see SKILL.md).
#
#   council.sh [--focus "<what to attack hardest>"] <artifact-file>
#
# Diversity is the point: disagreement reflects BOTH different lenses (personas) AND
# different models (codex vs gemini). Edit the PERSONAS array to rebalance.

set -uo pipefail
FOCUS=""
FILE=""
while [ $# -gt 0 ]; do
  case "$1" in
    --focus) FOCUS="${2:-}"; shift 2;;
    -h|--help) sed -n '2,14p' "$0"; exit 0;;
    *) FILE="$1"; shift;;
  esac
done
[ -n "$FILE" ] && [ -f "$FILE" ] || { echo "usage: council.sh [--focus \"...\"] <artifact-file>" >&2; exit 2; }
ART="$(cat "$FILE")"
HERE="$(cd "$(dirname "$0")" && pwd)"
GEMINI_REVIEW="$HERE/../adversarial-review/gemini-review.sh"

RUBRIC='Return EXACTLY this shape, nothing else:
VERDICT: PASS | CONCERNS | FAIL
FINDINGS (<=3, ranked, most important first):
- [H|M|L] <claim> — <why it matters> — fix: <one concrete fix>
BIGGEST RISK: <one line>
Be specific to THIS artifact; no generic advice. If you must rely on facts not in the
artifact, say "assumption:" and do not invent gaps that may not exist.'

# name | engine | model | lens   (both engines represented; add a 4th to rebalance)
# Codex model "default" = let codex use the account's configured model (a pinned
# model like gpt-5-codex 400s on a ChatGPT-account login — only API-key logins get it).
PERSONAS=(
  "Architect|codex|default|Soundness & correctness — will this actually work end to end? Hidden assumptions, missing cases, integration & failure modes, wrong abstractions."
  "Pragmatist|gemini|gemini-2.5-pro|YAGNI & cost — is this over-engineered? Is there a simpler path? Scope creep? Is the effort justified by the value? Channel a blunt lazy-senior-dev."
  "Verifier|codex|default|Verifiability & risk — is every step's done-condition checkable with real acceptance criteria? Irreversible / blast-radius risks? Could 'success' be faked (reward-hacked)?"
)

run_codex() { # model, prompt
  local m=()
  [ -n "$1" ] && [ "$1" != "default" ] && m=(-m "$1")
  codex exec --dangerously-bypass-approvals-and-sandbox --skip-git-repo-check ${m[@]+"${m[@]}"} "$2" 2>&1
}

for p in "${PERSONAS[@]}"; do
  IFS='|' read -r name engine model lens <<< "$p"
  echo
  echo "===== PERSONA: $name  ($engine : $model) ====="
  base="You are the \"$name\" reviewer on a review council grading a colleague's work. LENS: $lens"
  [ -n "$FOCUS" ] && base="$base
EXTRA FOCUS: $FOCUS"
  case "$engine" in
    codex)
      run_codex "$model" "$base

$RUBRIC

--- ARTIFACT (review ONLY this text; do not modify any files) ---
$ART" ;;
    gemini)
      if [ -x "$GEMINI_REVIEW" ] || [ -f "$GEMINI_REVIEW" ]; then
        bash "$GEMINI_REVIEW" --model "$model" --focus "$base

$RUBRIC" "$FILE"
      else
        echo "(gemini-review.sh not found at $GEMINI_REVIEW — skipping gemini persona)"
      fi ;;
    *) echo "(unknown engine: $engine)" ;;
  esac
done
echo
echo "===== END COUNCIL — Claude now synthesizes per SKILL.md (majority verdict + deduped must-fix) ====="
