---
name: openrouter
description: Call any LLM (Anthropic, Google, OpenAI, DeepSeek, Meta, Mistral, …) through OpenRouter's single OpenAI-compatible API with one key. Use when you want "a second model / a different model" for a task, to "compare models" or "route to the cheapest model", when the task says "use OpenRouter" / "call gpt/gemini/llama/deepseek via API", or when you need an LLM the local harness doesn't expose. NOT when the gemini CLI already covers it (use adversarial-review / visual-critique) and NOT for Claude itself (use the Anthropic key directly). Pairs with cli-for-agents (wrap it in a tool) and tracks toward llm_bridge (JAS-2) / an AI gateway (JAS-8).
---

# OpenRouter

One API key → hundreds of models behind an OpenAI-compatible gateway. Base URL
`https://openrouter.ai/api/v1`, standard `/chat/completions` and `/models`
endpoints, model ids namespaced by provider (`anthropic/claude-...`,
`google/gemini-...`, `deepseek/deepseek-...`). It's the fast path to "give me a
different model" without standing up per-vendor SDKs.

**Announce at start:** "Using openrouter to call <model> via the OpenRouter gateway."

## When to use

- You need a model *other than the Claude you're already running* — a cheap
  workhorse, a frontier competitor for a second opinion, or a model with a
  capability (long context, specific provider) the harness lacks.
- You want to **compare** the same prompt across vendors with one auth path.
- You're building a CLI/tool/agent step that calls an LLM and don't want to
  bind it to one vendor (see `cli-for-agents`; this is the runtime for JAS-2's
  `llm_bridge` idea).

## When NOT to use

- A red-team / independent critique where the **gemini CLI** already works →
  use `adversarial-review` (plans/specs/diffs) or `visual-critique` (renders).
- Calling **Claude itself** → use `ANTHROPIC_API_KEY` directly; no reason to add
  a hop.
- Anything latency- or cost-critical at scale → revisit routing through an AI
  gateway (JAS-8) for caching/analytics first.

## Setup: the key (NEVER hardcode)

The key lives in Bitwarden Secrets Manager as `OPENROUTER_API_KEY`. Load it into
the environment on demand — never write it to a file or paste it into a command:

```bash
eval "$(grep BWS_ACCESS_TOKEN ~/dev/.env.local)"; export BWS_ACCESS_TOKEN
export OPENROUTER_API_KEY="$(bws secret list -o json | python3 -c 'import sys,json;print(next((s["value"] for s in json.loads(sys.stdin.read(),strict=False) if s["key"]=="OPENROUTER_API_KEY"),""))')"
[ -n "$OPENROUTER_API_KEY" ] || echo "OPENROUTER_API_KEY missing from bws — create it (see Errors table)"
```

If the key is not yet in bws, create it once:

```bash
eval "$(grep BWS_ACCESS_TOKEN ~/dev/.env.local)"; export BWS_ACCESS_TOKEN
PROJECT_ID="$(bws project list -o json | jq -r '.[0].id')"   # pick the right project
bws secret create OPENROUTER_API_KEY "sk-or-v1-..." "$PROJECT_ID"
```

## Usage

1. **Load the key** with the bws snippet above. Confirm `$OPENROUTER_API_KEY` is
   non-empty before calling — a blank key produces a 401, not a clear error.
2. **Pick a model id.** List live ids with `GET /api/v1/models` (see below) or
   browse https://openrouter.ai/models. Ids are `provider/model`; append `:free`
   for the free tier (e.g. `meta-llama/llama-3.3-70b-instruct:free`), which has daily rate
   limits but costs nothing.
3. **Call `/chat/completions`** (OpenAI-compatible body: `model` + `messages`).
   Add the optional `HTTP-Referer` / `X-Title` headers to attribute usage to your
   app on the OpenRouter dashboard.
4. **Parse the response** — same shape as OpenAI: `.choices[0].message.content`,
   token usage under `.usage`. On a cost-sensitive job, check `.usage` and the
   model's per-token price before scaling up.
5. **For repeated use,** wrap this in a small CLI/function rather than re-running
   curl by hand (`cli-for-agents`), and prefer a cheap default model.

### Copy-pasteable: list models

```bash
eval "$(grep BWS_ACCESS_TOKEN ~/dev/.env.local)"; export BWS_ACCESS_TOKEN
export OPENROUTER_API_KEY="$(bws secret list -o json | python3 -c 'import sys,json;print(next((s["value"] for s in json.loads(sys.stdin.read(),strict=False) if s["key"]=="OPENROUTER_API_KEY"),""))')"
curl -s https://openrouter.ai/api/v1/models \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  | jq -r '.data[] | "\(.id)\t\(.pricing.prompt)/\(.pricing.completion)"' | head -40
```

### Copy-pasteable: a 1-token chat completion (cheap smoke test)

```bash
eval "$(grep BWS_ACCESS_TOKEN ~/dev/.env.local)"; export BWS_ACCESS_TOKEN
export OPENROUTER_API_KEY="$(bws secret list -o json | python3 -c 'import sys,json;print(next((s["value"] for s in json.loads(sys.stdin.read(),strict=False) if s["key"]=="OPENROUTER_API_KEY"),""))')"
curl -s https://openrouter.ai/api/v1/chat/completions \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "Content-Type: application/json" \
  -H "HTTP-Referer: https://jasonv.dev" \
  -H "X-Title: jpvarbed-agents" \
  -d '{
    "model": "meta-llama/llama-3.1-8b-instruct",
    "max_tokens": 1,
    "messages": [{"role": "user", "content": "ping"}]
  }' | jq '{model, content: .choices[0].message.content, usage}'
```

## Recommended models

All ids below were confirmed live in the catalog on 2026-06-29. They drift fast
(the catalog is on gemini-3.x / deepseek-v4 now), so **always re-confirm with
`GET /api/v1/models` before relying on one** (see the model-not-found row).

| Need | Model id | Why |
| --- | --- | --- |
| Dirt-cheap workhorse / smoke tests | `meta-llama/llama-3.1-8b-instruct`, `mistralai/mistral-nemo` | ~$0.00000002/token — near-free, fine for plumbing checks. |
| Free (rate-limited) | `meta-llama/llama-3.3-70b-instruct:free`, `qwen/qwen3-coder:free` | `:free` suffix = $0 with daily caps; good for throwaway checks. |
| Cheap + fast quality | `google/gemini-2.5-flash`, `deepseek/deepseek-chat-v3.1` | Fast, cheap, long context, solid general quality. |
| Second-opinion frontier | `openai/gpt-5`, `google/gemini-2.5-pro` | A non-Claude frontier model for cross-checks. |

Prefer `:free` or an 8B/Nemo id for exploratory work; reserve frontier ids for
things that matter.

## Errors

| Issue | Fix |
| --- | --- |
| `401 No auth credentials found` / `User not found` | `$OPENROUTER_API_KEY` is empty or wrong. Re-run the bws load snippet and check it's non-empty. If the key isn't in bws at all, create it with `bws secret create OPENROUTER_API_KEY "sk-or-v1-..." <project-id>`. |
| `400 ... is not a valid model id` (model-not-found) | The id is stale or mistyped. List live ids: `curl -s https://openrouter.ai/api/v1/models -H "Authorization: Bearer $OPENROUTER_API_KEY" \| jq -r '.data[].id'` and pass an exact `provider/model` slug. |
| `402 Insufficient credits` / `Payment required` | No paid balance. Add credits at openrouter.ai, or use a `:free` model id (e.g. `meta-llama/llama-3.3-70b-instruct:free`) for $0 calls. |
| `429 Too Many Requests` | Hit a rate limit (common on `:free` daily caps). Back off, switch to a paid model, or retry later. |
| `404` from a wrong path | Endpoint is `/api/v1/chat/completions` (note `/api/v1`), not `/v1/...`. Base URL is `https://openrouter.ai/api/v1`. |
| bws snippet returns nothing | `BWS_ACCESS_TOKEN` not loaded — confirm `~/dev/.env.local` has it and `eval "$(grep BWS_ACCESS_TOKEN ~/dev/.env.local)"; export BWS_ACCESS_TOKEN` ran. Check `bws --version` works. |

## Notes

- It's an external API call — don't send secrets in prompts.
- Prefer the cheapest model that passes your check; escalate deliberately.
- Drop-in OpenAI-compatible: point any OpenAI SDK at `baseURL =
  https://openrouter.ai/api/v1` with this key to use the same models from code.
