---
brief: A template's example slots and a spec's examples define capabilities, not fill quotas. Produce the slot when the case earns it; do not manufacture content to match the example's count or shape. Hard exemption for fields a schema marks required.
triggers:
  - topic:templates
  - topic:examples
  - phrase:"fill in the template"
  - phrase:"like the example"
  - phrase:"same shape as"
related:
  - rules/audit-file-character-before-applying-global-rule.md
  - rules/literal-request-over-intent.md
  - rules/generalize-before-enumerate.md
tier: 2
category: rules
updated: 2026-09-18
stale_after_days: 365
---
# Examples define capabilities, not quotas

A template shows every slot to define them; an implementation fills a slot only when THIS case has the thing the slot is for. An empty section is worse than none; an invented one is worse than both. Counts in examples are illustrative: two real findings beat three where the third is padding.

Hard exemption: a field a schema, parser or validator marks REQUIRED is a contract, not an example. Fill it, or write "none" with the reason; never omit it.

Diagnostic: typing content into a slot because the example had that slot, and you cannot name the fact in this case the slot exists to hold.

Provenance, lived cases and the full reasoning: `~/.claude/rules-provenance/examples-as-quotas.md`
