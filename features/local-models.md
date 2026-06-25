---
brief: Local-model CLI suite on this Mac — q (quick LLM), imagine (image gen), see (image/screenshot → text via VLM), review (PR/code review), warm (residency), lm (front door); all on PATH, $0, offline
triggers:
  - tool:lm
  - tool:q
  - tool:imagine
  - tool:warm
  - tool:see
  - tool:review
  - topic:vision
  - topic:local-models
  - topic:ollama
  - topic:image-generation
related: [features/llm-mini.md]
tier: 2
category: features
updated: 2026-06-23
stale_after_days: 90
---

# local-models — the local LLM + image-gen suite

A toolkit at `~/Code/local-models` that runs models entirely on this machine (M5 Pro, 64 GB),
alongside cloud Claude. Hard rules: **no idle penalty** (nothing resident unless toggled) and
**snappy** (<1s first token when warm). Everything is a bare command on PATH. **Read
`~/Code/local-models/docs/STATE.md` first** for current state; `docs/GOALS.md` for per-command
goals + design rationale.

## Commands (all on PATH, all have `-h`)

| Command | What | Agent-relevant notes |
|---|---|---|
| `q "..."` | quick local answer (≤2 sentences) | intents: `cmd` (one macOS command) · `title` (2-5 words) · `commit` (`git diff \| q commit`) · piped stdin = input context · `q -c` continues the last exchange · deterministic (temp 0) |
| `imagine "..."` | local image gen (Flux/Qwen, mflux) | `redo/vary/refine N` iterate on history entry N · `--enhance` (LLM prompt rewrite) · `critique IMG` (local vision) · `star N`/`prune`/`gallery` · auto-open is TTY-gated, so agent calls won't pop windows |
| `see <img> [q]` | local vision: structural read of an image/screenshot (type + text + layout + state) or a grounded answer | `--json` → `{ok,text,model,ms}` · `-m minicpm-v` (default; strong-but-imperfect text — **verify exact strings/values, don't trust verbatim blindly**) or `gemma4:26b` · local-only, unloads after · permits interpretive asks |
| `review <pr#\|file\|dir>` | local code review — the `review` intent on the code tier | `gh pr diff N \| review` · `review src/` · `cat x \| review` · `--json` · `-m` picks the coder |
| `warm on\|off` | pin/unpin the small warm model (~5.6 GB) | residency is a deliberate human choice — agents should not toggle it unasked |
| `lm` | front door: overview, `status`, `doctor`, `timeline` | `lm doctor` = full smoke check; `lm status` = server/resident/disk |

## Integration surface for agents

- **Histories are the API:** `logs/q-history.jsonl` and `outputs/imagine-history.jsonl` record
  every run (imagine: full reproducible config + `parent`/`kind` lineage). `q history --json`,
  `imagine history --json`, `lm timeline` for machine reads.
- **Server:** self-hosted `ollama serve` on `127.0.0.1:11434` (LaunchAgent
  `com.alcatraz.local-models-ollama`, policy in `bin/lm-serve`: `KEEP_ALIVE=0`,
  `MAX_LOADED_MODELS=2`). `keep_alive` is **last-writer-wins per request** — any direct API
  caller must check residency first (`bin/_lib.sh: ollama_resident`) or it will un-pin the
  warm model.
- **Tab-title auto-base:** `scripts/tab-title/hooks/auto-base.sh` titles sessions from the
  first prompt via `q title` — only when the warm model is resident.
- **Good offload tasks** (proven, glance-verifiable): commit messages, titles, terse one-command
  lookups, image prompt enhancement/critique. **Not** suitable for multi-step reasoning or code
  generation — that stays with cloud Claude (research: `~/Code/local-models/.claude/output/20260612-lm-research/`).
