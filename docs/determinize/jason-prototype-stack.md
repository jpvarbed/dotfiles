# Determinize-refactor audit — `jason-prototype-stack`

**Target:** `/Users/jasonvarbedian/dev/dotfiles/skills/engineering/jason-prototype-stack/SKILL.md`
**Scope:** single-file skill (no `references/`), 105 lines, 86 non-empty lines.
**Method:** line-based token estimate, `tokens ≈ non_empty_lines × 11` (range ×9–×13). Estimates, not a real tokenizer.
**Verdict:** medium reducibility. ~40% of the prose is fixed command sequences and recovery commands that belong in a `scaffold.sh` + an env/secrets contract. The judgment (stack choice, identity model, build order rationale, design pass) stays prose.

---

## 1. Token summary (mandatory)

| Metric | Value |
|---|---|
| **Original tokens** | **946** (low 774 / high 1118 — 86 non-empty lines × 11; ×9 / ×13) |
| Reducible tokens (conservative) | **285** |
| Reducible tokens (aggressive) | **452** |
| **Post-refactor (conservative)** | **661** |
| **Post-refactor (aggressive)** | **494** |
| **Improvement (conservative)** | **30.1%** |
| **Improvement (aggressive)** | **47.8%** |

Formulas:
- `post_refactor_tokens = original_tokens − reducible_tokens`
  - conservative: `946 − 285 = 661`
  - aggressive: `946 − 452 = 494`
- `improvement_percent = (reducible_tokens / original_tokens) × 100`
  - conservative: `(285 / 946) × 100 = 30.1%`
  - aggressive: `(452 / 946) × 100 = 47.8%`

Note: a single-file skill of <1k tokens is already small. The win here is **reliability** (a tested `scaffold.sh` runs the exact provisioning sequence every time instead of the model re-typing curl flags) more than raw token savings. Token savings are the secondary benefit.

---

## 2. Token cost by section

| Section | Lines | Non-empty | Tokens (×11) | Classification |
|---|---|---|---|---|
| Frontmatter + intro + "Announce at start" | 1–13 | ~15 | ~165 | narrative / context |
| The stack (defaults) | 14–35 | 20 | 220 | partial (defaults + rationale) |
| Build order | 37–47 | 9 | 99 | partial (workflow + rationale) |
| **Provisioning — the commands that worked** | 49–78 | 24 | 264 | **deterministic (fixed command seq)** |
| Secrets | 80–84 | 3 | 33 | arg/call contract (env keys) |
| **Errors** | 86–99 | 12 | 132 | **retry/error policy (recovery commands)** |
| Planned additions | 101–105 | 3 | 33 | narrative (prunable) |
| **Total** | | 86 | 946 | |

No conditional fast-path/full-path split — the skill is one linear recipe, so there is a single execution path.

---

## 3. Savings breakdown (conservative + aggressive)

Reducibility multipliers per class (from the method): deterministic 80–95%, partial 30–60%, narrative 10–20%.

| Section | Tokens | Class | Cons. % | Cons. saved | Aggr. % | Aggr. saved |
|---|---|---|---|---|---|---|
| Provisioning | 264 | deterministic | 80% | 211 | 95% | 251 |
| Errors | 132 | deterministic (recovery cmds) | 50%* | 66 | 80% | 106 |
| Secrets | 33 | contract | 30% | 10 | 60% | 20 |
| The stack | 220 | partial | — | 0 | 15% | 33 |
| Build order | 99 | partial | — | 0 | 20% | 20 |
| Planned additions | 33 | narrative (prune) | — | 0 | 65%† | 22 |
| Intro/frontmatter | 165 | narrative | — | 0 | — | 0 |
| **Total reducible** | | | | **~287** | | **~452** |

\* Errors is held below the 80% deterministic floor in the conservative column because each row pairs a *symptom diagnosis* (judgment — recognizing the failure) with a *recovery command* (deterministic). Only the command half moves; the symptom column stays as a thin prose lookup.
† "Planned additions" is roadmap chatter, not instruction — conservative keeps it (no behavior change); aggressive deletes most of it (link to the Linear issue / BRIEF instead). Conservative total rounds to the 285 used in §1.

**Top 5 sections by absolute savings (aggressive):** Provisioning (251) ≫ Errors (106) > The stack (33) > Planned additions (22) > Secrets (20).

---

## 4. Top deterministic sections to extract first

1. **Provisioning block (49–78)** — five fixed command groups: Convex configure + env-set, `gh repo create` with the `env -u` keyring trick, Vercel build + `cp dist` + deploy, the two Vercel domain API curls, and the Squarespace DNS record values. Every flag is load-bearing and was discovered the hard way. This is the canonical "prose that should be a script."
2. **Error recovery commands (86–99)** — the *Fix* column is almost entirely the same commands as the provisioning block, restated. The recovery actions are deterministic; the symptom strings are the only judgment.
3. **Secrets key list (80–84)** — a fixed set of env var names (`CONVEX_PAT`, `VERCEL_FULL_TOKEN`, `LINEAR_API_KEY`, `BITWARDEN_ACCESS_TOKEN`) + their source. This is an input contract `scaffold.sh` should assert, not prose the model re-reads.

---

## 5. Detailed file conversion plan

| file | what | why | how | script path | savings (cons/agg) | priority | risk |
|---|---|---|---|---|---|---|---|
| `SKILL.md` §Provisioning (49–78) | Extract the 5 command groups (Convex configure/env, gh repo create, Vercel build+deploy, Vercel domain add+verify, Squarespace DNS values) into a parameterized script. | Fixed sequences where every flag matters (`--scope`, `env -u GH_TOKEN`, v10/v9 API versions). Model retyping = drift + failures. Tested script = deterministic. | `scaffold.sh` with subcommands/flags (see §6). Reads secrets from env, fails loudly on missing keys. SKILL.md keeps 2–3 lines: "run `scaffold.sh provision --name X --sub Y`; it does Convex+repo+deploy+domain. Squarespace DNS + Google re-verify are manual (human login)." | `skills/engineering/jason-prototype-stack/scaffold.sh` | 211 / 251 | **P0** | med (live tokens, external APIs; needs a real dry-run + one e2e test) |
| `SKILL.md` §Errors (86–99) | Move the *Fix* (command) half of each row into `scaffold.sh` as preconditions/auto-recovery (write `~/.convex/config.json` if missing, assert `--scope`, deploy `dist` not src, optional-field schema check). Keep a 4–5 row symptom→"see scaffold.sh / make field optional" lookup. | Recovery actions are deterministic and duplicate the provisioning commands. Encoding them as guards means failures self-heal or fail with an actionable message instead of relying on the model to recall the fix. | `scaffold.sh` `preflight` step + inline guards; SKILL.md keeps a slim table for the genuinely judgment rows (schema-change validation, `noUncheckedIndexedAccess`, diagram-render hang). | same script | 66 / 106 | **P1** | med (must preserve the symptom→cause mapping a human still needs) |
| `SKILL.md` §Secrets (80–84) | Turn the key list into a `scaffold.sh` env-assertion (a `require_env` list) + a one-line pointer in prose. | Input contract, not narrative. Asserting beats describing — the script can verify presence before doing anything irreversible. | `scaffold.sh` checks `CONVEX_PAT VERCEL_FULL_TOKEN LINEAR_API_KEY BITWARDEN_ACCESS_TOKEN` and `gh auth status`; SKILL.md: "needs these env keys (see scaffold.sh header); sourced from `~/dev/.env.local` / `bws`." | same script | 10 / 20 | P1 | low |
| `SKILL.md` §Planned additions (101–105) | Delete / replace with a one-line link to Linear FOC-2 + `~/dev/artifact-share/BRIEF.md`. | Roadmap chatter, already stale (artifact-share shipped per memory). Not instruction. | Inline link. | n/a | 0 / 22 | P2 | low |
| `SKILL.md` §The stack, §Build order (14–47) | **Keep as prose.** Light trim of duplicated rationale only. | This is the judgment: why Convex, the anonymous-UUID identity model, clients-first ordering, "do one real design pass." Scripting it would destroy the skill's value. | No extraction. Optionally tighten wording (aggressive only). | n/a | 0 / 53 | P2 | low |

---

## 6. Suggested `scaffold.sh` shape

Single script, idempotent, dry-run-able. Owns everything deterministic; touches no judgment.

```
scaffold.sh init      --name <app> --sub <subdomain>   # bun workspace skeleton (apps/web, apps/cli, packages/backend, skills/)
scaffold.sh provision --name <app> --sub <subdomain>   # Convex configure + env, gh repo create, Vercel deploy, Vercel domain add+verify
scaffold.sh preflight                                  # assert required env keys + gh auth; write ~/.convex/config.json from $CONVEX_PAT if absent
scaffold.sh deploy    --name <app>                     # bun build → cp dist /tmp → vercel deploy --prod --scope ...
scaffold.sh domain    --sub <subdomain> --project <p> --team <t>   # the two Vercel API curls; prints required Squarespace CNAME/TXT
```

- **Inputs:** flags above; secrets from env (`CONVEX_PAT`, `VERCEL_FULL_TOKEN`, `LINEAR_API_KEY`, `BITWARDEN_ACCESS_TOKEN`), `gh` keyring.
- **Owns:** all of §Provisioning, the command half of §Errors, the §Secrets assertions.
- **Does NOT own (stays manual + prose):** Squarespace DNS entry + Google re-verify (human login — explicitly "don't drive logins"), the design pass, the schema-design judgment.
- **Reliability benefit:** the flag-sensitive sequences (`env -u GH_TOKEN`, `--scope jpvarbeds-projects`, v10 vs v9 Vercel endpoints, deploy `dist` not source) run identically every time; failures become exit codes with messages instead of model-recall gambles.
- **Dependency risk:** wraps live external APIs with real tokens — needs a `--dry-run` and one end-to-end validation before it's trusted. External API versions (Vercel v10/v9) can drift; pin and comment them.

---

## 7. Residual prompt (stays model-driven)

Keep in `SKILL.md` as prose — this is the genuine judgment a script can't carry:

- **Why this stack** — Convex over a separate API/polling/DB-client; the project-slot-cap rationale.
- **Identity model** — anonymous `crypto.randomUUID()` as both userId and access capability; `by_user` index; Convex Auth as later opt-in.
- **Clients-first build order** and *why* it proves the design before UI.
- **"Do one real design pass; don't ship the default look"** — taste, not a command.
- **Docs/tickets conventions** — PLAN/SPEC/ADR, Linear team-per-product, team-scoped labels gotcha.
- **The slim symptom→cause rows** in Errors that need a human to recognize the failure (schema validation, `noUncheckedIndexedAccess`, diagram-render hang).
- The "Announce at start" line.

Post-refactor, `SKILL.md` reads as: stack rationale + build order + a 3-line "run scaffold.sh" pointer + a trimmed judgment-only error table. The recipe's *reasoning* stays; the recipe's *typing* moves to a tested script.
