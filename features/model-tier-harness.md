---
brief: Mechanics of the model-tier harness — guard-model-tier.sh (warn on unpinned dispatch, hard-block fable-as-sub-agent, dispatch telemetry), the logs it writes, the scheduled reviews, and the lm gemini pairing lane.
triggers:
  - tool:guard-model-tier
  - tool:lm-gemini
  - topic:model-tier
  - topic:dispatch-telemetry
  - topic:gemini
related:
  - ../rules/model-tier-routing.md
  - hook-design
  - local-models
tier: 2
category: features
updated: 2026-07-10
stale_after_days: 180
---

# Model-tier harness — mechanics

The rule is [`rules/model-tier-routing.md`](../rules/model-tier-routing.md); this doc is
how the machinery works. Design provenance:
`~/Code/local-models/.claude/output/20260707-model-tier-harness/proposal.md` (+ the two
recon files beside it).

## The hook — `scripts/hooks/guard-model-tier.sh` (PreToolUse · Agent|Task)

Copied from the `guard-subagent-output.sh` shape: cheap jq over the dispatch payload, no
LLM calls. Three behaviors, in order:

1. **Telemetry, always:** every dispatch appends
   `{ts, session_id, tool, model (null if unpinned), prompt_head}` to
   `~/.claude/logs/model-dispatch.jsonl`. This is the efficacy-review data feed.
2. **Hard block (LIFTED 2026-07-23):** `model` matching fable/mythos → `decision:block`
   unless the human-owned sentinel `~/.claude/.allow-fable-subagents` exists (it does,
   per the owner's "lift the fable hard-block altogether"; trash it to re-arm).
   Rationale: that tier is priced per-token OUTSIDE the subscription cap; a sub-agent on
   it multiplies uncapped spend (user decision 2026-07-07 — when the flagship was
   cap-covered Opus, this didn't matter; the block keys on pricing, not flagship-ness).
3. **Warn (muteable):** `model` absent → `additionalContext` nudge citing the rule.
   Mute: `touch ~/.claude/.model-tier-off` or `MODEL_TIER_OFF=1` one-shot.

Fires log via `warn-log.sh` (`--hook model-tier --action block|nudge`) for FP-rate audits
per `features/hook-design.md`. A mis-tier heuristic (research-verbs on opus-high, etc.) is
deliberately NOT nudging yet — telemetry accumulates first, revisit at the reviews below.

## The plan-time nudge — `scripts/hooks/nudge-model-plan.sh` (PreToolUse · ExitPlanMode)

The Phase C half: a plan whose text signals sub-agents / workflows / large ingestion /
modality tools but carries no `Model plan:` block gets one `additionalContext` nudge
citing the rule. Advisory only, never a block (a false fire costs one line; a missing
Model Plan costs an unrouted fleet). Shares the model-tier mutes
(`.model-tier-off` / `MODEL_TIER_OFF=1`); telemetry via `warn-log.sh`
(`--hook model-plan --action nudge`), folded into the same reviews. Shipped 2026-07-10;
verified with sandboxed-HOME pipe-tests (signal→nudge, block-present→silent,
no-signal→silent, muted→silent).

## Telemetry + reviews

| Stream | Written by | Reviewed |
|---|---|---|
| `logs/model-dispatch.jsonl` | the hook | tier-telemetry-review |
| `logs/image-reads.jsonl` | `hooks/log-image-reads.sh` (PostToolUse · Read; `est_tokens ≈ w·h/750`; mute `.no-image-read-log`) | image-tools-review |
| `~/Code/local-models/logs/{q,see,fleet,gem}-history.jsonl` | the lm suite | lm weekly self-audit + both reviews |

Scheduled (gcc-schedule, calendar-visible): **image-tools-review** one-shot Tue
2026-07-28 15:00 · **tier-telemetry-review** one-shot Tue 2026-08-04 15:00. Both run
`scripts/image-tools-review.sh` (which digests every stream above, 21-day window).

## The gemini lane — `lm gemini`

Lives in the local-models suite (`~/Code/local-models/lib/gemini`, front door
`lm gemini`), NOT here — see `features/local-models.md` + that repo's CAPABILITIES.md.
Contract highlights: model pinned `gemini-3.5-flash`; **Claude never invokes the `gemini`
binary directly, wrapper only** (isolates the deprecated gemini-cli backend, EOL
2026-12-18 — swap to Antigravity/ACP later is wrapper-internal); per-project sessions
(ingest/ask); structured `gemini_unavailable` error → the agent FLAGS it to the user and
falls back to sonnet/lm.
