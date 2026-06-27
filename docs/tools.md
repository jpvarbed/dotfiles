# Interesting dev tools

A running log of dev tools worth knowing — what they are and where they stand.
Status: **✅ using** · **🔬 evaluating** (JAS#) · **👀 watching**. Add a row when a tool comes up.

## Agent tooling & skills infra
| Tool | What | Status |
|---|---|---|
| [skills](https://skills.sh) (`skills` CLI) | Install/manage agent skills across agents; registry search | ✅ using |
| [agent-browser](https://github.com/vercel-labs/agent-browser) | Browser-automation CLI for agents (verify UI, screenshots, a11y tree) | ✅ using |
| [portless](https://github.com/vercel-labs/portless) | Named `https://<name>.localhost` dev URLs; worktree branch-prefixing | ✅ using |
| [emulate](https://github.com/vercel-labs/emulate) | Offline stateful fakes of Stripe/GitHub/Google/AWS for tests | ✅ using |
| [pixelbrowse / PixelRAG](https://github.com/StarTrail-org/PixelRAG) | pixelbrowse = "give Claude eyes" (read a page visually); visual-RAG pipeline | ✅ pixelbrowse · 🔬 RAG (JAS-12) |
| [agent-native + Clips](https://github.com/BuilderIO/agent-native) | Framework for agent-native apps (one action → UI/agent/MCP/CLI). Clips = agent-readable Loom | 🔬 (JAS-13 golf video) |
| ponytail / superpowers | "Lazy senior dev" + process backbone (TDD/debug/brainstorm) plugins | ✅ using |
| [claude-memory-health](https://github.com/alexknowshtml/claude-memory-health) | Audit MEMORY.md (bloat/orphans/staleness) + demote stale notes to cold storage (200-line load cliff) | ✅ tried — flagged D2R inline bloat |
| [XState / @statelyai/agent](https://github.com/statelyai/xstate) | Statecharts/actors; `@statelyai/agent` models agent loops as inspectable state machines (harnesses). `@xstate/store` for light client state | 🔬 (JAS-17) |

## Verify / build / run
| Tool | What | Status |
|---|---|---|
| [gemini CLI](https://github.com/google-gemini/gemini-cli) | Independent second model for `adversarial-review` / `visual-critique` (`gy` alias = `--yolo --skip-trust`) | ✅ using |
| [ast-grep](https://github.com/ast-grep/ast-grep) | Structural (AST) code search & rewrite — multi-language | 🔬 (JAS-1) |
| [apple/container](https://github.com/apple/container) | Local Linux containers as lightweight VMs on Apple Silicon (Docker Desktop alt; local counterpart to CF Sandbox) | 🔬 (JAS-16) |

## Storage / data / RAG
| Tool | What | Status |
|---|---|---|
| [files-sdk](https://github.com/haydenbleasel/files-sdk) | One JS/TS API over 35+ storage backends (S3/R2/GCS/Azure); agent file tools; MIT | 🔬 (JAS-15) |
| [Cloudflare R2](https://developers.cloudflare.com/r2/) | No-egress object storage; pair with Convex | 🔬 (JAS-11) |
| [PixelRAG](https://github.com/StarTrail-org/PixelRAG) | Visual RAG over screenshots (keeps tables/layout) — finance PDFs, golf | 🔬 (JAS-12) |

## Cloudflare platform
| Tool | What | Status |
|---|---|---|
| Sandbox SDK | Throwaway Linux container — run builds / untrusted user apps | 🔬 (JAS-7, artifact-share) |
| AI Gateway | Front Claude/Gemini for caching/analytics/spend | 🔬 (JAS-8) |
| Dynamic Workflows / CI | `ci.ts` durable workflow + sandbox = CI from first principles | 🔬 (JAS-9) |
| Browser Rendering | Cloud headless Chromium — agent-browser fallback | 🔬 (JAS-10) |

## Santander AI Lab (OSS)
| Tool | What | Status |
|---|---|---|
| [llm_bridge](https://github.com/SantanderAI/llm_bridge) | Vendor-neutral LLM client (OpenAI/Bedrock/Gemini) | 🔬 (JAS-2, cloned) |
| [gen-fraud-graph](https://github.com/SantanderAI/gen-fraud-graph) | Synthetic fraud-graph generator → finance | 🔬 (JAS-3, cloned) |
| [mech-gov-framework](https://github.com/SantanderAI/mech-gov-framework) | Governance/hard-gates for high-stakes LLM decisions | 🔬 (JAS-4) |
| [autoguardrails](https://github.com/SantanderAI/autoguardrails) | Autoresearch scaffold for LLM guardrails | 🔬 (JAS-5) |

## Personal / misc
| Tool | What | Status |
|---|---|---|
| [FluidVoice](https://github.com/altic-dev/FluidVoice) | Local OSS macOS dictation (vs Willow) | 🔬 (JAS-14) |

Installed skills are tracked separately in [`../skills/CHEATSHEET.md`](../skills/CHEATSHEET.md).
