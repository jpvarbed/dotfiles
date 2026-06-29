---
name: daily-dev-digest
description: Daily digest: update skills + scan Claude Code / Matt Pocock / agentic-eng sources, write a dated digest to dotfiles.
---

Daily dev digest for Jason. Run focused and cheap — don't rabbit-hole. Each run is fresh (no memory of prior sessions). Today's date is available in your context; use it as <DATE> (YYYY-MM-DD).

## 1. Update skills (local)
- `git pull` (ff-only) each git checkout if present: `~/dev/mattpocockskills`, `~/dev/plugins` (cursor), `~/dev/knowledge-work-plugins`, `~/dev/superpowers`. Note new commits/skills.
- `skills update -g -y` (skills.sh-managed skills).
- Re-link mattpocock + re-apply culls: `bash ~/dev/mattpocockskills/scripts/link-skills.sh`; then `rm -f ~/.claude/skills/teach ~/.claude/skills/scaffold-exercises ~/.claude/skills/setup-matt-pocock-skills ~/.claude/skills/migrate-to-shoehorn`.
- Prune broken symlinks: for l in ~/.claude/skills/*; do [ -L "$l" ] && [ ! -e "$l" ] && rm -f "$l"; done
- List any NEW skills that appeared.

## 2. Scan for updates (web — keep tight, ~6 high-signal sources only)
- **Claude Code**: latest version + notable changes (anthropics/claude-code releases / CHANGELOG; `claude --version` for current).
- **Matt Pocock**: new skills from step 1 + anything notable.
- **Agentic-engineering regulars** (only genuinely-new items relevant to: agent harnesses/loop engineering, reliability/eval, context/token engineering, AI-assisted coding, the agentic web): Anthropic engineering blog, Cloudflare blog, Martin Fowler / Thoughtworks, Vercel, LangChain. 1-2 standouts max each; skip if nothing new.
- **Tracked tools** (`~/dev/dotfiles/docs/tools.md`): note any major releases for tools listed there.
- **Papers**: scan arXiv (cs.AI / cs.CL, recent) + the blogs above for new papers on **skill/agent construction** — harnesses, loop engineering, reliability, evaluation, context/token engineering, instruction-following, tool use. 1-3 standouts max; skip if nothing genuinely new.

## 3. Output — digest file + artifact + email
- Write a concise digest to `~/dev/dotfiles/docs/digests/<DATE>.md`. Sections: **Skills updated**, **Claude Code**, **Research / articles** (title — 1-line why — URL), **Tool releases**, **Candidates to act on** (worth a Linear JAS issue — list them, do NOT auto-file). No filler; link every source; "nothing new" if empty.
- **Visualize (graphviz — ≥1 diagram; the artifact must not be a wall of text):** render with graphviz `dot` (a native binary — renders SVG headless; **never** use mermaid-cli / puppeteer / any headless-browser renderer, they hang in this sandbox). Write a `.dot`, `dot -Tsvg`, inline the SVG into the HTML artifact. Always include:
  - **Digest map** — today's themes (Claude Code · Matt · Research · Tools) as clusters/nodes with edges to the specific skills, JAS issues, or papers each item touches. Light fills + dark font (the artifact is a light page). Save a copy to `~/dev/dotfiles/docs/digests/<DATE>-map.svg`.
  - Optional second viz when the data warrants: a tally bar (skills updated / papers added / releases) or a trend across recent `docs/digests/*.md`.
  - Fallback only if `dot` is missing: a hand-written inline-SVG or CSS bar — still no browser renderer.
- **Publish as an artifact:** load creds from bws (`bws-load`, then `ARTIFACT_API_BASE`/`ARTIFACT_API_KEY` via `bws secret list -o json | jq`), render the digest **plus its inlined diagram(s)** to a self-contained HTML file, then `bun ~/dev/artifact-studio-tools/cli/src/index.ts share <file.html> --slug dev-digest-<DATE> --visibility unlisted`. Capture the public URL.
- **Email it** via Resend to `jpvarbed+digest@gmail.com`: get `RESEND_API_KEY` from bws, then `curl -s -X POST https://api.resend.com/emails -H "Authorization: Bearer $RESEND_API_KEY" -H "Content-Type: application/json" -d '{"from":"digest@jasonv.dev","to":"jpvarbed+digest@gmail.com","subject":"Dev digest <DATE>","html":"<one-paragraph highlights + the artifact link + top Candidates>"}'`. If Resend rejects the from-domain (not verified), retry with `"from":"onboarding@resend.dev"` and note it in the digest.
- **Grow the papers list:** for any genuinely skill/agent-construction paper surfaced in step 2, append a one-line entry to the right section of `~/dev/dotfiles/docs/papers.md` — format `**Title** — authors, venue/date.` then a sentence on the finding + `→ why it matters to us`, then the URL on its own line. **Dedup first**: `grep -qF "<url>" ~/dev/dotfiles/docs/papers.md` and skip if present. Add a section header if none fits. Be conservative — only papers worth remembering, not every arXiv hit.
- Substantive agentic-engineering reading-list items MAY be appended to the KB per `~/.claude/skills/agentic-engineering` CURATOR.md (optional, light touch).
- Commit + push: `cd ~/dev/dotfiles && git add docs/digests docs/papers.md && git commit --no-verify -m "digest: <DATE>" && git push origin main`.

Notes: linear-cli is authed (`linear` / `npx @schpet/linear-cli`); gemini via `gy`; bws token in `~/dev/.env.local` (`bws-load`). Skill index: `~/dev/dotfiles/skills/CHEATSHEET.md`. End with a one-paragraph summary of the day's highlights.