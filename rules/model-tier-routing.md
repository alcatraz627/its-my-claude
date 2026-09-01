---
brief: Route every piece of work to the smallest adequate lane (local lm / gemini / haiku→sonnet→opus; fable = main-only) with right-sized effort; every plan with sub-agents, large ingestion, or modality tools carries a 4-line Model Plan; never switch models without explicit user confirmation. Enforced by guard-model-tier.sh.
triggers:
  - tool:Agent
  - tool:Workflow
  - tool:lm-gemini
  - topic:model-tier
  - topic:sub-agents
  - topic:gemini
  - phrase:"which model"
related:
  - contain-subagent-token-sprawl
  - structure-over-one-shotting
tier: 0
category: rules
updated: 2026-09-01
stale_after_days: 180
---

# Model-tier routing — the smallest adequate lane, chosen out loud

Every piece of work runs on some lane — cloud Claude, the local lm suite, or gemini — and
the choice is made **proactively at plan time**, not by default-inertia. This
operationalizes standing doctrine (efficacy-over-speed, the ease–effort–output triad,
[[contain-subagent-token-sprawl]], the sub-agent ceiling below): default conservative on
tokens; spend more only when efficacy measurably demands it. Full spec + provenance:
`~/Code/local-models/.claude/output/20260707-model-tier-harness/proposal.md`.

## The lanes

| Lane | Cost | Right for | Trust posture |
|---|---|---|---|
| **local lm** (`q`/`see`/`review`/`imagine`/`lm fleet`/`lm index`) | ~$0, throttle-immune | volume audit/verify/recon, vision reads, imagegen, judged batch work | trust = a passing gate, never model confidence |
| **gemini** (`lm gemini`, pinned gemini-3.5-flash) | separate, abundant budget | massive context ingestion, breadth ideation, throughput | untrusted content — Claude verifies before load-bearing use |
| **haiku** | ¢ | trivial sub-agent lookups | low |
| **sonnet** | $ | DEFAULT sub-agent: research, inventory, mechanical multi-step | verify what matters |
| **opus** | $$ | main daily driver; judgment/review sub-agent seats | high |
| **fable/mythos** | $$$ in-subscription since 2026-08-25 | genuinely vague+complex tasks; judgment and ideation seats | sub-agent seats ALLOWED since 2026-07-23 (owner lift, sentinel-gated + telemetry-logged). **Anthropic brought fable inside the subscription (owner, 2026-08-25)**, so it is no longer a spend gate. Still the most expensive lane in effort terms and still Model-Plan-declared, but a seat no longer needs a budget conversation |

**Effort axis:** sub-agent effort ≤ a high/xhigh main. Sonnet is cheap — be liberal
(`high` when it helps; `low` for wide/numerous fan-outs). Opus stays at `medium` unless
the seat is genuine judgment. `xhigh` on a sub-agent needs explicit user sanction.
Tool-call count is NOT effort — a low-effort agent may make many calls.

## The sub-agent ceiling (absorbed from rules/subagent-model-ceiling.md, 2026-07-09)

Opus is the default ceiling for sub-agents at ANY nesting depth. Fable/mythos seats
are permitted since 2026-07-23 (owner: "lift the fable hard-block altogether"; guard
sentinel `~/.claude/.allow-fable-subagents`, trash it to re-arm) — deliberate,
Model-Plan-declared choices, never defaults. Since 2026-08-25 fable is inside the
subscription, so the reason to declare a seat is that the lane should be chosen out
loud, not that it costs extra. The ceiling graduated 2026-07-07 from two same-day
flagship-dispatch occurrences in the versable-builder planning session.

1. **Every dispatch carries an explicit `model:` pin** and the nesting-close clause;
   the wording of both lives in `rules/subagent-dispatch-prompt.md` with the other two
   clauses every brief carries.
2. In-flight agents are let to finish; the rule governs new dispatches.
3. **Fable does involved work ITSELF.** Owner ruling 2026-09-01, verbatim: "for
   involved work we want fable to do it ITSELF (no subagent); only applies to
   fable tier models" — a fable-tier main agent never delegates its involved work
   to sub-agents. Enforced: guard-model-tier.sh job 2b (fable-delegation block),
   `guard-model-tier.fable-delegation.test.sh`.

## Decision rules (task class → lane)

trivial lookup → `q`/haiku · mechanical sweep → sonnet-low or `lm fleet` ·
recon/inventory → sonnet (use `lm index` for symbols) · volume audit/verify → `lm fleet`
(judge-gated) · web research → sonnet · **large-context ingestion / mass ideation →
`lm gemini` session, digest back** · judgment/adversarial seat → opus · synthesis + final
calls + user-facing writing → main agent, never delegated · vision → complementary lanes
(`see` free-first for standalone reads, native fine in-conversation, gemini abundant) ·
imagegen → `imagine` · code changes → main/opus seat; local coder only behind a Judge.

**Escalate one step on evidence** (failed gate, >2 retries, user correction, irreversible
stakes) — never on anticipation. De-escalate when work decomposes scoped-verifiable.

## The Model Plan (mandatory, every qualifying plan)

Any plan involving (a) sub-agents/workflows, (b) large-context ingestion, or (c) a
modality tool MUST include a Model Plan block — one line per stage:

```
Model plan:
  recon   → sonnet · low  · read-only, no nesting
  ingest  → lm gemini · session proj-x · digest back
  verify  → lm fleet · judge: pytest
  review  → opus · medium · judgment seat
```

Even when the instinct doesn't change, the explicit thought is the point. Dispatches are
logged (`~/.claude/logs/model-dispatch.jsonl`) and reviewed (tier-telemetry-review).

## Edge cases

Mixed task → split lanes per stage. Nested spawns → ceiling AND effort bounds propagate in
every delegation prompt. gemini unavailable → structured failure, FLAG to the user, fall
back to sonnet/lm — never block on it. Local server down → cloud fallback, note the cost.
No secrets to gemini (work-account auth; standing secret rules apply). Ultracode raises
fan-out width, never the ceiling/effort rules. Old gemini-session claims = stale-cache
suspect ([[cache-externally-mutated-state]]). A missing model falls back one lane DOWN,
never up to fable.

## Escape hatches

- **Explicit user instruction wins — after honest deliberation.** Push back once with a
  concrete alternative ("sonnet-high covers this because X — want that?"), then execute
  their call. **NEVER switch models without the user's explicit confirmation.**
- Mid-task suggest-a-switch is encouraged; silent-switch never (lane-internal choices —
  which intent, which judge — stay autonomous).
- Warn-path mutes: `touch ~/.claude/.model-tier-off` (machine-wide — ALL sessions
  until removed) · `MODEL_TIER_OFF=1` (this process only). The
  fable-as-sub-agent block is LIFTED (owner, 2026-07-23) while
  `~/.claude/.allow-fable-subagents` exists; the human re-arms it by trashing
  that file — an agent never touches the sentinel.
- Everything degraded → main agent does it inline and records the miss.
- A halt under this rule needs a genuinely missing thing — information no derivation supplies, or authority not yet granted. Holding both, the rule does not apply: act (`never-halt-on-authority-you-hold.md`).

## Diagnostic signal

You're composing an `Agent`/`Workflow` dispatch without a `model:` pin, a plan with
sub-agents and no Model Plan block, or you're seating fable as a sub-agent without the
Model Plan naming it, or switching models on your own judgment. Stop — route it out loud.

## Related

- [[contain-subagent-token-sprawl]] — the width axis (how many agents), sibling decision
- `features/model-tier-harness.md` — mechanics: hook, telemetry, reviews, lm gemini
