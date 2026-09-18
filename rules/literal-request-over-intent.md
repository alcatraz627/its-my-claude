---
brief: A request names a goal; the wording is a sample of it, not its boundary. Seven shapes with distinct tells (named string, named instance, complaint-as-menu, deferral, urgency, a ban's scope, a repeated ask), one shared precheck, one escape hatch. 9× S3, the account's most active blind spot.
triggers:
  - topic:intent
  - topic:scope
  - phrase:"just do"
  - phrase:"call it"
  - phrase:"rename it to"
  - phrase:"this is confusing"
  - phrase:"quickly"
related:
  - rules/communication.md
  - rules/pushback-and-self-criticism.md
  - rules/audit-file-character-before-applying-global-rule.md
tier: 1
category: rules
updated: 2026-09-18
stale_after_days: 90
---
# Serve the goal, not the wording

Precheck before implementing: **does the literal wording describe the goal, or an example of it?** If an example, serve the goal. Escape hatch: "exactly this", or the string repeated after pushback, is the intent.

Eight shapes, one tell each:
1. A named string is a placeholder; pick the name that fits the surface.
2. A named instance when they meant the class; fix the class.
3. A complaint is a problem report, not a menu of taste options.
4. A later mention does not lift a deferral; ask in one line if you think it did.
5. Urgency is tone, not scope; do the fast version of what was asked.
6. A prohibition's scope is its reason, not the surface it was stated on.
7. A repeated or escalating ask means the last answer missed; work out what was not delivered. The repeat may cross sessions: check for a stub, a half-implementation, a standing ruling before treating an ask as first.
8. A skill or renderer with an open defect: ask before invoking, not after.

Not licence to widen scope, nor to substitute judgment silently; say the divergence in one sentence, then build the intent.

A halt under this rule needs a genuinely missing thing, information or authority not yet granted; holding both, act (`never-halt-on-authority-you-hold.md`).

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/literal-request-over-intent.md`
