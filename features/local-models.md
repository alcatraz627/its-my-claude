---
brief: Local-model CLI suite on this Mac — q (quick LLM) · see (vision: --ui/--ocr/--crop, artifact store) · ui-verify (UI claim gate, screenshots or live AX trees) · review (code) · fleet (judged fan-out) · index (repo symbols) · gemini (huge-context lane, ingest-repo) · imagine (image gen) · warm (leases); all on PATH, $0, offline
triggers:
  - tool:lm
  - tool:q
  - tool:imagine
  - tool:warm
  - tool:see
  - tool:review
  - tool:ui-verify
  - topic:vision
  - topic:ocr
  - topic:local-models
  - topic:ollama
  - topic:image-generation
  - topic:accessibility-tree
related: [features/llm-mini.md, features/model-tier-harness.md]
tier: 2
category: features
updated: 2026-07-10
stale_after_days: 90
---

# local-models — the local LLM + vision + image-gen suite

A toolkit at `~/Code/local-models` that runs models entirely on this machine (M5 Pro, 64 GB),
alongside cloud Claude. Hard rules: **no idle penalty** (nothing resident unless pinned/leased)
and **trust = a passing gate, never model confidence**. Everything is a bare command on PATH.
**Read `~/Code/local-models/docs/STATE.md` first** for current state; `docs/CAPABILITIES.md` is
the full menu with examples.

## Commands (all on PATH, all have `-h`)

| Command | What | Agent-relevant notes |
|---|---|---|
| `q "..."` | quick local answer | intents: `cmd`/`title`/`commit`/`review`… · `--json` envelope · `--format SCHEMA` = constrained decoding → parsed `.data` · `--ctx -` pipes a context doc · `--big`/`--code` tiers · temp 0 |
| `see <img> [q]` | local vision, three lanes | `--ui` = sectioned UI inventory (big tier; `--ui --json` = schema-constrained `.data`) · `--ocr` = EXACT text via Apple Vision (no model, ~300ms) · plain = structural read/grounded answer (good-but-verify strings) · `--crop WxH+X+Y`/`--region top…center` composes with all lanes (small crops read near-perfectly) · `--menubar` = capture+read the live top strip · every read lands `outputs/see/<ts>-…/` (`see open -1`, `see more "q"`, `see note "…"`) |
| `lm ui-verify` | the $0 UI claim gate | `<img> "claim"…` judges against a `--ui --json` inventory; `--app <Name> "claim"…` judges against the LIVE accessibility tree (`ax`, exact, cites AX identifiers) · pass/fail/unsure, unsure never passes, exit 0 only when all pass · `--json` for agents |
| `review <pr#\|file\|dir>` | local code review (probe-gated qwen3.6) | `review 214 --full` = whole files via API, no checkout · `--findings` = schema-constrained objects · first-pass triage, Claude keeps judgment |
| `lm fleet <intent> <files…>` | judged batch fan-out | concurrency-capped, envelope+`--judge` gate, salvage-first, auto warmth lease; run records in `outputs/fleet/` |
| `lm index [find X]` | repo symbol map | "where is X" without a model call; live staleness check |
| `lm gemini` | the abundant-context side lane (pinned flash, wrapper-only) | `ingest <files>` / `ingest-repo [dir]` (repomix-packed, artifact-ignoring) / `ask "q"` per-project sessions · read-only posture · structured `gemini_unavailable` fallback — FLAG it, fall back to claude/lm · sessions self-heal when gemini's chat store is cleaned |
| `imagine "..."` | local image gen (mflux) | `redo/vary/refine N` · `--enhance` · `critique IMG` · TTY-gated auto-open |
| `warm on\|off [tier] [ttl]` | residency: forever-pin (small) or bounded lease (big tiers) | leases self-heal; `warm off all` sweeps; agents don't toggle unasked — but fleet/opencode lease automatically |
| `lm` / `status` / `doctor` / `timeline` | front door, health, merged history | `scripts/verify.sh` = the ~30-check smoke battery; run after any change |

## Integration surface for agents

- **Histories are the API:** `logs/{q,see,fleet,gem}-history.jsonl` + `outputs/imagine-history.jsonl`
  record every run (successes AND failures); `lm timeline` merges them. Weekly self-audit mines
  failures (`scripts/self-audit.sh`, Sun 11:00).
- **The UI-reading trio** (pick per case): **AX tree** (`ax` / `ui-verify --app`) for running native
  apps — exact + semantic; **`see --ui`** for any pixels — structured, good-but-verify;
  **`see --ocr`** for verbatim text — the exactness lane. gcc consumers already wired:
  `/ui-gripe` (confusion diagnosis), `/designer-reviewer`, `/web-design`.
- **Server:** self-hosted `ollama serve` on `127.0.0.1:11434` (LaunchAgent, `KEEP_ALIVE=0`,
  `MAX_LOADED_MODELS=2`). `keep_alive` is **last-writer-wins per request** — direct API callers
  must honor the residency contract (`bin/_lib.sh: ollama_resident`) or they evict warm pins.
- **Constrained decoding everywhere:** `q --format` / `see --ui --json` / `review --findings` /
  `ui-verify` all return schema-valid parsed `.data` — build gates on those, not on prose parsing.
- **Trust boundaries (measured):** local vision = zero fabrications on enumerables, weak
  aesthetics → verifier seat, never critic. Local coder qwen3.6 = probe-gated 9/9, finished a
  16-step codebase exercise under a pytest judge → fine for judged batch work; synthesis and
  final calls stay with cloud Claude. User doctrine: images are ephemeral — parse-now beats
  recall; capability-per-workflow beats throughput.
- **Archival (built, tested, not adopted):** a full local RAG lane (`lm rag`, unadvertised) —
  swim-tested 12/13 with 0 fabrications over the gcc docs; rebuild in ~20s if ever needed
  (`.claude/output/20260710-rag-swim-test/report.md`).
