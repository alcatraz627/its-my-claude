---
brief: When designing a hook, weight its false positives by cost-of-false-fire, not raw FP rate — then match the consequence (block vs warn vs nudge) to that cost. A cheap-to-dismiss false fire on a high-value guard is worth keeping; a costly one on a low-value guard gets muted on sight.
triggers:
  - topic:hook-design
  - topic:false-positives
  - phrase:"build a hook"
  - phrase:"hook false positive"
  - phrase:"should this hook block"
related:
  - features/declared-ready-stop-hook.md
  - features/hooks-tui-limits.md
  - rules/surface-hook-nudges-to-user.md
tier: 2
category: features
updated: 2026-07-05
stale_after_days: 180
---

# Hook design — price false fires by cost, then match the consequence

A hook is a bet: it fires on a pattern in exchange for some rate of false fires.
Whether that bet is worth making is **not** a function of the false-positive rate
alone — it is the FP rate times the cost of each false fire, weighed against the
value of each true fire. A guard that false-fires often but costs nearly nothing
to dismiss, on a failure that is expensive when it slips through, is a good bet
even at a high FP rate. The reflex to "disable the noisy hook" reads raw
frequency and misses this.

## The two questions, in order

1. **What does one false fire cost the agent?** A block on `git push` costs a
   full stop plus a re-approval round — expensive. A one-line nudge the agent
   dismisses with "wiring it next edit" costs almost nothing. An extra `Read`
   that forces filesystem grounding costs one cheap tool call — and may be
   *valuable* even when it "false"-fires, because it corrects an ungrounded
   claim.
2. **Match the consequence to that cost.** Three tiers:
   - **block (exit 2 / `decision:block`)** — only for catastrophic, irreversible,
     or shared-state actions where a wrong pass is far worse than a wrong stop
     (credential writes, `git push`, `rm`, prod deploys). Reserve blocking for
     high cost-of-*miss*.
   - **warn (additionalContext nudge)** — for frequent-but-recoverable patterns
     where a false fire is cheap to ignore (speculative-export, prefer-rg). The
     agent self-corrects or dismisses in one line.
   - **nudge / log-only** — for signals you want to measure before you trust,
     or that are advisory by nature.

## Worked examples from this machine

- `guard-structural-claim` measured **~98% FP** over 959 transcripts and was
  headed for disable. The right call was to keep it: each false fire costs one
  cheap `Read` that forces the agent to ground an authority claim in a file:line,
  which the user explicitly values. Only the *ungroundable* fire classes
  (meta-claims, person-owns, already-cited) were cut. Source affirm:
  `aff-20260702-121112-21`.
- `guard-speculative-export.sh` sits at a **~35% FP floor** and is deliberately
  **warn-only** — its header notes a block at that floor "would be muted on
  sight." A cheap-to-dismiss nudge at 35% FP is a good bet; a block at 35% FP is
  a self-inflicted mute.
- `guard-user-commit.sh` **blocks** with no self-liftable mute — because the
  cost-of-*miss* (an agent committing in a user-owned repo) is high and the true
  fire is exactly the thing being prevented. High cost-of-miss earns the block.

## The trap

Ranking hooks by raw FP rate and disabling the top of the list. That optimizes
the wrong quantity. A 40%-FP warn-nudge that catches a costly slip beats a
2%-FP block that mutes the whole hook the first time it false-fires on a push.
Weigh FP by cost-of-false-fire; design the consequence to the cost tolerance.
