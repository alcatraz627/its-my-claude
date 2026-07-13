---
brief: Local-model CLI suite on this Mac — q (quick LLM) · see (vision: --ui/--ocr/--crop; **see diff A B** = the $0 fabrication-proof imitation-fidelity lane behind /vis-compare) · ui-verify (UI claim gate) · review (code) + findings-gate (fail-closed trust layer) · fleet (judged fan-out) · index (repo symbols) · gemini (huge-context lane) · imagine (image gen; seed-locked refine drives the convergence loop) · asset-verify (derived icon rungs) · warm (leases); all on PATH, $0, offline
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
  - topic:visual-regression
  - topic:image-comparison
  - phrase:"does it match"
  - phrase:"compare these images"
  - phrase:"recreate this UI"
related: [features/llm-mini.md, features/model-tier-harness.md]
tier: 2
category: features
updated: 2026-07-13
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
| `see diff A B` | **"does B faithfully imitate A?"** — the compare lane | `$0` deterministic evidence pack (text/colour/hash/shape) that **cannot fabricate** a difference · `--no-read` = evidence only, ~1s (the loop default) · `--only E5 --grid 32` = slice rerun · feeds the `/vis-compare` judge |
| `imagine "..."` | local image gen (mflux) | `redo/vary/refine N` · `--enhance` · `critique IMG` · TTY-gated auto-open · **`refine N` is SEED-LOCKED** — the only way to converge on a reference (see the loop below) · **`qwen` = default/finisher (~3min), `schnell` = loop scratch model (~46s)** · refuses to run on a half-downloaded model (fail-fast preflight, since a partial cache silently re-enters a 22GB fetch and looks like a slow render) |
| `lib/asset-verify.py` | are the derived asset rungs as good as their size allows? | `<source> <rung...>` — judges each rung against a best-achievable resample AT ITS OWN SIZE (not the source), so "a 30px icon can't hold every edge" is not counted against it. Exit 1 on any flagged rung |
| `lib/findings-gate.py` | the $0 review pre-gate's trust layer | `review --findings --json -m small \| … \| findings-gate.py --root <repo>` — drops any finding whose file:line does not exist. **Fail-CLOSED** (absolute paths / `..` escapes are rejected). Survivors are OPINIONS to triage, never verdicts |
| `lib/e8-dom.py` | exact CSS on a live web surface | run `lib/e8-extract.js` in any browser driver (Playwright/CDP MCP), feed both captures in — the judge reads exact hexes/padding instead of estimating from pixels |
| `warm on\|off [tier] [ttl]` | residency: forever-pin (small) or bounded lease (big tiers) | leases self-heal; `warm off all` sweeps; agents don't toggle unasked — but fleet/opencode lease automatically |
| `lm` / `status` / `doctor` / `timeline` | front door, health, merged history | `scripts/verify.sh` = the ~30-check smoke battery; run after any change |

## The imitation-fidelity stack (2026-07-13) — reach for this when B is a REBUILD of A

Three layers, strict roles: **scripts measure, models judge, the ledger tracks.** Use it
for a UI recreation, an icon/logo/theme comparison, a visual regression, or an imagegen
convergence run.

| Layer | What | Entry point |
|---|---|---|
| **L1 evidence** | $0, deterministic, fabrication-proof | `see diff A B --json` |
| **L2 judgment** | Claude reads the pixels + your taste `policy.md` → looks-worse / neutral / improvement / not-worth-chasing (never a raw score) | `/vis-compare A B` |
| **L3 loop** | fix → re-render → re-compare, tracking fixed / persisting / regressed until it converges or stalls | `/vis-compare --loop A B` |

**The one rule that will bite you (binding, `policy.md` v4):** in a loop, **read progress
from the LEDGER, never from the scores.** Region/pixel metrics saturate the moment
composition moves — a live round fixed 3 of 5 divergences while grid-delta *rose* 93.8% →
100%. A loop that stops on "the scores plateaued" quits exactly when it is working.
`lib/vis-ledger.py` states progress in-band so you cannot misread it.

**Imagegen convergence:** `imagine` (schnell, ~46s) → `see diff --no-read` → judge at nudged
moments → `imagine refine N "<the verdict's fix_hints>"` (**seed-locked** — a fresh roll
makes every divergence read as new and destroys the ledger's meaning) → repeat. Proven live:
one refine fixed 3 of 5 divergences. Design: `~/Code/local-models/docs/10-visual-compare-design.md` §11.

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
- **Routing verdict (2026-07-13, measured on a REAL task):** the local coder re-implemented an
  actual shipped change (E1 numeric deltas) in a pre-change worktree under the battery judge —
  **33/33 green, first round, 35s**, including a requirement stated only in prose. So the
  **scoped-worker-under-a-mechanical-judge seat CLEARS the efficacy bar**: route a unit local
  when (a) it is scoped to named functions/files, (b) a mechanical judge exists BEFORE dispatch,
  (c) the orchestrator applies + judges. The **autonomous tier is NOT evidenced** — decomposition,
  fixture authorship, and repo navigation all came from cloud Claude. Experiment + repeatable
  harness: `~/Code/local-models/.claude/output/20260713-fleet-code-task/experiment.md`.
- **Archival (built, tested, not adopted):** a full local RAG lane (`lm rag`, unadvertised) —
  swim-tested 12/13 with 0 fabrications over the gcc docs; rebuild in ~20s if ever needed
  (`.claude/output/20260710-rag-swim-test/report.md`).
