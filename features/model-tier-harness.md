---
brief: Mechanics of the model-tier harness. guard-model-tier.sh (warn on unpinned dispatch, hard-block fable-as-sub-agent, dispatch telemetry), the logs it writes, the scheduled reviews, and the lm gemini pairing lane.
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

# Model-tier harness: mechanics

The rule is [`rules/model-tier-routing.md`](../rules/model-tier-routing.md). This doc
covers how the machinery works. Design provenance:
`~/Code/local-models/.claude/output/20260707-model-tier-harness/proposal.md` (and the two
recon files beside it).

## The hook: `scripts/hooks/guard-model-tier.sh` (PreToolUse · Agent|Task)

Copied from the `guard-subagent-output.sh` shape: cheap jq over the dispatch payload, no
LLM calls. It has three behaviors, in order:

1. **Telemetry, always:** every dispatch appends
   `{ts, session_id, tool, model (null if unpinned), prompt_head}` to
   `~/.claude/logs/model-dispatch.jsonl`. This is the efficacy-review data feed.
2. **Hard block (LIFTED 2026-07-23):** `model` matching fable/mythos → `decision:block`
   unless the human-owned sentinel `~/.claude/.allow-fable-subagents` exists. It does exist,
   per the owner's "lift the fable hard-block altogether". Trash it to re-arm.
   Original rationale: that tier was priced per-token outside the subscription cap, so a
   sub-agent on it multiplied spend (user decision 2026-07-07). When the flagship was
   cap-covered Opus this did not matter, and the block keyed on pricing rather than on
   flagship-ness. **That rationale expired on 2026-08-25**, when Anthropic brought fable
   inside the subscription (owner). The sentinel stays because the owner still wants
   the lane chosen deliberately, but it no longer guards a bill. Do not cite cost
   as the reason to refuse a fable seat.
3. **Warn (muteable):** when `model` is absent, an `additionalContext` nudge cites the rule.
   Mute with `touch ~/.claude/.model-tier-off`, or `MODEL_TIER_OFF=1` for one shot.

Fires log via `warn-log.sh` (`--hook model-tier --action block|nudge`) for FP-rate audits
per `features/hook-design.md`. A mis-tier heuristic (research-verbs on opus-high, etc.) is
deliberately NOT nudging yet. Telemetry accumulates first, and the reviews below revisit it.

## The plan-time nudge: `scripts/hooks/retired/nudge-model-plan.sh` (RETIRED 2026-10-14, never registered)

This was the Phase C half. When a plan's text signaled sub-agents, workflows, large ingestion or
modality tools but carried no `Model plan:` block, it gave one `additionalContext` nudge
citing the rule. It was advisory only, never a block (a false fire costs one line, while a missing
Model Plan costs an unrouted fleet). It shared the model-tier mutes
(`.model-tier-off` / `MODEL_TIER_OFF=1`) and logged via `warn-log.sh`
(`--hook model-plan --action nudge`), folded into the same reviews. It shipped 2026-07-10 and was
verified with sandboxed-HOME pipe-tests (signal→nudge, block-present→silent,
no-signal→silent, muted→silent).

## Telemetry and reviews

| Stream | Written by | Reviewed |
|---|---|---|
| `logs/model-dispatch.jsonl` | the hook | tier-telemetry-review |
| `logs/image-reads.jsonl` | `hooks/log-image-reads.sh` (PostToolUse · Read; `est_tokens ≈ w·h/750`; mute `.no-image-read-log`) | image-tools-review |
| `~/Code/local-models/logs/{q,see,fleet,gem}-history.jsonl` | the lm suite | lm weekly self-audit + both reviews |

Scheduled (gcc-schedule, calendar-visible): **image-tools-review** one-shot Tue
2026-07-28 15:00 · **tier-telemetry-review** one-shot Tue 2026-08-04 15:00. Both run
`scripts/image-tools-review.sh`, which digests every stream above over a 21-day window.

## The gemini lane: `lm gemini`

It lives in the local-models suite (`~/Code/local-models/lib/gemini`, front door
`lm gemini`), NOT here. See `features/local-models.md` and that repo's CAPABILITIES.md.
Contract highlights: the model is pinned to `gemini-3.5-flash`. **Claude never invokes the `gemini`
binary directly, wrapper only**, which isolates the deprecated gemini-cli backend (EOL
2026-12-18; a later swap to Antigravity/ACP is wrapper-internal). Sessions are per project
(ingest/ask). A structured `gemini_unavailable` error means the agent FLAGS it to the user and
falls back to sonnet/lm.
