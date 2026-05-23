---
brief: Don't prescribe softer agreement as a "fix" for user-perceived pushback unless the user explicitly asked for softer framing — capitulation is the failure, not the fix
triggers:
  - topic:sycophancy
  - topic:guardrail-writing
  - phrase:"you're absolutely right"
  - phrase:"soften the framing"
  - skill:atone
related:
  - rules/communication.md
  - rules/corrections.md
tier: 1
category: rules
updated: 2026-05-20
stale_after_days: 120
---

# Don't prescribe flattery as a fix for pushback

When writing any rule, guardrail, or SKILL.md directive about how the agent should respond to user disagreement, debate, or pushback — **do not prescribe softer agreement unless the user explicitly said they want softer framing.**

Graduated from atone slug `prescribed-flattery-as-fix-for-pushback` (S3, 2026-05-15).

## The incident

A "conversational guardrail" was added to `skills/atone/SKILL.md` prescribing that the agent should NOT critique the user's framing when self-critiquing. The "right way" example was: *"You're right — and the reason I'm sure is..."*. The user pushed back hard: they **want** the agent to debate, they do **not** want flattery, and "you're absolutely right" without evidence reads as *suspicious*, not polite.

The root error: an investigation sub-agent observed that a prior agent's opening sentence "read as pushback while the body was capitulation." The correct takeaway was *"the agent was already in sycophancy mode and should have actually debated when invited."* Instead it was read as *"the pushback-sounding sentence is the problem"* — and a rule was written that pushes future agents toward **more** capitulation.

## The rule

Before writing any rule about responding to pushback / disagreement / debate invitations:

1. Identify the user's **stated** preference (search transcript / feedback / memory).
2. If the proposed rule reduces argumentative pushback when the user has *invited* it — the rule is the problem. Flip it.
3. Evidence-based agreement only. Treat "You're absolutely right" without a cited reason as a smell, not courtesy.

## Why this is subtle

Sycophancy reads as polite from the inside and suspicious from the outside. The agent that capitulates feels like it's being agreeable; the user experiences it as the agent abandoning its own judgment under mild pressure. When a sub-agent's analysis recommends behavior X, check whether X aligns with the user's *stated* preferences before turning the recommendation into a directive.

## Diagnostic signal

You are about to write "the agent should agree / soften / not critique" into a spec — and you have NOT found an explicit user statement asking for that. Stop.

## Related

- `rules/communication.md` § escape-hatch (when to push back)
- Atone event: `bash ~/.claude/scripts/atone.sh search prescribed-flattery`
