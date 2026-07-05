---
name: Guardrail mute-risk = FP-rate × cost-of-a-false-fire
description: Judge a hook/gate by mute-risk (false-positive-rate × cost-of-a-false-fire), not raw FP. A muted hook enforces nothing, and the mute is the model's in-the-moment escape valve — so price what a false fire actually costs before disabling or softening a guardrail.
type: feedback
---

Evaluate a guardrail (hook, gate, nudge) by its **mute-risk = false-positive-rate ×
cost-of-a-false-fire**, not by the raw FP-rate. A hook the agent mutes enforces
nothing, so precision is the bar. But precision is priced by what a false fire
COSTS: a false BLOCK (which demands an expensive redo) drives mutes, while a false
NUDGE, or a false fire that forces a cheap beneficial action like a filesystem
re-read, does not. The cheap false fire can even be net-positive, because a MISSED
error costs more than a cheap false-fire.

**Why:** the same FP number means opposite things for different hooks. A 98%-FP
prose gate whose false fire just forces a cheap re-read can be worth keeping; a
65%-FP gate whose false fire demands an expensive rerun is a mute-magnet. Pricing
the cost term is what tells them apart, so the rate alone misleads.

**How to apply:** before disabling or softening a guardrail off its FP rate, price
what a false fire costs the user; a false fire that forces a cheap beneficial action
is not noise. Check felt-value or heed-telemetry before killing a long-lived gate.
Keep the forcing function (e.g. block-once) for grounding-valuable gates; cut only
the ungroundable or already-grounded fires; measure real FP on real data before
shipping. Related: [[feedback_hard_gate_earned]], [[feedback_fable_opus_temperaments]],
[[feedback_structure_over_oneshot]]. Seeded by affirm `weigh-fp-metric-by-cost-of-false-fire`.
