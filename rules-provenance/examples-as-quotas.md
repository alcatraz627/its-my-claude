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
updated: 2026-08-26
stale_after_days: 365
---

# Examples define capabilities, not quotas

A template sketch has to show every slot in order to define them. A faithful
implementation treats each slot as conditional: present when the case has that thing,
absent when it does not. The failure is reading the exhaustive example as the required
shape and manufacturing content to fill it: a Caveats section with an invented caveat,
a Risks row with a risk nobody holds, three bullets because the sample had three.

Owner-pinned across five consecutive daily digests (2026-08-16 through 2026-08-20), with
the generalisation asked for in the owner's words: "where else do we treat examples as
quotas". The affirm side is
`inferring the earned/conditional nature of structure even when the provided example
is necessarily exhaustive`, which is the behaviour this rule names as correct.

## The rule

1. Before filling a slot, ask whether THIS case has the thing the slot is for. If not,
   omit the slot. An empty section is worse than no section; an invented one is worse
   than both.
2. Counts in examples are illustrative. Two real findings beat three where the third
   is padding.
3. **Exemption, hard:** a field a schema, parser, or validator marks REQUIRED is not an
   example, it is a contract. Fill it, and when there is genuinely nothing to put
   there, say so in the field ("none", with the reason) rather than omitting it. This
   is the challenger's objection from the audit, and it is right: the rule must never
   produce a structurally incomplete artifact.

## Where this has bitten

Reports with a Blockers table holding no blockers. Decision pages with a `note` on
every item because the schema showed one. Rule files with a Provenance section that
restates the brief. In each, the reader spent attention on structure that carried
nothing.

## Diagnostic signal

You are typing content into a slot because the example had that slot, and you cannot
name the fact in this case that the slot exists to hold.

## Provenance

2026-08-23 i-dream audit P6 (dreams-analyst, owner-pinned), applied 2026-08-26 with the
required-field exemption. P13 (abandoned-threads, same file) discharged by this landing.
