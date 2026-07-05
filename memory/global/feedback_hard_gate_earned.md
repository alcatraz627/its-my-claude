---
name: Hooks fuzzy-by-default; hard-blocks must be earned
description: Guardrails default to fuzzy-and-mutable; a deterministic hard-block is the exception a hook earns by being vital AND near-zero-mismatch. The mute is the driver's escape valve; remove it only where there's no mismatch to trap on.
type: feedback
---

Guardrails should be **fuzzy and mutable by default; a deterministic hard-block is
the exception a hook must EARN** by being both vital and having a near-zero mismatch
surface. The mute is the driver's in-the-moment escape valve for a hook that is
wrong in this specific case. Removing it (a hard block) turns every mismatch into a
trap, so it only makes sense where there is no mismatch to trap on: deterministic,
zero-FP, high-cost-of-miss actions (commit in a protected repo is a yes/no; rm vs
trash; writing a credential). Fuzzy or heuristic hooks (prose gates, verbosity
checks) stay soft, because they will misfire and the mute is what makes them
survivable.

**Why:** advisory rules bind unevenly across drivers. A literal model heeds them; a
more intent-eager model bypasses them under goal-delivery pressure (see
[[feedback_fable_opus_temperaments]]). The temptation is to hard-block everything to
force compliance, but that removes the model's judgment exactly where mismatches are
most likely, which is the opposite of what you want.

**How to apply:** default a new hook to a mutable nudge or soft-block. Promote to a
hard block only when the check is deterministic with ~0 mismatch surface, the
miss-cost is high, and (for a specific model that ignores the nudge) heed-telemetry
proves the miss-cost justifies losing the escape valve. Evidence-driven, targeted
escalation, never a blanket policy. Related: [[feedback_guardrail_mute_risk]].
