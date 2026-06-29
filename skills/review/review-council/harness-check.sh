#!/usr/bin/env bash
# harness-check.sh — DETERMINISTIC pre-judge for the review council (no LLM).
# Computes objective facts about an artifact and a hard PASS/FAIL on gates that
# need no judgment. The council prints this first, feeds the facts to the LLM
# personas (so they grade against ground truth), and treats a HARNESS FAIL as a
# hard blocker on the council verdict — judgment can't override a fact.
#
#   harness-check.sh <artifact-file> [--gates <repo-dir>]
#
# Doc checks (always): unresolved markers, acceptance criteria, EARS requirements,
# task checkboxes, vague terms, spec sections.
# Repo gates (with --gates DIR, best-effort): typecheck / build / test / lint.

set -uo pipefail
FILE=""; REPO=""
while [ $# -gt 0 ]; do
  case "$1" in
    --gates) REPO="${2:-}"; shift 2;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    -*) echo "unknown flag: $1" >&2; exit 2;;
    *) FILE="$1"; shift;;
  esac
done
[ -n "$FILE" ] && [ -r "$FILE" ] || { echo "error: cannot read artifact: ${FILE:-<none>}" >&2; exit 2; }

blockers=()
cnt() { grep -cE "$1" "$FILE" 2>/dev/null || true; }

echo "===== HARNESS (deterministic — objective facts, no LLM) ====="

# artifact type
if   grep -qE '^(diff --git |--- |\+\+\+ |@@ )' "$FILE"; then TYPE="diff"
elif grep -qiE '^#+ .*(requirement|design|task)|THE SYSTEM SHALL|EARS' "$FILE"; then TYPE="spec-doc"
else TYPE="doc"; fi
echo "type: $TYPE"

# HARD GATE: unresolved markers
markers="$(grep -nE '<[A-Z][A-Z0-9_]{2,}>|\bTODO\b|\bFIXME\b|\bXXX\b|\bTBD\b|\?\?\?' "$FILE" 2>/dev/null || true)"
mn=$(printf '%s' "$markers" | grep -c . 2>/dev/null || true)
echo "unresolved_markers: $mn"
if [ "$mn" -gt 0 ]; then
  blockers+=("$mn unresolved marker(s) — TODO/FIXME/TBD/???/<PLACEHOLDER>; a plan ready to grade shouldn't contain them")
  printf '%s\n' "$markers" | head -6 | sed 's/^/    /'
fi

ac=$(cnt 'acceptance|expected behavior|done when|verif(y|ied)|criteria')
echo "acceptance_criteria_mentions: $ac"
ears=$(cnt '\b(WHEN|WHILE|IF|WHERE)\b.*\bSHALL\b')
echo "ears_requirements: $ears"
open=$(cnt '^[[:space:]]*[-*] \[ \]'); checked=$(cnt '^[[:space:]]*[-*] \[[xX]\]')
echo "task_checkboxes: $checked done / $((open+checked)) total"
vague=$(grep -onE '\b(fast|robust|scalable|seamless|simple|flexible|efficient|performant)\b' "$FILE" 2>/dev/null | wc -l | tr -d ' ')
echo "vague_terms: $vague (soft signal)"

if [ "$TYPE" = "spec-doc" ]; then
  # Kiro-style specs split across sibling files (requirements.md / design.md / tasks.md),
  # so a section counts as present if it's an in-file header OR a sibling file in the dir.
  SDIR="$(cd "$(dirname "$FILE")" && pwd)"
  for s in requirement design task; do
    if grep -qiE "^#+ .*$s" "$FILE" || ls "$SDIR/${s}"*.md >/dev/null 2>&1; then
      echo "section_${s}s: ok"
    else
      echo "section_${s}s: MISSING"; blockers+=("no '$s' section (in-file header or sibling ${s}*.md)")
    fi
  done
  grep -qiE 'non-?requirement|out of scope|not (build|do)|explicitly (not|does not)' "$FILE" && echo "section_non_requirements: ok" || echo "section_non_requirements: missing (soft)"
  [ "$ac" -eq 0 ] && blockers+=("0 acceptance/verification criteria — tasks aren't verifiable")
fi

# Repo gates (opt-in, best-effort)
if [ -n "$REPO" ]; then
  echo "--- repo gates ($REPO) ---"
  if [ ! -d "$REPO" ]; then echo "  (repo dir not found — skipping gates)"; else
    TO=""; command -v gtimeout >/dev/null 2>&1 && TO="gtimeout 300"; [ -z "$TO" ] && command -v timeout >/dev/null 2>&1 && TO="timeout 300"
    RUN="npm"; { [ -f "$REPO/bun.lock" ] || [ -f "$REPO/bun.lockb" ]; } && RUN="bun"
    X="npx"; [ "$RUN" = "bun" ] && X="bunx"
    has() { [ -f "$REPO/package.json" ] && grep -q "\"$1\"[[:space:]]*:" "$REPO/package.json"; }
    gate() { # label, cmd
      if ( cd "$REPO" && eval "$TO $2" ) >/dev/null 2>&1; then echo "  $1: PASS"
      else echo "  $1: FAIL"; blockers+=("repo gate '$1' FAILED — fix before grading"); fi
    }
    [ -f "$REPO/tsconfig.json" ] && gate typecheck "$X tsc --noEmit" || echo "  typecheck: skip (no tsconfig)"
    has build && gate build "$RUN run build" || echo "  build: skip (no script)"
    has test  && gate test  "$RUN run test"  || echo "  test: skip (no script)"
    has lint  && gate lint  "$RUN run lint"  || echo "  lint: skip (no script)"
  fi
fi

echo
if [ "${#blockers[@]}" -eq 0 ]; then
  echo "HARNESS VERDICT: PASS"
else
  echo "HARNESS VERDICT: FAIL"
  echo "HARNESS BLOCKERS:"
  for b in "${blockers[@]}"; do echo "  - $b"; done
fi
